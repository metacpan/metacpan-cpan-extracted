package Aspect::Pointcut::Throwing;

use strict;
use Carp                        ();
use Params::Util                ();
use Aspect::Pointcut            ();
use Aspect::Pointcut::Not       ();
use Aspect::Pointcut::Returning ();

our $VERSION = '1.04';
our @ISA     = 'Aspect::Pointcut';





######################################################################
# Constructor

sub new {
	my $class = shift;
	my $spec  = shift;

	# Handle the any exception case
	unless ( defined $spec ) {
		return bless [
			$spec,
			'$Aspect::POINT->{exception}',
		], $class;
	}

	# Handle a specific die message
	if ( Params::Util::_STRING($spec) ) {
		return bless [
			$spec,
			"Params::Util::_INSTANCE(\$Aspect::POINT->{exception}, '$spec')",
		], $class;
	}

	# Handle a specific exception class
	if ( Params::Util::_REGEX($spec) ) {
		my $regex = "/$spec/";
		$regex =~ s|^/\(\?([xism]*)-[xism]*:(.*)\)/\z|/$2/$1|s;
		return bless [
			$spec,
			"defined \$Aspect::POINT->{exception} and not ref \$Aspect::POINT->{exception} and \$Aspect::POINT->{exception} =~ $regex",
		], $class;
	}

	Carp::croak("Invalid throwing pointcut specification");
}





######################################################################
# Weaving Methods

# Exception pointcuts always match at weave time and should curry away
sub curry_weave {
	return;
}

# Throwing pointcuts do not curry.
# (But maybe they should, when used with say a before {} block)
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

Aspect::Pointcut::Throwing - Exception typing pointcut

  use Aspect;
  
  # Catch a Foo::Exception object exception
  after {
      $_->return_value(1)
  } throwing 'Foo::Exception';
  
=head1 DESCRIPTION

The B<Aspect::Pointcut::Throwing> pointcut is used to match situations
in which an after() advice block wishes to intercept the throwing of a specific
exception string or object.

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
