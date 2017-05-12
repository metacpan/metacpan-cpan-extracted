#!/usr/bin/perl
package AuthDigestTestApp;
use Catalyst qw/
      Authentication
      Authentication::Store::Minimal
      Authentication::Credential::HTTP
      Cache
  /;
use Test::More;
our $users;
sub moose : Local {
    my ( $self, $c ) = @_;
    $c->authorization_required( realm => 'testrealm@host.com' );
    $c->res->body( $c->user->id );
}
__PACKAGE__->config->{cache}{backend} = {
    class => 'Cache::FileCache',
};
__PACKAGE__->config->{authentication}{http}{type} = 'digest';
__PACKAGE__->config->{authentication}{users} = $users = {
    Mufasa => { password         => "Circle Of Life", },
};
__PACKAGE__->setup;

