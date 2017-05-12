package A::Schema::Candy;

use base 'DBIx::Class::Candy';

sub base { 'A::Schema::Result' }

1;
