package Catalyst::Plugin::Authentication::Credential::Flickr;
use strict;

use Flickr::API;
use NEXT;
use UNIVERSAL::require;

our $VERSION = '0.05';

=head1 NAME

Catalyst::Plugin::Authentication::Credential::Flickr - Flickr authentication for Catalyst

=head1 SYNOPSIS

    use Catalyst qw/
      Authentication
      Authentication::Credential::Flickr
      Session
      Session::Store::FastMmap
      Session::State::Cookie
      /;
    
    MyApp->config(
        authentication => {
            use_session => 1, # default 1. see C::P::Authentication
            flickr      => {
                key    => 'your api_key',
                secret => 'your secret_key',
                perms  => 'read', # or write
            },
        },
    );
    
    sub default : Private {
        my ( $self, $c ) = @_;
    
        if ( $c->user_exists ) {
            # $c->user setted
        }
    }
    
    # redirect flickr's login form
    sub login : Local {
        my ( $self, $c ) = @_;
        $c->res->redirect( $c->authenticate_flickr_url );
    }
    
    # login callback url
    sub auth : Path('/flickr') {
        my ( $self, $c ) = @_;
        if ( $c->authenticate_flickr ) {
            $c->res->redirect( $c->uri_for('/') );
        }
    }

=head1 DESCRIPTION

This module provide authentication via Flickr, using it's api.

=head1 EXTENDED METHODS

=head2 setup

=cut

sub setup {
    my $c = shift;

    my $config = $c->config->{authentication}->{flickr} ||= {};

    $config->{flickr_object} ||= do {
        ( $config->{user_class}
                ||= "Catalyst::Plugin::Authentication::User::Hash" )->require;

        my $flickr = Flickr::API->new(
            {   key    => $config->{key},
                secret => $config->{secret},
            }
        );

        $flickr;
    };

    $c->NEXT::setup(@_);
}

=head1 METHODS

=head2 authenticate_flickr_url

=cut

sub authenticate_flickr_url {
    my $c = shift;

    my $config = $c->config->{authentication}->{flickr};
    my $perms  = shift || $config->{perms};

    return $config->{flickr_object}->request_auth_url($perms);
}

=head2 authenticate_flickr

=cut

sub authenticate_flickr {
    my $c = shift;

    my $config = $c->config->{authentication}->{flickr};
    my $flickr = $config->{flickr_object};
    my $frob   = $c->req->params->{frob} or return;

    my $api_response = $flickr->execute_method( 'flickr.auth.getToken',
        { frob => $frob, } );

    if ( $api_response->{success} ) {
        my $user    = {};
        my $content = $api_response->content;
        ( $user->{token} )    = $content =~ m!<token>(.*?)</token>!;
        ( $user->{perms} )    = $content =~ m!<perms>(.*?)</perms>!;
        ( $user->{nsid} )     = $content =~ m!nsid="(.*?)"!;
        ( $user->{username} ) = $content =~ m!username="(.*?)"!;
        ( $user->{fullname} ) = $content =~ m!fullname="(.*?)"!;

        $c->log->debug("Successfully authenticated user '$user->{username}'.")
            if $c->debug;

        my $store = $config->{store} || $c->default_auth_store;
        if ( $store
            and my $store_user
            = $store->get_user( $user->{username}, $user ) )
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
            sprintf
                "Failed to authenticate flickr.  Error code: '%d', Reason: '%s'",
            $api_response->{error_code},
            $api_response->{error_message},
            )
            if $c->debug;

        return;
    }
}

=head1 SEE ALSO

L<Catalyst::Plugin::Authentication>, L<Catalyst::Plugin::Authentication::Credential::TypeKey>

=head1 AUTHOR

Daisuke Murase E<lt>typester@cpan.orgE<gt>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
