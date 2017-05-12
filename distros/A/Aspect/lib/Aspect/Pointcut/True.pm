package Aspect::Pointcut::True;

use strict;
use Aspect::Pointcut ();

our $VERSION = '1.04';
our @ISA     = 'Aspect::Pointcut';





######################################################################
# Weaving Methods

# The true pointcut is a run-time only pointcut
sub curry_weave {
	return;
}

# The true pointcut contains no state and doesn't need to be curried.
# Simply return it as-is and reuse it everywhere.
sub curry_runtime {
	return $_[0];
}





######################################################################
# Runtime Methods

sub compile_runtime {
	$_[0]->[0];
}





######################################################################
# Optional XS Acceleration

BEGIN {
	local $@;
	eval <<'END_PERL';
use Class::XSAccessor::Array 1.08 {
	replace => 1,
	getters => {
		'compile_runtime' => 0,
	},
};
END_PERL
}

1;

__END__

=pod

=head1 NAME

Aspect::Pointcut::True - Pointcut that allows arbitrary Perl code

=head1 SYNOPSIS

  use Aspect;
  
  # High-level creation
  my $pointcut1 = true { rand() > 0.5 };
  
  # Manual creation
  my $pointcut2 = Aspect::Pointcut::True->new(
    sub { rand() > 0.5 }
  );

=head1 DESCRIPTION

Because L<Aspect>'s weaving phase technically occurs at run-time (relative
to the overall process) it does not need to be limit itself only to 
conditions that are fully describable at compile-time.

B<Aspect::Pointcut::True> allows you to take advantage of this to create your
own custom run-time pointcut conditions, although for safety and purity
reasons you are not permitted to create custom conditions that interact
with the L<Aspect::Point> object for the call.

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
