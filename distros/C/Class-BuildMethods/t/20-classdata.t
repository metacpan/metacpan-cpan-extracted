#!perl 

use Test::More tests => 11;

use lib 'lib';

{

    package Universe;

    use Class::BuildMethods 
      'age',
      pi => { 
        class_data => 1,
        default    => 3.1415927
      };

    sub new { bless [], shift }

    package Texas;

    @Texas::ISA = 'Universe';

    sub new {
        my $class = shift;
        my $self = bless \qr//, $class;
        return $self;
    }

    package Roman;

    # Note that the story that Romans used the value '3' for PI is probably
    # apocryphal.

    use Class::BuildMethods 
      pi => { 
        class_data => 1,
        default    => 3
      };

    @Roman::ISA = 'Universe';

    sub new {
        my $class = shift;
        my $self = bless \qr//, $class;
        return $self;
    }
}

my $uni1 = Universe->new;
my $uni2 = Universe->new;
$uni1->age(23);
$uni2->age(42);
is $uni1->pi, '3.1415927', 'We should allow defaults for class methods';
cmp_ok $uni1->pi, '==', $uni2->pi, '... and all instances should share it';
cmp_ok $uni1->age, '!=', $uni2->age,
  '... but they should not share instance data';

my $tex = Texas->new;

is $tex->pi, $uni1->pi, 'Classes inheriting class data will share class data';
$uni1->pi(4);
is $tex->pi, $uni1->pi, '... even when the superclass data are changed';
$tex->pi(5);
is $tex->pi, $uni1->pi, '... or the subclass data are changed';

my $roman = Roman->new;
cmp_ok $roman->pi, '!=', $uni1->pi,
  'Class implementing their own class data should not inherit it';
$uni1->pi(2);
cmp_ok $roman->pi, '!=', $uni1->pi,
  '... even when the superclass data are changed';
$roman->pi('cherry');
cmp_ok $roman->pi, 'ne', $uni1->pi, '... or the subclass data are changed';

Class::BuildMethods->reset('Universe');
cmp_ok $uni1->pi, '==', 3.1415927,
  'Resetting class values should succeed';
cmp_ok $tex->pi, '==', 3.1415927,
  '... even for the subclasses';
