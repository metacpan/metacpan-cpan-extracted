package App::Math::Tutor::Cmd::Natural::Cmd::Add;

use warnings;
use strict;

use vars qw(@ISA $VERSION);

=head1 NAME

App::Math::Tutor::Cmd::Natural::Cmd::Add - Plugin for addition and subtraction of natural numbers

=cut

our $VERSION = '0.005';

use Moo;
use MooX::Cmd;
use MooX::Options;

has template_filename => (
    is      => "ro",
    default => "twocols"
);

with "App::Math::Tutor::Role::NaturalExercise";

sub _build_command_names { qw(add sub); }

sub _build_exercises
{
    my ($self) = @_;

    my (@tasks);
    foreach my $i ( 1 .. $self->quantity )
    {
        my @line;
        foreach my $j ( 0 .. 1 )
        {
            my ( $a, $b ) = $self->get_natural_number(2);
            push @line, [ $a, $b ];
        }
        push @tasks, \@line;
    }

    my $exercises = {
        section    => "Natural number addition / subtraction",
        caption    => 'NaturalNums',
        label      => 'natural_number_addition',
        header     => [ [ 'Natural Number Addition', 'Natural Number Subtraction' ] ],
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
            push @way, $op eq "+" ? $a->_numify + $b->_numify : $a->_numify - $b->_numify;

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
