
use strict;
use warnings;

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;
use Test::More ();

plan tests => 2, \&need_lwp;
my $r = GET('/');

ok( $r->code() >= 200 );
my ( $mpv )  = ( $r->headers()->header('Server') || '' ) =~ /mod_perl\/(\d+)(?:\.\d+)+/;
my ( $fmpv ) = ( $r->headers()->header('Server') || '' ) =~ /mod_perl\/(\d+(?:\.\d+)+)+/;
ok( $mpv >= 2 ) || Test::More::diag("mod_perl/$fmpv"); 
