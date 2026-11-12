use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Shared qw(shared_set shared_children);

# `sort` in scalar context is undefined, so a sorted-list accessor must count instead.
my $root = Data::Shared->new;
eval {
    $root->mount('alpha', 'hashmap:ii', undef, 64);
    $root->mount('beta',  'hashmap:ii', undef, 64);
    1;
} or plan skip_all => "backend unavailable: $@";

my @mounts = $root->mounts;
is scalar @mounts, 2, 'mounts returns both in list context';
is_deeply \@mounts, ['alpha', 'beta'], 'mounts is sorted';

my $count = $root->mounts;
is $count, 2, 'mounts returns a count in scalar context';
ok scalar($root->mounts), 'mounts is true when mounts exist';

my $names = $root->mount_names;
is $names, 2, 'mount_names returns a count in scalar context';

my $types = Data::Shared::available_types();
cmp_ok $types, '>=', 39, 'available_types returns a count in scalar context';
my @types = Data::Shared::available_types();
cmp_ok scalar @types, '==', $types, 'available_types list and scalar agree';

SKIP: {
    my $have = eval { require Data::HashMap::Shared; 1 };
    skip 'composite parent backend unavailable', 3 unless $have;
    my $dir = tempdir(CLEANUP => 1);
    my $app = Data::Shared->new($dir);
    $app->mount('users', ['hashmap:ss', 1024, ['hashmap:ss', 64]]);
    shared_set($app, '/users/ada/name', 'ada');

    my @kids = $app->children('/users');
    is scalar @kids, 1, 'children returns one address in list context';
    my $kids = $app->children('/users');
    is $kids, 1, 'children returns a count in scalar context';
    my $via = shared_children($app, '/users');
    is $via, 1, 'shared_children returns a count in scalar context';
}

done_testing;
