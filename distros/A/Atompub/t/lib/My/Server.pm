package My::Server;

use strict;
use warnings;
use XML::Atom::Feed;
use FindBin;
use base qw( Atompub::Server );

sub init {
    my $server = shift;
    $server->realm('Atompub');
    $server->SUPER::init(@_);
}

sub handle_request {
    my $server = shift;
    $server->authenticate || return;
    my $method = $server->request_method;
    if ( $method eq 'GET' ) {
	return $server->search_feed;
    }
}

my %Passwords = ( foo => 'foo' );
sub password_for_user {
    my $server = shift;
    my ( $username ) = @_;
    return $Passwords{$username};
}

sub search_feed {
    my $server = shift;
    return XML::Atom::Feed->new->as_xml;
}

1;
