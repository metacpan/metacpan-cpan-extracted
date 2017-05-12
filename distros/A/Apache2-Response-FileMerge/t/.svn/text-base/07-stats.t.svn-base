
use strict;
use warnings;

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 4, \&need_lwp;

my $r = GET('verify.js');
ok( $r->code() == 200 );
ok( $r->content() !~ /\/\*.*mtime.*\*\//sg );

$r = GET('/stats/stats.js');
ok( $r->code() == 200 );
ok( $r->content() =~ /\/\*.*mtime.*\*\//sg );

