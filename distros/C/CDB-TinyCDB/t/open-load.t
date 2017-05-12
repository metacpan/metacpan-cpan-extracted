
BEGIN {
    if ( $ENV{DEVELOPER_TEST_RUN_VALGRIND} ) {
        eval "require Test::Valgrind";
        Test::Valgrind->import();
    }
}

use Test::More tests => 1 + 1 + 135 * 2;
use Test::Exception;
use Test::NoWarnings;

use File::Copy qw( cp );

BEGIN { use_ok('CDB::TinyCDB') };

my $dbfile = "t/data.cdb";

open(BIN_FILE, "t/bin-file.cdb") or die "Cannot open binary file $dbfile: $!";
binmode(BIN_FILE);
my $binary_data = '';
{
    local $/;
    my $buf;
    while ( (my $n = read BIN_FILE, $buf, 20) != 0) {
        $binary_data .= $buf;
    }
}
close(BIN_FILE);

my ($gtop, $mem_before, $mem_after); 
my @mems = qw(
    size
    vsize
);

for my $method ( qw( open load ) ) {
    # diag $method;

    my %cdb = (
        (
            map {
                my $n = $_;
                $n = "0$n" if length($n) < 2;
                ( "k$n" => "v$n" )
            } ( 0 .. 99 )
        ),
        binary_file => $binary_data,
    );

    my %cdb_dups = (
        (
            map {
                my $n = $_;
                ( "k$n" => "v$n" )
            } ( 40 .. 49, 80 .. 89 )
        ),
        binary_file => $binary_data,
    );


    if ($ENV{DEVELOPER_TEST_RUN}) {
        eval "require GTop;";
        $gtop = GTop->new();
        $mem_before = $gtop->proc_mem( $$ ); 
    }

    {
        my $cdb;

        lives_ok {
            $cdb = CDB::TinyCDB->$method( $dbfile );
        } "$method";

        eval {
            $cdb->$method( $dbfile );
        };

        like( $@, qr/is already blessed/,
            "open() cannot be called on object reference"
        );

        eval {
            $cdb->put_add( new_key => "some value" );
        };
        like( $@, qr/Database opened in read only mode/,
            "put_add() forbidden in read only mode"
        );

        eval {
            $cdb->put_replace( new_key => "some value" );
        };
        like( $@, qr/Database opened in read only mode/,
            "put_replace() forbidden in read only mode"
        );

        eval {
            $cdb->put_replace0( new_key => "some value" );
        };
        like( $@, qr/Database opened in read only mode/,
            "put_replace0() forbidden in read only mode"
        );

        eval {
            $cdb->put_insert( new_key => "some value" );
        };
        like( $@, qr/Database opened in read only mode/,
            "put_insert() forbidden in read only mode"
        );

        lives_ok {
            $cdb->exists("k12")
        } "exists() available in read only mode";

        is( $cdb->exists("k12"), 1,
            "exists() returns true for existent records"
        );

        is( $cdb->get("k45"), 'v45', 'get() returns correct value');
        is( join('|', $cdb->getall("k45")),
            'v45|v45',
            'getall() returns all values'
        );
        is( $cdb->getlast("k45"), 'v45',
            'getlast() returns last value'
        );

        is_deeply( 
            [ sort ( $cdb->keys ) ], [ sort ( keys %cdb, keys %cdb_dups ) ],
            "keys() returns old and new records"
        );

        while ( my ($k, $v) = $cdb->each ) {
            is( delete $cdb{$k} || delete $cdb_dups{$k}, $v,
                "each() returns correct value for $k"
            );
        }

        is( keys(%cdb) + keys(%cdb_dups), 0, "each() returns all records");
    }

    if ($ENV{DEVELOPER_TEST_RUN}) {

        $mem_after = $gtop->proc_mem( $$ ); 

        if ( $method eq 'open' ) {
            is( $mem_after->$_ - $mem_before->$_, 0,
                "process memory $_ unchanged for $method") for @mems;
        } else {
            is( $mem_after->$_ - $mem_before->$_ >= 0, 1,
                "process memory $_ changed for $method") for @mems;
        }
    }

}

