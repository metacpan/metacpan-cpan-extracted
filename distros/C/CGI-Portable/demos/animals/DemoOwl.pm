package DemoOwl;
use strict;
use warnings;
use CGI::Portable;

sub main {
	my ($class, $globals) = @_;
	my $url = $globals->pref( 'fly_to' );
	$globals->http_status_code( '301 Moved' );
	$globals->http_redirect_url( $url );
}

1;
