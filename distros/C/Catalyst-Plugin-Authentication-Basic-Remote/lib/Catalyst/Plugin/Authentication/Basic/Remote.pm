package Catalyst::Plugin::Authentication::Basic::Remote;

use strict;
use base qw/Class::Accessor::Fast/;
use NEXT;

use LWP::UserAgent;
use MIME::Base64;

our $VERSION = '0.03';

__PACKAGE__->mk_accessors(qw/_login/);

=head1 NAME

Catalyst::Plugin::Authentication::Basic::Remote - (DEPRECATED) Basic authentication via remote host.

=head1 SYNOPSIS

  use Catalyst;
  MyApp->setup(qw/Authentication::Basic::Remote Session::FastMmap/);

  MyApp->config(
      authentication => {
          auth_url => 'http://example.com/',
	  
	  # Use Template when unauthorized. (option)
	  view_tt  => 'MyApp::V::TT',
	  template => '401.tt',

          # text in Authentication dialog (default="Require Authorization")
          auth_name => 'Require Authorization',
      },
  );

=head1 DEPRECATION NOTICE

This module has been deprecated. The use of a new Authentication style is recommended.

See L<Catalyst::Plugin::Authetnication> for detail.

=head1 DESCRIPTION

Catalyst authentication plugin that use remote host's Basic authentication.

It is only first time that plugin request to remote host for authentication.
After that, user infomation keeps in sessions.

=head1 METHODS

=over 4

=item prepare

=cut

sub prepare {
    my $c = shift;

    $c = $c->NEXT::prepare(@_);

    if ( $c->session->{user} and $c->session->{password} ) {
        $c->log->debug("Auth info found in Session:");
        $c->log->debug("user: ".$c->session->{user});
        $c->log->debug("pass: ".$c->session->{password});

        $c->req->{user}     = $c->session->{user};
        $c->req->{password} = $c->session->{password};
        return $c;
    }

    if ( $c->config->{authentication}->{auth_url} ) {
        if ( $c->req->header('Authorization') and  my ($tokens) = ( $c->req->header('Authorization') =~ /^Basic (.+)$/) ) {
            my ( $username, $password ) = split /:/, decode_base64($tokens);

            $c->log->debug("Authentication via ". $c->config->{authentication}->{auth_url} );
            $c->log->debug("user: $username");
            $c->log->debug("pass: $password");

            my $ua = LWP::UserAgent->new;
            my $req = HTTP::Request->new( HEAD => $c->config->{authentication}->{auth_url} );
            $req->header( 'Authorization' => $c->req->header('Authorization') );

            my $res = $ua->request($req);

            if ( $res->code ne '401' ) {
                $c->log->debug("Authorization successful.");
                $c->req->{user}         = $username;
                $c->session->{user}     = $username;
                $c->req->{password}     = $password;
                $c->session->{password} = $password;
                $c->_login(1);
            } else {
                $c->log->debug("Authorization failed.");
                $c->log->debug("Remote status line: " . $res->status_line);
            }
        }

        unless ( $c->req->{user} ) {
            $c->log->debug("return 401 Unauthorized.");
            $c->res->status(401);
            $c->res->header( 'WWW-Authenticate' =>
                  qq!Basic realm="@{[ $c->config->{authentication}->{auth_name} || 'Require Authorization' ]}"!
            );
        }
    }

    return $c;
}

=item dispatch

=cut

sub dispatch {
    my $c = shift;

    if ( $c->config->{authentication}->{template} ) {
        my $view = $c->config->{authentication}->{view_tt} || $c->config->{name};

        if ($view and $c->res->status eq '401') {
            $c->stash->{template} = $c->config->{authentication}->{template};
            $c->forward($view);
            return;
        }
    }

    return $c->NEXT::dispatch(@_);
}

=item login

=cut

sub login {
    my $c = shift;

    return unless $c->session->{user};
    return if ($c->_login);

    if ($c->config->{authentication}->{auth_url}) {
        $c->log->debug("Login method called");

        delete $c->session->{user} if $c->session->{user};
        delete $c->session->{password} if $c->session->{password};

        $c->res->status(401);
        $c->res->header( 'WWW-Authenticate' =>
              qq!Basic realm="@{[ $c->config->{authentication}->{auth_name} || 'Require Authorization' ]}"!
        );

        return 1;
    }

    return;
}

=item logout

=cut

sub logout {
    my $c = shift;

    return unless $c->config->{authentication}->{auth_url};

    delete $c->session->{user}     if $c->session->{user};
    delete $c->session->{password} if $c->session->{password};

    delete $c->req->{user}     if $c->req->{user};
    delete $c->req->{password} if $c->req->{password};

    1;
}

=back

=head1 SEE ALSO

L<Catalyst>

=head1 AUTHOR

Daisuke Murase, E<lt>typester@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Daisuke Murase

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

1;
