package Acme::Dice;

use 5.008008;
use strict;
use warnings;

use Carp;
use Data::Dumper;

BEGIN {
    use Exporter ();
    use vars qw(@ISA @EXPORT_OK);
    @ISA = qw(Exporter);

    @EXPORT_OK = qw( roll_dice roll_craps );
}

$Acme::Dice::VERSION = '1.01';

my $defaults = {
    dice  => 1,
    sides => 6,
    favor => 0,
    bias  => 20,
};

sub roll_dice {
    my $raw_args = @_ == 1 ? shift : {@_};

    # no need to check params if coming from roll_craps
    my $args =
      delete( $raw_args->{skip_validate} )
      ? $raw_args
      : _validate_params($raw_args);

    my @rolls;
    my $roll_total = 0;
    for ( 1 .. $args->{dice} ) {
        my $roll = ( int( rand( $args->{sides} ) ) + 1 );
        _apply_bias( \$roll, $args ) if $args->{favor} && $args->{bias};
        push( @rolls, $roll );
        $roll_total += $roll;
    }

    return wantarray ? @rolls : $roll_total;
}

sub roll_craps {
    my $raw_args = @_ == 1 ? shift : {@_};

    croak "param present but undefined: bias"
      if exists( $raw_args->{bias} ) && !defined( $raw_args->{bias} );

    my $bias = delete( $raw_args->{bias} ) || 0;

    croak "Illegal value for 'bias': $bias" if $bias < 0 || $bias > 100;
    croak 'RTFM! Unknown params: ' . join( ', ', keys( %{$raw_args} ) )
      if keys( %{$raw_args} );

    # hey, this is Acme, remember? you were TOLD not to look inside!
    return ( wantarray ? ( 3, 4 ) : 7 ) if rand(100) < 5;

    my @rolls;
    push(
        @rolls,
        roll_dice(
            skip_validate => 1,
            dice          => 1,
            sides         => 6,
            favor         => 3,
            bias          => $bias
        )
    );
    push(
        @rolls,
        roll_dice(
            skip_validate => 1,
            dice          => 1,
            sides         => 6,
            favor         => 4,
            bias          => $bias
        )
    );

    return wantarray ? @rolls : $rolls[0] + $rolls[1];
}

sub _validate_params {
    my $raw_args = @_ == 1 ? shift : {@_};

    my $args = {};
    my @errors;

    # put put defaults in place for missing params
    # and detect incoming undefined params
    for ( keys( %{$defaults} ) ) {
        $raw_args->{$_} = $defaults->{$_} if !exists( $raw_args->{$_} );
        push( @errors, "param present but undefined: $_" )
          unless defined $raw_args->{$_};
        $args->{$_} = delete( $raw_args->{$_} );
        push( @errors, "$_ must be a non-negative integer: $args->{$_}" )
          if defined( $args->{$_} ) && $args->{$_} !~ m/^\d+$/;
    }
    push( @errors,
        'RTFM! Unknown params: ' . join( ', ', keys( %{$raw_args} ) ) )
      if keys( %{$raw_args} );

    croak join( "\n", @errors ) if @errors;

    # validate individual params now
    push( @errors, "Illegal value for 'dice': $args->{dice}" )
      if $args->{dice} < 1;
    push( @errors, "Really? Roll $args->{dice} dice?" ) if $args->{dice} > 100;

    push( @errors, "Illegal value for 'sides': $args->{sides}" )
      if $args->{sides} < 1;

    push( @errors, "Illegal value for 'favor': $args->{favor}" )
      if $args->{favor} < 0 || $args->{favor} > $args->{sides};
    push( @errors, "Illegal value for 'bias': $args->{bias}" )
      if $args->{bias} < 0 || $args->{bias} > 100;

    croak join( "\n", @errors ) if @errors;

    return $args;
}

sub _apply_bias {
    my $roll_src = shift;
    my $args     = shift;

    ${$roll_src} = $args->{favor}
      if ${$roll_src} != $args->{favor} && rand(100) < $args->{bias};

    return;
}

1;
__END__

=head1 NAME

Acme::Dice - The finest in croo ..., uhhh, precision dice!

=head1 SYNOPSIS

 use Acme::Dice qw(roll_dice roll_craps);
   
 my $total = roll_dice( dice => 3, sides => 6, favor => 6, bias => 30 );
 my @dice = roll_dice( dice => 3, sides => 6, favor => 6, bias => 30 );
   
 my $craps_roll = roll_craps( bias => 30 );
 my @craps_dice = roll_craps( bias => 30 );

=head1 DESCRIPTION

Acme knows that sometimes one needs more flexibility in one's rolls than
using normal dice normally allows. Here at last is a package that gives one
exactly the flexibility that has been lacking.

With Acme::Dice, not only can one specify the number and type of dice to be
rolled, not only can one choose to have just the total number or the
individual die results returned, but one can exert some amount of influence
over the outcome as well!

=head1 FUNCTIONS

Nothing is C<EXPORT>ed by default, However, the following functions are
available as imports.

=head2 roll_dice

This is the primary function. It accepts the parameters listed below to
control behavior and will return either the sum of the rolls or an array
containing the results of individual dice rolls depending upon context.

 my $total = roll_dice( dice => 3, sides => 6, favor => 6, bias => 30 );
 my @dice = roll_dice( dice => 3, sides => 6, favor => 6, bias => 30 );
  
The two examples above both roll three six-sided dice with a 30% bias in
favor of rolling a six (6) on each die. The first returns the total of the
three dice in a scalar, and the second returns an array with the individual
rolls.

All parameters are optional, and if the function is called with no parameters
it will roll a single 6-sided die with no bias.

The parameters are as follows:

=over 4

=item dice

This is an integer specifying the number of dice to roll. Default: 1

An exception will be thrown if it is less than 1 or greater than 100.

=item sides

This is an integer specifying how many sides are on the dice to be rolled.
Default: 6

An exception will be thrown if it is less than 1. (Huh? A 1-sided die?
Nothing is impossible for Acme!)

=item favor

This integer specifies which number (if any) should be favored  and must be
between 0 and the value specified for C<sides>. A value of 0 disables
any bias even if a value for C<bias> is given. Default: 0

=item bias

This is an integer between 0 and 100 that determines how much "weight" to
place on the favored side. A value of C<20> says to increase the chance of
rolling the favored number by 20%. A value of C<100> would mean to always
roll the favored number. A value of 0 will disable favoring completely,
even if a value for C<favor> is given. Default: 0

An exception will be thrown if the value is less than 0 or greater than 100.

=back

=head2 roll_craps

This function is sugar for C<roll_dice> that automatically rolls two 6-sided
dice. It will also automatically adjust the C<favor> parameter for "3" and "4"
as appropriate if a value for C<bias> is given, simulating "loaded" dice.

Like C<roll_dice>, the return value depends upon context.

  my $total = roll_craps( bias => 30 );
  my @dice = roll_craps( bias => 30 );

It will only accept a single, optional parameter: C<bias>

The C<bias> parameter behaves the same as described above for C<roll_dice>.
Any other parameters, including those that are otherwise legal for
C<roll_dice>, will cause an exception to be thrown.

The default is an un-biased roll of two 6-sided dice.

=head1 BUGS

Bugs? In an Acme module?!? Yeah, right.

=head1 SUPPORT

Support is provided by the author. Please report bugs or make feature requests
to the author or use the GitHub repository:

http://github.com/boftx/Acme-Dice

=head1 AUTHOR

Jim Bacon <jim@nortx.com>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. The full text of the license can be found in
the LICENSE file included with this module.

=head1 DISCLAIMER

Finding a way to use this module, and the consequences of doing so, is the
sole responsibility of the user!

=head1 NOTE

Acme employs the finest technology available to ensure the quality of its
products. There are no user-servicable parts inside. For your own safety,
DO NOT EXAMINE THE CONTENTS OF THIS PACKAGE!

=cut
