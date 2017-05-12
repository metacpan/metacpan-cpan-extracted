package testlib::StatusStorage::CrazyStatus;
use strict;
use warnings;
use Exporter qw(import);
use Test::More;
use testlib::CrazyStatus ();
use testlib::Timeline_Util qw(*LOOP *UNLOOP sync status);
use Try::Tiny;

our @EXPORT_OK = qw(test_storage_crazy_statuses);

sub crazy_statuses {
    my ($accept_crazy_timestamps) = @_;
    my @common = testlib::CrazyStatus::crazy_statuses();
    my (@ng, @crazy_but_ok);
    foreach my $s (@common) {
        if(!defined($s->{busybird}) || ref($s->{busybird}) eq 'HASH') {
            push @crazy_but_ok, $s;
        }else {
            push @ng, $s;
        }
    }
    my @crazy_timestamps = (
        {
            id => 'crazy: created_at in weird format',
            created_at => 'foobar'
        },
        {
            id => 'crazy: created_at is array-ref',
            created_at => [1, 3 ,4]
        },
        {
            id => 'crazy: created_at is hash-ref',
            created_at => {epoch => 1001011},
        },
        {
            id => 'crazy: busybird.acked_at in weird format',
            busybird => { acked_at => 'foobar' },
        },
        {
            id => 'crazy: busybird.acked_at is array-ref',
            busybird => { acked_at => [] }
        },
        {
            id => 'crazy: busybird.acked_at is hash-ref',
            busybird => { acked_at => {} }
        }
    );
    if($accept_crazy_timestamps) {
        push @crazy_but_ok, @crazy_timestamps;
    }else {
        push @ng, @crazy_timestamps;
    }
    return (\@ng, \@crazy_but_ok);
}

sub test_storage_crazy_statuses {
    my ($storage, $loop, $unloop, $opts) = @_;
    local $LOOP = $loop || sub {};
    local $UNLOOP = $unloop || sub {};
    $opts ||= {};
    my ($ngs, $oks) = crazy_statuses($opts->{accept_crazy_timestamps});
    {
        note('--- crazy_statuses: you can put some crazy statuses (if the craziness is moderate)');
        my %oktl = (timeline => "ok timeline");
        foreach my $s (@$oks) {
            my ($error, $num) = sync($storage, "put_statuses", %oktl, mode => "insert", statuses => $s);
            is $error, undef, "$s->{id}: put OK";
            is $num, 1, "$s->{id}: put 1 crazy status";
            ($error, my $got_statuses) = sync($storage, "get_statuses", %oktl, count => "all");
            is $error, undef, "$s->{id}: get OK";
            is $got_statuses->[0]{id}, $s->{id}, "$s->{id}: obtained status ID OK";
            ($error) = sync($storage, "delete_statuses", %oktl, ids => undef);
            is $error, undef, "$s->{id}: delete OK";
        }
    }

    {
        note('--- crazy_statuses: you cannot put really crazy statuses');
        my %ngtl = (timeline => 'ng timeline');
        foreach my $s (@$ngs) {
            my ($error, $num) = try {
                sync($storage, "put_statuses", %ngtl, mode => "insert",
                     statuses => [ status(100), $s ]);
            }catch {
                @_
            };
            ok $error, "$s->{id}: put should fail (either throwing exception or calling back with error)." and do {
                note("put error message: $error");
            };
            ($error, my $got_statuses) = sync($storage, "get_statuses", %ngtl, count => "all");
            is $error, undef, "$s->{id}: get OK";
            is scalar(@$got_statuses), 0, "$s->{id}: no status is input to the timeline";
        }
    }
}

1;
