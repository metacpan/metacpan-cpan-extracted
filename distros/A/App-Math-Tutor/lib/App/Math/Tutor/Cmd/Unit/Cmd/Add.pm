package App::Math::Tutor::Cmd::Unit::Cmd::Add;

use warnings;
use strict;

use vars qw(@ISA $VERSION);

=head1 NAME

App::Math::Tutor::Cmd::Unit::Cmd::Add - Plugin for addition and subtraction of numbers with units

=cut

our $VERSION = '0.005';

use Moo;
use MooX::Cmd;
use MooX::Options;

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
        section    => "Unit addition / subtraction",
        caption    => 'Units',
        label      => 'unit_addition',
        header     => [ [ 'Unit Addition', 'Unit Subtraction' ] ],
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
            push( @challenge, "\$ $a $op $b = \$" );

            my @way;    # remember Frank Sinatra :)
            push( @way, "$a $op $b" );
            my $beg = $a->begin < $b->begin ? $a->begin : $b->begin;
            my $end = $a->end > $b->end     ? $a->end   : $b->end;
            my @ap  = @{ $a->parts };
            my @bp  = @{ $b->parts };
            my ( @cparts, @dparts );
            for my $i ( $beg .. $end )
            {
                my @cps;
                $i >= $a->begin and $i <= $a->end and push( @cps, shift @ap );
                $i >= $b->begin and $i <= $b->end and push( @cps, shift @bp );
                scalar @cps or next;
                my $cp = join( " $op ", @cps );
                my $dp = eval "$cp;";
                if ( $dp < 0 )
                {
                    --$dparts[-1];
                    $dp += $a->type->{spectrum}->[$i]->{max} + 1;
                }
                elsif ( defined $a->type->{spectrum}->[$i]->{max}
                    and $dp > $a->type->{spectrum}->[$i]->{max} )
                {
                    @dparts and ++$dparts[-1];
                    @dparts or push @dparts, 1;
                    $dp -= $a->type->{spectrum}->[$i]->{max} + 1;
                }
                push( @cparts, $cp );
                push( @dparts, $dp );
            }
            my $c = Unit->new(
                type  => $a->type,
                begin => $beg,
                end   => $end,
                parts => \@cparts
            );
            my $d = Unit->new(
                type  => $a->type,
                begin => $beg - ( scalar @cparts - scalar @dparts ),
                end   => $end,
                parts => \@dparts
            );

            push( @way, "$c" );
            push( @way, "$d" );

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
