use strict;
use warnings;
use Test::Most;

use File::Spec;
use File::Temp qw(tempdir);

use Test::Mockingbird::TimeTravel qw(
    now freeze_time travel_to advance_time rewind_time restore_all
);

use App::FileSync::Lock;
use App::FileSync::Merge;
use App::FileSync::Snapshot;
use App::FileSync::Trash;

my $DAY = 24 * 60 * 60;

sub write_file {
    my ($path, $content) = @_;

    open my $fh, '>', $path or die "Cannot write $path: $!";
    print {$fh} $content;
    close $fh;

    return $path;
}

sub bucket {
    my ($root, @parts) = @_;
    return File::Spec->catdir($root, @parts);
}

# ------------------------------------------------- trash retention boundary
# prune() compares whole days against a cutoff of now - days, so a bucket
# exactly "days" old is already past the line while one day younger is not.
{
    my $root   = tempdir(CLEANUP => 1);
    my $source = tempdir(CLEANUP => 1);

    freeze_time('2026-10-23T00:00:00Z');
    my $midnight = now();

    my $young = App::FileSync::Trash::move_to_trash(
        src   => write_file(File::Spec->catfile($source, 'young.txt'), "young\n"),
        rel   => 'young.txt',
        root  => $root,
        epoch => $midnight - 29 * $DAY,
    );
    my $edge = App::FileSync::Trash::move_to_trash(
        src   => write_file(File::Spec->catfile($source, 'edge.txt'), "edge\n"),
        rel   => 'edge.txt',
        root  => $root,
        epoch => $midnight - 30 * $DAY,
    );

    is(App::FileSync::Trash::date_of($young), '2026-09-24', 'a bucket 29 days old');
    is(App::FileSync::Trash::date_of($edge), '2026-09-23', 'a bucket 30 days old');

    my $pruned = App::FileSync::Trash::prune(root => $root, days => 30, now => now());
    ok((grep { $_ eq bucket($root, '2026', '09', '23') } @{$pruned}),
        'a bucket exactly thirty days old is pruned');
    ok(!(grep { $_ eq bucket($root, '2026', '09', '24') } @{$pruned}),
        'a bucket one day younger is kept');
    ok(-d bucket($root, '2026', '09', '24'), 'and is still on disk');

    # The same bucket crosses the line when the clock reaches the next midnight.
    advance_time(1 => 'day');
    my $tomorrow = App::FileSync::Trash::prune(root => $root, days => 30, now => now());
    ok((grep { $_ eq bucket($root, '2026', '09', '24') } @{$tomorrow}),
        'at the next midnight it is thirty days old and goes');
    ok(!-d bucket($root, '2026', '09', '24'), 'and is removed from disk');

    restore_all();
}

# -------------------------------------------------- snapshot day rollover
{
    my $root = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($root, 'a.txt'), "alpha\n");

    freeze_time('2026-10-23T23:59:59Z');
    my $before = App::FileSync::Snapshot::create(root => $root, now => now());
    is($before->{date}, '2026-10-23', 'the snapshot is dated by the clock');
    is($before->{created}, 1, 'the first snapshot is created');

    advance_time(2);
    is(App::FileSync::Snapshot::date_for_epoch(now()), '2026-10-24',
        'two seconds later the clock is on the next day');

    my $after = App::FileSync::Snapshot::create(root => $root, now => now());
    is($after->{date}, '2026-10-24', 'the next snapshot lands in the new day');
    isnt($after->{path}, $before->{path}, 'the days are separate directories');
    ok(-e File::Spec->catfile($after->{path}, 'a.txt'), 'the new day captured the file');

    travel_to('2026-10-24T00:05:00Z');
    my $again = App::FileSync::Snapshot::create(root => $root, now => now());
    is($again->{created}, 0, 'the first snapshot of the day is never overwritten');
    is($again->{path}, $after->{path}, 'and it is the same day directory');

    restore_all();
}

# ------------------------------------------- day boundary during a sync
# The server stamps conflict copies with the time the plan ran, so a sync that
# straddles midnight must not mix the two days in one name.
{
    my $H1 = 'a' x 64;
    my $H2 = 'b' x 64;

    my $conflict = sub {
        my $plan = App::FileSync::Merge::plan(
            base      => {},
            client    => { 'notes.txt' => { t => 'f', s => 10, m => 300, h => $H2 } },
            master    => { 'notes.txt' => { t => 'f', s => 10, m => 100, h => $H1 } },
            client_id => 'laptop-1',
            now       => now(),
        );
        my ($action) = grep { $_->{p} eq 'notes.txt' } @{ $plan->{actions} };
        return $action;
    };

    freeze_time('2026-10-23T23:59:59Z');
    my $late = $conflict->();
    is($late->{a}, 'conflict', 'a contested file conflicts at midnight');
    is($late->{loser_name}, 'notes.conflict-laptop-1-20261023T235959Z.txt',
        'the conflict copy is stamped with the day the run started');

    advance_time(2);
    my $early = $conflict->();
    is($early->{loser_name}, 'notes.conflict-laptop-1-20261024T000001Z.txt',
        'a run two seconds later is stamped with the new day');

    restore_all();
}

# ---------------------------------------- concurrent runs and clock rewind
# Two clients conflicting in the same frozen second still get distinct copies.
{
    my $H1 = 'a' x 64;
    my $H2 = 'b' x 64;

    freeze_time('2026-10-23T12:00:00Z');

    my $plan_for = sub {
        my ($client_id) = @_;
        my $plan = App::FileSync::Merge::plan(
            base      => {},
            client    => { 'report.txt' => { t => 'f', s => 10, m => 300, h => $H2 } },
            master    => { 'report.txt' => { t => 'f', s => 10, m => 100, h => $H1 } },
            client_id => $client_id,
            now       => now(),
        );
        my ($action) = grep { $_->{p} eq 'report.txt' } @{ $plan->{actions} };
        return $action;
    };

    my $laptop  = $plan_for->('laptop-1');
    my $desktop = $plan_for->('desktop-2');

    is($laptop->{loser_name}, 'report.conflict-laptop-1-20261023T120000Z.txt',
        'the first client gets a copy named after itself');
    is($desktop->{loser_name}, 'report.conflict-desktop-2-20261023T120000Z.txt',
        'the second client gets a copy named after itself');
    isnt($laptop->{loser_name}, $desktop->{loser_name},
        'simultaneous conflicts do not share one copy name');

    restore_all();
}

# A held lock does not expire just because time passes, and closing the holder
# releases it straight away.
{
    my $dir  = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($dir, 'lock');

    freeze_time('2026-10-23T12:00:00Z');
    my $held = App::FileSync::Lock::acquire(path => $path, nonblock => 1);
    ok($held, 'a session takes the lock');

    advance_time(1 => 'hour');
    my $second = App::FileSync::Lock::acquire(path => $path, nonblock => 1);
    ok(!defined $second, 'another run cannot take it however much time passes');

    close $held;
    my $third = App::FileSync::Lock::acquire(path => $path, nonblock => 1);
    ok($third, 'closing the holder releases it immediately');
    close $third if $third;

    restore_all();
}

# A rewound clock must never prune a bucket dated in the future.
{
    my $trash  = tempdir(CLEANUP => 1);
    my $source = tempdir(CLEANUP => 1);

    freeze_time('2026-10-25T00:00:00Z');
    my $moved = App::FileSync::Trash::move_to_trash(
        src   => write_file(File::Spec->catfile($source, 'ahead.txt'), "ahead\n"),
        rel   => 'ahead.txt',
        root  => $trash,
        epoch => now(),
    );
    is(App::FileSync::Trash::date_of($moved), '2026-10-25',
        'the bucket is dated when the delete ran');

    rewind_time(2 => 'days');
    my $early = App::FileSync::Trash::prune(root => $trash, days => 1, now => now());
    is_deeply($early, [], 'a rewound clock prunes nothing that is still ahead of it');
    ok(-e $moved, 'and the file survives');

    travel_to('2026-11-26T00:00:00Z');
    my $late = App::FileSync::Trash::prune(root => $trash, days => 1, now => now());
    ok((grep { $_ eq bucket($trash, '2026', '10', '25') } @{$late}),
        'once the clock passes it, the bucket is pruned');
    ok(!-e $moved, 'and the file is gone');

    restore_all();
}

# Snapshots keep their dates, and the listing stays newest-first, even when the
# clock moves backwards between runs.
{
    my $root = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($root, 'a.txt'), "alpha\n");

    freeze_time('2026-10-25T00:00:00Z');
    my $ahead = App::FileSync::Snapshot::create(root => $root, now => now());
    is($ahead->{date}, '2026-10-25', 'a snapshot taken ahead of the clock');

    rewind_time(5 => 'days');
    my $today = App::FileSync::Snapshot::create(root => $root, now => now());
    is($today->{date}, '2026-10-20', 'the rewound clock dates a new snapshot');
    isnt($today->{date}, $ahead->{date}, 'the two snapshots stay on their own days');

    is_deeply(
        [ map { $_->{date} } @{ App::FileSync::Snapshot::list(root => $root) } ],
        [ '2026-10-25', '2026-10-20' ],
        'the listing is newest-first even when the clock went backwards',
    );

    restore_all();
}

done_testing();
