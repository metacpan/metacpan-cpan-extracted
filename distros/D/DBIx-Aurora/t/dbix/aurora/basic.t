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

subtest connect => sub {
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

    is_deeply +$aurora->audience->writer(sub {
        my $dbh = shift;
        my $row = $dbh->selectrow_hashref($sql);
        return $row;
    }), { readonly => 0 };

    for (1..10) {
        is_deeply +$aurora->audience->reader(sub {
            my $dbh = shift;
            my $row = $dbh->selectrow_hashref($sql);
            return $row;
        }), { readonly => 1 };
    }
};

done_testing;
