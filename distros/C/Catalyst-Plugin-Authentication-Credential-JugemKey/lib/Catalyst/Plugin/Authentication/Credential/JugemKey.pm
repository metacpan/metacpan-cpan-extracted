package Catalyst::Plugin::Authentication::Credential::JugemKey;

use warnings;
use strict;

our $VERSION = '0.04';

use WebService::JugemKey::Auth;
use UNIVERSAL::require;
use NEXT;

sub setup {
    my $c = shift;

    my $config = $c->config->{authentication}->{jugemkey} ||= {};

    $config->{jugemkey_object} ||= do {
        ( $config->{user_class}
              ||= 'Catalyst::Plugin::Authentication::User::Hash' )->require;

        my $api = WebService::JugemKey::Auth->new({
            api_key => $config->{api_key},
            secret  => $config->{secret},
        });
        $api->perms( $config->{perms} );
        $api;
    };

    $c->NEXT::setup(@_);
}

sub authenticate_jugemkey_url {
    my ($c, $params) = @_;
    $c->config->{authentication}->{jugemkey}->{jugemkey_object}->uri_to_login($params);
}

sub authenticate_jugemkey_get_token {
    my $c = shift;

    my $config = $c->config->{authentication}->{jugemkey};
    my $jugemkey = $config->{jugemkey_object};

    my $frob = $c->req->params->{frob} or return;
    if ( my $user = $jugemkey->get_token($frob) ) {
        $c->log->debug("Successfully get token of user '$user->name'.")
            if $c->debug;

        my $store = $config->{store} || $c->default_auth_store;
        if ( $store
            and my $store_user = $store->get_user( $user->name, $user ) )
        {
            $c->set_authenticated($store_user);
        }
        else {
            $user = $config->{user_class}->new($user);
            $c->set_authenticated($user);
        }

        return $user;
    }
    else {
        $c->log->debug(
            sprintf "Failed to authenticate jugemkey.  Reason: '%s'",
            $jugemkey->errstr, )
            if $c->debug;

        return;
    }
}


=head1 NAME

Catalyst::Plugin::Authentication::Credential::JugemKey - JugemKey authentication plugin for Catalyst

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

  # load plugin and setup
  use Catalyst qw(
      Authentication
      Authentication::Credential::JugemKey
      Session
      Session::Store::FastMmap
      Session::State::Cookie
  );

  __PACKAGE__->config->{authentication}->{jugemkey} = {
      api_key => 'your api_key',
      secret  => 'your shared secret',
      perms   => 'permission',
  };

  # in controller
  # redirect login url
  sub login : Path('/jugemkey/login') {
      my ( $self, $c ) = @_;
      $c->res->redirect(
          $c->authenticate_jugemkey_url({
              callback_url => 'http://your_callback_url/jugemkey/auth',
              param1       => 'value1',
              param2       => 'value2',
          })
      );
  }

  # callback url
  sub auth : Path('/jugemkey/auth') {
      my ( $self, $c ) = @_;

      if ( my $user = $c->authenticate_jugemkey_get_token ) {
          # login successful
          $c->session->{name}  = $user->name;
          $c->session->{token} = $user->token;
          $c->res->redirect( $c->uri_for('/') );
      }
      else {
          # something wrong
      }
  }

=head1 METHODS

=over 2

=item authenticate_jugemkey_url

Creates login url.

=item authenticate_jugemkey_get_token

Exchange frob for token and JugemKey user name.

=back

=head1 INTERNAL METHODS

=over 1

=item setup

=back

=head1 SEE ALSO

L<WebService::JugemKey::Auth>, L<http://jugemkey.jp/api/auth/>

=head1 AUTHOR

Gosuke Miyashita, C<< <gosukenator at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-plugin-authentication-credential-jugemkey at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-Authentication-Credential-JugemKey>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::Authentication::Credential::JugemKey

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-Authentication-Credential-JugemKey>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-Authentication-Credential-JugemKey>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-Authentication-Credential-JugemKey>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-Authentication-Credential-JugemKey>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Gosuke Miyashita, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Catalyst::Plugin::Authentication::Credential::JugemKey
