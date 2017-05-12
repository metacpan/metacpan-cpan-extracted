package App::Math::Tutor::Cmd::Roman::Cmd::Add;

use warnings;
use strict;

use vars qw(@ISA $VERSION);

=head1 NAME

App::Math::Tutor::Cmd::Roman::Cmd::Add - Plugin for addition and subtraction of roman numbers

=cut

our $VERSION = '0.005';

use Moo;
use MooX::Cmd;
use MooX::Options;

has template_filename => (
    is      => "ro",
    default => "twocols"
);

with "App::Math::Tutor::Role::Roman", "App::Math::Tutor::Role::NaturalExercise";

sub _build_command_names
{
    qw(add sub);
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
          REDO:
            my ( $a, $b ) = $self->get_natural_number(2);
            $j and $a == $b and goto REDO;
            push @line, [ $a, $b ];
        }
        push @tasks, \@line;
    }

    my $exercises = {
        section    => "Roman number addition / subtraction",
        caption    => 'Roman Numeral Addition / Subtraction',
        label      => 'roman_numeral_addition',
        header     => [ [ 'Roman Number Addition', 'Roman Number Subtraction' ] ],
        solutions  => [],
        challenges => [],
    };

    foreach my $line (@tasks)
    {
        my ( @solution, @challenge );

        foreach my $i ( 0 .. 1 )
        {
            my ( $a, $b ) = @{ $line->[$i] };
            my $op = $i ? '-' : '+';
            $op eq '-' and $a < $b and ( $b, $a ) = ( $a, $b );
            push @challenge, sprintf( '$ %s %s %s = $', $a, $op, $b );

            my @way;    # remember Frank Sinatra :)
            push @way, sprintf( '%s %s %s', $a, $op, $b );
            push @way, RomanNum->new( value => $op eq "+" ? $a->_numify + $b->_numify : $a->_numify - $b->_numify );

            push( @solution, '$ ' . join( " = ", @way ) . ' $' );
        }

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
