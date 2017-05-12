package App::Math::Tutor::Cmd::Power::Cmd::Rules;

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

with "App::Math::Tutor::Role::PowerExercise";

sub _build_exercises
{
    my ($self) = @_;

    my (@tasks);
    foreach my $i ( 1 .. $self->quantity )
    {
        my @line;
        foreach my $j ( 0 .. 1 )
        {
            my ($a) = $self->get_power_to(1);
            push @line, [$a];
        }
        push @tasks, \@line;
    }

    my $exercises = {
        section    => "Power mathematic rules",
        caption    => 'Power mathematic rules',
        label      => 'power_to',
        header     => [ [ 'Simpify', 'Simplify' ] ],
        solutions  => [],
        challenges => [],
    };

    foreach my $line (@tasks)
    {
        my ( @solution, @challenge );

        foreach my $i ( 0 .. 1 )
        {
            my ($a) = @{ $line->[$i] };
            push @challenge, sprintf( '$ %s = $', $a );

            my @way;    # remember Frank Sinatra :)
            push @way, sprintf( "%s", $a );
            $a->mode( ( $a->mode + 1 ) % 2 );
            push @way, sprintf( "%s", $a );

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
