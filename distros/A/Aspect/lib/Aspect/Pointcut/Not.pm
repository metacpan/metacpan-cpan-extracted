package Aspect::Pointcut::Not;

use strict;
use Aspect::Pointcut::Logic ();

our $VERSION = '1.04';
our @ISA     = 'Aspect::Pointcut::Logic';





######################################################################
# Constructor

sub new {
	my $class = shift;

	# Check the thing we are negating
	unless ( Params::Util::_INSTANCE($_[0], 'Aspect::Pointcut') ) {
		Carp::croak("Attempted to apply pointcut logic to non-pointcut '$_[0]'");
	}

	$class->SUPER::new(@_);
}





######################################################################
# Weaving Methods

sub compile_weave {
	my $child = $_[0]->[0]->compile_weave;
	if ( ref $child ) {
		return sub { not $child->() };
	}
	unless ( $child eq '1' ) {
		return "not ( $child )";
	}

	# When the child matches everything, the negation doesn't negate
	# the set of things matched. So we match everything too.
	return 1;
}

sub compile_runtime {
	my $child = $_[0]->[0]->compile_runtime;
	if ( ref $child ) {
		return sub { not $child->() };
	} else {
		return "not ( $child )";
	}
}

sub match_contains {
	my $self  = shift;
	my $count = $self->[0]->match_contains($_[0]);
	return $self->isa($_[0]) ? ++$count : $count;
}

sub match_runtime {
	$_[0]->[0]->match_runtime;
}

# Logical not inherits it's curryability from the element contained
# within it. We continue to be needed if and only if something below us
# continues to be needed as well.
sub curry_weave {
	my $self = shift;
	my $child = $self->[0]->curry_weave or return;

	# Handle the special case where the collapsing pointcut results
	# in a "double not". Fetch the child of our child not and return
	# it directly.
	if ( $child->isa('Aspect::Pointcut::Not') ) {
		return $child->[0];
	}

	# Return our clone with the curried child
	my $class = ref($self);
	return $class->new( $child );
}

# Logical not inherits it's curryability from the element contained
# within it. We continue to be needed if and only if something below us
# continues to be needed as well.
# For cleanliness (and to avoid accidents) we make a copy of ourself
# in case our child curries to something other than it's pure self.
sub curry_runtime {
	my $self  = shift;
	my $child = $self->[0]->curry_runtime or return;

	# Handle the special case where the collapsing pointcut results
	# in a "double not". Fetch the child of our child not and return
	# it directly.
	if ( $child->isa('Aspect::Pointcut::Not') ) {
		return $child->[0];
	}

	# Return our clone with the curried child
	my $class = ref($self);
	return $class->new( $child );
}

1;

__END__

=pod

=head1 NAME

Aspect::Pointcut::Not - Logical 'not' pointcut

=head1 SYNOPSIS

  use Aspect;
  
  # High-level creation
  my $pointcut1 = ! call 'one';
  
  # Manual creation
  my $pointcut2 = Aspect::Pointcut::Not->new(
      Aspect::Pointcut::Call->new('one')
  );

=head1 DESCRIPTION

B<Aspect::Pointcut::Not> is a logical condition, which is used
to create higher-order conditions from smaller parts.

It takes two or more conditions, and applies appropriate logic during the
various calculations that produces a logical set-wise 'and' result.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Marcel GrE<uuml>nauer E<lt>marcel@cpan.orgE<gt>

Ran Eilam E<lt>eilara@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2001 by Marcel GrE<uuml>nauer

Some parts copyright 2009 - 2013 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
