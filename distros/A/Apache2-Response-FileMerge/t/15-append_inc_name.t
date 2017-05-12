
use strict;
use warnings;

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 6, \&need_lwp;

my $r = GET('verify.js');
ok( $r->code() == 200 );

$r = GET('/stats/stats.js');
ok( $r->code() == 200 );
ok( $r->content() =~ /\/\*.*mtime.*\*\//sg );
ok( $r->content() !~ /\/\*.*Append: 1.*\*\//sg );

$r = GET('/inc/inc.js');
ok( $r->code() == 200 );
ok( $r->content() =~ /\/\*.*Append: 1.*\*\//sg );
