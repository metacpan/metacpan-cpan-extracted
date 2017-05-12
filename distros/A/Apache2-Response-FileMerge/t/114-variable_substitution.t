
use strict;
use warnings;

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 10, \&need_lwp;

my $r;

$r = GET('/varsub/varsub-do.js?foo-or-bar=foo');
ok( $r->code() == 200 );
ok( $r->content() =~ /before\s+foo\s+after/sg );
ok( $r->content() !~ /before\s+bar\s+after/sg );

$r = GET('/varsub/varsub-do.js?foo-or-bar=bar');
ok( $r->code() == 200 );
ok( $r->content() !~ /before\s+foo\s+after/sg );
ok( $r->content() =~ /before\s+bar\s+after/sg );

$r = GET('/varsub/varsub-do.js?foo-or-bar=baz');
ok( $r->code() == 200 );
ok( $r->content() !~ /before\s+foo\s+after/sg );
ok( $r->content() !~ /before\s+bar\s+after/sg );
ok( $r->content() =~ /before\s+after/sg );
