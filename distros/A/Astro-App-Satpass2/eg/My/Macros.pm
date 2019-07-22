package My::Macros;

use 5.008;

use strict;
use warnings;

use parent qw{ Astro::App::Satpass2 };

use Astro::App::Satpass2::Utils qw{ __arguments };
use Astro::Coord::ECI::Utils 0.059 qw{ rad2deg };
use Scalar::Util 1.26 qw{ refaddr };

our $VERSION = '0.040';

{
    my %operands;

    sub MODIFY_CODE_ATTRIBUTES {
	my ( $pkg, $code, @args ) = @_;
	my @rslt;
	foreach ( @args ) {
	    if ( m{ \A Operands [(] ( \d+ ) [)] \z }smx ) {
		$operands{ refaddr( $code ) } = $1;
	    } else {
		push @rslt, $_;
	    }
	}
	return $pkg->SUPER::MODIFY_CODE_ATTRIBUTES( $code, @rslt );
    }

    sub operands {
	my ( $code ) = @_;
	return $operands{ refaddr( $code ) } || 0;
    }
}

sub after_load : Verb() {
    my ( undef, $opt, @args ) = @_;	# Invocant unused
    my $rslt;
    foreach my $key ( keys %{ $opt } ) {
	$rslt .= "-$key $opt->{$key}\n";
    }
    foreach my $val ( @args ) {
	$rslt .= "$val\n";
    }
    return $rslt;
}

sub angle : Verb( radians! places=i ) {
    my ( $self, $opt, $name1, $name2, $time ) = __arguments( @_ );
    $time = $self->__parse_time( $time, time );
    defined $name1
	and defined $name2
	or $self->wail( 'Two names or OIDs must be provided' );
    my @things = $self->__choose(
	{ bodies => 1, sky => 1 },
	[ $name1, $name2 ],
    );
    @things
	or $self->wail( 'No bodies chosen' );
    @things < 2
	and $self->wail( 'Only 1 body (',
	    $things[0]->get( 'name' ),
	    ') chosen' );
    @things > 2
	and $self->wail( scalar @things, ' bodies chosen' );
    my $station = $self->station()->universal( $time );
    foreach my $body ( @things ) {
	$body->universal( $time );
    }
    my $angle = $station->angle( @things );
    $opt->{radians}
    or $angle = rad2deg( $angle );
    defined $opt->{places}
	or return "$angle\n";
    return sprintf "%.*f\n", $opt->{places}, $angle;
}

sub hi : Verb() {
    my ( undef, undef, $name ) = __arguments( @_ );
    defined $name
	or $name = 'world';
    return "Hello, $name!\n";
}

{
    my %operator = (
	and		=> sub : Operands(2) {
	    my ( undef, $stack ) = @_;	# Invocant unused
	    push @{ $stack }, pop @{ $stack } && pop @{ $stack };
	    return;
	},
	choose	=> sub : Operands(1) {
	    my ( $self, $stack ) = @_;
	    # We want the number of bodies, but __choose(), for better
	    # or worse, provides a reference to the array of bodies in
	    # scalar context. So the empty parens provide list context
	    # to __choose(), hiding the fact that ultimately we do a
	    # scalar assign.
	    my $count = () = $self->__choose(
		{ bodies	=> 1 },
		[ pop @{ $stack } ],
	    );
	    push @{ $stack }, $count;
	    return;
	},
	else		=> sub : Operands(1) {
	    my ( undef, $stack ) = @_;	# Invocant unused
	    $stack->[-1] = ! $stack->[-1];
	    no warnings qw{ exiting };
	    last TEST_LOOP;
	},
	not		=> sub : Operands(1) {
	    my ( undef, $stack ) = @_;	# Invocant unused
	    $stack->[-1] = ! $stack->[-1];
	    return;
	},
	or		=> sub : Operands(2) {
	    my ( undef, $stack ) = @_;	# Invocant unused
	    push @{ $stack }, pop @{ $stack } || pop @{ $stack };
	    return;
	},
	then		=> sub : Operands(1) {
	    no warnings qw{ exiting };
	    last TEST_LOOP;
	},
    );

    sub test : Verb() {
	my ( $self, undef, @arg ) = __arguments( @_ );
	my @stack;

	eval {
	    TEST_LOOP:
	    while ( @arg ) {
		my $current = shift @arg;
		if ( my $code = $operator{$current} ) {
		    my $operands = operands( $code );
		    @stack >= $operands
			or $self->wail( "Not enough operands. Need $operands" );
		    $code->( $self, \@stack );
		} else {
		    push @stack, $current;
		}
	    }
	    1;
	} or $self->wail( $@ );
	@stack > 1
	    and $self->wail( 'More than one value left on stack' );
	$stack[-1]
	    and @arg
	    or return;
	return $self->dispatch( @arg );
    }
}

sub dumper : Verb() {
    my ( $self, @args ) = @_;
    use YAML;
    return ref( $self ) . "\n" . Dump( \@args );
}

1;

__END__

=head1 NAME

My::Macros - Implement 'macros' using code.

=head1 SYNOPSIS

The following assumes this file is actually findable in C<@INC>:

 satpass2> macro load My::Macros
 satpass2> hi Yehudi
 Hello, Yehudi!
 satpass2> angle sun moon -places 2
 102.12
 satpass2>

=head1 DESCRIPTION

This Perl package defines code macros for Astro::App::Satpass2. These
are implemented as subroutines, but do not appear as methods of
Astro::App::Satpass2. Nonetheless, they are defined and called the same
way an Astro::App::Satpass2 interactive method is called, and return
their results as text.

=head1 SUBROUTINES

This class supports the following public subroutines, which are
documented as though they are methods of Astro::App::Satpass2:

=head2 after_load

If this subroutine exists, it will be called after the code macro is
successfully loaded, and passed the processed arguments of the
C<macro load> command. That is, the first argument (after the invocant)
will be the option hash, followed by the non-option arguments in order.

This subroutine returns the options (if any) one per line, followed by
the arguments, also one per line.

=head2 angle

 $output = $satpass2->dispatch( angle => 'sun', 'moon', 'today noon' );
 satpass2> angle sun moon 'today noon'

This subroutine computes and returns the angle between the two named
bodies at the given time. The time defaults to the current time.

The following options may be specified, either as command-line-style
options or in a hash as the second argument to C<dispatch()>:

=over

=item -places number

This option specifies the number of places to display after the decimal.
If it is specified, the number of degrees is formatted with C<sprintf>.
If not, it is simply interpolated into a string.

=item -radians

This option specifies that the angle is to be returned in radians.
Otherwise it is returned in degrees.

=back

=head2 dumper

 $output = $satpass2->dispatch( 'dumper', 'foo', 'bar' );
 satpass2> dumper foo bar

This subroutine is a diagnostic that displays the class name of its
first argument (which under more normal circumstances would be its
invocant), and a C<YAML> C<Dump()> of a reference to the array of
subsequent arguments.

There are no options.

=head2 hi

 $output = $satpass2->dispatch( 'hi', 'sailor' );
 satpass2> hi sailor
 Hello sailor!

This subroutine simply returns its optional argument C<$name> (which
defaults to C<'world'>) interpolated into the string
C<"Hello, $name\n">.

There are no options.

=head2 test

 $output = $satpass2->spaceflight( qw{ -all -effective } );
 $output .= $satpass2->dispatch(
     qw{ test 25544 choose else spacetrack retrieve 25544 } );
 
 satpass2> spaceflight -all -full
 satpass2> test 25544 choose else spacetrack retrieve 25544
 
 # In either of the above cases, the orbital elements come
 # from Space Track only if they could not be retrieved from
 # the NASA's Human Space Flight web site.

This subroutine implements conditional logic. Its arguments are a
logical expression expressed in reverse Polish notation, and a command
to dispatch if the expression is true.

In a reverse Polish system, everything can be evaluated as it is
encountered. Operands (in practice, anything not recognized as an
operator) are placed on the stack. Operators remove their operands from
the stack, and place their results on the stack.

The last operator is either C<then> or C<else> (but not both!).
Everything after this is taken as a command, to be dispatched only if
the single operand left on the stack has the expected logical value:
true for C<then>, or false for C<else>.

The following operators are implemented:

=over

=item and

This operator removes two arguments from the top of the stack, takes the
logical C<and> of them, and pushes the result onto the stack.

=item choose

This operator removes an operand from the stack, which is interpreted as
a satellite OID or name, or perhaps more than one, comma-delimited. It
pushes onto the stack the number of satellites matching any of the names
or numbers given. Note that this produces a true value provided any
satellites were found.

=item else

This operator requires an argument on the stack, but does not remove it.
Instead it logically negates it, and causes the Polish notation code to
terminate.

=item or

This operator removes two arguments from the top of the stack, takes the
logical C<or> of them, and pushes the result onto the stack.

=item not

This operator removes an argument from the top of the stack, logically
negates it, and pushes the result onto the stack.

=item then

This operator requires an argument on the stack, but does not remove it.
Instead it causes the Polish notation code to terminate.

=back

There are no options.

=head1 SEE ALSO

L<Astro::App::Satpass2|Astro::App::Satpass2>

L<Astro::App::Satpass2::Macro::Code|Astro::App::Satpass2::Macro::Code>.

The L<Code Macros|Astro::App::Satpass2::TUTORIAL/Code Macros> write-up
in the L<TUTORIAL|Astro::App::Satpass2::TUTORIAL>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2019 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
