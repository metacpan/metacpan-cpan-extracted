BEGIN {
    delete $INC{ 'FindBin.pm' };
    require FindBin;
}

use autobox::Core;
use Test::Most;
use Capture::Tiny 'capture_stdout', 'capture_stderr', 'capture';
use Cwd 'realpath';
use DBIx::Squirrel::util ':all';
use DBIx::Squirrel;

use lib realpath( "$FindBin::Bin/../lib" );
use T::Database ':all';

our (
    $sql, $sth, $res, $got, @got, $exp, @exp, $row, $dbh, $it, $stdout,
    $stderr, @hashrefs, @arrayrefs, $standard_dbi_dbh, $standard_ekorn_dbh,
    $cached_ekorn_dbh,
);

$standard_dbi_dbh   = DBI->connect( @T_DB_CONNECT_ARGS );
$standard_ekorn_dbh = DBIx::Squirrel->connect( @T_DB_CONNECT_ARGS );
isa_ok $standard_ekorn_dbh, 'DBIx::Squirrel::db';
$cached_ekorn_dbh = DBIx::Squirrel->connect_cached( @T_DB_CONNECT_ARGS );
isa_ok $cached_ekorn_dbh, 'DBIx::Squirrel::db';

test_clone_connection( $_ ) foreach (
    [ $standard_dbi_dbh,   'standard DBI connection' ],
    [ $standard_ekorn_dbh, 'standard DBIx::Squirrel connection' ],
    [ $cached_ekorn_dbh,   'cached DBIx::Squirrel connection' ],
);

ok 1, __FILE__ . ' complete';
done_testing;

sub test_clone_connection
{
    my ( $master, $description ) = @{ +shift };

    diag "";
    diag "Test connection cloned from a $description";
    diag "";

    my $clone = DBIx::Squirrel->connect( $master );
    isa_ok $clone, 'DBIx::Squirrel::db';

    diag "";
    diag "Test prepare-execute-fetch cycle";
    diag "";
    test_prepare_execute_fetch_single_row( $clone );

    $clone->disconnect;
    $master->disconnect;
    return;
}

sub test_prepare_execute_fetch_single_row
{
    my ( $dbh ) = @_;

    diag "Result contains a single row";
    diag "";

    $sql = << '';
    SELECT *
    FROM media_types
    ORDER BY MediaTypeId
    LIMIT 1

    @arrayrefs = (
        [ 1, "MPEG audio file", ],
    );

    @hashrefs = ( {
            MediaTypeId => 1,
            Name        => "MPEG audio file",
        }
    );

    $sth = $dbh->prepare( $sql );
    isa_ok $sth, 'DBIx::Squirrel::st';

    $res = $sth->execute;
    is $res, '0E0', 'execute';
    diag_result $sth;

    ( $exp, $got ) = (
        $arrayrefs[ 0 ],
        do {
            ( $stderr, $row ) = capture_stderr {
                $sth = $dbh->prepare( $sql );
                $it  = $sth->it;
                $it->single;
            };
            $row;
        },
    );
    is_deeply $exp, $got, 'single';
    is $stderr, '', 'got no warning when result contains single row';

    return;
}
