package My::Role::Thing;
use Moose::Role;


sub doThing {
	my ($self) = @_;
	return 'done';
}

1;

