use strict;

use Params::Validate qw(:types);
my $SCALAR = SCALAR;   # So we don't have to keep importing it below

# Create some boilerplate classes
{
  no strict 'refs';
  foreach my $class (qw(Parent Boy Toy Daughter)) {
    push @{$class.'::ISA'}, 'Class::Container';
  }
}

# Define the relationships
{
  package Parent;
  push @Parent::ISA, 'Foo';  # Make sure it works with non-container superclasses
  # Has one son and several daughters
  __PACKAGE__->valid_params( parent_val => { type => $SCALAR },
			     son => {isa => 'Son'},
			   );
  __PACKAGE__->contained_objects( son => 'Son',
				  daughter => {delayed => 1,
					       class => 'Daughter'});
}

{
  package Boy;
  __PACKAGE__->valid_params( eyes => { default => 'brown', type => $SCALAR },
			     toy => {isa => 'Toy'});
  __PACKAGE__->contained_objects( toy => 'Slingshot',
				  other_toys => {class => 'Toy', delayed => 1},
				);
}

{
  package Son;
  push @Son::ISA, 'Boy';
  __PACKAGE__->valid_params( mood => { type => $SCALAR } );
}

{
  package Slingshot;
  push @Slingshot::ISA, 'Toy';
  __PACKAGE__->valid_params( weapon => { default => 'rock', type => $SCALAR } );
}

{
  package Daughter;
  __PACKAGE__->valid_params( hair => { default => 'short' } );
}

{
  package StepDaughter;
  push @StepDaughter::ISA, 'Daughter';
  __PACKAGE__->valid_params( toy => {isa => 'Toy'} );
  __PACKAGE__->contained_objects( toy => { class => 'Toy'},
				  other_toys => {class => 'Toy', delayed => 1},
				);
}
{
  push @StepSon::ISA, 'Son';
  push @Ball::ISA, 'Toy';
  push @Streamer::ISA, 'Toy';
}

1;
