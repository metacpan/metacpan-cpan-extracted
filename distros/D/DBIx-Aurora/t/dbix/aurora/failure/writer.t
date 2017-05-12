use strict;
use warnings;
use Test::More ($ENV{TEST_DBIX_AURORA_RUN} ? () : (skip_all => 'set TEST_DBIX_AURORA_RUN env var'));
use DBIx::Aurora;
use t::dbix::aurora::Test::DBIx::Aurora;

my $sql = 'SELECT @@global.innodb_read_only AS readonly';

my %guard = (
    writer => writer,
    reader => {
        1 => reader,
    }
);

subtest 'writer instance failure' => sub {
    my $aurora = DBIx::Aurora->new(
        AUDIENCE => {
            instances => [
                [ connect_info($guard{writer}->get_port),    { } ],
                [ connect_info($guard{reader}{1}->get_port), { } ],
            ],
            opts => {
                force_reader_only  => 1,
                reconnect_interval => 10,
            }
        }
    );

    subtest 'writer/reader should be ok' => sub {
        is_deeply $aurora->audience->writer(sub { shift->selectrow_arrayref($sql) }),
                  [ 0 ];
        is_deeply $aurora->audience->reader(sub { shift->selectrow_arrayref($sql) }),
                  [ 1 ];
    };

    delete $guard{writer}; # lost connection
    sleep 5;

    subtest 'writer should throw exception' => sub {
        my $row = eval { $aurora->audience->writer(sub { shift->selectrow_hashref($sql) }) };
        if (my $e = $@) {
            ok ref $e eq 'DBIx::Aurora::Instance::Exception::Connectivity::LostConnection', $e;
        } else {
            fail "should raise exception";
        }
    };

    subtest 'reader should be ok' => sub {
        my $row = $aurora->audience->reader(sub { shift->selectrow_arrayref($sql) });
        is_deeply $row, [ 1 ];
    };
};

done_testing;

