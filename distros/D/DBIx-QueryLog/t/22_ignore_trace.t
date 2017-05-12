use strict;
use warnings;
use Test::Requires 'DBD::SQLite';
use Test::More;
use t::Util;
use DBIx::QueryLog ();

my $dbh = t::Util->new_dbh;

sub test_execute {
    my %specs = @_;
    my ($ignore_trace, $expects, $desc) = @specs{qw/ignore_trace expects desc/};

    DBIx::QueryLog->enable;

    if ($ignore_trace) {
        my $guard = DBIx::QueryLog->ignore_trace;
        my $res = capture {
            $dbh->do('SELECT * FROM sqlite_master');
        };
        is $res, $expects, 'undef';
    }
    else {
        my $res = capture {
            $dbh->do('SELECT * FROM sqlite_master');
        };
        like $res, $expects, 'result ok';
    }
}

test_execute(
    ignore_trace => 1,
    expects      => undef,
    desc         => 'not enable',
);

test_execute(
    ignore_trace => 0,
    expects      => qr/SELECT \* FROM sqlite_master/,
    desc         => 'not enable',
);

done_testing;
