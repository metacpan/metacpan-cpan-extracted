package Devel::DZVii; # initialized by import

BEGIN {
	push @ISA, 'Devel::DebugHooks';
}

sub bbreak {
	my $self =  shift;

	print $self->SUPER::bbreak( @_ );
}


use Devel::DebugHooks();
1;
