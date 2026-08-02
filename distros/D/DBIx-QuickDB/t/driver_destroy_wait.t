use strict;
use warnings;

use Test2::V0;

use DBIx::QuickDB::Driver;

my @events;

{
    package Test::DestroyWait::Watcher;

    sub eliminate { push @events => 'eliminate'; return }
    sub wait      { push @events => 'wait';      return }
}

{
    package Test::DestroyWait::Driver;
    our @ISA = ('DBIx::QuickDB::Driver');

    sub _disconnect_handles { push @events => 'disconnect'; return }
    sub cleanup             { push @events => 'cleanup';    return }
}

my $watcher = bless {}, 'Test::DestroyWait::Watcher';
my $retained_watcher = $watcher;

my $db = bless {
    DBIx::QuickDB::Driver::ROOT_PID() => $$,
    DBIx::QuickDB::Driver::DIR()      => '/not/a/real/database',
    DBIx::QuickDB::Driver::_CLEANUP() => 1,
    DBIx::QuickDB::Driver::WATCHER()  => $watcher,
}, 'Test::DestroyWait::Driver';

undef $watcher;
undef $db;

is(
    \@events,
    [qw/disconnect eliminate wait cleanup/],
    'graceful DESTROY waits for the watcher before deleting the data directory',
);

ok($retained_watcher,
    'DESTROY ordering does not depend on destroying the watcher object');

done_testing;
