package App::Math::Tutor::Role::Unit;

use warnings;
use strict;

=head1 NAME

App::Math::Tutor::Role::Unit - role for numererical parts for calculation with units

=cut

use Moo::Role;

our $VERSION = '0.005';

use Hash::MoreUtils qw/slice_def/;
use App::Math::Tutor::Numbers;

has unit_definitions => ( is => "lazy" );

sub _build_unit_definitions
{
    {
        time => {
            base       => { s => { max => 59 } },
            multiplier => {
                w => {
                    max    => 52,
                    factor => 7 * 24 * 60 * 60,
                },
                d => {
                    max    => 6,
                    factor => 24 * 60 * 60,
                },
                h => {
                    max    => 23,
                    factor => 60 * 60,
                },
                min => {
                    max    => 59,
                    factor => 60,
                },
            },
            divider => {
                ms => {
                    max    => 999,
                    factor => 1000,
                },
            },
        },
        length => {
            base       => { m => { max => 999 } },
            multiplier => {
                km => {
                    factor => 1000,
                },
            },
            divider => {
                dm => {
                    max    => 9,
                    factor => 10,
                },
                cm => {
                    max    => 9,
                    factor => 100,
                },
                mm => {
                    max    => 9,
                    factor => 1000,
                },
            }
        },
        weight => {
            base       => { g => { max => 999 } },
            multiplier => {
                kg => {
                    max    => 999,
                    factor => 1000,
                },
                t => {
                    factor => 1000 * 1000,
                },
            },
            divider => {
                mg => {
                    max    => 999,
                    factor => 1000,
                },
            },
        },
        euro => {
            base    => { '\euro{}' => {} },
            divider => {
                'cent' => {
                    factor => 100,
                    max    => 99
                }
            },
        },
        pound => {
            base    => { '\textsterling{}' => {} },
            divider => {
                'p' => {
                    factor => 100,
                    max    => 99
                }
            },
        },
        dollar => {
            base    => { '\textdollar{}' => {} },
            divider => {
                '\textcent{}' => {
                    factor => 100,
                    max    => 99
                }
            },
        },
    };
}

has ordered_units => ( is => "lazy" );

requires "relevant_units";

sub _build_ordered_units_flatten_helper
{
    my $unit_part = $_[0];
    my @flatten;

    foreach my $upnm ( keys %{$unit_part} )
    {
        my ( $min, $max, $factor ) = @{ $unit_part->{$upnm} }{qw(min max factor)};
        defined $min    or $min    = 0;
        defined $factor or $factor = 1;
        my %upv = slice_def {
            min    => $min,
            max    => $max,
            factor => $factor,
            unit   => $upnm
        };
        push @flatten, \%upv;
    }

    @flatten;
}

sub _build_ordered_units
{
    my $self = shift;
    my %ou;    # ordered units
    my $ud = $self->unit_definitions;
    my $ru = $self->relevant_units;

    foreach my $cat (@$ru)
    {
        my @base = _build_ordered_units_flatten_helper( $ud->{$cat}->{base} );
        my @mult = _build_ordered_units_flatten_helper( $ud->{$cat}->{multiplier} );
        my @div  = _build_ordered_units_flatten_helper( $ud->{$cat}->{divider} );
        my %ru;    # reworked unit

        1 != scalar @base and die "Invalid unit description: $cat";

        @mult = sort { $b->{factor} <=> $a->{factor} } @mult;
        @div  = sort { $a->{factor} <=> $b->{factor} } @div;
        $ru{base}     = scalar @mult;
        $ru{spectrum} = [ @mult, @base, @div ];
        $ou{$cat}     = \%ru;
    }

    \%ou;
}

sub _guess_unit_number
{
    my ( $unit_type, $lb, $ub ) = @_;
    my @rc;

    $lb == $ub and $lb == scalar @{ $unit_type->{spectrum} } and --$lb;
    $lb == $ub and $ub == 0 and scalar @{ $unit_type->{spectrum} } > 0 and ++$ub;
    $lb == $ub and $ub < $unit_type->{base} and ++$ub;
    $lb == $ub and --$lb;

  REDO:
    my ( $_lb, $_ub ) = ( $lb, $ub );
    my $i;
    for ( $i = $_lb; $i <= $_ub; ++$i )
    {
        my ( $min, $max ) = @{ $unit_type->{spectrum}->[$i] }{qw(min max)};
        defined $max
          or $max = 100;    # largest unit doesn't have an upper limit - XXX make it user definable
        push( @rc, int( rand( $max + $min ) ) - $min );
    }
    ++$_lb and shift @rc while ( @rc and !$rc[0] );
    $_ub-- and pop @rc   while ( @rc and !$rc[-1] );
    @rc or goto REDO;

    Unit->new(
        type  => $unit_type,
        begin => $_lb,
        end   => $_ub,
        parts => \@rc
    );
}

requires "unit_length";
requires "deviation";

=head1 METHODS

=head2 get_unit_numbers

Returns as many numbers with units as requested. Does Factory :)

=cut

sub get_unit_numbers
{
    my ( $self, $amount, $ut ) = @_;

    my $ou = $self->ordered_units;
    my @result;
    my @unames = keys %$ou;
    defined $ut or $ut = $ou->{ $unames[ int( rand( scalar @unames ) ) ] };
    my $length = $self->has_unit_length ? $self->unit_length : scalar @{ $ut->{spectrum} };
    my $deviation = $self->deviation;
    my ( $lo, $uo );

    my $fits = sub {
        my ( $lb, $ub ) = @_;
        $ub - $lb >= $length and return 0;
        defined $deviation or return 1;
        defined $lo and abs( $lb - $lo ) > $deviation and return 0;
        defined $uo and abs( $lb - $uo ) > $deviation and return 0;
        1;
    };

    while ( $amount-- )
    {
        my ( @bounds, $unit );
        do
        {
            @bounds = ( int( rand( scalar @{ $ut->{spectrum} } ) ), int( rand( scalar @{ $ut->{spectrum} } ) ) );
            $bounds[0] > $bounds[1] and @bounds = reverse @bounds;
        } while ( !$fits->(@bounds) );

        $unit = _guess_unit_number( $ut, @bounds );
        @result or ( $lo, $uo ) = ( $unit->begin, $unit->end );
        push( @result, $unit );
    }

    @result;
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
