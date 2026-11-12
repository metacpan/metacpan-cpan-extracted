use strict;
use warnings;
use Test::More;
use FindBin;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
eval { require Test::Pod::Coverage; Test::Pod::Coverage->import(); 1 }
    or plan skip_all => 'Test::Pod::Coverage required';

pod_coverage_ok('Data::Shared::Registry', 'Registry documented');
pod_coverage_ok('Data::Shared::Compiled', 'Compiled documented');
pod_coverage_ok('Data::Shared',
    { trustme => [qr/^shared/, qr/^(?:get|set|delete|exists|incr|call|push|pop|compile|registry|available_types|dir|readonly|manifest_path|mount_names|node|children)$/] },
    'Shared functions documented by tier in prose');
pod_coverage_ok('Data::Shared::Node',
    { trustme => [qr/^(?:new|get|set|delete|exists|incr|call|push|pop)$/] },
    'Node verbs documented as a group');

my @internal = grep { !m{/(?:Node|Compiled|Registry)\.pm$} }
    sort(glob("$FindBin::Bin/../lib/Data/Shared/*.pm"),
         glob("$FindBin::Bin/../lib/Data/Shared/Adapter/*.pm"));
cmp_ok scalar @internal, '>=', 11, 'the internal modules were found';
for my $file (@internal) {
    open my $fh, '<', $file or die "$file: $!";
    my $pod = do { local $/; <$fh> };
    like $pod, qr/^Internal to L<Data::Shared>; not a public API\./m,
        ($file =~ m{(Data/Shared/.+)$})[0] . ' declares itself internal';
}

done_testing;
