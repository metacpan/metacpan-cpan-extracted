use strict;
use warnings;
use Test::More ($ENV{TEST_DBIX_AURORA_RUN} ? () : (skip_all => 'set TEST_DBIX_AURORA_RUN env var'));
use DBIx::Aurora;
use t::dbix::aurora::Test::DBIx::Aurora;

subtest force_reader_only => sub {
    subtest on => sub {
        my %guard = (
            writer => writer,
        );

        my $aurora = DBIx::Aurora->new(
            AUDIENCE => {
                instances => [
                    [ connect_info($guard{writer}->get_port), { } ],
                    [ connect_info($guard{writer}->get_port), { } ],
                ],
                opts => { force_reader_only => 1 }
            }
        );

        my $row = eval { $aurora->audience->reader(sub { shift->selectrow_arrayref('SELECT 1') })};
        if (my $e = $@) {
            ok $e =~ /No reader found/;
        } else {
            fail "should raise exception";
        }
    };

    subtest off => sub {
        my %guard = (
            writer => writer,
        );

        my $aurora = DBIx::Aurora->new(
            AUDIENCE => {
                instances => [
                    [ connect_info($guard{writer}->get_port), { } ],
                    [ connect_info($guard{writer}->get_port), { } ],
                ],
                opts => { }
            }
        );

        my $row = $aurora->audience->reader(sub { shift->selectrow_arrayref('SELECT 1') });
        is_deeply $row, [ 1 ] or note explain $row;
    };
};

done_testing;

