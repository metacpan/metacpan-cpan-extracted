package App::Math::Tutor::Cmd::VulFrac::Cmd::Add;

use warnings;
use strict;

use vars qw(@ISA $VERSION);

=head1 NAME

App::Math::Tutor::Cmd::VulFrac::Cmd::Add - Plugin for addition and subtraction of vulgar fractions

=cut

our $VERSION = '0.005';

use Moo;
use MooX::Cmd;
use MooX::Options;

has template_filename => (
    is      => "ro",
    default => "twocols"
);

with "App::Math::Tutor::Role::VulFracExercise";

my %result_formats = (
    keep      => 1,
    reducable => 1,
);

=head1 ATTRIBUTES

=head2 result_format

Allows controlling of accepted format of exercise output

=cut

option result_format => (
    is        => "ro",
    predicate => 1,
    doc       => "Let one specify result format behavior",
    long_doc  => "Let one specify result format behavior, pick one of\n\n"
      . "reducable: result can be reduced, "
      . "keep: keep exercise format (after reducing)",
    coerce => sub {
        defined $_[0] or return {};
        "HASH" eq ref $_[0] and return $_[0];
        my ( @fail, %rf );
        $rf{$_} = defined $result_formats{$_} or push @fail, $_ foreach @{ $_[0] };
        @fail
          and die "Invalid result format: " . join( ", ", @fail ) . ", pick any of " . join( ", ", keys %result_formats );
        \%rf;
    },
    format     => "s@",
    autosplit  => ",",
    repeatable => 1,
    short      => "r",
);

sub _build_command_names { qw(add sub); }

my $a_plus_b = sub {
    PolyNum->new(
        operator => $_[0],
        values   => [ splice @_, 1 ]
    );
};
my $a_mult_b = sub {
    ProdNum->new(
        operator => $_[0],
        values   => [ splice @_, 1 ]
    );
};

sub _operands_ok
{
    my ( $self, $op, @operands ) = @_;
    $self->has_result_format or return 1;
    my $s = shift @operands;
    while (@operands)
    {
        my $b = shift @operands;
        my $a = $s->_reduce;
        $b = $b->_reduce;
        my $gcd = VulFrac->new(
            num   => $a->denum,
            denum => $b->denum
        )->_gcd;
        my ( $fa, $fb ) = ( $b->{denum} / $gcd, $a->{denum} / $gcd );
        my ( $xa, $xb ) = (
            VulFrac->new(
                num   => int( $a_mult_b->( '*', $a->num,   $fa ) ),
                denum => int( $a_mult_b->( '*', $a->denum, $fa ) ),
                sign  => $a->sign
            ),
            VulFrac->new(
                num   => int( $a_mult_b->( '*', $b->num,   $fb ) ),
                denum => int( $a_mult_b->( '*', $b->denum, $fb ) ),
                sign  => $b->sign
            )
        );
        $s = VulFrac->new(
            num   => int( $a_plus_b->( $op, $xa->sign * $xa->num, $xb->sign * $xb->num ) ),
            denum => $xa->denum
        );
    }
    my ( $max_num, $max_denum ) = ( @{ $_[0]->format } );
    my %result_format = %{ $self->result_format };
    $s->_gcd > 1 or return 0 if defined $result_format{reducable} and $result_format{reducable};
    $s = $s->_reduce;
    $s->num <= $max_num     or return 0 if defined $result_format{keep} and $result_format{keep};
    $s->denum <= $max_denum or return 0 if defined $result_format{keep} and $result_format{keep};
    1;
}

sub _build_exercises
{
    my ($self) = @_;
    my $neg = $self->negativable;

    my (@tasks);
    foreach my $i ( 1 .. $self->quantity )
    {
        my @line;
        foreach my $j ( 0 .. 1 )
        {
          REDO: my ( $a, $b ) = $self->get_vulgar_fractions(2);
            $self->_operands_ok( $j ? '-' : '+', $a, $b ) or goto REDO;
            push @line, [ $a, $b ];
        }
        push @tasks, \@line;
    }

    my $exercises = {
        section    => "Vulgar fraction addition / subtraction",
        caption    => 'Fractions',
        label      => 'vulgar_fractions_addition',
        header     => [ [ 'Vulgar Fraction Addition', 'Vulgar Fraction Subtraction' ] ],
        solutions  => [],
        challenges => [],
    };
    # use Text::TabularDisplay;
    # my $table = Text::TabularDisplay->new( 'Bruch -> Dez', 'Dez -> Bruch' );
    foreach my $line (@tasks)
    {
        my ( @solution, @challenge );

        foreach my $i ( 0 .. 1 )
        {
            my ( $a, $b ) = @{ $line->[$i] };
            my $op = $i ? '-' : '+';
            $op eq '-' and $a < $b and ( $b, $a ) = ( $a, $b ) unless $neg;
            push @challenge, sprintf( '$ %s = $', $a_plus_b->( $op, $a, $b ) );

            my @way;    # remember Frank Sinatra :)
            push @way, $a_plus_b->( $op, $a, $b );

            ( $a, $b ) = ( $a->_reduce, $b = $b->_reduce ) and push @way, $a_plus_b->( $op, $a, $b )
              if ( $a->_gcd > 1 or $b->_gcd > 1 );

            my $gcd = VulFrac->new(
                num   => $a->denum,
                denum => $b->denum
            )->_gcd;
            my ( $fa, $fb ) = ( $b->{denum} / $gcd, $a->{denum} / $gcd );

            my ( $xa, $xb ) = (
                VulFrac->new(
                    num   => $a_mult_b->( '*', $a->num,   $fa ),
                    denum => $a_mult_b->( '*', $a->denum, $fa ),
                    sign  => $a->sign
                ),
                VulFrac->new(
                    num   => $a_mult_b->( '*', $b->num,   $fb ),
                    denum => $a_mult_b->( '*', $b->denum, $fb ),
                    sign  => $b->sign
                )
            );
            push @way, $a_plus_b->( $op, $xa, $xb );
            $xa = VulFrac->new(
                num   => int( $xa->num ),
                denum => int( $xa->denum ),
                sign  => $xa->sign
            );
            $xb = VulFrac->new(
                num   => int( $xb->num ),
                denum => int( $xb->denum ),
                sign  => $xb->sign
            );
            push @way, $a_plus_b->( $op, $xa, $xb );

            my $s = VulFrac->new(
                num   => $a_plus_b->( $op, $xa->sign * $xa->num, $xb->sign * $xb->num ),
                denum => $xa->denum
            );

            push @way, $s;
            $s = VulFrac->new(
                num   => int( $s->num ),
                denum => $s->denum,
                sign  => $s->sign
            );
            push @way, "" . $s;
            $s->_gcd > 1 and $s = $s->_reduce and push @way, $s;

            $s->num > $s->denum and $s->denum > 1 and push @way, $s->_stringify(1);

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
