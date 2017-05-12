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

    subtest 'before writer outage' => sub {
        subtest 'writer/reader should be ok' => sub {
            is_deeply $aurora->audience->writer(sub { shift->selectrow_arrayref($sql) }),
                    [ 0 ];
            is_deeply $aurora->audience->reader(sub { shift->selectrow_arrayref($sql) }),
                    [ 1 ];
        };
    };

    delete $guard{writer}; # lost connection
    sleep 3;

    subtest 'after writer outage' => sub {
        subtest 'writer should throw exception' => sub {
            my $row = eval { $aurora->audience->writer(sub { shift->selectrow_arrayref($sql) }) };
            if (my $e = $@) {
                ok ref $e eq 'DBIx::Aurora::Instance::Exception::Connectivity::LostConnection'
            } else {
                fail "should raise exception";
            }
        };

        subtest 'after writer outage | reader should be ok' => sub {
            my $row = $aurora->audience->reader(sub { shift->selectrow_arrayref($sql) });
            is_deeply $row, [ 1 ];
        };
    };

    undef %guard; # lost ALL connection
    sleep 2;

    subtest 'after lost all connections' => sub {
        subtest 'writer should throw exception' => sub {
            my $row = eval { $aurora->audience->writer(sub { shift->selectrow_arrayref($sql) }) };
            if (my $e = $@) {
                ok ref $e eq 'DBIx::Aurora::Instance::Exception::Connectivity::LostConnection'
            } else {
                fail "should raise exception";
            }
        };

        subtest 'reader should throw exception' => sub {
            my $row = eval { $aurora->audience->reader(sub { shift->selectrow_arrayref($sql) }) };
            if (my $e = $@) {
                ok ref $e eq 'DBIx::Aurora::Instance::Exception::Connectivity::LostConnection'
            } else {
                fail "should raise exception";
            }
        };
    };

    # launch all instances
    %guard = (
        writer => writer,
        reader => {
            1 => reader,
        }
    );

    sleep 15; # wait until `reconnect_interval` expiration

    { # ugh
        $aurora->audience->{instances}{0}{instance}{handler}{_connect_info}[0]
            = connect_info($guard{writer}->get_port)->[0];
        $aurora->audience->{instances}{1}{instance}{handler}{_connect_info}[0]
            = connect_info($guard{reader}{1}->get_port)->[0];
    }

    subtest 'after recovering and reconnect_interval expired' => sub {
        subtest 'writer/reader should be ok' => sub {
            is_deeply $aurora->audience->writer(sub { shift->selectrow_arrayref($sql) }),
                    [ 0 ];
            is_deeply $aurora->audience->reader(sub { shift->selectrow_arrayref($sql) }),
                    [ 1 ];
        };
    };
};

done_testing;
