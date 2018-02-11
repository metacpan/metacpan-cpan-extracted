package Dancer2::Plugin::SPID;
$Dancer2::Plugin::SPID::VERSION = '0.10';
# ABSTRACT: SPID authentication for Dancer2 web applications
use Dancer2::Plugin;

has '_spid'         => (is => 'lazy');
has 'spid_button'   => (is => 'lazy', plugin_keyword => 1);

use Carp;
use Crypt::JWT qw(encode_jwt decode_jwt);
use Net::SPID;
use URI::Escape;

plugin_hooks qw(before_login after_login before_logout after_logout);

my $DEFAULT_JWT_SECRET = 'default.jwt.secret';

sub _build__spid {
    my ($self) = @_;
    
    # Initialize our Net::SPID object with information about this SP and the
    # CA certificate used for validation of IdP certificates (if cacert_file
    # is omitted, CA validation is skipped).
    my $spid = Net::SPID->new(
        sp_entityid     => $self->config->{sp_entityid},
        sp_key_file     => $self->config->{sp_key_file},
        sp_cert_file    => $self->config->{sp_cert_file},
        cacert_file     => $self->config->{cacert_file},
    );
    
    # Load Identity Providers from their XML metadata.
    $spid->load_idp_metadata($self->config->{idp_metadata_dir});

    return $spid;
}

sub _build_spid_button {
    my ($self, %args) = @_;
    
    return $self->_spid->get_button($self->config->{login_endpoint} . '?idp=%s');
}

sub spid_session :PluginKeyword {
    my ($self) = @_;
    return $self->dsl->session('__spid_session');
}

sub BUILD {
    my ($self) = @_;
    
    # Check that we have all the required config options.
    foreach my $key (qw(sp_entityid sp_key_file sp_cert_file idp_metadata_dir
        login_endpoint logout_endpoint)) {
        croak "Missing required config option for SPID: '$key'"
            if !$self->config->{$key};
    }
    
    # Create a hook for populating the spid_* variables in templates.
    $self->app->add_hook(Dancer2::Core::Hook->new(
        name => 'before_template_render',
        code => sub {
            my $vars = shift;
            
            my $url_cb = sub {
                my ($idp_id, %args) = @_;
                
                my $jwt = encode_jwt(
                    payload => {
                        idp         => $idp_id,
                        level       => ($args{level} || 1),
                        redirect    => ($args{redirect} || '/'),
                    },
                    alg => 'HS256',
                    key => $self->config->{jwt_secret} // $DEFAULT_JWT_SECRET,
                );
                sprintf '%s?t=%s',
                    $self->config->{login_endpoint},
                    $jwt;
            };
            
            $vars->{spid_button} = sub {
                my %args = %{$_[0]};
                $self->_spid->get_button($url_cb, %args);
            };
            
            $vars->{spid_login} = sub {
                my %args = %{$_[0]};
                $url_cb->($self->spid_session->idp_id, %args);
            };
            
            $vars->{spid_logout} = sub {
                my %args = %{$_[0]};
                
                sprintf '%s?redirect=%s',
                    $self->config->{logout_endpoint},
                    ($args{redirect} || '/');
            };
            
            $vars->{spid_session} = sub { $self->spid_session };
        }
    ));
    
    # Create a route for the login endpoint.
    # This endpoint initiates SSO through the user-chosen Identity Provider.
    $self->app->add_route(
        method  => 'get',
        regexp  => $self->config->{login_endpoint},
        code    => sub {
            $self->execute_plugin_hook('before_login');
            
            my $jwt = decode_jwt(
                token   => $self->dsl->param('t'),
                key     => $self->config->{jwt_secret} // $DEFAULT_JWT_SECRET,
            );
            
            # Check that we have the mandatory 'idp' parameter and that it matches
            # an available Identity Provider.
            my $idp = $self->_spid->get_idp($jwt->{idp})
                or return $self->dsl->status(400);
    
            # Craft the AuthnRequest.
            my $authnreq = $idp->authnrequest(
                #acs_url     => 'http://localhost:3000/spid-sso',
                acs_index   => 0,
                attr_index  => 1,
                level       => $jwt->{level} || 1,
            );
    
            # Save the ID of the Authnreq so that we can check it in the response
            # in order to prevent forgery.
            $self->dsl->session('__spid_authnreq_id' => $authnreq->id);
            
            # Save the redirect destination to be used after successful login.
            $self->dsl->session('__spid_sso_redirect' => $jwt->{redirect} || '/');
    
            # Redirect user to the IdP using its HTTP-Redirect binding.
            $self->dsl->redirect($authnreq->redirect_url, 302);
        },
    );
    
    # Create a route for the SSO endpoint (AssertionConsumerService).
    # During SSO, the Identity Provider will redirect user to this URL POSTing
    # the resulting assertion.
    $self->app->add_route(
        method  => 'post',
        regexp  => $self->config->{sso_endpoint},
        code    => sub {
            # Parse and verify the incoming assertion. This may throw exceptions so we
            # enclose it in an eval {} block.
            my $assertion = eval {
                $self->_spid->parse_assertion(
                    $self->dsl->param('SAMLResponse'),
                    $self->dsl->session('__spid_authnreq_id'),  # Match the ID of our authentication request for increased security.
                );
            };
            
            # Clear the ID of the outgoing Authnreq, regardless of the result.
            $self->dsl->session('__spid_authnreq_id' => undef);
            
            # TODO: better error handling:
            # - authentication failure
            # - authentication cancelled by user
            # - temporary server error
            # - unavailable SPID level
            
            # In case of SSO failure, display an error page.
            if (!$assertion) {
                $self->dsl->warning("Bad Assertion received: $@");
                $self->dsl->status(400);
                $self->dsl->content_type('text/plain');
                return "Bad Assertion: $@";
            }
            
            # Login successful! Initialize our application session and store
            # the SPID information for later retrieval.
            # $assertion->spid_session is a Net::SPID::Session object which is a
            # simple hashref thus it's easily serializable.
            # TODO: this should be stored in a database instead of the current Dancer
            # session, and it should be indexed by SPID SessionID so that we can delete
            # it when we get a LogoutRequest from an IdP.
            $self->dsl->session('__spid_session' => $assertion->spid_session);
            
            # TODO: handle SPID level upgrade:
            # - does session ID remain the same? better assume it changes
            
            $self->dsl->redirect($self->dsl->session('__spid_sso_redirect'));
            $self->dsl->session('__spid_sso_redirect' => undef);
            
            $self->execute_plugin_hook('after_login');
        },
    );
    
    # Create a route for the logout endpoint.
    $self->app->add_route(
        method  => 'get',
        regexp  => $self->config->{logout_endpoint},
        code    => sub {
            # If we don't have an open SPID session, do nothing.
            return $self->dsl->redirect('/')
                if !$self->spid_session;
            
            $self->execute_plugin_hook('before_logout');
            
            # Craft the LogoutRequest.
            my $idp = $self->_spid->get_idp($self->spid_session->idp_id);
            my $logoutreq = $idp->logoutrequest(session => $self->spid_session);
            
            # Save the ID of the LogoutRequest so that we can check it in the response
            # in order to prevent forgery.
            $self->dsl->session('__spid_logoutreq_id' => $logoutreq->id);
            
            # Redirect user to the Identity Provider for logout.
            $self->dsl->redirect($logoutreq->redirect_url, 302);
        },
    );
    
    # Create a route for the SingleLogoutService endpoint.
    # This endpoint exposes a SingleLogoutService for our Service Provider, using
    # a HTTP-POST or HTTP-Redirect binding (it does not support SOAP).
    # Identity Providers can direct both LogoutRequest and LogoutResponse messages
    # to this endpoint.
    $self->app->add_route(
        method  => 'post',
        regexp  => $self->config->{slo_endpoint},
        code    => sub {
            if ($self->dsl->param('SAMLResponse') && $self->dsl->session('__spid_logoutreq_id')) {
                my $response = eval {
                    $self->_spid->parse_logoutresponse(
                        $self->dsl->param('SAMLResponse'),
                        $self->dsl->session('__spid_logoutreq_id'),
                    )
                };
                
                # Clear the ID of the outgoing LogoutRequest, regardless of whether we accept the response or not.
                $self->dsl->session('spid_logoutreq_id' => undef);
                
                if ($@) {
                    $self->dsl->warning("Bad LogoutResponse received: $@");
                    $self->dsl->status(400);
                    $self->dsl->content_type('text/plain');
                    return "Bad LogoutResponse: $@";
                }
                
                # Call the hook *before* clearing spid_session.
                $self->execute_plugin_hook('after_logout', $response->success);
                
                # Logout was successful! Clear the local session.
                $self->dsl->session('__spid_session' => undef);
                
                # Redirect user back to main page.
                $self->dsl->redirect('/');
            } elsif ($self->dsl->param('SAMLRequest')) {
                my $request = eval {
                    $spid->parse_logoutrequest($self->dsl->param('SAMLRequest'))
                };
                
                if ($@) {
                    $self->dsl->warning("Bad LogoutRequest received: $@");
                    $self->dsl->status(400);
                    $self->dsl->content_type('text/plain');
                    return "Bad LogoutRequest: $@";
                }
                
                # Now we should retrieve the local session corresponding to the SPID
                # session $request->session. However, since we are implementing a HTTP-POST
                # binding, this HTTP request comes from the user agent so the current Dancer
                # session is automatically the right one. This simplifies things a lot as
                # retrieving another session by SPID session ID is tricky without a more
                # complex architecture.
                my $status = 'success';
                if ($request->session eq $self->spid_session->session) {
                    # Call the hook *before* clearing spid_session.
                    $self->execute_plugin_hook('after_logout', 'success');
                    
                    $self->dsl->session('__spid_session' => undef);
                } else {
                    $status = 'partial';
                    $self->dsl->warning(
                        sprintf "SAML LogoutRequest session (%s) does not match current SPID session (%s)",
                            $request->session, $self->spid_session->session
                    );
                }
                
                # Craft a LogoutResponse and send it back to the Identity Provider.
                my $idp = $self->_spid->get_idp($request->issuer);
                my $response = $idp->logoutresponse(in_response_to => $request->id, status => $status);
    
                # Redirect user to the Identity Provider; it will continue handling the logout process.
                $self->dsl->redirect($response->redirect_url, 302);
            } else {
                $self->dsl->status(400);
            }
        },
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::SPID - SPID authentication for Dancer2 web applications

=head1 VERSION

version 0.10

=head1 SYNOPSIS

    use Dancer2;
    use Dancer2::Plugin::SPID;
    
    hook 'plugin.SPID.after_login' => sub {
        # log assertion:
        info "User " . spid_session->nameid . " logged in";
        info "SPID Assertion: " . spid_session->assertion_xml;
    };
    
    hook 'plugin.SPID.after_logout' => sub {
        debug "User " . spid_session->nameid . " logged out";
    };

    dance;

=head1 ABSTRACT

This Perl module is a plugin for the L<Dancer2> web framework. It allows developers of SPID Service Providers to easily add SPID authentication to their Dancer2 applications. L<SPID|https://www.spid.gov.it/> is the Italian digital identity system, which enables citizens to access all public services with single set of credentials.

This module provides the highest level of abstraction and ease of use for integration of SPID in a Dancer2 web application. Just set a few configuration options and you'll be able to generate the HTML markup for the SPID button on the fly (to be completed) in order to place it wherever you want in your templates. This plugin will automatically generate all the routes for SAML bindings, so you don't need to perform any plumbing manually. Hooks are provided for customizing behavior.

See the F<example/> directory for a demo application.

This is module is based on L<Net::SPID> which provides the lower-level framework-independent implementation of SPID for Perl.

=head1 CONFIGURATION

Configuration options can be set in the Dancer2 config file:

    plugins:
      SPID:
        sp_entityid: "https://www.prova.it/"
        sp_key_file: "sp.key"
        sp_cert_file: "sp.pem"
        idp_metadata_dir: "idp_metadata/"
        login_endpoint: "/spid-login"
        logout_endpoint: "/spid-logout"
        sso_endpoint: "/spid-sso"
        slo_endpoint: "/spid-slo"

=over

=item I<sp_entityid>

(Required.) The entityID value for this Service Provider. According to SPID regulations, this should be a URI.

=item I<sp_key_file>

(Required.) The absolute or relative file path to our private key file.

=item I<sp_cert_file>

(Required.) The absolute or relative file path to our certificate file.

=item I<idp_metadatadir>

(Required.) The absolute or relative path to a directory containing metadata files for Identity Providers in XML format (their file names are expected to end in C<.xml>).

=item I<login_endpoint>

(Required.) The relative HTTP path we want to use for the SPID button login action. A route handler will be created for this path that generates an AuthnRequest and redirects the user to the chosen Identity Provider using the HTTP-Redirect binding.

=item I<logout_endpoint>

(Required.) The relative HTTP path we want to use for the logout action. A route handler will be created for this path that generates a LogoutRequest and redirects the user to the current Identity Provider using the HTTP-Redirect binding.

=item I<sso_endpoint>

(Required.) The relative HTTP path we want to expose as AssertionConsumerService. This must match the URL advertised in the Service Provider metadata.

=item I<slo_endpoint>

(Required.) The relative HTTP path we want to expose as SingleLogoutService. This must match the URL advertised in the Service Provider metadata.

=item I<jwt_secret>

(Optional.) The secret using for encoding relay state data.

=back

=head1 KEYWORDS

The following keywords are available.

=head2 spid_session

This keyword returns the current L<Net::SPID::Session> object if any. It can be used to check whether we have an active SPID session.

    if (spid_session) {
        template 'user';
    } else {
        template 'index';
    }

This keyword is also available in templates, so you can use it for accessing attributes:

        Attribute: [% spid_session.attributes.MyAttribute %]

=head1 TEMPLATE KEYWORDS

=head2 spid_button

This keyword generates the HTML markup for the SPID login button. Just place it wherever you want the button to appear:

    [% spid_button(level => 2, redirect => '/') %]

The following arguments can be supplied:

=over

=item I<level>

(Optional.) The required SPID level, expressed as an integer (1, 2, or 3). If omitted, 1 will be requested.

=item I<redirect>

(Optional.) The relative HTTP path where user will be redirected after successful login. If omitted, C</> will be used.

=back

=head2 spid_login

This keyword will return the URL for directing the user to the current Identity Provider in order to perform a SPID level upgrade. The URL is preformatted with the HTTP-Redirect AuthnRequest. It accepts the same arguments described for L<spid_button>. You must check whether the user has an active SPID session before using it.

    [% IF spid_session %]
        <a href="[% spid_login(level => 2, redirect => '/') %]">Upgrade to L2</a>
    [% END %]

=head2 spid_logout

This keyword will return the URL for initiating a Single Logout by directing the user to the current Identity Provider with a LogoutRequest. You must check whether the user has an active SPID session before using it. It accepts an optional C<redirect> argument as described for L<spid_button>.

    [% IF spid_session %]
        <a href="[% spid_logout(redirect => '/') %]">Logout</a>
    [% END %]

=head1 HOOKS

=head2 before_login

This hook is called when the login endpoint is called (i.e. the SPID button is clicked or user visited the upgrade URL returned by L<spid_login>) and the AuthnRequest is about to be crafted.

    hook 'plugin.SPID.before_login' => sub {
        info "User is initiating SSO";
    };

=head2 after_login

This hook is called after the user returns to us after initiating the SPID session with the Identity Provider.

    hook 'plugin.SPID.after_login' => sub {
        info "User " . spid_session->nameid . " logged in";
    
        # Here you might want to create the user in your local database or do more
        # things for initializing the session. Make sure everything you do here is
        # idempotent.
    
        # Log assertion as required by the SPID rules.
        # Warning: in order to comply with rules, this should be logged in a more
        # permanent way than regular Dancer logs, so you'd better use a database
        # or a dedicated log file.
        info "SPID Assertion: " . spid_session->assertion_xml;
    };

=head2 before_logout

This hook is called when the logout endpoint is called and the LogoutRequest
is about to be crafted.

    hook 'plugin.SPID.before_logout' => sub {
        debug "User " . spid_session->nameid . " is about to logout";
    };

=head2 after_logout

This hook is called when a SPID session is terminated. Note that this might be triggered also when user initiated logout from another Service Provider or directly within the Identity Provider, thus without calling our logout endpoint and the L<before_logout> hook).
L<spid_session> will be cleared I<after> this hook is executed, so you can use it.

    hook 'plugin.SPID.after_logout' => sub {
        my $success = shift;  # 'success' or 'partial'
        debug "User " . spid_session->nameid . " logged out";
    };

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Alessandro Ranellucci.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
