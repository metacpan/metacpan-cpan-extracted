package Catalyst::Authentication::Credential::HTTP::Proxy;
use base qw/Catalyst::Authentication::Credential::HTTP/;

use strict;
use warnings;

use String::Escape ();
use URI::Escape    ();
use Catalyst::Authentication::Credential::HTTP::Proxy::User;

our $VERSION = "0.06";

__PACKAGE__->mk_accessors(qw/ 
    url
/);

sub init {
    my ($self) = @_;
    
    my $type = $self->type || 'basic';
    
    if (!$self->_config->{url}) {
        Catalyst::Exception->throw(__PACKAGE__ . " configuration does not include a 'url' key, cannot proceed");
    }
    
    if (!grep /^$type$/, ('basic')) {
        Catalyst::Exception->throw(__PACKAGE__ . " used with unsupported authentication type: " . $type);
    }
    $self->type($type);
}

sub authenticate_basic {
    my ( $self, $c, $realm, $auth_info ) = @_;

    $c->log->debug('Checking http basic authentication.') if $c->debug;

    my $headers = $c->req->headers;

    if ( my ( $user, $password ) = $headers->authorization_basic ) {
        my $ua = Catalyst::Authentication::Credential::HTTP::Proxy::User->new;
        $ua->credentials($user, $password);
        my $resp = $ua->get($self->url);
        if ( $resp->is_success ) {
            # Config username_field TODO
	        my $user_obj = $realm->find_user( { username => $user }, $c);
	        unless ($user_obj) {
                $c->log->debug("User '$user' doesn't exist in the default store")
                    if $c->debug;
                return;
            }
            $c->set_authenticated($user_obj);
            return 1;
        }
        else {
            $c->log->info('Remote authentication failed:'.$resp->message);
            return 0;
        }
    } 
    elsif ( $c->debug ) {
        $c->log->info('No credentials provided for basic auth');
        return 0;
    }
}

1;

__END__

=pod

=head1 NAME

Catalyst::Authentication::Credential::HTTP::Proxy - HTTP Proxy authentication
for Catalyst.

=head1 SYNOPSIS

    use Catalyst qw/
        Authentication
    /;

    $c->config( authentication => {
        realms => {
            example => {
                credential => {
                    class => 'HTTP::Proxy',
                    type => 'basic', # Only basic supported
                    url => 'http://elkland.no/auth',
                },
            },
            store => {
                class => 'Minimal',
                users => {
                    Mufasa => { },
                },
            },
        },
    });
    
    sub foo : Local { 
        my ( $self, $c ) = @_;

        $c->authenticate(); 
        
        # either user gets authenticated or 401 is sent

        do_stuff();
    }

=head1 DESCRIPTION

This module lets you use HTTP Proxy authentication with
L<Catalyst::Plugin::Authentication>.

Currently this module only supports the Basic scheme, but upon request Digest
will also be added. Patches welcome!

=head1 CONFIG

All configuration is stored in C<< YourApp->config(authentication => { yourrealm => { credential => { class => 'HTTP::Proxy', %config } } } >>.

This should be a hash, and it can contain the following entries:

=over 4

=item url

Required. A url protected with basic authentication to authenticate against.

=item type

Must be either C<basic> or not present (then it defaults to C<basic>).

This will be used to support digest authentication in future.

=back

=head1 METHODS

=over

=item init

Initializes the configuration.

=item authenticate_basic

Looks inside C<< $c->request->headers >> and processes the basic (badly named)
authorization header. Then authenticates this against the provided url.

=back

=head1 AUTHORS

Marcus Ramberg <mramberg@cpan.org>

Tomas Doran <bobtfish@bobtfish.net>

=head1 COPYRIGHT & LICENSE

        Copyright (c) 2005-2008 the aforementioned authors. All rights
        reserved. This program is free software; you can redistribute
        it and/or modify it under the same terms as Perl itself.

=cut

