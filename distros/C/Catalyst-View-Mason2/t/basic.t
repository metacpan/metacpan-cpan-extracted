#!perl
use strict;
use warnings;
use lib qw(t/TestApp/lib);
use Test::More tests => 7;

use_ok( 'Catalyst::Test', 'TestApp' );

sub trim {
    my ($str) = @_;
    if ( defined($str) ) {
        for ($str) { s/^\s+//; s/\s+$// }
    }
    return $str;
}

sub try {
    my ( $url, $expect ) = @_;

    my $request = request($url);
    ok( $request->is_success, 'request ok' );
    is( trim( $request->content ), trim($expect) );
}

try( "/hello",        "Hello Joe!" );
try( "/action",       "Hello Bob! Action = 'action'." );
try( "/noautoextend", "Hello Mary!" );
