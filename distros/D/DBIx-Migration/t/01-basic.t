use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT is is_deeply like note use_ok ) ], tests => 12;
use Test::API import => [ qw( class_api_ok ) ];
use Test::Fatal qw( exception );

use DBI::Const::GetInfoType qw( %GetInfoType );
use Path::Tiny              qw( cwd );

my ( $class, $subclass );

BEGIN {
  $class = 'DBIx::Migration';
  use_ok( $class ) or BAIL_OUT "Cannot load class '$class'!";
  $subclass = 'DBIx::Migration::Pg';
  use_ok( $subclass ) or BAIL_OUT "Cannot load class '$subclass'!";
}

# "before" should not be part of the API:
# https://github.com/haarg/MooX-SetOnce/issues/2
class_api_ok( $class,
  qw( before new dsn username password dbh dir do_before do_while tracking_table placeholders create_tracking_table quoted_tracking_table driver latest migrate version )
);

class_api_ok( $subclass,
  qw( new do_before do_while dsn managed_schema tracking_schema create_tracking_table placeholders quoted_tracking_table )
);

like exception { $class->new() }, qr/\Aboth dsn and dbh are not set/, '"dsn" or "dbh" are both absent';

like exception { $class->new( dsn => 'dbi:Mock:', dbh => DBI->connect( 'dbi:Mock:', undef, undef, {} ) ) },
  qr/\Adsn and dbh cannot be used at the same time/, '"dsn" and "dbh" are mutually exclusive';

like exception { $class->new( dbh => DBI->connect( 'dbi:Mock:', undef, undef, {} ), username => 'foo' ) },
  qr/\Adbh and username cannot be used at the same time/, '"dbh" and "username" are mutually exclusive';

my $dbh = DBI->connect( 'dbi:Mock:', undef, undef, {} );
note 'Numeric value of the GetInfo Type Code SQL_DATA_SOURCE_NAME: ', $GetInfoType{ SQL_DATA_SOURCE_NAME };
$dbh->{ mock_get_info } = { $GetInfoType{ SQL_DATA_SOURCE_NAME } => 'dbi:SQLite:' };
like exception { $subclass->new( dbh => $dbh ) },
  qr/\Asubclass DBIx::Migration::Pg cannot handle SQLite driver/, 'subclass-driver inconsistency';

my $m = $class->new( dbh => $dbh );
$m->dir( cwd->child( qw( t sql match ) ) );
is ref( my $files = $m->_files( 'up', [ 1 .. 1 ] ) ), 'ARRAY', 'migrations found';
is_deeply [ map { $_->{ name }->basename } @$files ], [ qw( schema_1_up.sql ) ],
  'single migration with proper name (not "schema_11_up.sql")';

$m = $class->new( dbh => $dbh );
$m->dir( cwd->child( qw( t sql match ) ) );
is ref( $files = $m->_files( 'up', [ 1 .. 2 ] ) ), 'ARRAY', 'migrations found';
is_deeply [ map { $_->{ name }->basename } @$files ], [ qw( schema_1_up.sql 2_up.sql ) ],
  'two migrations: one with and one without "schema_" prefix';
