
use strict;
use warnings;

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 4, \&need_lwp;
my $r = GET('/css/foo~foo.bar.css');

ok( $r->code() == 200 );
ok( $r->content() =~ /foo/sm  );
ok( $r->content() =~ /foo.bar/sm );
ok( $r->content_type() eq 'text/css' );
