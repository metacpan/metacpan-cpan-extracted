use strict;
use warnings FATAL => 'all';

use Apache::Test qw( -withtestmore );
use Apache::TestRequest qw(GET GET_OK);

plan tests => 5, need_lwp;

# Test Apache2::Foo->dispatch_index
my $uri = '/plain';
ok GET_OK $uri;

# Test Apache2::Foo->dispatch_foo
$uri = '/plain/foo';
ok GET_OK $uri;

# Test non-usage of Apache2::Foo::Bar->dispatch_index since
# Apache2::Foo->dispatch_bar does not exist
$uri = '/plain/bar';
my $res = GET $uri;
ok $res->code == 404;

# Test Apache2::Foo::Bar->dispatch_baz
$uri = '/plain/bar/baz';
ok GET_OK $uri;

# Test root location special case
$uri = '/';
ok GET_OK $uri
