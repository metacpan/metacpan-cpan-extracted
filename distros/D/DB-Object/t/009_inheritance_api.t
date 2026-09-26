#!perl
##----------------------------------------------------------------------------
## SQL API Abstraction - t/009_inheritance_api.t
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use vars qw( $DEBUG );
    use lib './lib';
    use Test::More;
    select(($|=1,select(STDERR),$|=1)[1]);
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use_ok( 'DB::Object' )                    or BAIL_OUT( 'Cannot load DB::Object' );
    use_ok( 'DB::Object::Tables' )            or BAIL_OUT( 'Cannot load DB::Object::Tables' );
    use_ok( 'DB::Object::Statement' )         or BAIL_OUT( 'Cannot load DB::Object::Statement' );
    use_ok( 'DB::Object::Query' )             or BAIL_OUT( 'Cannot load DB::Object::Query' );
    use_ok( 'DB::Object::SQLite::Tables' )    or BAIL_OUT( 'Cannot load DB::Object::SQLite::Tables' );
    use_ok( 'DB::Object::SQLite::Statement' ) or BAIL_OUT( 'Cannot load DB::Object::SQLite::Statement' );
    use_ok( 'DB::Object::Mysql::Tables' )     or BAIL_OUT( 'Cannot load DB::Object::Mysql::Tables' );
    use_ok( 'DB::Object::Mysql::Statement' )  or BAIL_OUT( 'Cannot load DB::Object::Mysql::Statement' );
    use_ok( 'DB::Object::Postgres::Tables' )  or BAIL_OUT( 'Cannot load DB::Object::Postgres::Tables' );
};

is_deeply( \@DB::Object::ISA, [qw( Module::Generic DBI )], 'DB::Object keeps historical DBI inheritance' );
ok( DB::Object->isa( 'DBI' ), 'DB::Object remains a DBI subclass for compatibility' );

is_deeply( \@DB::Object::Tables::ISA, [qw( DB::Object )], 'DB::Object::Tables has its natural parent' );
is_deeply( \@DB::Object::Statement::ISA, [qw( DB::Object )], 'DB::Object::Statement has its natural parent' );
is_deeply( \@DB::Object::Query::ISA, [qw( DB::Object )], 'DB::Object::Query has its natural parent' );

is_deeply( \@DB::Object::SQLite::Tables::ISA, [qw( DB::Object::Tables )], 'SQLite tables use single inheritance' );
is_deeply( \@DB::Object::SQLite::Statement::ISA, [qw( DB::Object::Statement )], 'SQLite statements use single inheritance' );
is_deeply( \@DB::Object::Mysql::Tables::ISA, [qw( DB::Object::Tables )], 'MySQL tables use single inheritance' );
is_deeply( \@DB::Object::Mysql::Statement::ISA, [qw( DB::Object::Statement )], 'MySQL statements use single inheritance' );
is_deeply( \@DB::Object::Postgres::Tables::ISA, [qw( DB::Object::Tables )], 'PostgreSQL tables use single inheritance' );

SKIP:
{
    eval { require DB::Object::Postgres::Statement; 1 } || skip( 'DBD::Pg is not installed', 1 );
    is_deeply( \@DB::Object::Postgres::Statement::ISA, [qw( DB::Object::Statement )], 'PostgreSQL statements use single inheritance' );
}

ok( DB::Object::Tables->can( 'having' ), 'DB::Object::Tables provides having() directly' );
is( DB::Object::SQLite::Tables->can( 'having' ), DB::Object::Tables->can( 'having' ), 'SQLite tables inherit having() from DB::Object::Tables' );
is( DB::Object::Mysql::Tables->can( 'having' ), DB::Object::Tables->can( 'having' ), 'MySQL tables inherit having() from DB::Object::Tables' );
is( DB::Object::Postgres::Tables->can( 'having' ), DB::Object::Tables->can( 'having' ), 'PostgreSQL tables inherit having() from DB::Object::Tables' );

ok( DB::Object::SQLite::Tables->can( 'stat' ), 'SQLite tables keep an explicit stat() delegation' );
isnt( DB::Object::SQLite::Tables->can( 'stat' ), DB::Object::Tables->can( 'stat' ), 'SQLite stat() is driver-specific and not the generic table method' );

ok( !DB::Object::SQLite::Tables->isa( 'DB::Object::SQLite' ), 'SQLite tables are not database objects' );
ok( !DB::Object::Mysql::Tables->isa( 'DB::Object::Mysql' ), 'MySQL tables are not database objects' );
ok( !DB::Object::Postgres::Tables->isa( 'DB::Object::Postgres' ), 'PostgreSQL tables are not database objects' );
ok( !DB::Object::SQLite::Statement->isa( 'DB::Object::SQLite' ), 'SQLite statements are not database objects' );
ok( !DB::Object::Mysql::Statement->isa( 'DB::Object::Mysql' ), 'MySQL statements are not database objects' );

SKIP:
{
    eval { require DB::Object::Postgres::Statement; 1 } || skip( 'DBD::Pg is not installed', 1 );
    ok( !DB::Object::Postgres::Statement->isa( 'DB::Object::Postgres' ), 'PostgreSQL statements are not database objects' );
}

done_testing();

__END__
