package App::Math::Tutor::Cmd::VulFrac::Cmd::Cast;

use warnings;
use strict;

use vars qw(@ISA $VERSION);

=head1 NAME

App::Math::Tutor::Cmd::VulFrac::Cmd::Cast - Plugin for casting of vulgar fraction into decimal fraction and vice versa

=cut

our $VERSION = '0.005';

use Moo;
use MooX::Cmd;
use MooX::Options;

has template_filename => (
    is      => "ro",
    default => "twocols"
);

with "App::Math::Tutor::Role::VulFracExercise", "App::Math::Tutor::Role::DecFracExercise";

=head1 ATTRIBUTES

=head2 chart

Enable chart for fraction approximation.

Warning: This is experimental and requires LaTeX::Driver 0.20+ and properly working xelatex

Default: 0

=cut

option chart => (
    is       => "ro",
    doc      => "Enable chart for fraction approximation",
    long_doc => "Enable chart for fraction approximation\n\n"
      . "Warning: This is experimental and requires LaTeX::Driver 0.20+ and properly working xelatex\n\n"
      . "Default: 0",
    default     => sub { 0 },
    negativable => 1,
);

sub _build_command_names { qw(cast); }

sub _get_castable_numbers
{
    my ( $self, $quantity ) = @_;

    my @result;
    while ( $quantity-- )
    {
        my $vf;
        do
        {
            $vf = $self->_guess_vulgar_fraction;
        } while ( !$self->_check_vulgar_fraction($vf) or !$self->_check_decimal_fraction($vf) );

        push @result, $vf;
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
            my ($a) = $self->_get_castable_numbers(1);
            push @line, [$a];
        }
        push @tasks, \@line;
    }

    my $exercises = {
        section     => "Vulgar fraction <-> decimal fracion casting",
        caption     => 'Fractions',
        label       => 'vulgar_decimal_fractions',
        header      => [ [ 'Vulgar => Decimal Fraction', 'Decimal => Vulgar Fraction' ] ],
        solutions   => [],
        challenges  => [],
        usepackages => [qw(pstricks pstricks-add)],
    };

    my $digits = $self->digits;
    foreach my $line (@tasks)
    {
        my ( @solution, @challenge );

        # cast vulgar fraction to decimal
        my ($a) = @{ $line->[0] };
        push @challenge, sprintf( '$ %s = $', $a );

        my @way;    # remember Frank Sinatra :)
        push @way, "" . $a;
        $a = $a->_reduce;
        $a->num != $line->[0]->[0]->num and push @way, "" . $a;
        my $rd = $digits + length( int($a) ) + 1;
        push @way, sprintf( "%0.${rd}g", $a );
        $self->chart and push @way,
          sprintf(
            '\begin{pspicture}(-0.25,-0.25)(0.25,0.25)\psChart[chartColor=color,chartSep=1pt]{%d,%d}{}{0.25}\end{pspicture}',
            $a->num % $a->denum,
            $a->denum - ( $a->num % $a->denum )
          );
        push( @solution, '$ ' . join( " = ", @way ) . ' $' );

        # cast decimal to vulgar fraction
        @way = ();
        ($a) = @{ $line->[1] };
        $rd = $digits + length( int($a) ) + 1;
        push @challenge, sprintf( "\$ %0.${rd}g = \$", $a );
        push @way,       sprintf( "%0.${rd}g",         $a );
        $a = $a->_reduce;
        push @way, "" . $a;
        $self->chart and push @way,
          sprintf(
            '\begin{pspicture}(-0.25,-0.25)(0.25,0.25)\psChart[chartColor=color,chartSep=1pt]{%d,%d}{}{0.25}\end{pspicture}',
            $a->num % $a->denum,
            $a->denum - ( $a->num % $a->denum )
          );
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
