use strict;
use warnings;
use Test::More;
use Test::Fatal;
use BusyBird::Test::StatusStorage qw(:storage :status);
use File::Temp 0.19;
use Test::MockObject::Extends;
use DBI;
use lib "t";
use testlib::Timeline_Util qw(sync status test_sets);
use testlib::StatusStorage::CrazyStatus qw(test_storage_crazy_statuses);

BEGIN {
    use_ok('BusyBird::StatusStorage::SQLite');
}

my %STORAGE_PATH_BUILDER = (
    file => sub { File::Temp->new(EXLOCK => 0) },
    memory => sub { ":memory:" },
);

sub create_storage {
    my ($type) = @_;
    my $path = $STORAGE_PATH_BUILDER{$type}->();
    my $storage = BusyBird::StatusStorage::SQLite->new(path => "$path");
    return ($path, $storage);
}

sub connect_db {
    my ($filename) = @_;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$filename", "", "", {
        PrintError => 0, RaiseError => 1, AutoCommit => 1
    });
    $dbh->do(q{PRAGMA foreign_keys = ON});
    return $dbh;
}

sub test_sqlite {
    my ($storage_type) = @_;
    note("------------ test $storage_type");
    {
        my ($path, $storage) = create_storage($storage_type);
        test_storage_common($storage);
        test_storage_ordered($storage);
        test_storage_missing_arguments($storage);
        test_storage_requires_status_ids($storage);
        test_storage_undef_in_array($storage);
        test_storage_crazy_statuses($storage);
    }
    {
        my $path = $STORAGE_PATH_BUILDER{$storage_type}->();
        my $storage = BusyBird::StatusStorage::SQLite->new(
            path => "$path", max_status_num => 5, hard_max_status_num => 10
        );
        test_storage_truncation($storage, {soft_max => 5, hard_max => 10});
    }
    {
        note('------ vacuum_on_delete tests.');
        my $path = $STORAGE_PATH_BUILDER{$storage_type}->();
        my @vacuum_log = ();
        my $create_spied_storage = sub {
            my $storage = BusyBird::StatusStorage::SQLite->new(
                path => "$path",
                max_status_num => 10, hard_max_status_num => 20, vacuum_on_delete => 5
            );
            can_ok($storage, "vacuum");
            my $vacuum_orig = $storage->can('_do_vacuum');
            Test::MockObject::Extends->new($storage);
            $storage->mock(_do_vacuum => sub {
                push(@vacuum_log, [@_[1..$#_]]);
                goto $vacuum_orig;
            });
            return $storage;
        };
        my $storage = $create_spied_storage->();
    
        my %base = (timeline => "_test_tl_vacuum");
        my ($error, $ret_num);

        note('--- manual vacuum()');
        @vacuum_log = ();
        $storage->vacuum();
        is(scalar(@vacuum_log), 1, "vacuum called via public vacuum() method");

        note("--- vacuum on delete (single)");
        @vacuum_log = ();
        ($error, $ret_num) = sync(
            $storage, 'put_statuses', %base,
            mode => 'insert', statuses => [map {status($_)} 1..10]
        );
        is($error, undef, "put succeeds");
        is($ret_num, 10, "10 inserted");
        ($error, $ret_num) = sync(
            $storage, 'delete_statuses', %base, ids => [7..10]
        );
        is($error, undef, "delete succeeds");
        is($ret_num, 4, '4 deleted');
    
        is(scalar(@vacuum_log), 0, 'vacuum should not be called yet. Only 4 statuses are deleted.');

        ($error, $ret_num) = sync(
            $storage, 'delete_statuses', %base, ids => 6
        );
        is($error, undef, 'delete succeeds');
        is($ret_num, 1, "1 deleted");
        is(scalar(@vacuum_log), 1, 'vacuum should be called once.');

        note("--- vacuum on delete (whole timeline)");
        @vacuum_log = ();
        ($error, $ret_num) = sync(
            $storage, 'delete_statuses', %base, ids => undef
        );
        is($error, undef, 'delete succeeds');
        is($ret_num, 5, '5 deleted');
        is(scalar(@vacuum_log), 1, 'vacuum should be called once.');

        note('--- vacuum on delete (multiple ids)');
        @vacuum_log = ();
        ($error, $ret_num) = sync(
            $storage, 'put_statuses', %base, mode => 'insert', statuses => [map {status($_)} 1..13]
        );
        is($error, undef, 'put succeeds');
        is($ret_num, 13, '13 inserted');
        is(scalar(@vacuum_log), 0, "vacuum should not be called yet");
        ($error, $ret_num) = sync(
            $storage, 'delete_statuses', %base, ids => [1..13]
        );
        is($error, undef, 'delete succeeds');
        is($ret_num, 13, '13 deleted');
        is(scalar(@vacuum_log), 1, 'vacuum should be called once (no matter how many statuses are deleted in one delete_statuses())');

        note('--- vacuum on delete (due to truncation)');
        @vacuum_log = ();
        ($error, $ret_num) = sync(
            $storage, 'put_statuses', %base, mode => 'insert', statuses => [map {status($_)} 1..20]
        );
        is($error, undef, 'put succeeds');
        is($ret_num, 20, '20 inserted');
        is(scalar(@vacuum_log), 0, 'vacuum should not be called yet');
        ($error, $ret_num) = sync(
            $storage, 'put_statuses', %base, mode => 'insert', statuses => status(21)
        );
        is($error, undef, 'put succeeds');
        is($ret_num, 1, '1 inserted');
        ($error, my $statuses) = sync(
            $storage, 'get_statuses', %base, count => 'all'
        );
        is($error, undef, 'get succeeds');
        test_status_id_list($statuses, [reverse 12..21], '10 statuses due to status truncation');
        is(scalar(@vacuum_log), 1, 'vacuum should be called due to status truncation.');
        ($error, $ret_num) = sync($storage, "delete_statuses", %base, ids => undef);
        is($error, undef, "delete succeeds. timeline cleared.");
        is($ret_num, 10, "10 deleted");
        is(scalar(@vacuum_log), 2, "vacuum should be called once again by explicit call to delete_statuses.");

        {
            note('--- vacuum count is shared by all timelines.');
            @vacuum_log = ();
            my %base2 = (timeline => '_another_timeline_for_vacuum');
            sync($storage, 'put_statuses', %base, mode => 'insert', statuses => [map {status($_)} 1..4]);
            ($error, $ret_num) = sync($storage, 'delete_statuses', %base, ids => undef);
            is($error, undef, 'delete succeeds');
            is($ret_num, 4, '4 deleted');
            is(scalar(@vacuum_log), 0, 'vacuum should not be called yet');
        
            sync($storage, 'put_statuses', %base2, mode => 'insert', statuses => [map {status($_)} 1..10]);
            ($error, $ret_num) = sync($storage, 'delete_statuses', %base2, ids => 1);
            is($error, undef, 'delete succeeds');
            is($ret_num, 1, '1 deleted');
            is(scalar(@vacuum_log), 1, 'vacuum should be called because vacuum count is shared by all timelines.');
        }

        if($storage_type eq 'file') {
            note('--- vacuum count is persistent');
            @vacuum_log = ();
            ($error, $ret_num) = sync(
                $storage, 'put_statuses', %base, mode => 'insert', statuses => [map {status($_)} 1..5]
            );
            is($error, undef, "put succeeds");
            is($ret_num, 5, '5 inserted');
            ($error, $ret_num) = sync(
                $storage, 'delete_statuses', %base, ids => [1..4]
            );
            is($error, undef, 'delete succeeds');
            is($ret_num, 4, '4 deleted');
            is(scalar(@vacuum_log), 0, 'vacuum should not be called yet');
            undef $storage;
            $storage = $create_spied_storage->();
            ($error, $ret_num) = sync(
                $storage, 'delete_statuses', %base, ids => 5,
            );
            is($error, undef, 'delete succeeds');
            is($ret_num, 1, '1 deleted');
            is(scalar(@vacuum_log), 1, 'vacuum should be called even though storage object is re-created.');
        }
    }
    {
        note("--- timestamps with non-UTC timezones");
        my ($path, $storage) = create_storage($storage_type);
        my %base = (timeline => '_test_nonutc');
        my $status = {
            id => 1,
            created_at => 'Tue Jun 04 14:08:33 +0900 2013',
            busybird => {
                acked_at => 'Fri May 31 21:42:00 -0400 2013'
            }
        };
        my ($error, $ret_num) = sync($storage, 'put_statuses', %base, mode => 'insert', statuses => $status);
        is($error, undef, "put succeeds");
        is($ret_num, 1, "1 inserted");
        ($error, my $statuses) = sync($storage, 'get_statuses', %base, count => 'all');
        is($error, undef, "get succeeds");
        is(scalar(@$statuses), 1, "1 status obtained");
        is($statuses->[0]{created_at}, 'Tue Jun 04 14:08:33 +0900 2013', 'created_at maintained');
        is($statuses->[0]{busybird}{acked_at}, 'Fri May 31 21:42:00 -0400 2013', 'acked_at maintained');
    }
    {
        note("--- get_timeline_names()");
        my ($path, $storage) = create_storage($storage_type);
        is_deeply [$storage->get_timeline_names], [], "at first, no timeline";
        sync($storage, 'put_statuses', timeline => 'tl1', mode => "insert", statuses => status(0));
        is_deeply [$storage->get_timeline_names], ["tl1"], "timeline tl1 is created";
        sync($storage, 'put_statuses', timeline => 'tl2', mode => "insert", statuses => status(0));
        test_sets [$storage->get_timeline_names], ["tl1", "tl2"],
            "get_timeline_names() returns unordered set of tl1 and tl2";
        sync($storage, 'put_statuses', timeline => 'tl3', mode => "insert", statuses => status(0));
        test_sets [$storage->get_timeline_names], ["tl1", "tl2", "tl3"],
            "get_timeline_names() returns unordered set of tl1, tl2 and tl3";
        sync($storage, "delete_statuses", timeline => "tl2", ids => undef);
        test_sets [$storage->get_timeline_names], ["tl1", "tl3"],
            "delete_timelines(ids => undef) should delete the timeline altogether";
    }
}

######################################################


test_sqlite('file');

{
    note("--- trying to create DB at non-existent path");
    like(
        exception {
            my $s = BusyBird::StatusStorage::SQLite->new(
                path => './this/path/should/never/exist.sqlite3'
            );
        },
        qr{exist\.sqlite3},
        "trying to create DB at non-existent path throws an exception."
    );
}

{
    note('--- timestamps with non-UTC timezones are stored in DB as UTC timestamps');
    my ($tempfile, $storage) = create_storage('file');
    my %base = (timeline => '_test_timestamp_timezones');
    my $status = status(1);
    $status->{created_at} = 'Mon Jul 01 05:12:11 +0900 2013';
    $status->{busybird}{acked_at} = 'Fri Apr 19 20:06:00 -1000 2013';
    my ($error, $ret_num) = sync($storage, 'put_statuses', %base, mode => 'insert', statuses => $status);
    is($error, undef, "put succeed");
    is($ret_num, 1, '1 inserted');
    my $dbh = connect_db($tempfile->filename);
    my $record = $dbh->selectrow_hashref(q{SELECT * FROM statuses WHERE status_id = ?}, undef, 1);
    isnt($record, undef, "get record OK");
    is($record->{utc_created_at}, '2013-06-30T20:12:11', 'row utc_created_at OK');
    is($record->{timezone_created_at}, '+0900', 'row timezone_created_at OK');
    is($record->{utc_acked_at}, '2013-04-20T06:06:00', 'row utc_acked_at OK');
    is($record->{timezone_acked_at}, '-1000', 'row timezone_acked_at OK');
}

{
    note('--- manipulation to DB timestamp columns is reflected to obtained stutuses');
    my ($tempfile, $storage) = create_storage('file');
    my %base = (timeline => '_test_timestamp_cols');
    my ($error, $ret_num);
    ($error, $ret_num) = sync($storage, 'put_statuses', %base, mode => 'insert', statuses => status(1));
    is($error, undef, "put succeed");
    is($ret_num, 1, "1 inserted");

    my $dbh = connect_db($tempfile->filename);
    my $count = $dbh->do(<<SQL, undef, '2013-01-01T04:32:50', '-1000', '2012-12-31T22:41:05', '+0900', 1);
UPDATE statuses SET utc_acked_at = ?, timezone_acked_at = ?,
                    utc_created_at = ?, timezone_created_at = ?
              WHERE status_id = ?
SQL
    is($count, 1, '1 row updated');
    ($error, my $statuses) = sync($storage, 'get_statuses', %base, count => 'all');
    is($error, undef, "get succeeds");
    is(scalar(@$statuses), 1, "1 status obtained");
    is($statuses->[0]{busybird}{acked_at}, 'Mon Dec 31 18:32:50 -1000 2012', 'acked_at timestamp restored');
    is($statuses->[0]{created_at}, 'Tue Jan 01 07:41:05 +0900 2013', 'created_at timestamp restored');
}

{
    note('--- manipulation to DB level columns is reflected to obtained statuses');
    my ($tempfile, $storage) = create_storage('file');
    my %base = (timeline => '_test_level_cols');
    my ($error, $ret_num);
    ($error, $ret_num) = sync($storage, 'put_statuses', %base, mode => 'insert', statuses => status(1));
    is($error, undef, "put succeed");
    is($ret_num, 1, "1 inserted");
    ($error, my $unacked_counts) = sync($storage, 'get_unacked_counts', %base);
    is($error, undef, "get_unacked_counts succeed");
    is_deeply($unacked_counts, {total => 1, 0 => 1}, '1 status in level 0');

    my $dbh = connect_db($tempfile->filename);
    my $count = $dbh->do(<<SQL, undef, 5, 1);
UPDATE statuses SET level = ? WHERE status_id = ?
SQL
    ($error, $unacked_counts) = sync($storage, 'get_unacked_counts', %base);
    is($error, undef, "get_unacked_counts succeed");
    is_deeply($unacked_counts, {total => 1, 5 => 1}, '1 status in level 5');
    ($error, my $statuses) = sync($storage, 'get_statuses', %base, count => 'all');
    is($error, undef, "get succeed");
    is(scalar(@$statuses), 1, "1 status obtained");
    is($statuses->[0]{busybird}{level}, 5, "level is set to 5");
}

{
    note('--- foreign key constraint on statuses.timeline_id');
    my ($tempfile, $storage) = create_storage('file');
    my %base = (timeline => '_test_level_foreign');
    my ($error, $ret_num);
    ($error, $ret_num) = sync($storage, 'put_statuses', %base, mode => 'insert', statuses => status(1));
    is($error, undef, "put succeeds");
    is($ret_num, 1, '1 inserted');
    my $dbh = connect_db($tempfile->filename);
    like(exception { $dbh->do(q{UPDATE statuses SET timeline_id = 256}) }, qr/foreign/i,
         "statuses.timeline_id cannot be modified to non-existent ID due to foreign key constraint");
}

test_sqlite('memory');

done_testing();
