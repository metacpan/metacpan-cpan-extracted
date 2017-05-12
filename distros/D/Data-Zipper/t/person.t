use warnings FATAL => 'all';
use strict;
use Test::More;

use Data::Zipper::MOP;

{
    package Person;
    use Moose;

    has name => ( is => 'ro' );
}

{
    package Container;
    use Moose;

    has person => ( is => 'ro' );
}

my $john = Person->new( name => 'John' );
my $sally = Data::Zipper::MOP->new( focus => $john )
    ->traverse('name')
      ->set('Sally')
    ->zip;

isa_ok($sally => 'Person');
is($sally->name => 'Sally');

my $container = Container->new( person => Person->new( name => 'Ollie' ));
my $new_container = Data::Zipper::MOP->new( focus => $container )
    ->traverse('person')
      ->traverse('name')
        ->set('STEEEEVE')
      ->up
    ->zip;

isa_ok($new_container, 'Container');
isa_ok($new_container->person, 'Person');
is($new_container->person->name, 'STEEEEVE');

done_testing;
