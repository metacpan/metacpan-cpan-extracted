
use strict;
use warnings;

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 4, \&need_lwp;
my $r = GET('/js/bar.js');

ok( $r->code() == 200 );
ok( $r->content() =~ /bar/sm  );
ok( $r->content() =~ /bar\.baz/sm );
ok( $r->content_type() eq 'text/javascript' );
