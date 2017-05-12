package Aspect::Pointcut::Wantarray;

use strict;
use Carp             ();
use Aspect::Pointcut ();

our $VERSION = '1.04';
our @ISA     = 'Aspect::Pointcut';

use constant VOID   => 1;
use constant SCALAR => 2;
use constant LIST   => 3;





######################################################################
# Constructor Methods

sub new {
	return bless [
		LIST,
		'$Aspect::POINT->{wantarray}',
	], $_[0] if $_[1];

	return bless [
		SCALAR,
		'defined $Aspect::POINT->{wantarray} and not $Aspect::POINT->{wantarray}',
	], $_[0] if defined $_[1];

	return bless [
		VOID,
		'not defined $Aspect::POINT->{wantarray}',
	], $_[0];
}





######################################################################
# Weaving Methods

# This is a run-time only pointcut of no value at weave time
sub curry_weave {
	return;
}

# For wantarray pointcuts we keep the original
sub curry_runtime {
	return $_[0];
}

sub compile_runtime {
	$_[0]->[1];
}





######################################################################
# Optional XS Acceleration

BEGIN {
	local $@;
	eval <<'END_PERL';
use Class::XSAccessor::Array 1.08 {
	replace => 1,
	getters => {
		'compile_runtime' => 1,
	},
};
END_PERL
}

1;

__END__

=pod

=head1 NAME

Aspect::Pointcut::Wantarray - A pointcut for the run-time wantarray context

=head1 SYNOPSIS

  use Aspect;
  
  # High-level creation
  my $pointcut1 = wantlist | wantscalar | wantvoid;
  
  # Manual creation
  my $pointcut2 = Padre::Pointcut::Or->new(
    Padre::Pointcut::Wantarray->new( 1 ),     # List
    Padre::Pointcut::Wantarray->new( 0 ),     # Scalar
    Padre::Pointcut::Wantarray->new( undef ), # Void
  );

=head1 DESCRIPTION

The C<Aspect::Pointcut::Wantarray> pointcut allows the creation of
aspects that only trap calls made in a particular calling context
(list, scalar or void).

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2001 by Marcel GrE<uuml>nauer

Some parts copyright 2009 - 2013 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
