package App::Math::Tutor::Cmd::Unit::Cmd::Cast;

use warnings;
use strict;

use vars qw(@ISA $VERSION);

=head1 NAME

App::Math::Tutor::Cmd::Unit::Cmd::Cast - Plugin for casting of numbers with units

=cut

our $VERSION = '0.005';

use Moo;
use MooX::Cmd;
use MooX::Options;

use Carp qw(croak);
use File::ShareDir ();
use Template       ();
use Scalar::Util qw(looks_like_number);

has template_filename => (
    is      => "ro",
    default => "twocols"
);

with "App::Math::Tutor::Role::UnitExercise", "App::Math::Tutor::Role::DecFracExercise";

sub _get_castable_numbers
{
    my ( $self, $quantity ) = @_;

    my @result;
    while ( $quantity-- )
    {
        my ( $un, $base, $ut );
        do
        {
            ($un) = $self->get_unit_numbers( 1, $ut );
            my $rng = $un->end - $un->begin;
            $base = int( rand($rng) ) + $un->begin;
            defined $ut or $ut = $un->type;
        } while ( !$self->_check_decimal_fraction( $un->_numify($base) ) );

        push @result,
          [
            $un,
            Unit->new(
                parts => [ $un->_numify($base) ],
                begin => $base,
                end   => $base,
                type  => $un->type
            )
          ];
    }

    @result;
}

sub _build_exercises
{
    my ($self) = @_;

    my (@tasks);
    foreach my $i ( 1 .. $self->quantity )
    {
        my @line;
        foreach my $j ( 0 .. 1 )
        {
            push @line, $self->_get_castable_numbers(1);
        }
        push @tasks, \@line;
    }

    my $exercises = {
        section    => "Unit casting",
        caption    => 'Units',
        label      => 'unit_castings',
        header     => [ [ 'Multiple entity => Single entity', 'Single entity => Multiple entity' ] ],
        solutions  => [],
        challenges => [],
    };

    my $digits = $self->digits;
    foreach my $line (@tasks)
    {
        my ( @solution, @challenge );
        # cast unit with multiple entities to unit with one entity
        my ( $unit, $based ) = @{ $line->[0] };
        my $base      = $based->begin;
        my $base_name = $unit->type->{spectrum}->[$base]->{unit};
        push @challenge, sprintf( '$ %s = %s\\text{%s} $', $unit, "\\ldots" x int( length($based) / 3 ), $base_name );

        my @way;    # remember Frank Sinatra :)
        push @way, "" . $unit;
        push @way, "" . $based;
        push( @solution, '$ ' . join( " = ", @way ) . ' $' );

        # cast decimal to vulgar fraction
        @way = ();
        ( $unit, $based ) = @{ $line->[1] };
        $base_name = $unit->type->{spectrum}->[$base]->{unit};
        $base      = $based->begin;
        push @challenge, sprintf( '$ %s = %s $', $based, "\\ldots" x int( length($unit) / 3 ) );
        push @way,       "" . $based;
        push @way,       "" . $unit;
        push( @solution, '$ ' . join( " = ", @way ) . ' $' );

        push( @{ $exercises->{solutions} },  \@solution );
        push( @{ $exercises->{challenges} }, \@challenge );
    }

    $exercises;

}

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
