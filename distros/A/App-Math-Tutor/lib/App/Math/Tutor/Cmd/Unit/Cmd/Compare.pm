package App::Math::Tutor::Cmd::Unit::Cmd::Compare;

use warnings;
use strict;

use vars qw(@ISA $VERSION);

=head1 NAME

App::Math::Tutor::Cmd::Unit::Cmd::Compare - Plugin for comparing numbers with units

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

with "App::Math::Tutor::Role::UnitExercise";

sub _build_exercises
{
    my ($self) = @_;

    my (@tasks);

    foreach my $i ( 1 .. $self->quantity )
    {
        my @line;
        foreach my $j ( 0 .. 1 )
        {
            my ( $a, $b ) = $self->get_unit_numbers(2);
            push @line, [ $a, $b ];
        }
        push @tasks, \@line;
    }

    my $exercises = {
        section    => "Unit comparison",
        caption    => 'Units',
        label      => 'unit_comparison',
        header     => [ [ 'Unit Comparison', 'Unit Comparison' ] ],
        solutions  => [],
        challenges => [],
    };

    foreach my $line (@tasks)
    {
        my ( @solution, @challenge );

        foreach my $i ( 0 .. 1 )
        {
            my ( $a, $b ) = @{ $line->[$i] };
            push( @challenge, "\$ $a \\underbracket[0.5pt]{\\texttt{ }}\\text{ } $b \$" );

            my @way;    # remember Frank Sinatra :)
            my $op = $a <=> $b;
            $op < 0  and push( @way, "$a < $b" );
            $op > 0  and push( @way, "$a > $b" );
            $op == 0 and push( @way, "$a = $b" );

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
