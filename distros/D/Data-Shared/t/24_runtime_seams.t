use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Shared qw(shared_get shared_set);

my $root = Data::Shared->new;
eval { $root->mount('cache', 'hashmap:ii', undef, 64); 1 }
    or plan skip_all => "backend unavailable: $@";
shared_set($root, '/cache/1', 5);

for my $p ('/cache/1', '//cache/1', '///cache/1', '////cache/1') {
    is eval { shared_get($root, $p) }, 5, "leading slash run resolves: '$p'";
}

{
    package T24::Err;
    sub new { bless { code => 42 }, shift }
}
my $thrown = eval {
    $root->mount('boom', sub { die T24::Err->new });
    1;
};
ok !$thrown, 'factory exception propagates';
isa_ok $@, 'T24::Err', 'exception object survives rollback';
is ref($@) && $@->{code}, 42, 'its payload is intact';

# An int-keyed composite parent keys on the numeric value while the child index
# keys on the string, so only canonical spellings may register.
SKIP: {
    my $dir = tempdir(CLEANUP => 1);
    my $app = Data::Shared->new($dir);
    unless (eval { $app->mount('u', ['hashmap:ii', 64, ['hashmap:ss', 16]]); 1 }) {
        my $err = $@;
        skip 'composite backends unavailable', 7
            if $err =~ /is not available; install the|Can't locate \S+\.pm/;
        fail "mounting the composite failed: $err";
        last SKIP;
    }
    shared_set($app, '/u/7/name', 'seven');
    for my $addr ('007', '-0', "7\n") {
        my $shown = $addr; $shown =~ s/\n/\\n/;
        ok !eval { shared_set($app, "/u/$addr/name", 'twin'); 1 },
            "non-canonical int address rejected: '$shown'";
        like $@, qr/canonical|composite address/,
            "'$shown' refused for its spelling, not by accident";
    }
    is_deeply [$app->children('/u')], ['7'], 'only the canonical child exists';
}

done_testing;
