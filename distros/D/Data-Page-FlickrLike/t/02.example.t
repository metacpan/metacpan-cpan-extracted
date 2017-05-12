use Test::More tests => 30;

use Data::Page;
use Data::Page::FlickrLike;

use YAML;
my $tests = YAML::LoadFile('t/test.yaml');

for my $test (@$tests) {
    my $pager = Data::Page->new();
    $pager->$_($test->{input}{$_})
        for qw(total_entries entries_per_page current_page);
    my $out = join (' | ',
                    map { $_ == 0 ? '...' : $_} @{$pager->navigations});
    ok( $out eq $test->{expected}->{out},
        'current_page ' . $test->{input}{current_page});
}
