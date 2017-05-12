package App::Math::Tutor::Cmd::Roman::Cmd::Cast;

use warnings;
use strict;

use vars qw(@ISA $VERSION);

=head1 NAME

App::Math::Tutor::Cmd::Roman::Cmd::Cast - Plugin for casting of roman numerals into natural numbers and vice versa

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
        section    => "Roman number cast from/to natural number",
        caption    => 'Roman Numerals Casting',
        label      => 'roman_number_cast',
        header     => [ [ 'Cast From Roman Number', 'Cast Into Roman Number' ] ],
        solutions  => [],
        challenges => [],
    };

    foreach my $line (@tasks)
    {
        my ( @solution, @challenge );

        # cast roman into natural number
        my ($a) = @{ $line->[0] };
        push @challenge, sprintf( '$ %s = $', $a );

        my @way;    # remember Frank Sinatra :)
        push @way, "" . $a;
        push @way, int($a);
        push( @solution, '$ ' . join( " = ", @way ) . ' $' );

        # cast natural number into roman
        @way = ();
        ($a) = @{ $line->[1] };
        push @challenge, sprintf( '$ %d = $', $a );
        push @way,       int($a);
        push @way,       "" . $a;
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
