#! /usr/bin/perl

use strict;
use warnings;
use Test::More (tests => 17);

use Cache::MemoryCache;

BEGIN {
    use_ok(q(Cache::Adaptive));
};

my $log;

my $cache = Cache::Adaptive->new({
    backend     => Cache::MemoryCache->new({
        namespace => q(byload),
    }),
    log         => sub { $log = shift },
});

is(ref $cache, q(Cache::Adaptive));

# test default logic

is($cache->access({
    key     => q(default),
    builder => sub { "foo" },
}), "foo");
is($log->{type}, 'miss');

$cache->access({
    key     => q(default),
    builder => sub { sleep 2; "foo" },
});
is($log->{type}, 'miss');
ok($log->{entry}->{expires_in});

is($cache->access({
    key     => q(default),
    builder => sub { "should not reach here" },
}), "foo");
is($log->{type}, 'hit');

# test expiration time logic

my %opts = (
    key      => q(logic),
    builder  => sub { "foo" },
);
$cache->expires_initial(3);
$cache->access({ %opts, check_load => sub { 1 } });
is($log->{entry}->{expires_in}, 3);
while ($cache->access({ %opts, check_load => sub { 1 } })) {
    last if $log->{type} eq 'miss';
    sleep 1;
}
is($log->{entry}->{expires_in}, 4.5);
$cache->expires_max(5);
while ($cache->access({ %opts, check_load => sub { 1 } })) {
    last if $log->{type} eq 'miss';
    sleep 1;
}
is($log->{entry}->{expires_in}, 5);
while ($cache->access({ %opts, check_load => sub { 1 } })) {
    last if $log->{type} eq 'miss';
    sleep 1;
}
is($log->{entry}->{expires_in}, 5);
while ($cache->access({ %opts, check_load => sub { -1 } })) {
    last if $log->{type} eq 'miss';
    sleep 1;
}
is($log->{entry}->{expires_in}, 4);
$cache->expires_min(3.5);
while ($cache->access({ %opts, check_load => sub { -1 } })) {
    last if $log->{type} eq 'miss';
    sleep 1;
}
is($log->{entry}->{expires_in}, 3.5);
while ($cache->access({ %opts, check_load => sub { -1 } })) {
    last if $log->{type} eq 'miss';
    sleep 1;
}
is($log->{entry}->{expires_in}, 0);
is($cache->access({
    %opts,
    builder  => sub { "shouldbethis" },
    check_load => sub { 0 },
}), "shouldbethis");
is($log->{entry}->{expires_in}, 0);
