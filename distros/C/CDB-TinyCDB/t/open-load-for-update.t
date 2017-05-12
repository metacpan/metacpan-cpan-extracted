
BEGIN {
    if ( $ENV{DEVELOPER_TEST_RUN_VALGRIND} ) {
        eval "require Test::Valgrind";
        Test::Valgrind->import();
    }
}

use Test::More tests => 1 + 1 + 308 * 2;
use Test::Exception;
use Test::NoWarnings;

use File::Copy qw( cp );

BEGIN { use_ok('CDB::TinyCDB') };

my $dbfileorig = "t/data.cdb";
my $dbfile = "t/data4up.cdb";

# shared refs
{
    package CDB::TinyCDB::Test::Package1;
    sub new { bless {name=>__PACKAGE__}, shift };
}
{
    package CDB::TinyCDB::Test::Package2;
    use overload '""' => sub { shift->{name} };
    sub new { bless {name=>__PACKAGE__}, shift };
}

open(BIN_FILE, "t/bin-file.cdb") or die "Cannot open binary file t/bin-file.cdb: $!";
binmode(BIN_FILE);
my $binary_data = '';
{
    local $/;
    my $buf;
    while ( (my $n = read BIN_FILE, $buf, 20) != 0) {
        $binary_data .= $buf;
    }
}


my %refs = (
    scalar_ref => \'new_value1',
    array_ref => [qw( foo bar )],
    hash_ref => { foo => 'bar' },
    code_ref => sub { print "hello" },
    glob_ref => \*BIN_FILE,
    obj_ref1 => CDB::TinyCDB::Test::Package1->new,
    obj_ref2 => CDB::TinyCDB::Test::Package2->new,
);
# shared refs

for my $method ( qw( open load ) ) {
    # diag $method;

    cp( $dbfileorig, $dbfile )
        or die "Cannot create a copy of t/data.cdb: $!\n";

    my $cdb;
    lives_ok {
        $cdb = CDB::TinyCDB->$method( $dbfile, for_update => "$dbfile.$$" );
    } "$method(for_update)";

    is( $cdb->get("k12"), 'v12',
        'get() returns correct value'
    );

    is( join('|', $cdb->getall("k42")), 'v42|v42',
        'getall() returns all values'
    );

    is( $cdb->getlast("k42"), 'v42',
        'getlast() returns last value'
    );

    my %cdb_orig = (
        (
            map {
                my $n = $_;
            $n = "0$n" if length($n) < 2;
                ( "k$n" => "v$n" )
            } ( 0 .. 99 )
        ),
        binary_file => $binary_data,
    );
    my %cdb_orig_dups = (
        (
            map {
                my $n = $_;
                ( "k$n" => "v$n" )
            } ( 40 .. 49, 80 .. 89 )
        ),
        binary_file => $binary_data,
    );

    is_deeply( 
        [ sort ( $cdb->keys ) ], [ sort ( keys %cdb_orig, keys %cdb_orig_dups ) ],
        "keys() returns old records"
    );

    while ( my ($k, $v) = $cdb->each ) {
        is( delete $cdb_orig{$k} || delete $cdb_orig_dups{$k}, $v,
            "each() returns correct value for $k"
        );
    }

    is( $cdb->exists("k34"), 1,
        "exists() returns true for previously existent records"
    );

    # put_*
    #
    lives_ok {
        $cdb->put_add( new => 'value' );
    } "put_add() is the only method allowed";

    is(
        $cdb->put_add(
            new_key1 => 'new_value1',
            new_key2 => 'new_value2',
            new_key3 => 'new_value3',
        ), 3,
        "put_add() returns correct number of new records added"
    );

    is(
        $cdb->put_add(
            k12 => 1 + 2,
            k21 => 2 + 1,
        ), 2,
        "put_add() works for keys that already exist in cdb file"
    );

    is( $cdb->put_add( binary_data => $binary_data ), 1,
        "put_add() works fine with binary data"
    );

    is(
        $cdb->put_add( %refs ), 7,
        "put_add() works for references - stringified values are stored"
    );

    is( $cdb->put_add( binary_data => $binary_data ), 1,
        "put_add() works fine with binary data (added again)"
    );

    is(
        $cdb->put_replace( non_existent_key => 'brand_new_value' ), 0,
        "put_replace() adds non existent keys and returns 0 (records replaced)"
    );

    is(
        $cdb->put_replace0( put_replace0 => 'that will be replaced later' ), 0,
        "put_replace0() adds non existent keys and returns 0 (records replaced)"
    );


    is(
        $cdb->put_replace( non_existent_key => 'brand_new_value2' ), 1,
        "put_replace() tells how many records have been replaced"
    );

    is(
        $cdb->put_replace0( put_replace0 => 'previous entry filled with zeros' ), 1,
        "put_replace0() tells how many records have been replaced"
    );

    is(
        $cdb->put_replace0( replace0_2 => 'this will be deleted later' ), 0,
        "put_replace0() adds non existent keys and returns 0 (records replaced)"
    );

    is(
        $cdb->put_replace0( replace0_2 => 'previous entry deleted' ), 1,
        "put_replace0() of last record works same way as put_replace()"
    );

    is(
        $cdb->put_add( nulls => chr(0) x 10 ), 1,
        "put_add() adds null strings fine"
    );
    {
        my $warning;
        local $SIG{__WARN__} = sub {
            $warning = shift;
        };
        my $res = $cdb->put_add( undefs => undef );
        like( $warning, qr/Use of uninitialized value in subroutine entry/,
            "put_add() warns about uninitialized value,"
           ."but adds them anyway as empty string" 
        );

        is( $res, 1, "put_add() adds undef values fine");
    }

    is(
        $cdb->put_insert(
            that_cant_exist_before => 'inserted record',
        ), 1,
        "put_insert() returns number of rows added"
    );

    is( $cdb->exists("that_cant_exist_before"), 1,
        "exists() returns true for just inserted records"
    );

    is( $cdb->exists("k34"), 1,
        "exists() returns true for previously existent records"
    );

    eval {
        $cdb->put_insert(
            k34 => 'that record already exists',
        );
    };
    like ( $@ , qr/Unable to insert new record - key exists/,
        "put_insert() cannot add duplicated records"
    );

    {
        my $warning;
        local $SIG{__WARN__} = sub {
            $warning = shift;
        };

        my $res = $cdb->put_warn(
            k95 => 'that record already exists',
            k1234567 => 'that record is new',
        );
        like( $warning, qr/Key k95 already exists - added anyway/,
            "put_warn() warns about duplicated entries, but adds them anyway" 
        );

        is( $res, 2, "put_warn() returns number of rows added");
    };

    eval {
        $cdb->finish(invalid_option => 1);
    };
    like( $@, qr/Invalid option/, "finish() won't accept invalid options");

    lives_ok {
        $cdb->finish( reopen => 1, save_changes => 1 ),
    } "finish() saves changes and reopens db";

    eval {
        $cdb->put_add( new_key => "some value" );
    };
    like( $@, qr/Database changes already committed/,
        "put_add() forbidden after finish() was called"
    );

    eval {
        $cdb->put_replace( new_key => "some value" );
    };
    like( $@, qr/Database changes already committed/,
        "put_replace() forbidden after finish() was called"
    );

    eval {
        $cdb->put_replace0( new_key => "some value" );
    };
    like( $@, qr/Database changes already committed/,
        "put_replace0() forbidden after finish() was called"
    );

    eval {
        $cdb->put_insert( new_key => "some value" );
    };
    like( $@, qr/Database changes already committed/,
        "put_insert() forbidden after finish() was called"
    );


    my %cdb = cdb_values();
    my %cdb_dups = (
        (
            map {
                my $n = $_;
                ( "k$n" => "v$n" )
            } ( 40 .. 49, 80 .. 89 )
        ),
        k12 => 1 + 2,
        k21 => 2 + 1,
        k95 => 'that record already exists',
        binary_file => $binary_data,
        binary_data => $binary_data,
    );

    is( $cdb->get("k89"), 'v89', 'get() returns correct value');
    is( join('|', $cdb->getall("k89")),
        'v89|v89',
        'getall() returns all values'
    );
    is( $cdb->getlast("k89"), 'v89', 'getlast() returns last value');

    is( $cdb->get("binary_data"), $binary_data,
        "get() returns correct binary data"
    );

    is( join('|',$cdb->getall("binary_data")),
         join('|', $binary_data, $binary_data),
        "getall() returns correct binary data"
    );

    is( $cdb->getlast("binary_data"), $binary_data,
        "getlast() returns correct binary data"
    );

    is_deeply( 
        [ sort ( $cdb->keys ) ], [ sort ( keys %cdb, keys %cdb_dups ) ],
        "keys() returns old and new records"
    );
    while ( my ($k, $v) = $cdb->each ) {
        my $val = exists $cdb{$k} ? delete $cdb{$k} : delete $cdb_dups{$k};
        is( $val, $v,
            "each() returns correct value for $k"
        );
    }

    is( keys(%cdb) + keys(%cdb_dups), 0, "each() returns all records");

}


sub cdb_values {
    my %v = (
        (
            map {
                $_ => "$refs{$_}" # stringify
            } keys %refs,
        ),
        (
            map {
                my $n = $_;
                $n = "0$n" if length($n) < 2;
                ( "k$n" => "v$n" )
            } ( 0 .. 99 )
        ),
        binary_file => $binary_data,
        binary_data => $binary_data,
        new => 'value',
        nulls => chr(0) x 10,
        undefs => '',
        new_key1 => 'new_value1',
        new_key2 => 'new_value2',
        new_key3 => 'new_value3',
        non_existent_key => 'brand_new_value',
        put_replace0 => 'that will be replaced later',
        non_existent_key => 'brand_new_value2',
        put_replace0 => 'previous entry filled with zeros',
        replace0_2 => 'this will be deleted later',
        replace0_2 => 'previous entry deleted',
        that_cant_exist_before => 'inserted record',
        k1234567 => 'that record is new',
    );

    return %v;
}

END {
    close(BIN_FILE);
    unlink $dbfile;
};

