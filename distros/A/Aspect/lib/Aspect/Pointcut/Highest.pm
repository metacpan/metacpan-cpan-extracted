package Aspect::Pointcut::Highest;

use strict;
use Carp                               ();
use Scalar::Util                       ();
use Params::Util                       ();
use Aspect::Guard                      ();
use Aspect::Pointcut                   ();

our $VERSION = '1.04';
our @ISA     = 'Aspect::Pointcut';





######################################################################
# Constructor Methods

sub new {
	bless [ ], $_[0];
}





######################################################################
# Weaving Methods

# The highest pointcut is a run-time only pointcut
sub curry_weave {
	return;
}

# Call pointcuts curry away to null, because they are the basis
# for which methods to hook in the first place. Any method called
# at run-time has already been checked.
sub curry_runtime {
	bless [ 0 ], $_[0];
}





######################################################################
# Runtime Methods

sub compile_runtime {
	my $depth = 0;
	return sub {
		$_->{highest} = Aspect::Guard->new( sub { $depth-- } );
		return ! $depth++;
	};
}

1;

__END__

=pod

=head1 NAME

Aspect::Pointcut::Highest - Pointcut for preventing recursive matching

=head1 SYNOPSIS

  use Aspect;
  
  # High-level creation
  my $pointcut1 = highest;
  
  # Manual creation
  my $pointcut2 = Aspect::Pointcut::Highest->new;

=head1 DESCRIPTION

For aspects including timers and other L<Aspect::Advice::Around|around>-based
advice, recursion can be significant problem.

The C<highest> pointcut solves this problem by matching only on the highest
invocation of a function. If the function is called again recursively within
the first call, at any depth, the deeper calls will be not match and the
advice will not be executed.

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
