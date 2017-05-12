#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 7;
use Catalyst::Test 'TestApp';
use HTTP::Request::Common;
use Tie::Hash::Indexed;

my $creq;

my %params;
tie %params, 'Tie::Hash::Indexed';

my @params = qw/a b c d e f g/;
%params = map { $_ => 1 } @params;

my $request = POST( 'http://localhost', 
    'Content'      => \%params,
    'Content-Type' => 'application/x-www-form-urlencoded'
);

ok( my $response = request($request), 'Request' );
ok( $response->is_success, 'Response Successful 2xx' );
ok( eval '$creq = ' . $response->content, 'Unserialize Catalyst::Request' );
is_deeply( $creq, [keys %params], 'ordered POST params ok' );

ok( $response = request('http://localhost?l=1&m=1&n=1&o=1&p=1'), 'Request' );
ok( eval '$creq = ' . $response->content, 'Unserialize Catalyst::Request' );
is_deeply( $creq, [qw/l m n o p/], 'ordered GET params ok' );
