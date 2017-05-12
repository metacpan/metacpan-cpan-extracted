#!perl -T

use Test::More;
use Test::Fatal qw/dies_ok lives_ok/;
# use File::Temp;
use DBI;
use DBD::SQLite;

use lib 't/lib';

use My::Schema;
use My::Model;

## Connect to a DB and dynamically build the DBIC model.
ok( my $dbh = DBI->connect("dbi:SQLite::memory:" , "" , "") , "Ok connected as a DBI");
ok( $dbh->{AutoCommit} = 1 , "Ok autocommit set");
ok( $dbh->do("PRAGMA foreign_keys = ON") , "Ok set foreign keys");
ok( $dbh->do('CREATE TABLE builder(id INTEGER PRIMARY KEY AUTOINCREMENT, bname VARCHAR(255) UNIQUE NOT NULL)') , "Ok creating builder table");
ok( $dbh->do('CREATE TABLE product(id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(255), active BOOLEAN DEFAULT FALSE, colour VARCHAR(10) NOT NULL DEFAULT \'blue\', builder_id INTEGER,FOREIGN KEY (builder_id) REFERENCES builder(id))') , "Ok creating product table");

## Build a schema dynamically.
ok( my $schema = My::Schema->connect(sub{ return $dbh ;} , { unsafe => 1 } ), "Ok built schema with dbh");
## Just to check
ok( $schema->resultset('Builder') , "Builder resultset is there");
ok( $schema->resultset('Product') , "Product resultset is there");


## Build a My::Model using it
ok( my $bm = My::Model->new({ dbic_schema => $schema }) , "Ok built a model");

## And test a few stuff.
ok( my $pf = $bm->dbic_factory('Product') , "Ok got product factory");

isa_ok( $pf , 'My::Model::Wrapper::Factory::Product');

ok( my $name_col = $bm->dbic_factory('Product')->get_column('name') , "Ok got a name column");
ok( my $pf2 = $bm->dbic_factory('ActiveProduct') , "Ok got another product factory");
ok( my $pf3 = $bm->dbic_factory('Product' , { dbic_rs => $bm->dbic_schema->resultset('Product')->search_rs({ active => 1})}), "Can build a general product on a specific Rs");
ok( my $bf = $bm->dbic_factory('Builder') , "Ok got builder factory");

## Object creation.
ok( my $in_memory = $bf->new_result({ bname => 'BuilderMemory' }) , "Ok can create an object just in memory");
ok( ! $in_memory->in_storage() , "Created object is not in storage");

ok( my $b = $bf->create( { bname => 'Builder1' }) , "Ok built the first builder");
ok( my $ob = $bf->find_or_create( { bname => 'Builder1' }) , "Ok found or create builder");
ok( my $first = $bf->first() , "Ok can find first builder");
ok( my $first_via_single = $bf->single(), "Ok can get first builder via single()" );
cmp_ok( $b->id() , '==' , $ob->id() , "Both builders are the same");
cmp_ok( $first->id(), '==', $first_via_single->id(), 'first() and single() get same object' );
## Object loopback
ok( $b = $bf->find($b->id()) , "Ok found it by id");
cmp_ok( $b->bname , 'eq' , 'Builder1' , "Good data");

{
  ok( my $other_builder = $bf->find_or_create( { bname => 'Something never heard of' } ) , "Ok could create a new one");
}

## Now a product
ok( my $p = $pf->create( { name => 'Hoover' , builder => $b }) , "Ok could make a product");
ok( $p->id() , "Hoover product has got an ID");
ok( $p->turn_on() , "Can be turned on as well");


## Another product. This one is active
## Note that it's created via the ActiveProduct resultset.
ok( my $ap = $pf2->create({ name => 'Kettle' , builder => $b , active => 1  }) , "Ok made an active product");
ok( ! $pf2->find($p->id()), "We cannot find the first product because it's not active");
ok( ! $pf3->find($p->id()), "Same thing for pf3, because it's built on a ad-hoc resultset");
ok( $pf2->find($ap->id()), "We can find the second product because it's active");

## Now some searching.
ok( my $search_rs = $pf->search_rs(undef , { page => 1 }) , "Ok got a resultset");


isa_ok( $search_rs , 'My::Model::Wrapper::Factory::Product' , "And its a Product factory");

is( $search_rs->pager()->total_entries() , 2 , "Can access total entries via pager");
cmp_ok( $search_rs->count() , '==' , 2 ,  "Got two products");
my $seen_p = 0;
while( my $next_p = $search_rs->next() ){
    $seen_p++;
    isa_ok( $next_p , 'My::Model::O::Product' , "Ok next is a product");
}
cmp_ok( $seen_p , '==' , 2 , "Seen two products thanks to next");

## Same thing on the active only products.
ok( my $act_search = $pf2->search() , "Ok got active product search");
isa_ok( $act_search , 'My::Model::Wrapper::Factory::Product' , "And its a Product factory");
cmp_ok( $act_search->count() , '==' , 1 ,  "Got one product");
$seen_p = 0;
while( my $next_p = $act_search->next() ){
    $seen_p++;
    isa_ok( $next_p , 'My::Model::O::Product' , "Ok next is a product");
}
cmp_ok( $seen_p , '==' , 1 , "Seen one product thanks to next");

$p->activate();
cmp_ok( $pf2->search()->count() , '==' , 2 , "Now two products in the active resultset");
cmp_ok( $pf3->search()->count() , '==' , 2 , "Same thing for pf3 (ad-hoc result set");

cmp_ok( scalar( $pf2->all() ) , '==' , 2 , "Two products via all");

## Now some colour testing
{
    ok( my $cr = $bm->dbic_factory('ColouredProduct') , "Ok coloured product resultset");
    cmp_ok( $cr->count() , '==' , 0 , "No coloured in green product found");
    $bm->colour('blue');
    cmp_ok( $bm->dbic_factory('ColouredProduct')->count() , '==' , 2 , 'Now two coloured product');
}

## Try deleting all the coloured products.
$bm->dbic_factory('ColouredProduct')->delete();
cmp_ok( $bm->dbic_factory('ColouredProduct')->count() , '==' , 0 , 'No coloured products anymore.');


## Test a non existing factory
{
  dies_ok { $bm->dbic_factory('BoudinBlanc') } "No boudin blanc factory";
}

{
  # Test inserting more stuff in builders.
  for( my $i = 1 ; $i < 100 ; $i++ ){
    $bf->create( { bname => 'pageBuilder_'.$i });
  }

  my $target_total = $bf->search(undef, { order_by => 'me.id'} )->count();
  my $real_total = 0;
  $bf->search(undef , { order_by => 'me.id' })->loop_through(sub{ my $o = shift;
                                                                  isa_ok( $o , 'My::Schema::Result::Builder');
                                                                  $real_total++;
                                                                });
  is( $real_total , $target_total , "Ok totals are the same");

  # Now try with a limit.
  my $limit = $target_total - 1;
  $real_total = 0;
  $bf->search(undef , { order_by => 'me.id' })->loop_through(sub{ my $o = shift;
                                                                  $real_total++;
                                                                } , { limit => $limit });
  is( $real_total , $limit , "Ok didnt go further than limit");
}

subtest 'find_or_new' => sub {
    plan tests => 4;
    ok( my $result = $bf->find_or_new( { bname => 'FindOrNew' } ), 'A result is always returned' );
    is( $result->in_storage(), 0, 'We have a result object which is not in storage' );
    $result->insert();
    ok( my $result2 = $bf->find_or_new( { bname => 'FindOrNew' } ), 'Found ( or new ) the result again' );
    is( $result2->in_storage(), 1, 'The result is in storage this time' );
};


done_testing();
