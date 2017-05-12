package App::Math::Tutor::Cmd::Poly::Cmd::Solve;

use warnings;
use strict;

use vars qw(@ISA $VERSION);

=head1 NAME

App::Math::Tutor::Cmd::Poly::Cmd::Solve - Plugin for solving polynoms

=cut

our $VERSION = '0.005';

use Moo;
use MooX::Cmd;
use MooX::Options;

use Carp qw(croak);
use Scalar::Util qw/blessed dualvar/;
use Math::Complex;

has template_filename => (
    is      => "ro",
    default => "onecolmlsol"
);

with "App::Math::Tutor::Role::PolyExercise";

use Math::Prime::Util qw(factor prime_precalc);

=head2 complex_solution

Specifies whether solution can become complex or not

=cut

option complex_solution => (
    is       => "ro",
    doc      => "Specifies whether solution can become complex or not",
    long_doc => "Hand's over control whether the solution has to be "
      . "a 'real' number or can get complex, respectively.\n\n"
      . "Default: no",
    default     => sub { 0 },
    short       => "c",
    negativable => 1,
);

sub _extract_sqrt
{
    my ( $self, $num, $exp ) = @_;
    my @nf = factor( abs($num) );
    my %nf;
    ++$nf{$_} for (@nf);
    my $bf = 1;
    my $rm = 1;
    foreach my $n ( sort keys %nf )
    {
        my $o = delete $nf{$n};
        my $c = $o;
        $c -= $exp while ( $c >= $exp );
        $c and $rm *= $c * $n;
        $o != $c and $bf *= $n**( ( $o - $c ) / $exp );
    }
    ( $bf, $rm );
}

sub _check_sqrt
{
    my ( $self, $num, $exp ) = @_;
    my ( $bf, $rm ) = $self->_extract_sqrt( $num, $exp );
    my $format = $self->format;
    $rm <= $format;
}

around _check_polynom => sub {
    my $orig = shift;
    my $self = shift;
    $self->$orig(@_) or return;

    my @values = @{ $_[0]->values };
    $values[0]->exponent == 2 or return;    # XXX
    my @fac = (0) x $values[0]->exponent;
    $fac[ $_->exponent ] = $_->factor for (@values);
    my ( $a, $b, $c ) = @fac;               # ( $values[0]->factor, $values[1]->factor || 0, $values[2]->factor || 0 );
    $a == 0 and return;
    my ( $p, $q ) = (
        VulFrac->new(
            num   => $b,
            denum => $a
          )->_reduce,
        VulFrac->new(
            num   => $c,
            denum => $a
        )->_reduce
    );
    my $p2 = VulFrac->new(
        num   => $p->num * $p->num,
        denum => $p->denum * $p->denum * 4
    )->_reduce;
    my $gcd = VulFrac->new(
        num   => $p2->denum,
        denum => $q->denum
    )->_gcd;
    my ( $fp, $fq ) = ( $q->{denum} / $gcd, $p2->{denum} / $gcd );
    my $d = VulFrac->new(
        num   => $p2->num * $fp - $q->sign * $q->num * $fq,
        denum => $p2->denum * $fp
    );
    $d->sign < 0 and !$self->complex_solution and return;
    $d->{num} = abs( $d->{num} );
    $d = $d->_reduce;
    $self->_check_sqrt( $d->num, $values[0]->exponent ) and $self->_check_sqrt( $d->denum, $values[0]->exponent );
};

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
my $sqr = sub {
    Power->new(
        basis    => $_[0],
        exponent => 2,
        mode     => defined $_[1] ? $_[1] : 0
    );
};
my $sqrt = sub {
    Power->new(
        basis    => $_[0],
        exponent => VulFrac->new(
            num   => 1,
            denum => 2
        ),
        mode => defined $_[1] ? $_[1] : 1
    );
};

sub _get_quad_solution
{
    my ( $self, $poly ) = @_;
    my ( @orig, @way, @solution );
    push @orig, 0, "$poly";

    my @values = @{ $poly->values };
    my @rvalues;
    my @pqvalues;
    my $reduced = 0;
    my $a_f     = $values[0]->factor;
    my ( $p, $q );
    foreach my $i ( 1 .. $#values )
    {
        my $exp = $values[$i]->exponent;
        my $f   = VulFrac->new(
            num   => $values[$i]->factor,
            denum => $a_f
        );
        push(
            @pqvalues,
            PolyTerm->new(
                factor   => $f,
                exponent => $exp
            )
        );
        $f->_gcd > 1 and ++$reduced and $f = $f->_reduce;
        push(
            @rvalues,
            PolyTerm->new(
                factor   => $f,
                exponent => $exp
            )
        );
        0 == $exp and $q = $f;
        1 == $exp and $p = $f;
    }
    defined $p
      or $p = VulFrac->new(
        num   => 0,
        denum => $a_f
      );
    defined $q
      or $q = VulFrac->new(
        num   => 0,
        denum => $a_f
      );
    unshift( @pqvalues, PolyTerm->new( exponent => $values[0]->exponent ) );
    unshift( @rvalues,  PolyTerm->new( exponent => $values[0]->exponent ) );
    $reduced and push @orig,
      PolyNum->new(
        values   => \@pqvalues,
        operator => "+"
      );
    push(
        @orig,
        PolyNum->new(
            values   => \@rvalues,
            operator => "+"
        )
    );

    push( @solution, '$ ' . join( " = ", @orig ) . ' $' );

    push @way, "X_{1/2}";

    my $d = PolyNum->new(
        values => [
            $sqr->(
                VulFrac->new(
                    num   => $p,
                    denum => 2
                )
            ),
            $q
        ],
        operator => "-",
    );

    my $X12 = PolyNum->new(
        operator => '\pm',
        values   => [
            VulFrac->new(
                num   => $p,
                denum => 2,
                sign  => -1
            ),
            $sqrt->($d),
        ]
    );
    push @way, "$X12";

    if ($p)
    {
        $p = VulFrac->new(
            num   => $p->num,
            denum => $a_mult_b->( '*', $p->denum, 2 ),
            sign  => $p->sign
        );
        $d = PolyNum->new(
            values   => [ $sqr->($p), $q ],
            operator => "-",
        );

        $X12 = PolyNum->new(
            operator => '\pm',
            values   => [ $p->_neg, $sqrt->($d) ]
        );
        push @way, "$X12";

        $p = VulFrac->new(
            num   => $p->num,
            denum => int( $p->denum ),
            sign  => $p->sign
        )->_reduce;
        $d = PolyNum->new(
            values   => [ $sqr->($p), $q ],
            operator => "-",
        );

        $X12 = PolyNum->new(
            operator => '\pm',
            values   => [ $p->_neg, $sqrt->($d) ]
        );
        push @way, "$X12";

        my $p2 = VulFrac->new(
            num   => $p->num * $p->num,
            denum => $p->denum * $p->denum,
            sign  => 1
        )->_reduce;
        $d = PolyNum->new(
            values   => [ $p2, $q ],
            operator => "-",
        );

        $X12 = PolyNum->new(
            operator => '\pm',
            values   => [ $p->_neg, $sqrt->($d) ]
        );
        push @way, "$X12";

        if ($q)
        {
            my $gcd = VulFrac->new(
                num   => $p2->denum,
                denum => $q->denum
            )->_gcd;
            my ( $fp, $fq ) = ( $q->{denum} / $gcd, $p2->{denum} / $gcd );
            $d = PolyNum->new(
                values => [
                    VulFrac->new(
                        num   => $a_mult_b->( '*', $p2->num,   $fp ),
                        denum => $a_mult_b->( '*', $p2->denum, $fp ),
                        sign  => $p2->sign
                    ),
                    VulFrac->new(
                        num   => $a_mult_b->( '*', $q->num,   $fq ),
                        denum => $a_mult_b->( '*', $q->denum, $fq ),
                        sign  => $q->sign
                    ),
                ],
                operator => "-",
            );
            $X12 = PolyNum->new(
                operator => '\pm',
                values   => [ $p->_neg, $sqrt->($d) ]
            );
            push @way, "$X12";

            $d = VulFrac->new(
                num   => $p2->num * $fp - $q->sign * $q->num * $fq,
                denum => $q->denum * $fq
            );
            $X12 = PolyNum->new(
                operator => '\pm',
                values   => [ $p->_neg, $sqrt->($d) ]
            );
            push @way, "$X12";
        }
    }
    elsif ($q)
    {
        $d   = $q->_neg;
        $X12 = PolyNum->new(
            operator => '\pm',
            values   => [ $p->_neg, $sqrt->($d) ]
        );
    }

    if ( "VulFrac" eq ref($d) )
    {
        my ( $nbf, $nrm ) = $self->_extract_sqrt( $d->num,   2 );
        my ( $dbf, $drm ) = $self->_extract_sqrt( $d->denum, 2 );

        if ( $nbf != 1 or $dbf != 1 )
        {
            $X12 = PolyNum->new(
                operator => '\pm',
                values   => [
                    $p->_neg,
                    VulFrac->new(
                        num => Power->new(
                            basis    => $d->sign * $nrm,
                            factor   => $nbf,
                            exponent => VulFrac->new(
                                num   => 1,
                                denum => 2
                            ),
                            mode => 1,
                        ),
                        denum => Power->new(
                            basis    => $drm,
                            factor   => $dbf,
                            exponent => VulFrac->new(
                                num   => 1,
                                denum => 2
                            ),
                            mode => 1
                        ),
                        sign => dualvar( 1, "" ),
                    ),
                ]
            );
            push @way, "$X12";
        }
    }

    push( @solution, '$ ' . join( " = ", @way ) . ' $' );

    #if ( $d >= 0 )
    {
        my $X1 = ref($X12)->new(
            operator => "+",
            values   => $X12->values
        );
        my ( $digits, $x1, $x2 ) = (6);    # $self->digits;
        my $dplus = $digits + 1;
        my $fmt   = sub {
            my $x = shift;
            my ( $xs, $approx ) = ( "" . $x, 0 );
            $x->display_format( 'format' => "%.${digits}f" ) and $xs = "" . $x and ++$approx
              if ( $xs =~ m/e\d+/i or $xs =~ m/\.\d{${dplus}}/ );
            push @way, $xs;
            push @solution, '$ ' . join( $approx ? " \\approx " : " = ", @way ) . ' $';
        };

        @way = "X_{1}";
        $fmt->( $X1->_numify );

        my $X2 = ref($X12)->new(
            operator => "-",
            values   => $X12->values
        );

        @way = "X_{2}";
        $fmt->( $X2->_numify );
    }

    @solution;
}

sub _build_exercises
{
    my ($self) = @_;
    my (@tasks);
    my $mf = Math::Prime::Util::MemFree->new;

    foreach my $i ( 1 .. $self->quantity )
    {
        my @line;
        push @line,  $self->get_polynom(1);
        push @tasks, \@line;
    }

    my $exercises = {
        section    => "Polynom Solving",
        caption    => 'Polynoms',
        label      => 'polynom_solving',
        header     => [ ['Polynom Solve'] ],
        solutions  => [],
        challenges => [],
    };

    foreach my $line (@tasks)
    {
        my ( @solution, @challenge );

        my ($a) = @{$line};
        push( @challenge, "\$ $a = 0 \$" );
        $a->values->[0]->exponent > 2 and die "No way to solve polynoms of power 3 or higher";
        $a->values->[0]->exponent == 2 and push @solution, $self->_get_quad_solution($a);

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
