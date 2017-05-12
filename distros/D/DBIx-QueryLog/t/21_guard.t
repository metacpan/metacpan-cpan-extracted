use strict;
use warnings;
use Test::Requires 'DBD::SQLite';
use Test::More;
use t::Util;
use DBIx::QueryLog ();

my $dbh = t::Util->new_dbh;

sub test_execute {
    my %specs = @_;
    my ($is_capture, $expects, $desc) = @specs{qw/is_capture expects desc/};

    if ($is_capture) {
        my $guard = DBIx::QueryLog->guard;
        my $res = capture {
            $dbh->do('SELECT * FROM sqlite_master');
        };

        like $res, $expects, 'result ok';
    }
    else {
        my $res = capture {
            $dbh->do('SELECT * FROM sqlite_master');
        };
        is $res, $expects, 'undef';
    }
}

test_execute(
    is_capture => 0,
    expects    => undef,
    desc       => 'not enable',
);

test_execute(
    is_capture => 1,
    expects    => qr/SELECT \* FROM sqlite_master/,
    desc       => 'not enable',
);

done_testing;
