package Aspect::Advice::After;

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

# NOTE: To simplify debugging of the generated code, all injected string
# fragments will be defined in $UPPERCASE, and all lexical variables to be
# accessed via the closure will be in $lowercase.
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
	my $MATCH_RUN = $compiled ? '$compiled->()' : 1;

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

			my \$wantarray = wantarray;
			if ( \$wantarray ) {
				my \$return = eval { [
					Sub::Uplevel::uplevel(
						2, \$original, \@_,
					)
				] };

				local \$Aspect::POINT = bless {
					type         => 'after',
					pointcut     => \$pointcut,
					original     => \$original,
					sub_name     => \$name,
					wantarray    => \$wantarray,
					args         => \\\@_,
					return_value => \$return,
					exception    => \$\@,
				}, 'Aspect::Point';

				unless ( $MATCH_RUN ) {
					return \@\$return unless \$Aspect::POINT->{exception};
					die \$Aspect::POINT->{exception};
				}

				# Execute the advice code
				local \$_ = \$Aspect::POINT;
				&\$code(\$Aspect::POINT);

				# Throw the same (or modified) exception
				my \$exception = \$_->{exception};
				die \$exception if \$exception;

				# Get the (potentially) modified return value
				return \@{\$_->{return_value}};
			}

			if ( defined \$wantarray ) {
				my \$return = eval {
					Sub::Uplevel::uplevel(
						2, \$original, \@_,
					)
				};

				local \$Aspect::POINT = bless {
					type         => 'after',
					pointcut     => \$pointcut,
					original     => \$original,
					sub_name     => \$name,
					wantarray    => \$wantarray,
					args         => \\\@_,
					return_value => \$return,
					exception    => \$\@,
				}, 'Aspect::Point';

				unless ( $MATCH_RUN ) {
					return \$return unless \$Aspect::POINT->{exception};
					die \$Aspect::POINT->{exception};
				}

				# Execute the advice code
				local \$_ = \$Aspect::POINT;
				&\$code(\$Aspect::POINT);

				# Throw the same (or modified) exception
				my \$exception = \$_->{exception};
				die \$exception if \$exception;

				# Return the potentially-modified value
				return \$_->{return_value};

			}

			eval {
				Sub::Uplevel::uplevel(
					2, \$original, \@_,
				)
			};

			local \$Aspect::POINT = bless {
				type         => 'after',
				pointcut     => \$pointcut,
				original     => \$original,
				sub_name     => \$name,
				wantarray    => \$wantarray,
				args         => \\\@_,
				return_value => undef,
				exception    => \$\@,
			}, 'Aspect::Point';

			unless ( $MATCH_RUN ) {
				return unless \$Aspect::POINT->{exception};
				die \$Aspect::POINT->{exception};
			}

			# Execute the advice code
			local \$_ = \$Aspect::POINT;
			&\$code(\$Aspect::POINT);

			# Throw the same (or modified) exception
			my \$exception = \$_->{exception};
			die \$exception if \$exception;

			return;
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

1;

__END__

=pod

=head1 NAME

Aspect::Advice::After - Execute code after a function is called

=head1 SYNOPSIS

  use Aspect;
  
  after {
      # Trace all returning calls to your module
      print STDERR "Called my function " . $_->sub_name . "\n";
  
      # Suppress exceptions AND alter the results to foo()
      if ( $_->short_name eq 'foo' ) {
          if ( $_->exception ) {
              $_->return_value(1);
          } else {
              $_->return_value( $_->return_value + 1 );
          }
      }
  
  } call qr/^ MyModule::\w+ $/

=head1 DESCRIPTION

The C<after> advice type is used to execute code after a function is called,
regardless of whether or not the function returned normally or threw an 
exception.

The C<after> advice type should be used when you need to potentially make
multiple different changes to the returned value or the thrown exception.

If you only care about normally returned values you should use C<returning> in
the pointcut to exclude join points occuring due to exceptions.

If you only care about handling exceptions you should use C<throwing> in the
pointcut to exclude join points occuring due to normal return.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 - 2013 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
