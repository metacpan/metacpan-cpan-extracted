package testlib::Timeline_Util;
use strict;
use warnings;
use Exporter qw(import);
use Test::More;
use Test::Builder;
use BusyBird::DateTime::Format;
use BusyBird::Test::StatusStorage qw(test_status_id_list);
use DateTime;

## We have to export typeglobs when we want to allow users
## to localize the LOOP and UNLOOP. See 'perlmod' for details.
our @EXPORT_OK = qw(sync status test_sets test_content *LOOP *UNLOOP);
our $LOOP   = sub {};
our $UNLOOP = sub {};

sub sync {
    my ($timeline, $method, %args) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $callbacked = 0;
    my $result;
    $timeline->$method(%args, callback => sub {
        $result = \@_;
        $callbacked = 1;
        $UNLOOP->();
    });
    $LOOP->();
    ok($callbacked, "sync $method callbacked.");
    return @$result;
}

sub status {
    my ($id, $level, $acked_at) = @_;
    my %busybird_elem = ();
    $busybird_elem{busybird}{level} = $level if defined $level;
    $busybird_elem{busybird}{acked_at} = $acked_at if defined $acked_at;
    return {
        id => $id,
        created_at => BusyBird::DateTime::Format->format_datetime(
            DateTime->from_epoch(epoch => $id, time_zone => 'UTC')
        ),
        %busybird_elem
    };
}

sub test_sets {
    my ($got_set_array, $exp_set_array, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($got_set_hash, $exp_set_hash) = map {
        my $a = $_;
        my $h = {};
        $h->{$_}++ foreach @$a;
        $h;
    } ($got_set_array, $exp_set_array);
    is_deeply($got_set_hash, $exp_set_hash, $msg);
}

sub test_content {
    my ($timeline, $args_ref, $exp, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($error, $statuses) = sync($timeline, 'get_statuses', %$args_ref);
    is($error, undef, "get_statuses succeed");
    test_status_id_list($statuses, $exp, $msg);
}

1;
