package Aspect::Pointcut::And;

use strict;
use Aspect::Pointcut::Logic ();

our $VERSION = '1.04';
our @ISA     = 'Aspect::Pointcut::Logic';





######################################################################
# Constructor

sub new {
	my $class = shift;
	my @parts = @_;

	# Validate the pointcut subexpressions
	foreach my $part ( @parts ) {
		next if Params::Util::_INSTANCE($part, 'Aspect::Pointcut');
		Carp::croak("Attempted to apply pointcut logic to non-pointcut '$part'");
	}

	# Collapse nested and statements at constructor time so we don't have
	# to do so multiple times later on during currying.
	while ( scalar grep { $_->isa('Aspect::Pointcut::And') } @parts ) {
		@parts = map {
			$_->isa('Aspect::Pointcut::And') ? @$_ : $_
		} @parts;
	}

	$class->SUPER::new(@parts);
}





######################################################################
# Weaving Methods

sub compile_weave {
	my $self = shift;

	# Handle special cases
	my @children = grep {
		ref $_ or $_ ne 1
	} map {
		$_->compile_weave
	} @$self;
	unless ( @children ) {
		# Potential bug, but why would we legitimately be empty
		return 1;
	}
	if ( @children == 1 ) {
		return $children[0];
	}

	# Collapse string conditions together,
	# and further collapse code conditions together.
	my @string = ();
	my @code   = ();
	foreach my $child ( @children ) {
		unless ( ref $child ) {
			push @string, $child;
			next;
		}
		if ( @string ) {
			my $group = join ' and ', map { "( $_ )" } @string;
			push @code, eval "sub () { $group }";
			@string = ();
		}
		push @code, $child;
	}

	if ( @string ) {
		my $group = join ' and ', map { "( $_ )" } @string;
		unless ( @code ) {
			# This is the only thing we have
			return $group;
		}
		push @code, eval "sub () { $group }";
	}

	# Join the groups
	return sub {
		foreach my $child ( @code ) {
			return 0 unless $child->();
		}
		return 1;
	};
}

sub compile_runtime {
	my $self = shift;

	# Handle special cases
	my @children = grep {
		ref $_ or $_ ne 1
	} map {
		$_->compile_runtime
	} @$self;
	unless ( @children ) {
		# Potential bug, but why would we legitimately be empty
		return 1;
	}
	if ( @children == 1 ) {
		return $children[0];
	}

	# Collapse string conditions together,
	# and further collapse code conditions together.
	my @string = ();
	my @code   = ();
	foreach my $child ( @children ) {
		unless ( ref $child ) {
			push @string, $child;
			next;
		}
		if ( @string ) {
			my $group = join ' and ', map { "( $_ )" } @string;
			push @code, eval "sub () { $group }";
			@string = ();
		}
		push @code, $child;
	}

	if ( @string ) {
		my $group = join ' and ', map { "( $_ )" } @string;
		unless ( @code ) {
			# This is the only thing we have
			return $group;
		}
		push @code, eval "sub () { $group }";
	}

	# Join the groups
	return sub {
		foreach my $child ( @code ) {
			return 0 unless $child->();
		}
		return 1;
	};
}

sub match_contains {
	my $self  = shift;
	my $type  = shift;
	my $count = $self->isa($type) ? 1 : 0;
	foreach my $child ( @$self ) {
		$count += $child->match_contains($type);
	}
	return $count;
}

sub match_runtime {
	my $self = shift;
	foreach my $child ( @$self ) {
		return 1 if $child->match_runtime;
	}
	return 0;
}

sub curry_weave {
	my $self = shift;
	my @list = @$self;

	# Curry down our children. Anything that is not relevant at weave
	# time is considered to always match, but curries to null.
	# In an AND scenario, any "always" match can be savely removed.
	@list = grep { defined $_ } map { $_->curry_weave } @list;

	# If none are left, curry us away to nothing
	return unless @list;

	# If only one remains, curry us away to just that child
	return $list[0] if @list == 1;

	# Create our clone to hold the curried subset
	return ref($self)->new( @list );
}

sub curry_runtime {
	my $self = shift;
	my @list = @$self;

	# Should we strip out the call pointcuts
	my $strip = shift;
	unless ( defined $strip ) {
		# Are there any elements that MUST exist at run-time?
		if ( $self->match_runtime ) {
			# If we have any nested logic that themselves contain
			# call pointcuts, we can't strip.
			$strip = not scalar grep {
				$_->isa('Aspect::Pointcut::Logic')
				and
				$_->match_contains('Aspect::Pointcut::Call')
			} @list;
		} else {
			# Nothing at runtime, so we can strip
			$strip = 1;
		}
	}

	# Curry down our children
	@list = grep { defined $_ } map {
		$_->isa('Aspect::Pointcut::Call')
		? $strip
			? $_->curry_runtime($strip)
			: $_
		: $_->curry_runtime($strip)
	} @list;

	# If none are left, curry us away to nothing
	return unless @list;

	# If only one remains, curry us away to just that child
	return $list[0] if @list == 1;

	# Create our clone to hold the curried subset
	return ref($self)->new( @list );
}

1;

__END__

=pod

=head1 NAME

Aspect::Pointcut::And - Logical 'and' pointcut

=head1 SYNOPSIS

  use Aspect;
  
  # High-level creation
  my $pointcut1 = call 'one' & call 'two' & call 'three';
  
  # Manual creation
  my $pointcut2 = Aspect::Pointcut::And->new(
      Aspect::Pointcut::Call->new('one'),
      Aspect::Pointcut::Call->new('two'),
      Aspect::Pointcut::Call->new('three'),
  );

=head1 DESCRIPTION

B<Aspect::Pointcut::And> is a logical condition, which is used
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
