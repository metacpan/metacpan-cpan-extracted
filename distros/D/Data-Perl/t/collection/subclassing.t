use strict;
use warnings;
use Test::More;

use Data::Perl;

BEGIN {
  package Local::Array;
  use parent 'Data::Perl::Collection::Array';
  sub monkey_around {
    my $self = shift;
    ref($self)->new(map "Bonobo", @$self);
  }
};

BEGIN {
  package Local::Hash;
  use parent 'Data::Perl::Collection::Hash';
  use constant _array_class => "Local::Array";
};

my $hash = Local::Hash->new(a => 1, b => 2);

isa_ok(
  $hash->keys,
  'Data::Perl::Collection::Array',
  'hash keys are an array',
);

isa_ok(
  $hash->keys,
  'Local::Array',
  'hash keys are our subclass of array',
);

can_ok(
  $hash->keys,
  'monkey_around',
);

is_deeply(
  $hash->keys->monkey_around,
  Local::Array->new(qw/ Bonobo Bonobo /),
  'our custom method works',
);

done_testing;
