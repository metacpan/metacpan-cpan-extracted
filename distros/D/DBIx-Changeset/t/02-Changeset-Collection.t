#!perl -T

use Test::More qw(no_plan); #tests => 1;
use Test::Exception;

use lib qw( ./t/lib );

BEGIN {
	use_ok( 'DBIx::Changeset::Collection' );
}

diag( "Testing DBIx::Changeset::Collection $DBIx::Changeset::Collection::VERSION, Perl $], $^X" );

my @registered_classes = DBIx::Changeset::Collection->get_registered_classes;
is( scalar @registered_classes, 1, 'Number of classes registered so far' );
is( $registered_classes[0], 'DBIx::Changeset::Collection::Disk', 'Default class registered' );

my @registered_types = DBIx::Changeset::Collection->get_registered_types;
is( scalar @registered_types, 1, 'Number of types registered so far' );
is( $registered_types[0], 'disk', 'Default type registered' );

### add a simple test factory so we can test the DBIx::Changeset::Record base func
DBIx::Changeset::Collection->add_factory_type( 'test' => FactoryCollectionTest );

### make sure we get an object create exception if we create with an undefined changeset_location
throws_ok(sub { DBIx::Changeset::Collection->new('test') }, 'DBIx::Changeset::Exception::ObjectCreateException', 'Cant create without changeset_location');
throws_ok(sub { DBIx::Changeset::Collection->new('test') }, qr/changeset_location/, 'correct error message from exception');

my $coll = DBIx::Changeset::Collection->new('test', {changeset_location => './t/data' });
isa_ok($coll, 'DBIx::Changeset::Collection');
can_ok($coll, qw(
				files				retrieve_all	retrieve 
				retrieve_like		next			next_outstanding 
				next_valid 			next_skipped	total 
				total_outstanding	total_valid		total_skipped 
				reset				current_index	add_changeset
				));

$coll->retrieve_all();

### is files an array of records
isa_ok($coll->files->[0], 'DBIx::Changeset::Record', 'got an array of DBIx::Changeset::Records');

### test total
my $total = $coll->total;
is($total,4,'Correct total');

### test next
my $next = $coll->next();
isa_ok($next, 'DBIx::Changeset::Record', 'Next returns a DBIx::Changeset::Record');

### test next_outstanding
my $next_out = $coll->next_outstanding();
isa_ok($next_out, 'DBIx::Changeset::Record', 'Next Outstanding returns a DBIx::Changeset::Record');
is($next_out->outstanding, 1, 'Next Outstanding returns an outstanding file');

### test next_valid
my $next_vld = $coll->next_valid();
isa_ok($next_vld, 'DBIx::Changeset::Record', 'Next Valid returns a DBIx::Changeset::Record');
is($next_vld->valid, 1, 'Next Valid returns a valid file');

### test next_skipped
my $next_skp = $coll->next_skipped();
isa_ok($next_skp, 'DBIx::Changeset::Record', 'Next Skipped returns a DBIx::Changeset::Record');
is($next_skp->skipped, 1, 'Next Skipped returns a skipped file');

### test total outstanding
is($coll->total_outstanding,1,'Correct outstanding total');

### test total valid
is($coll->total_valid,4,'Correct valid total');

### test total skipped
is($coll->total_skipped,1,'Correct skipped total');

### test reset goes back to begining
$coll->reset();
is($coll->current_index, undef, 'reset goes back to begining');

### test adding a changeset
$coll->add_changeset('5.sql');
is($coll->total,5,'Correct total after add');
is($coll->files->[4]->uri(),'5.sql','File name correct and added in correct place');

