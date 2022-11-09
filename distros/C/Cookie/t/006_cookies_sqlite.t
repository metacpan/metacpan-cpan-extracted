#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
    use vars qw( $DEBUG $HAS_DBI $HAS_SQLITE_BIN $SQLITE_BIN );
    # 2021-11-01T08:12:10
    use Test::Time time => 1635754330;
    use Devel::Confess;
    use File::Which ();
    use HTTP::Request ();
    use HTTP::Response ();
    use Module::Generic::File qw( file );
    our $CRYPTX_REQUIRED_VERSION = '0.074';
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Cookie' );
    use_ok( 'Cookie::Jar' );
    require( "./t/env.pl" ) if( -e( "t/env.pl" ) );
    eval
    {
        require DBI;
        require DBD::SQLite;
    };
    $HAS_DBI = !$@;
    $SQLITE_BIN = File::Which::which( 'sqlite3' );
    $HAS_SQLITE_BIN = ( defined( $SQLITE_BIN ) && length( $SQLITE_BIN ) ) ? 1 : 0;
    plan skip_all => "DBI and DBD::SQLite not installed and sqlite3 binary not found" if( !$HAS_DBI && !$HAS_SQLITE_BIN );
};

use strict;
use warnings;
my $rv;

my $jar = Cookie::Jar->new( debug => $DEBUG );
$jar->add({
    name => 'cookie1',
    value => 'value1',
    domain => 'example.com',
    path => '/',
    expires => '+100D',
    secure => 1,
    http_only => 0,
    strict => 0,
    created_on => '-2D',
});

$jar->add({
    name => 'cookie2',
    value => 'value2',
    domain => 'example.org',
    path => '/session',
    expires => 0,
    secure => 1,
    http_only => 1,
    strict => 1,
    created_on => 'now',
});

is( $jar->length, 2, 'total cookies in jar' );
my $db = file( __FILE__ )->parent->child( 'cookies.sqlite' );
$rv = $jar->save_as_mozilla( $db );
diag( ( $rv ? 'Successfully created' : 'Failed to create' ), " SQLite database ${db}" ) if( $DEBUG );
ok( $rv, "SQLite database ${db} created" );

my $jar2 = Cookie::Jar->new( debug => $DEBUG );
$rv = $jar2->load_as_mozilla( $db );
ok( $rv, "load_as_mozilla" );
is( $jar2->length, 2, 'number of cookies in repository' );
if( $db->exists )
{
    diag( "Removing temporary SQLite database file ${db}" ) if( $DEBUG );
    $db->remove;
}

SKIP:
{
    skip( "DBI and/or DBD::SQLite are not installed.", 3 ) if( !$HAS_DBI );
    $rv = $jar->save_as_mozilla( $db, {
        use_dbi => 1,
        ( $DEBUG ? ( log_sql => file( __FILE__ )->parent->child( 'sqlite_dbi_debug.log' ) ) : () )
    });
    if( !defined( $rv ) && $DEBUG )
    {
        diag( "Error saving cookies as mozilla SQLite database using DBI: ", $jar->error );
    }
    ok( $rv, 'SQLite cookies database created with DBI' );
    my $jar3 = Cookie::Jar->new( debug => $DEBUG );
    $rv = $jar3->load_as_mozilla( $db, { use_dbi => 1 } );
    if( !defined( $rv ) && $DEBUG )
    {
        diag( "Error loading cookies as mozilla SQLite database: ", $jar3->error );
    }
    ok( $rv, "load_as_mozilla using DBI" );
    is( $jar3->length, 2, 'number of cookies in repository' );
    if( $db->exists )
    {
        diag( "Removing temporary SQLite database file ${db}" ) if( $DEBUG );
        $db->remove;
    }
};

SKIP:
{
    skip( "No sqlite3 binary could be found.", 3 ) if( !$HAS_SQLITE_BIN );
    $rv = $jar->save_as_mozilla( $db, {
        sqlite => $SQLITE_BIN,
        ( $DEBUG ? ( log_sql => file( __FILE__ )->parent->child( 'sqlite_bin_debug.log' ) ) : () )
    });
    if( !defined( $rv ) && $DEBUG )
    {
        diag( "Error saving cookies as mozilla SQLite database using sqlite3 binary: ", $jar->error );
    }
    ok( $rv, "SQLite cookies database created with sqlite3 binary ${SQLITE_BIN}" );
    my $jar4 = Cookie::Jar->new( debug => $DEBUG );
    $rv = $jar4->load_as_mozilla( $db, { sqlite => $SQLITE_BIN } );
    if( !defined( $rv ) && $DEBUG )
    {
        diag( "Error loading cookies as mozilla SQLite database: ", $jar4->error );
    }
    ok( $rv, "load_as_mozilla using SQLite binary ${SQLITE_BIN}" );
    is( $jar4->length, 2, 'number of cookies in repository' );
    if( $db->exists )
    {
        diag( "Removing temporary SQLite database file ${db}" ) if( $DEBUG );
        $db->remove;
    }
};

done_testing();

__END__
