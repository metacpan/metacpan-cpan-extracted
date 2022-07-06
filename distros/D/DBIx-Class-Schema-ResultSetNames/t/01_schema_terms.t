use strict;
use warnings;
use lib 't/lib';
use Test2::V0;
use Try::Tiny;

use TestSchema;

try { require DBD::SQLite }
catch { plan skip_all => 'DBD::SQLite required to run these tests' if $_ };

my $s = TestSchema->connect( 'dbi:SQLite:t/db/test_database.sqlite3', undef, undef, {} );

plan tests => 6;

subtest 'Test resultset names when table name is singular' => sub {
   plan tests => 7;
   is( [ $s->humans->result_source->columns ], [qw(id name)], 'Plural term returns resultset' );
   is( $s->human(1)->name, 'Ruth Holloway', 'Singular term does a find()' );
   is( $s->human(4),       undef,           'Search for a missing entry returns undef' );
   try {
      $s->human()
   } catch {
      like(
         $_,
         qr/Can't call human without arguments/,
         'Search with missing params fails properly'
      )
   };
   try {
      local $SIG{__WARN__} = sub { die $_[0] };
      $s->human( { name => { '-like' => '%Holloway' } } );
   } catch {
      like(
         $_,
         qr/Query returned more than one row./,
         'Find that returns multiple rows throws warning'
      )
   };
   is( $s->humans->search( { name => { '-like' => '%Holloway' } } )->count(),
      2, 'Search can find multiple entries' );
   is( $s->humans->search( { name => { '-like' => '%Hollowai' } } )->count(),
      0, 'Search can find zero entries' );
};

subtest 'Test resultset names when table name is plural' => sub {
   plan tests => 6;
   is( [ $s->cars->result_source->columns ],
      [qw(id model human)], 'Plural term returns resultset' );
   is( $s->car(1)->model(), 'Corvair', 'Singular term does a find()' );
   try {
      $s->car()
   } catch {
      like(
         $_,
         qr/Can't call car without arguments/,
         'Search with missing params fails properly'
      )
   };
   try {
      local $SIG{__WARN__} = sub { die $_[0] };
      $s->car( { model => { '-like' => '%C%' } } );
   } catch {
      like(
         $_,
         qr/Query returned more than one row./,
         'Find that returns multiple rows throws warning'
      )
   };
   is( $s->cars->search( { model => { '-like' => '%C%' } } )->count(),
      2, 'Search can find multiple entries' );
   is( $s->cars->search( { model => { '-like' => '%Chev%' } } )->count(),
      0, 'Search can find zero entries' );
};

subtest 'Check resultsets when schema name is plural' => sub {
   plan tests => 2;
   is(
      [ $s->boxes->result_source->columns ],
      [qw(id created_at description)],
      'Plural term returns resultset'
   );
   is( $s->box(1)->description, 'Test Box', 'Singluar term correctly returns result' );
};

subtest 'Check relationships going toward a plural term' => sub {
   plan tests => 1;
   is( $s->human(3)->cars->count(), 3, 'singular RS to plural relation works' );
};

subtest 'Check relationships going toward a singular term' => sub {
   plan tests => 1;
   is(
      $s->car(3)->human()->name(),
      'Ruth Holloway',
      'Selecting singular record from singular term works'
   );
};

subtest 'Check to make sure term overrides do what they should.' => sub {
   plan tests => 4;
   is( [ $s->clocks->result_source->columns ],
      [qw(id created_at SKU)], 'Plural term returns resultset' );
   is( $s->block(1)->SKU, 'SKU123', 'Singluar term correctly returns result' );
   like(
      dies { $s->widgets },
      qr/Can't locate object method/,
      'Plural term from original name dies'
   );
      like(
      dies { $s->widget(1)->SKU },
      qr/Can't locate object method/,
      'Singular term from original name dies'
   );
};
