use v5.8.0;
use strict;
use warnings;
use Test::More;
use Test::Builder;
use BusyBird::StatusStorage::Memory;
use BusyBird::DateTime::Format;
use BusyBird::Log;
use DateTime;
use utf8;

$BusyBird::Log::Logger = undef;

sub test_log_contains {
    my ($logs_arrayref, $msg_pattern, $test_msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    ok(
        scalar(grep { $_->[1] =~ $msg_pattern } @$logs_arrayref),
        $test_msg
    );
}

sub status {
    my ($id) = @_;
    return {
        id => $id, text => "てくすと $_",
        created_at => BusyBird::DateTime::Format->format_datetime(
            DateTime->from_epoch(epoch => $id, time_zone => 'UTC')
        )
    };
}

my @logs = ();
my $filepath = 'test_status_storage_memory.json';
if(-r $filepath) {
    fail("$filepath exists before test. Test aborted.");
    exit(1);
}

{
    local $BusyBird::Log::Logger = sub { push(@logs, [@_]) };
    my $storage = new_ok('BusyBird::StatusStorage::Memory');
    ok(!$storage->load($filepath), "load() returns false if the file does not exist.");
    test_log_contains \@logs, qr{cannot.*read}i, "fails to load from $filepath";
    $storage->put_statuses(
        timeline => "hoge_tl", mode => 'insert',
        statuses => [ map { status($_) } 1..10 ],
    );
    ok($storage->save($filepath), "save() succeed");
    ok((-r $filepath), "$filepath is created");
    
    $storage->put_statuses(
        timeline => "hoge_tl", mode => "insert",
        statuses => [ map { status($_) } 50..55 ]
    );

    {
        my $another_storage = new_ok('BusyBird::StatusStorage::Memory');
        $another_storage->load($filepath);
        my $callbacked = 0;
        $another_storage->get_statuses(
            timeline => 'hoge_tl', count => 'all', callback => sub {
                my ($error, $statuses) = @_;
                $callbacked = 1;
                is($error, undef, "get_statuses succeed");
                is_deeply($statuses, [map { status($_) } reverse 1..10], "status loaded") or do {
                    diag(explain $statuses);
                };
            }
        );
        ok($callbacked, "callbacked");
        $another_storage->put_statuses(
            timeline => 'hoge_tl', mode => 'insert',
            statuses => [ map { status($_) } 11..15 ]
        );
        $another_storage->save($filepath);
    }

    ok($storage->load($filepath), "load() succeed");
    my $callbacked = 0;
    $storage->get_statuses(
        timeline => 'hoge_tl', count => 'all', callback => sub {
            my ($error, $statuses) = @_;
            is($error, undef, "get_statuses succeed");
            $callbacked = 1;
            is_deeply($statuses, [map { status($_)} reverse 1..15], "statuses loaded and they replaced the current content");
        }
    );
    ok($callbacked, "callbacked");
}

ok((-r $filepath), "$filepath exists");
unlink($filepath);

done_testing();

