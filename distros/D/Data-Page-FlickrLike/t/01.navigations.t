use Test::More tests => 30;

use Data::Page;
use Data::Page::FlickrLike;

use YAML;
my $tests = YAML::LoadFile('t/test.yaml');

for my $test (@$tests) {
    my $pager = Data::Page->new();
    $pager->$_($test->{input}{$_})
        for qw(total_entries entries_per_page current_page);
    ok( eq_array( scalar $pager->navigations, $test->{expected}->{navigations}),
        'current page: ' . $test->{input}{current_page} );
}

