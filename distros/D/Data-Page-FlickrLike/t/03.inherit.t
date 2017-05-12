use Test::More tests => 1;

use lib qw(t/lib);

use MyPager;
use Data::Page::FlickrLike;

my $pager = MyPager->new();

ok $pager->can('navigations');
