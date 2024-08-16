BEGIN {
    delete $INC{'FindBin.pm'};
    require FindBin;
}

use autobox::Core;
use Test::Most;
use Capture::Tiny 'capture_stdout', 'capture_stderr', 'capture';
use Cwd 'realpath';
use DBIx::Squirrel::util ':all';
use DBIx::Squirrel;

use lib realpath("$FindBin::Bin/../lib");
use T::Database ':all';

subtest 'test' => sub {
    my $dbh = DBIx::Squirrel->connect(@T_DB_CONNECT_ARGS);

    my @albums = $dbh->results('SELECT * FROM albums')->_slice([])->all;

    # diag_val @albums;

    $dbh->disconnect;

    ok 1, 'Subtest complete';
};

ok 1, __FILE__ . ' complete';
done_testing;
