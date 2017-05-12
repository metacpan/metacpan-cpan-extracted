package Aspect::Advice::Around;

use strict;

# Added by eilara as hack around caller() core dump
# NOTE: Now we've switched to Sub::Uplevel can this be removed? --ADAMK
use Carp::Heavy    (); 
use Carp           ();
use Sub::Uplevel   ();
use Aspect::Hook   ();
use Aspect::Advice ();
use Aspect::Point  ();

our $VERSION = '1.04';
our @ISA     = 'Aspect::Advice';

sub _install {
	my $self     = shift;
	my $pointcut = $self->pointcut;
	my $code     = $self->code;
	my $lexical  = $self->lexical;

	# Get the curried version of the pointcut we will use for the
	# runtime checks instead of the original.
	# Because $MATCH_RUN is used in boolean conditionals, if there
	# is nothing to do the compiler will optimise away the code entirely.
	my $curried   = $pointcut->curry_runtime;
	my $compiled  = $curried ? $curried->compiled_runtime : undef;
	my $MATCH_RUN = $compiled ? 'do { local $_ = $Aspect::POINT; $compiled->() }' : 1;

	# When an aspect falls out of scope, we don't attempt to remove
	# the generated hook code, because it might (for reasons potentially
	# outside our control) have been recursively hooked several times
	# by both Aspect and other modules.
	# Instead, we store an "out of scope" flag that is used to shortcut
	# past the hook as quickely as possible.
	# This flag is shared between all the generated hooks for each
	# installed Aspect.
	# If the advice is going to last lexical then we don't need to
	# check or use the $out_of_scope variable.
	my $out_of_scope   = undef;
	my $MATCH_DISABLED = $lexical ? '$out_of_scope' : '0';

	# Find all pointcuts that are statically matched
	# wrap the method with advice code and install the wrapper
	foreach my $name ( $pointcut->match_all ) {
		my $NAME = $name; # For completeness

		no strict 'refs';
		my $original = *$name{CODE};
		unless ( $original ) {
			Carp::croak("Can't wrap non-existent subroutine ", $name);
		}

		# Any way to set prototypes other than eval?
		my $PROTOTYPE = prototype($original);
		   $PROTOTYPE = defined($PROTOTYPE) ? "($PROTOTYPE)" : '';

		# Generate the new function
		no warnings 'redefine';
		eval <<"END_PERL"; die $@ if $@;
		package Aspect::Hook;

		*$NAME = sub $PROTOTYPE {
			# Is this a lexically scoped hook that has finished
			goto &\$original if $MATCH_DISABLED;

			# Apply any runtime-specific context checks
			my \$wantarray = wantarray;
			local \$Aspect::POINT = bless {
				type         => 'around',
				pointcut     => \$pointcut,
				original     => \$original,
				sub_name     => \$name,
				wantarray    => \$wantarray,
				args         => \\\@_,
				return_value => \$wantarray ? [ ] : undef,
				topic        => \\\$_,
			}, 'Aspect::Point';

			# Can we shortcut the advice code
			goto &\$original unless $MATCH_RUN;

			# Run the advice code
			SCOPE: {
				local \$_ = \$Aspect::POINT;
				Sub::Uplevel::uplevel(
					1, \$code, \$Aspect::POINT,
				);
			}

			# Return the result
			return \@{\$Aspect::POINT->{return_value}} if \$wantarray;
			return \$Aspect::POINT->{return_value};
		};
END_PERL
		$self->{installed}++;
	}

	# If this will run lexical we don't need a descoping hook
	return unless $lexical;

	# Return the lexical descoping hook.
	# This MUST be stored and run at DESTROY-time by the
	# parent object calling _install. This is less bullet-proof
	# than the DESTROY-time self-executing blessed coderef
	return sub { $out_of_scope = 1 };
}

# Check for pointcut usage not supported by the advice type
sub _validate {
	my $self     = shift;
	my $pointcut = $self->pointcut;

	# Pointcuts using "throwing" are irrelevant in before advice
	if ( $pointcut->match_contains('Aspect::Pointcut::Throwing') ) {
		return 'The pointcut throwing is illegal when used by around advice';
	}

	# Pointcuts using "throwing" are irrelevant in before advice
	if ( $pointcut->match_contains('Aspect::Pointcut::Returning') ) {
		return 'The pointcut returning is illegal when used by around advice';
	}

	$self->SUPER::_validate(@_);
}

1;

=pod

=head1 NAME

Aspect::Advice::Around - Execute code both before and after a function

=head1 SYNOPSIS

  use Aspect;
  
  around {
      # Trace all calls to your module
      print STDERR "Called my function " . $_->sub_name . "\n";
  
      # Lexically alter a global for this function
      local $MyModule::MAXSIZE = 1000;
  
      # Continue and execute the function
      $_->run_original;
  
      # Suppress exceptions for the call
      $_->return_value(1) if $_->exception;
  
  } call qr/^ MyModule::\w+ $/;

=head1 DESCRIPTION

The C<around> advice type is used to execute code on either side of a
function, allowing deep and precise control of how the function will be
called when none of the other advice types are good enough.

Using C<around> advice is also critical if you want to lexically alter
the environment in which the call will be made (as in the example above
where a global variable is temporarily changed).

This advice type is also the most computationally expensive to run, so if
your problem can be solved with the use of a different advice type,
particularly C<before>, you should use that instead.

Please note that unlike the other advice types, your code in C<around> is
required to trigger the execution of the target function yourself with the
C<proceed> method. If you do not C<proceed> and also do not set either a
C<return_value> or C<exception>, the function call will return C<undef>
in scalar context or the null list C<()> in list context.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 - 2013 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
