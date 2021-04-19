use Test::More;
use Art::World;
use Art::World::Util;
use Config::Tiny;
use List::Util 'shuffle';
use Path::Tiny;
use feature qw( postderef signatures );
no warnings qw( experimental::postderef experimental::signatures );

# Note that it is extremely important that the testing of the database should be
# done in the C<t/crud.t> file. If you want to test database or model
# functionnalities in other tests, remind to create objects by specifiying the
# config parameter that use the C<test.conf> file: only the database referenced in
# C<test.conf> will be available on cpantesters and C<art.db> wont be available there,
# only C<t/test.db> is available.

my $file_path = path( 't/test.db' );
ok $file_path->exists, 'DB file exist';
ok -B $file_path->stringify, 'DB file seems to be binary (SQLite)';

my $playground = Art::World->new_playground(
  config => Config::Tiny->read( './t/test.conf' ),
  name => 'A testing playground');

ok $playground->does('Art::World::Crud'), 'Our instance does Crud';
can_ok $playground, 'insert';
can_ok $playground, '_build_dbh';
can_ok $playground, '_build_db';

###
### TODO Could easily be transformed to a mass Agents creation utility in Art::World::Util::Person
my $artists = [];
my $artists_container = {};

for my $it ( 1..100 ) {
  $artists_container->{ 'artist_' . $it } = Art::World->new_artist(
    config => Config::Tiny->read( './t/test.conf' ),
    name => Art::World::Util->new_person->fake_name,
    id => $it,
    reputation => Art::World::Util->new_math->pick( 10, 1000 ));
  push $artists->@*, $artists_container->{ 'artist_' . $it };
}
###

# Here, we will empty the database
$playground->dbh->delete( 'agent', {} );
$playground->does( 'Art::World::Crud' );

for my $artist ( $artists->@* ) {
  my $insert = $playground
    ->insert(
      'agent',
      {  name => $artist->name,  reputation => $artist->reputation });
  ok $insert,  'Inserted in DB';
}

my @rows = $playground->dbh->search( 'Agent', {}, {});

my $amount = scalar $artists->@*;
is scalar @rows, $amount, 'We retrieved '. $amount .' artists';

# Test availability of DB tables
ok $playground->dbh->schema->get_table('Agent'), 'Can retrieve the Agent table';
ok $playground->dbh->schema->get_table('Event'), 'Can retrieve the Event table';


# for @artists -> $artist {
#     does-ok $artist, Art::Behavior::Crudable;
#     isa-ok $artist.database, "MongoDB::Database";
#     ok $artist.type-for-document eq 'artist', "split get-type() test";
#     $plan += 3;
# }

# does-ok $agent, Art::Behavior::CRUD;

# for Art::Agent.^attributes {
#     if $_ ~~ Art::Behavior::CRUD {
#         ok $_ ~~ Art::Behavior::CRUD,
#         'Attribute does CRUD through is crud trait';
#     }
# }

# $agent = Art::Agent.new(
#     id => 123456789,
#     name => "Camelia Butterfly",
#     reputation => 10
# );

# my @attributes = Art::Agent.^attributes;

# ok @attributes[1] ~~ Art::Behavior::CRUD, 'attribute does CRUD through is crud trait';
# ok $agent.name eq "Camelia Butterfly", 'Agent name contain the right value';

# my @found;

# for @attributes -> $attr {
#     if $attr ~~ Art::Behavior::CRUD {
#         @found.push($attr);
#     }
# }

# ok @found.Int == 3,
# 'The found number of attributes in the class is correct';

# ok $agent.introspect-crud-attributes == @found,
# '.introspect-crud-attributes returns the right number of elements';

# ddt $agent.introspect-crud-attributes;

$playground->dbh->delete( 'agent', {} );

done_testing;
