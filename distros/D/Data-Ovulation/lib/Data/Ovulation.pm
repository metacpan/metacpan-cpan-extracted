package Data::Ovulation;

use strict;
use warnings;

use 5.008;

use Carp;
use Data::Ovulation::Result;
use base qw/ Exporter /;

use vars qw/ @EXPORT /;
@EXPORT = qw/ DELTA_FERTILE_DAYS DELTA_OVULATION_DAYS DELTA_NEXT_CYCLE /;

use constant DELTA_FERTILE_DAYS     => 5;
use constant DELTA_OVULATION_DAYS   => 3;
use constant DELTA_NEXT_CYCLE       => 14;

=head1 NAME

Data::Ovulation - Female ovulation prediction based on basal body temperature values

=head1 VERSION

This document describes Data::Ovulation version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Data::Ovulation;

    my $ovul = Data::Ovulation->new;
    $ovul->add_temperature( { day => 1, temp => '36.5' } );
    $ovul->add_temperature( { day => 2, temp => '36.1' } );

    my $ovul = Data::Ovulation->new;
    $ovul->temperatures( [ qw/ 
        36.5 36.1 36.1 36.2 36.2 36.2 36.3 36.2 36.2 36.1 36.3 36.4
        36.2 36.4 36.4 36.4 36.4 36.5 36.7 36.7 36.6 36.6 36.7 36.8
    / ] );

    my $result = $ovul->calculate;
    my $could_be_pregnant   = $result->impregnation;
    my @ovulation_days      = @{ $result->ovulation_days };
    my @fertile_days        = @{ $result->fertile_days };

See L<Data::Ovulation::Result> for all result object methods.

=head1 DESCRIPTION

This module tries to predict (based on scientific facts) if and when an ovulation has occurred 
within the female menstrual cycle based on basal body temperature values. Taking the temperature 
values after the ovulation into account it is possible to predict if an impregnation has occured. 
This data is often used as the basis for basal temperature curves.

=head1 SUBROUTINES/METHODS

=head2 C<new()>

Creates a new L<Data::Ovulation> object. You may pass in an arrayref of temperatures during object
construction:

    my $ovul = Data::Ovulation->new( {
        temperatures    => [ qw/ 36.2 36.1 ... / ]
    } );

=cut

sub new {
    my ( $class, $param ) = @_;
    my $self = {};
    $self->{ '_temperatures' } = [];
    bless $self, $class;
}

=head2 C<temperatures()>

Set all temperatures at once. Expects an arrayref of temperatures for every day of the menstrual cycle in
consecutive order starting with day 1. If called without parameters returns an arrayref of set temperatures.

    $ovul->temperatures( [ qw/ 36.5 36.1 / ] );
    my @temperatures = @{ $ovul->temperatures };

=cut

sub temperatures {
    my ( $self, $param ) = @_;
    if ( $param ) {
        if ( ref( $param ) eq "ARRAY" ) {
            $self->{ '_temperatures' } = $param;
        }
        else {
            croak "Not an arrayref";
        }
    }
    else {
        return $self->{ '_temperatures' } || [];
    }
}

=head2 C<temperature()>

Sets/Gets the temperature for a day. Day numbering starts at 1 - not 0!
Day 1 is supposed to be the first day of a new menstrual cycle. Returns
the set value on success.

    $ovul->add_temperature( { day => 12, temp => '36.2' } );

=cut

sub temperature {
    my ( $self, $params ) = @_;

    croak "day out of range or not specified" if $params->{ 'day' } < 0 || ! int $params->{ 'day' };

    if ( defined $params->{ 'temp' } ) {
        $self->{ '_temperatures' }->[ $params->{ 'day' } - 1 ] = $params->{ 'temp' };
    }

    return $self->{ '_temperatures' }->[ $params->{ 'day' } - 1 ];
}

=head2 C<calculate()>

Calculates the ovulation day and various other aspects of the female menstrual cycle based on basal
body temperature values set in the object and returns a L<Data::Ovulation::Result> object with the results.
Returns 0 if the calculation failed. There must be at least 10 temperature values in the object
for the calculation to be somewhat reasonable. A warning will be issued if there are less than 10
values and the method will immediately return with a value of 0.

    $ovul->calculate();

=cut

sub calculate {
    my ( $self ) = @_;

    if ( $self->no_of_values < 10 ) {
        carp "Not enough values - need at least 10 temperature values to calculate ovulation";
        return 0;
    }

    my $list = $self->temperatures;
    
    #----------------------------------------------------------
    # Calculate min/max temperature values
    #----------------------------------------------------------
    my $max = 0;
    my $min = 99.9;    
    for my $day( 0 .. @{ $list } ) {
        if( defined $list->[ $day ] ) {
            $min = $list->[ $day ] if $list->[ $day ] < $min;
            $max = $list->[ $day ] if $list->[ $day ] > $max;
        }
    }

    #----------------------------------------------------------
    # Calculate ovulation day
    #----------------------------------------------------------
    my $ovulation_day;
    my $max6;
    for my $day ( 6 .. @{ $list } - 1 ) {

        # get highest temperature value of previous six entries
        $max6 = $self->_max6( $day );

        if ( int( $max6 ) > 0 ) {
            if (

                #----------------------------------------------
                # Rule 1
                # Three temperature values are greater than
                # $max6 and the third value is at least 0.2°
                # higher than $max6
                #----------------------------------------------
                ( sprintf( "%2.1f", $list->[ $day ] || 0 ) > $max6 )
                && ( sprintf( "%2.1f", $list->[ $day + 1 ] || 0 ) > $max6 )
                && (
                    sprintf( "%2.1f", $list->[ $day + 2 ] || 0 ) >= sprintf "%2.1f", ( $max6 + 0.2 )
                )
              )
            {
                $ovulation_day = $day + 1;
            }
            elsif (

                #----------------------------------------------
                # Rule 2
                # Four values are greater than $max6
                #----------------------------------------------
                ( sprintf( "%2.1f", $list->[ $day ] || 0 ) > $max6 )
                && ( sprintf( "%2.1f", $list->[ $day + 1 ] || 0 ) > $max6 )
                && ( sprintf( "%2.1f", $list->[ $day + 2 ] || 0 ) > $max6 )
                && ( sprintf( "%2.1f", $list->[ $day + 3 ] || 0 ) > $max6 )
              )
            {
                $ovulation_day = $day + 1;
            }
            elsif ( sprintf( "%2.1f", $list->[ $day ] ) > $max6 ) {

                #----------------------------------------------
                # Rule 3
                # One temperature value is "choked up", i.e.
                # only one value is less than $max6
                #----------------------------------------------
                my $higher_values = 1;
                for ( $day + 1 .. $day + 2 ) {
                    if ( sprintf( "%2.1f", $list->[ $_ ] > $max6 ) ) { $higher_values++ }
                }
                if ( $higher_values >= 2 ) {
                    if (
                        sprintf( "%2.1f", $list->[ $day + 3 ] || 0 ) >=
                        sprintf( "%2.1f", $max6 + 0.2 ) )
                    {
                        $ovulation_day = $day + 1;
                    }
                }
            }
        }

        last if $ovulation_day;
    }

    if ( $ovulation_day ) {

        my $impregnation = 0;

        if ( scalar @{ $list } > $ovulation_day + DELTA_NEXT_CYCLE ) {

            #-------------------------------------------------------------
            # Calculate if impregnation is likely to have occured.
            # This is the case if the temperature after the ovulation day
            # is still above $max6 when the next menstrual cycle begins.
            #-------------------------------------------------------------
            $impregnation = 1;
            for my $day ( $ovulation_day + DELTA_NEXT_CYCLE .. @{ $list } ) {
                if ( sprintf( "%2.1f", $list->[ $day - 1 ] ) < sprintf( "%2.1f", $max6 ) ) {
                    $impregnation = 0;
                    last;
                }
            }
        }

        my $result = Data::Ovulation::Result->new(
            {
                min                 => $min,
                max                 => $max,
                day_rise            => $ovulation_day,
                ovulation_days      => [ ( $ovulation_day - DELTA_OVULATION_DAYS + 1 .. $ovulation_day ) ],
                fertile_days        => [ ( $ovulation_day - DELTA_FERTILE_DAYS + 1 .. $ovulation_day ) ],
                cover_temperature   => $max6,
                impregnation        => $impregnation,
            }
        );
        return $result;
    }

    return 0;
}

=head2 C<no_of_values()>

Returns the number of temperature values set.

    my $no_of_values = $ovul->no_of_values();

=cut

sub no_of_values {
    return scalar grep { defined $_ } @{ shift->temperatures };
}

=head2 C<clear()>

Remove set temperatures.

    $ovul->clear();

=cut

sub clear { return shift->{ '_temperatures' } = [] }

# Return highest temperature value of previous six values

sub _max6 {
    my ( $self, $day ) = @_;
    my $max = 0.0;
    for my $value ( @{ $self->temperatures }[ $day - 6 .. $day - 1 ] ) {
        if ( ( sprintf "%2.1f", $value ) > ( sprintf "%2.1f", $max ) ) {
            $max = sprintf "%2.1f", $value;
        }
    }
    return $max;
}

=head1 EXPORTS

The following constants are exported by default:

    DELTA_FERTILE_DAYS          # Number of days the fertility lasts. 
                                # The fertile period is supposed to start around
                                # 5 days before the temperature rises.
 
    DELTA_OVULATION_DAYS        # The ovulation is supposed to happen on one of
                                # 3 days prior to the temperature rise.
                              
    DELTA_NEXT_CYCLE            # Number of days until the next menstrual cycle
                                # starts counted from the day the temperature rises.

=head1 KNOWN BUGS

None yet.

=head1 SUPPORT

C<< <cpan at funkreich dot de> >>.

=head1 AUTHOR

Tobias Kremer, C<< <cpan at funkreich dot de> >>

=head1 SEE ALSO

=over 

=item L<Data::Ovulation::Result> - Result class methods

=item L<http://en.wikipedia.org/wiki/Basal_temperature> - Wikipedia entry on Basal body temperature

=item L<http://www.urbia.de/services/zykluskalender/> - An example of this module in use (german only)

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Tobias Kremer, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
