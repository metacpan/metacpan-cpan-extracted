package Catalyst::Plugin::Authentication::Credential::Hatena;
use strict;
use warnings;

our $VERSION = '0.04';

use Hatena::API::Auth;
use UNIVERSAL::require;
use NEXT;

=head1 NAME

Catalyst::Plugin::Authentication::Credential::Hatena - Hatena authentication for Catalyst

=head1 SYNOPSIS

    # load plugin and setup
    use Catalyst qw(
        Authentication
        Authentication::Credential::Hatena
        
        Session
        Session::Store::FastMmap
        Session::State::Cookie
    );
    
    __PACKAGE__->config->{authentication}->{hatena} = {
        api_key => 'your api_key',
        secret  => 'your shared secret',
    };
    
    
    # in controller
    # redirect login url
    sub login : Path('/hatena/login') {
        my ( $self, $c ) = @_;
    
        $c->res->redirect( $c->authenticate_hatena_url );
    }
    
    # callback url
    sub auth : Path('/hatena/auth') {
        my ( $self, $c ) = @_;
    
        if ( $c->authenticate_hatena ) {
            # login successful
            $c->res->redirect( $c->uri_for('/') );
        }
        else {
            # something wrong
        }
    }

=head1 DESCRIPTION

This module provide authentication via Hatena, using its api.

=head1 SEE ALSO

L<Hatena::API::Auth>, http://auth.hatena.ne.jp/

=head1 EXTENDED METHODS

=head2 setup

=cut

sub setup {
    my $c = shift;

    my $config = $c->config->{authentication}->{hatena} ||= {};

    $config->{hatena_object} ||= do {
        ( $config->{user_class}
                ||= 'Catalyst::Plugin::Authentication::User::Hash' )->require;

        Hatena::API::Auth->new(
            {   api_key => $config->{api_key},
                secret  => $config->{secret},
            }
        );
    };

    $c->NEXT::setup(@_);
}

=head1 METHODS

=head2 authenticate_hatena_url

=cut

sub authenticate_hatena_url {
    shift->config->{authentication}->{hatena}->{hatena_object}->uri_to_login(@_);
}

=head2 authenticate_hatena

=cut

sub authenticate_hatena {
    my $c = shift;

    my $config = $c->config->{authentication}->{hatena};
    my $hatena = $config->{hatena_object};

    my $cert = $c->req->params->{cert} or return;

    if ( my $user = $hatena->login($cert) ) {
        $c->log->debug("Successfully authenticated user '$user->{name}'.")
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

        return 1;
    }
    else {
        $c->log->debug(
            sprintf "Failed to authenticate hatena.  Reason: '%s'",
            $hatena->errstr, )
            if $c->debug;

        return;
    }
}

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
