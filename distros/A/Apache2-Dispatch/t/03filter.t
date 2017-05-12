use strict;
use warnings FATAL => 'all';

use Apache::Test qw( -withtestmore );
use Apache::TestRequest qw(GET);

# figure out what version of apache we have we have
my $httpd   = Apache::Test::vars('httpd');
my $version = `$httpd -v`;

if ( $version =~ m/Apache\/2/ ) {
    plan
      tests => 2,
      skip_reason("Filtering not yet implemented in Apache2::Dispatch");
}
else {
    if ( eval { require Apache::Filter } ) {
        plan tests => 2, need_lwp;
    }
    else {
        plan
          tests => 2,
          skip_reason("You need Apache::Filter to run this test");
    }
}

my $url = '/filtered/foo';

my $res = GET $url;
ok( $res->is_success );
like( $res->content, qr/dispatch_foo/i, 'content like dispatch_foo' );
