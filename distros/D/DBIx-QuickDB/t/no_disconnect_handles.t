use strict;
use warnings;

use Test2::V0;
use Test2::Tools::QuickDB;
use File::Path qw/remove_tree/;

# no_disconnect_handles: when set, the teardown paths skip _disconnect_handles(),
# which would otherwise close every DBI handle in this process pointing at this
# db's data dir. Callers that hold their own live handles to the db being stopped
# (e.g. a test framework querying in teardown) opt out so their handles are not
# ripped out mid-query ("Lost connection ... during query").
#
# The gate lives in _disconnect_handles() itself, so we exercise it directly:
# calling it with the flag unset closes a matching handle, with the flag set it
# is a no-op. This is deterministic and does not depend on server shutdown timing.

my $db = get_db_or_skipall({driver => 'PostgreSQL'});

# clone() requires a stopped source.
$db->stop if $db->started;

subtest attribute_and_accessor => sub {
    my $clone = $db->clone(cleanup => 1, no_disconnect_handles => 1);
    ok($clone->no_disconnect_handles, "clone carries the no_disconnect_handles attribute");

    my $plain = $db->clone(cleanup => 1);
    ok(!$plain->no_disconnect_handles, "default is false");

    $clone->destroy_quietly;
    $plain->destroy_quietly;
};

subtest clone_data_propagation => sub {
    # The attribute must flow through clone_data() so a clone of a
    # no_disconnect_handles source is itself no_disconnect_handles.
    # autostart => 0: a started db cannot be cloned, and we re-clone below.
    my $clone = $db->clone(autostart => 0, cleanup => 1, no_disconnect_handles => 1);

    my %data = $clone->clone_data;
    ok(
        $data{DBIx::QuickDB::Driver::NO_DISCONNECT_HANDLES()},
        "clone_data propagates no_disconnect_handles to further clones",
    );

    my $grandchild = $clone->clone(cleanup => 1);
    ok($grandchild->no_disconnect_handles, "grandchild inherits the attribute");

    $grandchild->destroy_quietly;
    $clone->destroy_quietly;
};

subtest disconnect_happens_by_default => sub {
    # Baseline: with the flag unset, _disconnect_handles() closes this process's
    # handle to the db.
    my $clone = $db->clone(autostart => 1, cleanup => 1);
    my $dbh   = $clone->connect('quickdb');

    ok($dbh->{Active}, "handle is active before _disconnect_handles");

    $clone->_disconnect_handles;

    ok(!$dbh->{Active}, "handle was disconnected (default behavior)");

    $clone->destroy_quietly;
};

subtest disconnect_skipped_when_set => sub {
    # With the flag set, _disconnect_handles() is a no-op: the caller's handle
    # survives.
    my $clone = $db->clone(autostart => 1, cleanup => 1, no_disconnect_handles => 1);
    my $dbh   = $clone->connect('quickdb');

    ok($dbh->{Active}, "handle is active before _disconnect_handles");

    $clone->_disconnect_handles;

    ok($dbh->{Active}, "handle was NOT disconnected (no_disconnect_handles set)");

    # Disconnect ourselves so teardown of the disposable clone is clean (a live
    # client can make PostgreSQL's smart shutdown wait).
    $dbh->disconnect;
    $clone->destroy_quietly;
};

done_testing;
