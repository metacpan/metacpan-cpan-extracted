
use strict;
use warnings;

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 5, \&need_lwp;
my $r = GET('/cache/cache.js');

ok( $r->code() == 200 );
ok( $r->content() =~ /\/\*.*Cache:\s*1.*\*\//sg );
ok( my $header = $r->headers() );
ok( my $mod    = $header->header('Last-Modified') );

$r = GET(
    '/cache/cache.js',
    'If-Modified-Since' => $mod 
);
ok( $r->code() == 304 );

