use strict;
use warnings;
use Test::More ($ENV{TEST_DBIX_AURORA_RUN} ? () : (skip_all => 'set TEST_DBIX_AURORA_RUN env var'));
use DBIx::Aurora;
use t::dbix::aurora::Test::DBIx::Aurora;

my %guard = (
    writer => writer,
    reader => {
        1 => reader,
        2 => reader,
    }
);

subtest 'reader instance failure' => sub {
    my $aurora = DBIx::Aurora->new(
        AUDIENCE => {
            instances => [
                [ connect_info($guard{writer}->get_port),    { } ],
                [ connect_info($guard{reader}{1}->get_port), { } ],
                [ connect_info($guard{reader}{2}->get_port), { } ],
            ],
            opts => { }
        }
    );

    my $sql = 'SELECT @@global.innodb_read_only AS readonly';

    is_deeply +$aurora->audience->writer(sub { shift->selectrow_hashref($sql) }),
              { readonly => 0 };

    delete $guard{reader}{2}; # lost connection
    sleep 5;

    subtest 'reader should be selected randomly' => sub {
        my $counter = {
            failure => 0,
            success => 0,
        };

        for (1..10) {
            my $row = eval { $aurora->audience->reader(sub { shift->selectrow_hashref($sql) }) };
            if (my $e = $@) {
                fail "unexpected connection error: " . $e;
                $counter->{failure}++;
            } else {
                is_deeply $row, { readonly => 1 }, 'readonly';
                $counter->{success}++;
            }
        }

        subtest result => sub {
            ok $counter->{failure} ==  0;
            ok $counter->{success} == 10;
        };
    };
};

done_testing;

