#!perl
BEGIN
{
	use strict;
	use warnings;
	use vars qw( $DEBUG );
	use lib './lib';
    use DBI qw( :sql_types );
    use Module::Generic::File qw( file );
	use Scalar::Util ();
    use Test::More qw( no_plan );
    use_ok( 'DB::Object' ) || BAIL_OUT( "Unable to load DB::Object" );
    use_ok( 'DB::Object::Query::Element' ) || BAIL_OUT( "Unable to load DB::Object::Query::Element" );
	eval( 'use DBD::Pg qw( :pg_types );' );
	use constant HAS_POSTGRESQL => ( $@ ? 0 : 1 );
	eval
	{
		require DBD::SQLite;
		require DBD::SQLite::Constants;
	};
	use constant HAS_SQLITE => ( $@ ? 0 : 1 );
	eval
	{
		require DBD::mysql;
	};
	use constant HAS_MYSQL => ( $@ ? 0 : 1 );
	our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

my $me = file(__FILE__);
my $path = $me->parent;
my @cleanup = ();
local $SIG{__DIE__} = \&_cleanup;
local $SIG{ABRT} = \&_cleanup;
local $SIG{BUS}  = \&_cleanup;
local $SIG{INT}  = \&_cleanup;
local $SIG{QUIT} = \&_cleanup;
local $SIG{SEGV} = \&_cleanup;
local $SIG{TERM} = \&_cleanup;

my $elem = DB::Object::Query::Element->new;
isa_ok( $elem, 'DB::Object::Query::Element' );

# egrep -E '^sub ' ./lib/DB/Object/Query/Element.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$elem, ''$m'' );"'
can_ok( $elem, 'init' );
can_ok( $elem, 'elements' );
can_ok( $elem, 'field' );
can_ok( $elem, 'format' );
can_ok( $elem, 'index' );
can_ok( $elem, 'is_numbered' );
can_ok( $elem, 'placeholder' );
can_ok( $elem, 'query_object' );
can_ok( $elem, 'type' );
can_ok( $elem, 'value' );

SKIP:
{
    if( HAS_POSTGRESQL )
    {
        my $con_params =
        {
        db		=> ( $ENV{DB_DATABASE} || 'postgres' ),
        host    => ( $ENV{DB_HOST} || 'localhost' ),
        driver	=> 'Pg',
        debug   => $DEBUG,
        };
        $con_params->{conf_file} = $ENV{DB_CONF} if( exists( $ENV{DB_CONF} ) && $ENV{DB_CONF} );
        if( $^O eq 'MSWin32' )
        {
            $con_params->{login} = ( $ENV{DB_LOGIN} || getlogin ) if( !$ENV{DB_CON_FILE} );
        }
        else
        {
            $con_params->{login} = ( $ENV{DB_LOGIN} || getlogin || (getpwuid( $> ))[0] ) if( !$ENV{DB_CON_FILE} );
        }
        
        eval
        {
            require DB::Object::Postgres;
        };
        skip( "DBD::Pg not installed", 1 ) if( $@ );
        
        my $dbh = DB::Object::Postgres->connect( $con_params );
        if( !defined( $dbh ) )
        {
            skip( "PostgreSQL Database connection failed, cancelling other tests: " . DB::Object::Postgres->error, 17 );
        }
        else
        {
            $dbh->debug( $DEBUG );
            diag( "Debug value is: ", $dbh->debug );
            my $tbl = $dbh->table( 'products' );
            ok( $tbl, '$dbh->table( "products" )' );
            if( !defined( $tbl ) )
            {
                diag( "Error getting the table object: ", $dbh->error );
                skip( "Cannot get table object for PostgreSQL driver", 12 );
            }
            my $qo = $tbl->get_query_object;
            my $type_value = $dbh->datatype_to_constant( 'uuid' ) || do
            {
                BAIL_OUT( $dbh->error ) if( $dbh->error );
            };
            subtest 'numbered placeholder' => sub
            {
                $elem = DB::Object::Query::Element->new(
                    debug           => $DEBUG,
                    field           => 'product_id',
                    placeholder     => '$2',
                    query_object    => $qo,
                    # PG_UUID -> 2950
                    type            => &DBD::Pg::PG_UUID,
                );
                is( $elem->placeholder, '$2', 'placeholder' );
                ok( $elem->is_numbered, 'is_numbered' );
                is( $elem->index, 2, 'index' );
                is( $elem->field, 'product_id', 'field' );
                is( $elem->format, undef, 'format' );
                isa_ok( $elem->query_object, 'DB::Object::Query', 'query_object' );
                is( $elem->type, $type_value, 'type' );
                is( $elem->value, undef, 'value' );
            };
            
            subtest 'regular placeholder' => sub
            {
                $elem = DB::Object::Query::Element->new(
                    debug           => $DEBUG,
                    field           => 'product_id',
                    placeholder     => '?',
                    query_object    => $qo,
                    # PG_UUID -> 2950
                    type            => &DBD::Pg::PG_UUID,
                );
                is( $elem->placeholder, '?', 'placeholder' );
                ok( !$elem->is_numbered, 'is_numbered' );
                is( $elem->index, undef, 'index' );
                is( $elem->field, 'product_id', 'field' );
                is( $elem->format, undef, 'format' );
                isa_ok( $elem->query_object, 'DB::Object::Query', 'query_object' );
                is( $elem->type, $type_value, 'type' );
                is( $elem->value, undef, 'value' );
            };

            subtest 'field format' => sub
            {
                $elem = DB::Object::Query::Element->new(
                    debug           => $DEBUG,
                    field           => 'product_id',
                    format          => q{product_id = '2835c7e0-ab86-4fe9-928d-730d129c2415'},
                    query_object    => $qo,
                    # PG_UUID -> 2950
                    type            => &DBD::Pg::PG_UUID,
                    value           => '2835c7e0-ab86-4fe9-928d-730d129c2415',
                );
                is( $elem->placeholder, undef, 'placeholder' );
                ok( !$elem->is_numbered, 'is_numbered' );
                is( $elem->index, undef, 'index' );
                is( $elem->field, 'product_id', 'field' );
                is( $elem->format, q{product_id = '2835c7e0-ab86-4fe9-928d-730d129c2415'}, 'format' );
                isa_ok( $elem->query_object, 'DB::Object::Query', 'query_object' );
                is( $elem->type, $type_value, 'type' );
                is( $elem->value, '2835c7e0-ab86-4fe9-928d-730d129c2415', 'value' );
            };
        }
    }
    else
    {
        skip( "No DBD::Pg driver installed", 10 );
    }
    
    if( HAS_SQLITE )
    {
        my $test_db = $path->child( 'db_object_test.sqlite' );
        push( @cleanup, sub
        {
            diag( "Removing SQLite database file $test_db" ) if( $DEBUG && $test_db->exists );
            $test_db->remove if( $test_db->exists );
        });
        my $con_uri = $ENV{DB_CON_URI} = "file:${test_db}";
        
        eval
        {
            require DB::Object::SQLite;
        };
        skip( "DBD::SQLite not installed", 1 ) if( $@ );

        my $dbh = DB::Object::SQLite->connect(
            uri     => $con_uri,
            driver  => 'SQLite',
            debug   => $DEBUG,
        );
        if( !defined( $dbh ) )
        {
            skip( "SQLite Database connection failed, cancelling other tests: " . DB::Object::SQLite->error, 17 );
        }
        else
        {
            my $tbl = $dbh->table( 'products' );
            ok( $tbl, '$dbh->table( "products" )' );
            if( !defined( $tbl ) )
            {
                diag( "Error getting the table object: ", $dbh->error );
                skip( "Cannot get table object for SQLite driver", 12 );
            }

            my $qo = $tbl->get_query_object;
            my $type_value = $dbh->datatype_to_constant( 'varchar' );
            # <https://metacpan.org/pod/DBD::SQLite#Placeholders>
            # <https://www.sqlite.org/lang_expr.html#varparam>
            subtest 'numbered placeholder' => sub
            {
                $elem = DB::Object::Query::Element->new(
                    debug           => $DEBUG,
                    field           => 'product_id',
                    placeholder     => '?2',
                    query_object    => $qo,
                    # SQL_VARCHAR -> 12
                    type            => &DBD::SQLite::Constants::SQLITE_TEXT,
                );
                is( $elem->placeholder, '?2', 'placeholder' );
                ok( $elem->is_numbered, 'is_numbered' );
                is( $elem->index, 2, 'index' );
                is( $elem->field, 'product_id', 'field' );
                is( $elem->format, undef, 'format' );
                isa_ok( $elem->query_object, 'DB::Object::Query', 'query_object' );
                is( $elem->type, $type_value, 'type' );
                is( $elem->value, undef, 'value' );
            };
            
            subtest 'regular placeholder' => sub
            {
                $elem = DB::Object::Query::Element->new(
                    debug           => $DEBUG,
                    field           => 'product_id',
                    placeholder     => '?',
                    query_object    => $qo,
                    # SQL_VARCHAR -> 12
                    type            => &DBD::SQLite::Constants::SQLITE_TEXT,
                );
                is( $elem->placeholder, '?', 'placeholder' );
                ok( !$elem->is_numbered, 'is_numbered' );
                is( $elem->index, undef, 'index' );
                is( $elem->field, 'product_id', 'field' );
                is( $elem->format, undef, 'format' );
                isa_ok( $elem->query_object, 'DB::Object::Query', 'query_object' );
                is( $elem->type, $type_value, 'type' );
                is( $elem->value, undef, 'value' );
            };

            subtest 'field format' => sub
            {
                $elem = DB::Object::Query::Element->new(
                    debug           => $DEBUG,
                    field           => 'product_id',
                    format          => q{product_id = '2835c7e0-ab86-4fe9-928d-730d129c2415'},
                    query_object    => $qo,
                    # SQL_VARCHAR -> 12
                    type            => &DBD::SQLite::Constants::SQLITE_TEXT,
                    value           => '2835c7e0-ab86-4fe9-928d-730d129c2415',
                );
                is( $elem->placeholder, undef, 'placeholder' );
                ok( !$elem->is_numbered, 'is_numbered' );
                is( $elem->index, undef, 'index' );
                is( $elem->field, 'product_id', 'field' );
                is( $elem->format, q{product_id = '2835c7e0-ab86-4fe9-928d-730d129c2415'}, 'format' );
                isa_ok( $elem->query_object, 'DB::Object::Query', 'query_object' );
                is( $elem->type, $type_value, 'type' );
                is( $elem->value, '2835c7e0-ab86-4fe9-928d-730d129c2415', 'value' );
            };
        }
    }
    else
    {
        skip( "No DBD::SQLite driver installed", 10 );
    }
};

done_testing();

sub _cleanup
{
    foreach my $code ( @cleanup )
    {
        $code->() if( ref( $code ) eq 'CODE' );
    }
}

END
{
    &_cleanup;
};

__END__

