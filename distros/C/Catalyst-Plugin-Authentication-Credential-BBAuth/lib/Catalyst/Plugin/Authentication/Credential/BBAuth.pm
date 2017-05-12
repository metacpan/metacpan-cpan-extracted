package Catalyst::Plugin::Authentication::Credential::BBAuth;
use strict;
use warnings;

use NEXT;
use Yahoo::BBAuth;
use UNIVERSAL::require;

our $VERSION = '0.03';

sub setup {
    my $c = shift;
    my $config = $c->config->{authentication}->{bbauth} ||= {};
    unless (exists $config->{bbauth_object}) {
        $config->{user_class} ||= 'Catalyst::Plugin::Authentication::User::Hash';
        $config->{user_class}->require;
        $config->{bbauth_object} = Yahoo::BBAuth->new(
            appid  => $config->{appid},
            secret => $config->{secret},
        );
    }
    $c->NEXT::setup(@_);
}

sub authenticate_bbauth_url {
    my ($c, %param) = @_;
    $param{send_userhash} = 1;
    $c->config->{authentication}->{bbauth}->{bbauth_object}->auth_url(%param);
}

sub authenticate_bbauth {
    my $c = shift;
    return unless $c->req->params->{token};
    my $config = $c->config->{authentication}->{bbauth};
    my $bbauth = $config->{bbauth_object};
    if ($bbauth->validate_sig) {
        $c->log->debug('Successfully authenticated.') if $c->debug;
        my $user = { userhash => $bbauth->userhash };
        my $store = $config->{store} || $c->default_auth_store;
        if ($store and my $store_user = $store->get_user($user->{userhash}, $user)) {
            $c->set_authenticated($store_user);
        } else {
            $user = $config->{user_class}->new($user);
            $c->set_authenticated($user);
        }
        return 1;
    } else {
        $c->log->debug(
            sprintf(q/Failed to authenticate. Reason: '%s'/,
                $bbauth->sig_validation_error)
        ) if $c->debug;
        return;
    }
}

1;
__END__

=head1 NAME

Catalyst::Plugin::Authentication::Credential::BBAuth - Yahoo! Browser-Based Authentication for Catalyst.

=head1 SYNOPSIS

  use Catalyst qw(
      Authentication
      Authentication::Credential::BBAuth
      Session
      Session::Store::FastMmap
      Session::State::Cookie
  );

  MyApp->config(
      authentication => {
          use_session => 1, # default 1. see C::P::Authentication
          bbauth      => {
              appid  => 'your appid',
              secret => 'your secret',
          },
      },
  );

  sub default : Private {
      my ( $self, $c ) = @_;
      if ( $c->user_exists ) {
          # $c->user setted
      }
  }

  # redirect BBAuth login form
  sub login : Local {
      my ( $self, $c ) = @_;
      $c->res->redirect( $c->authenticate_bbauth_url );
  }

  # login callback url
  sub auth : Path('/auth') {
      my ( $self, $c ) = @_;
      if ( $c->authenticate_bbauth ) {
          # login successful
          $c->res->redirect( $c->uri_for('/') );
      } else {
          # login failed
      }
  }

=head1 DESCRIPTION

This module provide authentication via Yahoo! Browser-Based Authentication, using it's api.

=head1 EXTENDED METHODS

=head2 setup

Fills the config with defaults.

=head1 METHODS

=head2 authenticate_bbauth_url(%param)

Returns BBAuth login form url.

=head2 authenticate_bbauth

Authenticate by BBAuth.

Returns login succeeded or not.

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item * L<Catalyst::Plugin::Authentication>

=item * L<Yahoo::BBAuth>

=back

=cut

