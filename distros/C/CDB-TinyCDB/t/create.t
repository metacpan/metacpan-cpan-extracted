
BEGIN {
    if ( $ENV{DEVELOPER_TEST_RUN_VALGRIND} ) {
        eval "require Test::Valgrind";
        Test::Valgrind->import();
    }
}

use Test::More tests => 41 + ( $ENV{DEVELOPER_TEST_RUN} ? 2 : 0 );

use Test::Exception;
use Test::NoWarnings;

use File::Copy qw( cp );

BEGIN { use_ok('CDB::TinyCDB') };


my $dbfile = "t/data4cr.cdb";

cp( "t/data.cdb", $dbfile )
    or die "Cannot create a copy of t/data.cdb: $!\n";

my ($gtop, $mem_before, $mem_after); 
my @mems = qw(
    size
    vsize
);

if ($ENV{DEVELOPER_TEST_RUN}) {
    eval "require GTop;";
    $gtop = GTop->new();
    $mem_before = $gtop->proc_mem( $$ ); 
}

{
    my $cdb;

    lives_ok {
        $cdb = CDB::TinyCDB->create( $dbfile, "$dbfile.$$" );
    } "load(for_create)";

    eval {
        $cdb->create( $dbfile, "$dbfile.$$" );
    };
    like( $@, qr/is already blessed/,
        "create() cannot be called on object reference"
    );

    eval {
        $cdb->get("k12");
    };
    like( $@, qr/Database opened in create only mode/,
        "get() unavailable in create mode"
    );

    eval {
        $cdb->getall("k12");
    };
    like( $@, qr/Database opened in create only mode/,
        "getall() unavailable in create mode"
    );

    eval {
        $cdb->getlast("k12");
    };
    like( $@, qr/Database opened in create only mode/,
        "getlast() unavailable in create mode"
    );

    eval {
        $cdb->keys();
    };
    like( $@, qr/Database opened in create only mode/,
        "keys() unavailable in create mode"
    );

    eval {
        $cdb->each();
    };
    like( $@, qr/Database opened in create only mode/,
        "each() unavailable in create mode"
    );

    lives_ok {
        $cdb->exists("k12")
    } "exists() available before any changes made";

    is( $cdb->exists("k12"), 0,
        "exists() returns false for non-existent records"
    );

    # put_*

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
            new_key2 => 'new_value2 - added again',
            new_key3 => 'new_value3 - added again',
        ), 2,
        "put_add() works for just added keys "
    );

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
        $cdb->put_insert(
            that_cant_exist_before => 'inserted record',
        ), 1,
        "put_insert() returns number of rows added"
    );

    eval {
        $cdb->put_insert(
            new_key1 => 'that record already exists',
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
            new_key1 => 'that record already exists',
            k1234567 => 'that record is new',
        );
        like( $warning, qr/Key new_key1 already exists - added anyway/,
            "put_warn() warns about duplicated entries, but adds them anyway" 
        );

        is( $res, 2, "put_warn() returns number of rows added");
    };

    lives_ok {
        $cdb->exists("k12")
    } "exists() available before any changes made";

    is( $cdb->exists("k12"), 0,
        "exists() returns false for non-existent records"
    );


    eval {
        $cdb->finish(invalid_option => 1);
    };
    like( $@, qr/Invalid option/, "finish() won't accept invalid options");

    lives_ok {
        $cdb->finish( reopen => 1, save_changes => 1 ),
    } "finish() saves changes and reopens db";

    # after finish()
    #
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

    eval {
        $cdb->get("k12");
    };
    like( $@, qr/Database opened in create only mode/,
        "get() unavailable in create mode, even after finish()"
    );

    eval {
        $cdb->getall("k12");
    };
    like( $@, qr/Database opened in create only mode/,
        "getall() unavailable in create mode, even after finish()"
    );

    eval {
        $cdb->getlast("k12");
    };
    like( $@, qr/Database opened in create only mode/,
        "getlast() unavailable in create mode, even after finish()"
    );

    eval {
        $cdb->exists("k12")
    };
    like( $@, qr/Database changes already committed/,
        "exists() forbidden, in create mode, after finish() was called"
    );

    eval {
        $cdb->keys();
    };
    like( $@, qr/Database opened in create only mode/,
        "keys() unavailable in create mode, even after finish()"
    );

    eval {
        $cdb->each();
    };
    like( $@, qr/Database opened in create only mode/,
        "each() unavailable in create mode, even after finish()"
    );

    close (BIN_FILE);
}

if ($ENV{DEVELOPER_TEST_RUN}) {

    $mem_after = $gtop->proc_mem( $$ ); 

    is( $mem_after->$_ - $mem_before->$_, 0,
        "process memory $_ unchanged for create") for @mems;
}



END {
    unlink $dbfile;
};

