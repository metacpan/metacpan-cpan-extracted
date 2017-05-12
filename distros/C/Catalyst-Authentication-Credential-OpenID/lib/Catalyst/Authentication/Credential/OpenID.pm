package Catalyst::Authentication::Credential::OpenID;
use warnings;
use strict;
use base "Class::Accessor::Fast";

__PACKAGE__->mk_accessors(qw/
    realm debug secret
    openid_field
    consumer_secret
    ua_class
    ua_args
    extension_args
    errors_are_fatal
    extensions
    trust_root
    flatten_extensions_into_user
/);

our $VERSION = "0.19";

use Net::OpenID::Consumer;
use Catalyst::Exception ();

sub new {
    my ( $class, $config, $c, $realm ) = @_;
    my $self = {
                %{ $config },
                %{ $realm->{config} }
               };
    bless $self, $class;

    # 2.0 spec says "SHOULD" be named "openid_identifier."
    $self->{openid_field} ||= "openid_identifier";

    my $secret = $self->{consumer_secret} ||= join("+",
                                                   __PACKAGE__,
                                                   $VERSION,
                                                   sort keys %{ $c->config }
                                                  );

    $secret = substr($secret,0,255) if length $secret > 255;
    $self->secret($secret);
    # If user has no preference we prefer L::PA b/c it can prevent DoS attacks.
    my $ua_class = $self->{ua_class} ||= eval "use LWPx::ParanoidAgent" ?
        "LWPx::ParanoidAgent" : "LWP::UserAgent";

    my $agent_class = $self->ua_class;
    eval "require $agent_class"
        or Catalyst::Exception->throw("Could not 'require' user agent class " .
                                      $self->ua_class);

    $c->log->debug("Setting consumer secret: " . $secret) if $self->debug;

    return $self;
}

sub authenticate {
    my ( $self, $c, $realm, $authinfo ) = @_;

    $c->log->debug("authenticate() called from " . $c->request->uri) if $self->debug;

    my $field = $self->openid_field;

    my $claimed_uri = $authinfo->{ $field };

    # Its security related so we want to be explicit about GET/POST param retrieval.
    $claimed_uri ||= $c->req->method eq 'GET' ? 
        $c->req->query_params->{ $field } : $c->req->body_params->{ $field };


    my $csr = Net::OpenID::Consumer->new(
        ua => $self->ua_class->new(%{$self->ua_args || {}}),
        args => $c->req->params,
        consumer_secret => $self->secret,
    );

    if ( $self->extension_args )
    {
        $c->log->warn("The configuration key 'extension_args' is ignored; use 'extensions'");
    }

    my %extensions = ref($self->extensions) eq "HASH" ?
        %{ $self->extensions } : ref($self->extensions) eq "ARRAY" ?
        @{ $self->extensions } : ();

    if ( $claimed_uri )
    {
        my $current = $c->uri_for("/" . $c->req->path); # clear query/fragment...

        my $identity = $csr->claimed_identity($claimed_uri);
        unless ( $identity )
        {
            if ( $self->errors_are_fatal )
            {
                Catalyst::Exception->throw($csr->err);
            }
            else
            {
                $c->log->error($csr->err . " -- $claimed_uri");
                return;
            }
        }

        for my $key ( keys %extensions )
        {
            $identity->set_extension_args($key, $extensions{$key});
        }

        my $check_url = $identity->check_url(
            return_to  => $current . '?openid-check=1',
            trust_root => $self->trust_root || $current,
            delayed_return => 1,
        );
        $c->res->redirect($check_url);
        $c->detach();
    }
    elsif ( $c->req->params->{'openid-check'} )
    {
        if ( my $setup_url = $csr->user_setup_url )
        {
            $c->res->redirect($setup_url);
            return;
        }
        elsif ( $csr->user_cancel )
        {
            return;
        }
        elsif ( my $identity = $csr->verified_identity )
        {
            # This is where we ought to build an OpenID user and verify against the spec.
            my $user = +{ map { $_ => scalar $identity->$_ }
                qw( url display rss atom foaf declared_rss declared_atom declared_foaf foafmaker ) };
            # Dude, I did not design the array as hash spec. Don't curse me [apv].
            for my $key ( keys %extensions )
            {
                my $vals = $identity->signed_extension_fields($key);
                $user->{extensions}->{$key} = $vals;
                if ( $self->flatten_extensions_into_user )
                {
                    $user->{$_} = $vals->{$_} for keys %{$vals};
                }
            }

            my $user_obj = $realm->find_user($user, $c);

            if ( ref $user_obj )
            {
                return $user_obj;
            }
            else
            {
                $c->log->debug("Verified OpenID identity failed to load with find_user; bad user_class? Try 'Null.'") if $self->debug;
                return;
            }
        }
        else
        {
            $self->errors_are_fatal ?
                Catalyst::Exception->throw("Error validating identity: " . $csr->err)
                      :
                $c->log->error( $csr->err);
        }
    }
    return;
}

1;

__END__

=head1 NAME

Catalyst::Authentication::Credential::OpenID - OpenID credential for Catalyst::Plugin::Authentication framework.

=head1 BACKWARDS COMPATIBILITY CHANGES

=head2 EXTENSION_ARGS v EXTENSIONS

B<NB>: The extensions were previously configured under the key C<extension_args>. They are now configured under C<extensions>. C<extension_args> is no longer honored.

As previously noted, L</EXTENSIONS TO OPENID>, I have not tested the extensions. I would be grateful for any feedback or, better, tests.

=head2 FATALS

The problems encountered by failed OpenID operations have always been fatals in the past. This is unexpected behavior for most users as it differs from other credentials. Authentication errors here are no longer fatal. Debug/error output is improved to offset the loss of information. If for some reason you would prefer the legacy/fatal behavior, set the configuration variable C<errors_are_fatal> to a true value.

=head1 SYNOPSIS

In MyApp.pm-

 use Catalyst qw/
    Authentication
    Session
    Session::Store::FastMmap
    Session::State::Cookie
 /;

Somewhere in myapp.conf-

 <Plugin::Authentication>
     default_realm   openid
     <realms>
         <openid>
             <credential>
                 class   OpenID
                 ua_class   LWP::UserAgent
             </credential>
         </openid>
     </realms>
 </Plugin::Authentication>

Or in your myapp.yml if you're using L<YAML> instead-

 Plugin::Authentication:
   default_realm: openid
   realms:
     openid:
       credential:
         class: OpenID
         ua_class: LWP::UserAgent

In a controller, perhaps C<Root::openid>-

 sub openid : Local {
      my($self, $c) = @_;

      if ( $c->authenticate() )
      {
          $c->flash(message => "You signed in with OpenID!");
          $c->res->redirect( $c->uri_for('/') );
      }
      else
      {
          # Present OpenID form.
      }
 }

And a L<Template> to match in C<openid.tt>-

 <form action="[% c.uri_for('/openid') %]" method="GET" name="openid">
 <input type="text" name="openid_identifier" class="openid" />
 <input type="submit" value="Sign in with OpenID" />
 </form>

=head1 DESCRIPTION

This is the B<third> OpenID related authentication piece for
L<Catalyst>. The first E<mdash> L<Catalyst::Plugin::Authentication::OpenID>
by Benjamin Trott E<mdash> was deprecated by the second E<mdash>
L<Catalyst::Plugin::Authentication::Credential::OpenID> by Tatsuhiko
Miyagawa E<mdash> and this is an attempt to deprecate both by conforming to
the newish, at the time of this module's inception, realm-based
authentication in L<Catalyst::Plugin::Authentication>.

 1. Catalyst::Plugin::Authentication::OpenID
 2. Catalyst::Plugin::Authentication::Credential::OpenID
 3. Catalyst::Authentication::Credential::OpenID

The benefit of this version is that you can use an arbitrary number of
authentication systems in your L<Catalyst> application and configure
and call all of them in the same way.

Note that both earlier versions of OpenID authentication use the method
C<authenticate_openid()>. This module uses C<authenticate()> and
relies on you to specify the realm. You can specify the realm as the
default in the configuration or inline with each
C<authenticate()> call; more below.

This module functions quite differently internally from the others.
See L<Catalyst::Plugin::Authentication::Internals> for more about this
implementation.

=head1 METHODS

=over 4

=item $c->authenticate({},"your_openid_realm");

Call to authenticate the user via OpenID. Returns false if
authorization is unsuccessful. Sets the user into the session and
returns the user object if authentication succeeds.

You can see in the call above that the authentication hash is empty.
The implicit OpenID parameter is, as the 2.0 specification says it
SHOULD be, B<openid_identifier>. You can set it anything you like in
your realm configuration, though, under the key C<openid_field>. If
you call C<authenticate()> with the empty info hash and no configured
C<openid_field> then only C<openid_identifier> is checked.

It implicitly does this (sort of, it checks the request method too)-

 my $claimed_uri = $c->req->params->{openid_identifier};
 $c->authenticate({openid_identifier => $claimed_uri});

=item Catalyst::Authentication::Credential::OpenID->new()

You will never call this. Catalyst does it for you. The only important
thing you might like to know about it is that it merges its realm
configuration with its configuration proper. If this doesn't mean
anything to you, don't worry.

=back

=head2 USER METHODS

Currently the only supported user class is L<Catalyst::Plugin::Authentication::User::Hash>.

=over 4

=item $c->user->url

=item $c->user->display

=item $c->user->rss 

=item $c->user->atom

=item $c->user->foaf

=item $c->user->declared_rss

=item $c->user->declared_atom

=item $c->user->declared_foaf

=item $c->user->foafmaker

=back

See L<Net::OpenID::VerifiedIdentity> for details.

=head1 CONFIGURATION

Catalyst authentication is now configured entirely from your
application's configuration. Do not, for example, put
C<Credential::OpenID> into your C<use Catalyst ...> statement.
Instead, tell your application that in one of your authentication
realms you will use the credential.

In your application the following will give you two different
authentication realms. One called "members" which authenticates with
clear text passwords and one called "openid" which uses... uh, OpenID.

 __PACKAGE__->config
    ( name => "MyApp",
      "Plugin::Authentication" => {
          default_realm => "members",
          realms => {
              members => {
                  credential => {
                      class => "Password",
                      password_field => "password",
                      password_type => "clear"
                      },
                          store => {
                              class => "Minimal",
                              users => {
                                  paco => {
                                      password => "l4s4v3n7ur45",
                                  },
                              }
                          }
              },
              openid => {
                  credential => {
                      class => "OpenID",
                      store => {
                          class => "OpenID",
                      },
                      consumer_secret => "Don't bother setting",
                      ua_class => "LWP::UserAgent",
                      # whitelist is only relevant for LWPx::ParanoidAgent
                      ua_args => {
                          whitelisted_hosts => [qw/ 127.0.0.1 localhost /],
                      },
                      extensions => [
                          'http://openid.net/extensions/sreg/1.1',
                          {
                           required => 'email',
                           optional => 'fullname,nickname,timezone',
                          },
                      ],
                  },
              },
          },
      }
    );

This is the same configuration in the default L<Catalyst> configuration format from L<Config::General>.

 name   MyApp
 <Plugin::Authentication>
     default_realm   members
     <realms>
         <members>
             <store>
                 class   Minimal
                 <users>
                     <paco>
                         password   l4s4v3n7ur45
                     </paco>
                 </users>
             </store>
             <credential>
                 password_field   password
                 password_type   clear
                 class   Password
             </credential>
         </members>
         <openid>
             <credential>
                 <store>
                     class   OpenID
                 </store>
                 class   OpenID
                 <ua_args>
                     whitelisted_hosts   127.0.0.1
                     whitelisted_hosts   localhost
                 </ua_args>
                 consumer_secret   Don't bother setting
                 ua_class   LWP::UserAgent
                 <extensions>
                     http://openid.net/extensions/sreg/1.1
                     required   email
                     optional   fullname,nickname,timezone
                 </extensions>
             </credential>
         </openid>
     </realms>
 </Plugin::Authentication>

And now, the same configuration in L<YAML>. B<NB>: L<YAML> is whitespace sensitive.

 name: MyApp
 Plugin::Authentication:
   default_realm: members
   realms:
     members:
       credential:
         class: Password
         password_field: password
         password_type: clear
       store:
         class: Minimal
         users:
           paco:
             password: l4s4v3n7ur45
     openid:
       credential:
         class: OpenID
         store:
           class: OpenID
         consumer_secret: Don't bother setting
         ua_class: LWP::UserAgent
         ua_args:
           # whitelist is only relevant for LWPx::ParanoidAgent
           whitelisted_hosts:
             - 127.0.0.1
             - localhost
         extensions:
             - http://openid.net/extensions/sreg/1.1
             - required: email
               optional: fullname,nickname,timezone

B<NB>: There is no OpenID store yet.

You can set C<trust_root> now too. This is experimental and I have no idea if it's right or could be better. Right now it must be a URI. It was submitted as a path but this seems to limit it to the Catalyst app and while easier to dynamically generate no matter where the app starts, it seems like the wrong way to go. Let me know if that's mistaken.

=head2 EXTENSIONS TO OPENID

The Simple Registration--L<http://openid.net/extensions/sreg/1.1>--(SREG) extension to OpenID is supported in the L<Net::OpenID> family now. Experimental support for it is included here as of v0.12. SREG is the only supported extension in OpenID 1.1. It's experimental in the sense it's a new interface and barely tested. Support for OpenID extensions is here to stay.

Google's OpenID is also now supported. Uh, I think.

Here is a snippet from Thorben JE<auml>ndling combining Sreg and Google's extenstionsE<ndash>

 'Plugin::Authentication' => {
    openid => {
        credential => {
            class => 'OpenID',
            ua_class => 'LWP::UserAgent',
            extensions => {
                'http://openid.net/extensions/sreg/1.1' => {
                    required => 'nickname,email,fullname',
                    optional => 'timezone,language,dob,country,gender'
                },
                'http://openid.net/srv/ax/1.0' => {
                    mode => 'fetch_request',
                    'type.nickname' => 'http://axschema.org/namePerson/friendly',
                    'type.email' => 'http://axschema.org/contact/email',
                    'type.fullname' => 'http://axschema.org/namePerson',
                    'type.firstname' => 'http://axschema.org/namePerson/first',
                    'type.lastname' => 'http://axschema.org/namePerson/last',
                    'type.dob' => 'http://axschema.org/birthDate',
                    'type.gender' => 'http://axschema.org/person/gender',
                    'type.country' => 'http://axschema.org/contact/country/home',
                    'type.language' => 'http://axschema.org/pref/language',
                    'type.timezone' => 'http://axschema.org/pref/timezone',
                    required => 'nickname,fullname,email,firstname,lastname',
                    if_available => 'dob,gender,country,language,timezone',
            },
            },
        },
    },
    default_realm => 'openid',
 };


=head2 MORE ON CONFIGURATION

=over 4

=item ua_args and ua_class

L<LWPx::ParanoidAgent> is the default agent E<mdash> C<ua_class> E<mdash> if it's available, L<LWP::UserAgent> if not. You don't have to set it. I recommend that you do B<not> override it. You can with any well behaved L<LWP::UserAgent>. You probably should not. L<LWPx::ParanoidAgent> buys you many defenses and extra security checks. When you allow your application users freedom to initiate external requests, you open an avenue for DoS (denial of service) attacks. L<LWPx::ParanoidAgent> defends against this. L<LWP::UserAgent> and any regular subclass of it will not.

=item consumer_secret

The underlying L<Net::OpenID::Consumer> object is seeded with a secret. If it's important to you to set your own, you can. The default uses this package name + its version + the sorted configuration keys of your Catalyst application (chopped at 255 characters if it's longer). This should generally be superior to any fixed string.

=back

=head1 TODO

Option to suppress fatals.

Support more of the new methods in the L<Net::OpenID> kit.

There are some interesting implications with this sort of setup. Does a user aggregate realms or can a user be signed in under more than one realm? The documents could contain a recipe of the self-answering OpenID end-point that is in the tests.

Debug statements need to be both expanded and limited via realm configuration.

Better diagnostics in errors. Debug info at all consumer calls.

Roles from provider domains? Mapped? Direct? A generic "openid" auto_role?

=head1 THANKS

To Benjamin Trott (L<Catalyst::Plugin::Authentication::OpenID>), Tatsuhiko Miyagawa (L<Catalyst::Plugin::Authentication::Credential::OpenID>), Brad Fitzpatrick for the great OpenID stuff, Martin Atkins for picking up the code to handle OpenID 2.0, and Jay Kuri and everyone else who has made Catalyst such a wonderful framework.

Menno Blom provided a bug fix and the hook to use OpenID extensions.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2009, Ashley Pond V C<< <ashley@cpan.org> >>. Some of Tatsuhiko Miyagawa's work is reused here.

This module is free software; you can redistribute it and modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty for the software, to the extent permitted by applicable law. Except
when otherwise stated in writing the copyright holders and other parties provide the software "as is" without warranty of any kind, either
expressed or implied, including, but not limited to, the implied warranties of merchantability and fitness for a particular purpose. The
entire risk as to the quality and performance of the software is with you. Should the software prove defective, you assume the cost of all
necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing will any copyright holder, or any other party who may modify or
redistribute the software as permitted by the above license, be liable to you for damages, including any general, special, incidental, or
consequential damages arising out of the use or inability to use the software (including but not limited to loss of data or data being
rendered inaccurate or losses sustained by you or third parties or a failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of such damages.

=head1 SEE ALSO

=over 4

=item OpenID

L<Net::OpenID::Server>, L<Net::OpenID::VerifiedIdentity>, L<Net::OpenID::Consumer>, L<http://openid.net/>,
L<http://openid.net/developers/specs/>, and L<http://openid.net/extensions/sreg/1.1>.

=item Catalyst Authentication

L<Catalyst>, L<Catalyst::Plugin::Authentication>, L<Catalyst::Manual::Tutorial::Authorization>, and
L<Catalyst::Manual::Tutorial::Authentication>.

=item Catalyst Configuration

L<Catalyst::Plugin::ConfigLoader>, L<Config::General>, and L<YAML>.

=item Miscellaneous

L<Catalyst::Manual::Tutorial>, L<Template>, L<LWPx::ParanoidAgent>.

=back

=cut
