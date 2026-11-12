use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Shared qw(shared_set shared_get);

plan skip_all => 'hashmap backend unavailable'
    unless eval { require Data::HashMap::Shared::II; 1 };

for my $case (['$,' => sub { $, = ',' }], ['$\\' => sub { $\ = ";\n" }]) {
    my ($name, $set) = @$case;
    my $dir = tempdir(CLEANUP => 1);
    {
        local ($,, $\);
        $set->();
        my $root = Data::Shared->new($dir);
        $root->mount('cache', 'hashmap:ii', undef, 64);
    }
    my $reopened = eval { Data::Shared->open($dir) };
    ok $reopened, "manifest survives a caller's $name" or diag $@;
}

# A shared lock only reads, so a write-protected lock must not block open().
{
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    $root->mount('c', 'hashmap:ii', undef, 64);
    shared_set($root, '/c/1', 5);
    undef $root;
    chmod 0444, "$dir/.manifest.lock" or die $!;
    my $reopened = eval { Data::Shared->open($dir) };
    ok $reopened, 'open() works with a read-only lock file' or diag $@;
    is eval { shared_get($reopened, '/c/1') }, 5, 'and reads through it';
    chmod 0600, "$dir/.manifest.lock";
}

# Validation must keep JSON types, or the fingerprint changes and the next mount reads as stale.
{
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    $root->mount('c', 'hashmap:ii', undef, 1000);
    undef $root;
    my $again = Data::Shared->open($dir);
    ok eval { $again->mount('d', 'hashmap:ii', undef, 64); 1 },
        'a mount after reopen is not rejected as stale' or diag $@;
}

done_testing;
