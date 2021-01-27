use Test::More tests => 15;
use Art::World;
use Faker;

my $f = Faker->new;

use_ok 'Art::World::Agent';
my $agent = Art::World->new_agent( name => $f->person_name );
can_ok $agent, qw/participate networking/;

my $artist_1 = Art::World->new_artist(
  id => 1, reputation => 0, name => $f->person_first_name . ' ' . $f->person_last_name );
my $artist_2 = Art::World->new_artist(
  id => 2, reputation => 0, name => $f->person_first_name . ' ' . $f->person_last_name );
my $curator_1 = Art::World->new_curator(
  id => 3, reputation => 100, name => $f->person_first_name . ' ' . $f->person_last_name );

my $peoples = [ $artist_1, $artist_2, $curator_1 ];

can_ok $curator_1, 'networking';

is $curator_1->reputation, 100, 'Initial Curator reputation';
is $artist_1->reputation, 0,  'Initial Artist reputation';
is $artist_2->reputation, 0,  'Another initial Artist reputation';

$curator_1->networking( $peoples );

is $curator_1->reputation, 110, 'Curator reputation increased';
is $artist_1->reputation, 60, 'Artist reputation increased';
is $artist_2->reputation, 60, 'Artist reputation increased';

$curator_1->bump_fame(-101);

is $curator_1->reputation, 9, 'Basic calculation on the fame';

$curator_1->networking( $peoples );

is $curator_1->reputation, 15, 'Curator reputation increased';
is $artist_1->reputation, 396, 'Artist reputation increased';
is $artist_2->reputation, 396, 'Artist reputation increased';

$curator_1->bump_fame;

is $curator_1->reputation, 16, 'Default bump';

# does-ok $agent, Art::Behavior::Crudable;

SKIP: {
  skip 'Not implemented CRUD', 1;

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
  ok 1;
}
done_testing;
