use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT like use_ok ) ], tests => 6;
use Test::API import => [ qw( class_api_ok ) ];
use Test::Fatal qw( exception );

my $module;

BEGIN {
  $module = 'DBIx::Migration';
  use_ok( $module ) or BAIL_OUT "Cannot load module '$module'!";
}

# "before" should not be part of the API:
# https://github.com/haarg/MooX-SetOnce/issues/2
class_api_ok( $module, qw( before new dir dbh dsn username password migrate version tracking_schema tracking_table ) );

like exception { $module->new() }, qr/\Aboth dsn and dbh are not set/, '"dsn" or "dbh" are both absent';

like exception { $module->new( dsn => 'dbi:Mem:', dbh => DBI->connect( 'dbi:Mem:', undef, undef, {} ) ) },
  qr/\Adsn and dbh cannot be used at the same time/, '"dsn" and "dbh" are mutually exclusive';

like exception { $module->new( dbh => DBI->connect( 'dbi:Mem:', undef, undef, {} ), username => 'foo' ) },
  qr/\Adbh and username cannot be used at the same time/, '"dbh" and "username" are mutually exclusive';

like exception { my $m = $module->new( dsn => 'dbi:Mem:' ); $m->dir( 'foo' ); $m->dir( 'bar' ) },
  qr/\Acannot change value of SetOnce attribute dir/, '"dir" is a set-once attribute';
