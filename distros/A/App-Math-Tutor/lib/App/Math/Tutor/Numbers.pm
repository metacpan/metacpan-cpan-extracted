package App::Math::Tutor::Numbers;

use warnings;
use strict;

=head1 NAME

App::Math::Tutor::Numbers - Numbers provider for math exercises

=cut

use App::Math::Tutor::Util ();

our $VERSION = '0.005';

{
    package    #
      VulFrac;

    use Moo;
    use overload
      '""'   => "_stringify",
      'bool' => sub { !!$_[0]->num },
      '0+'   => "_numify",
      '<=>'  => "_num_compare";

    use Scalar::Util qw/blessed dualvar/;
    use Math::Complex;

    has num => (
        is       => "ro",
        required => 1
    );

    has denum => (
        is       => "ro",
        required => 1
    );
    has sign => (
        is       => "ro",
        required => 1
    );

    around BUILDARGS => sub {
        my $orig   = shift;
        my $self   = shift;
        my $params = $self->$orig(@_) or return;
        defined $params->{sign} or $params->{sign} = 1;
        $params->{num} < 0
          and $params->{num} = blessed $params->{num} ? $params->{num}->_abs : abs( $params->{num} )
          and $params->{sign} *= -1;
        $params->{denum} < 0
          and $params->{denum} = blessed $params->{denum} ? $params->{denum}->_abs : abs( $params->{denum} )
          and $params->{sign} *= -1;
        $params->{sign} = $params->{sign} < 0 ? dualvar( -1, "-" ) : dualvar( 1, "" );
        $params;
    };

    sub _stringify
    {
        $_[0]->num or return $_[0]->num;
        $_[0]->denum == 1 and return $_[0]->num;
        $_[1]
          and $_[0]->num > $_[0]->denum
          and return
          sprintf( '\normalsize{%d} \frac{%d}{%d}', int( $_[0]->num / $_[0]->denum ), $_[0]->num % $_[0]->denum, $_[0]->denum );

        my ( $lb, $rb ) = ( "", "" );
        $_[0]->sign < 0
          and ( blessed $_[0]->num or blessed $_[0]->denum )
          and ( $lb, $rb ) = ( "\\left(", "\\right)" );
        return sprintf( "%s\\frac{%s}{%s}", $_[0]->sign, $_[0]->num, $_[0]->denum );
    }

    sub _numify
    {
        my ( $s, $n, $d ) = ( $_[0]->sign, $_[0]->num, $_[0]->denum );
        blessed $n and $n = $n->_numify;
        blessed $d and $d = $d->_numify;
        return $s * $n / $d;
    }

    sub _num_compare
    {
        my ( $self, $other, $swapped ) = @_;
        $swapped and return $other <=> $self->_numify;

        blessed $other or return $self->_numify <=> $other;
        return $self->_numify <=> $other->_numify;
    }

    sub _euklid
    {
        my ( $a, $b ) = @_;
        my $h;
        while ( $b != 0 ) { $h = $a % $b; $a = $b; $b = $h; }
        return $a;
    }

    sub _gcd
    {
        my ( $a, $b ) = ( $_[0]->num, $_[0]->denum );
        my $gcd = $a > $b ? _euklid( $a, $b ) : _euklid( $b, $a );
        return $gcd;
    }

    sub _reciprocal
    {
        return ref( $_[0] )->new(
            num   => $_[0]->denum,
            denum => $_[0]->num,
            sign  => $_[0]->sign
        );
    }

    sub _neg
    {
        my $s = $_[0]->sign;
        $s *= -1;
        $s = $s < 0 ? dualvar( -1, "-" ) : dualvar( 1, "" );
        return ref( $_[0] )->new(
            num   => $_[0]->num,
            denum => $_[0]->denum,
            sign  => $s
        );
    }

    sub _abs
    {
        return ref( $_[0] )->new(
            num   => $_[0]->num,
            denum => $_[0]->denum,
            sign  => dualvar( 1, "" )
        );
    }

    sub _reduce
    {
        my ( $a, $b ) = ( $_[0]->num, $_[0]->denum );
        my $gcd = $a > $b ? _euklid( $a, $b ) : _euklid( $b, $a );
        return VulFrac->new(
            num   => $_[0]->num / $gcd,
            denum => $_[0]->denum / $gcd,
            sign  => $_[0]->sign
        );
    }

    sub _build_from_decimal
    {
        my ( $c, $n ) = @_;
        my $d = 1;
        while ( $n != int($n) )
        {
            $n *= 10;
            $d *= 10;
        }
        return $c->new(
            num   => $n,
            denum => $d
        )->_reduce;
    }
}

{
    package    #
      NatNum;

    use Moo;
    use overload
      '""'   => "_stringify",
      '0+'   => "_numify",
      'bool' => sub { $_[0]->value != 0 },
      '<=>'  => "_num_compare";

    use Scalar::Util qw/blessed/;
    use Math::Complex;

    has value => (
        is       => "ro",
        required => 1
    );

    sub _stringify { "" . $_[0]->value }
    sub _numify    { $_[0]->value }

    sub _num_compare
    {
        my ( $self, $other, $swapped ) = @_;
        $swapped and return $other <=> $self->_numify;

        blessed $other or return $self->_numify <=> $other;
        return $self->_numify <=> $other->_numify;
    }

    sub sign { return $_[0]->value <=> 0 }
    sub _abs { return NatNum->new( value => abs( $_[0]->value ) ) }
}

{
    package    #
      PolyTerm;

    use Moo;
    use overload
      '""'   => "_stringify",
      'bool' => sub { $_[0]->factor != 0 };

    use Scalar::Util qw/blessed/;
    use Math::Complex;

    has factor => (
        is      => "ro",
        default => sub { 1 },
    );
    has exponent => (
        is       => "ro",
        required => 1
    );

    sub _stringify
    {
        my ($self) = @_;
        my ( $fact, $exp ) = ( $self->factor, $self->exponent );
        $fact or return "0";
        0 == $exp  and return "$fact";
        1 == $exp  and 1 != $fact and return "{$fact}x";
        1 == $exp  and return "x";
        1 == $fact and return "x^{$exp}";
        return sprintf( "{%s}x^{%s}", $fact, $exp );
    }

    sub _abs
    {
        my ( $fact, $exp ) = ( $_[0]->factor, $_[0]->exponent );
        $fact = blessed $fact ? $fact->_abs() : abs($fact);
        return PolyTerm->new(
            factor   => $fact,
            exponent => $exp
        );
    }

    sub sign { return $_[0]->factor <=> 0 }
}

{
    package    #
      PolyNum;

    use Moo;
    use overload
      '""'   => "_stringify",
      '0+'   => "_numify",
      'bool' => "_filled",        # XXX prodcat(values->as_bool)
      '<=>'  => "_num_compare";

    use Scalar::Util qw/blessed/;
    use Math::Complex;
    App::Math::Tutor::Util->import(qw(sumcat_terms));

    has values => (
        is       => "ro",
        required => 1
    );
    has operator => (
        is       => 'ro',
        required => 1,
    );

    sub _stringify { sumcat_terms( $_[0]->operator, @{ $_[0]->values } ); }

    sub _numify
    {
        my ( $op, @terms ) = ( $_[0]->operator, @{ $_[0]->values } );
        my $rc = 0;

        foreach my $i ( 0 .. $#terms )
        {
            if ( $i == 0 )
            {
                $rc = blessed $terms[$i] ? $terms[$i]->_numify : $terms[$i];
                next;
            }

            $op eq "+" and $rc += blessed $terms[$i] ? $terms[$i]->_numify : $terms[$i];
            $op eq "-" and $rc -= blessed $terms[$i] ? $terms[$i]->_numify : $terms[$i];
        }

        return $rc;
    }

    sub _num_compare
    {
        my ( $self, $other, $swapped ) = @_;
        $swapped and return $other <=> $self->_numify;

        blessed $other or return $self->_numify <=> $other;
        return $self->_numify <=> $other->_numify;
    }

    sub _filled
    {
        $_ and return 1 foreach ( @{ $_[0]->values } );
        return;
    }

    sub sign { $_[0]->values->[0]->sign }

    sub _abs
    {
        my ( $first, @ov ) = @{ $_[0]->values };
        return ref( $_[0] )->new(
            operator => $_[0]->operator,
            values   => [ blessed $first ? $first->_abs : abs($first), @ov ]
        );
    }
}

{
    package    #
      ProdNum;

    use Moo;
    use overload
      '""'   => "_stringify",
      '0+'   => "_numify",
      'bool' => "_filled",        # XXX prodcat(values->as_bool)
      '<=>'  => "_num_compare";

    use Scalar::Util qw/blessed/;
    use Math::Complex;
    App::Math::Tutor::Util->import(qw(prodcat_terms));

    has values => (
        is       => "ro",
        required => 1
    );
    has operator => (
        is       => 'ro',
        required => 1,
    );

    sub _stringify { prodcat_terms( $_[0]->operator, @{ $_[0]->values } ); }

    sub _numify
    {
        my ( $op, @terms ) = ( $_[0]->operator, @{ $_[0]->values } );
        my $rc = 0;

        foreach my $i ( 0 .. $#terms )
        {
            my $t = blessed $terms[$i] ? $terms[$i]->_numify : $terms[$i];
            if ( $i == 0 )
            {
                $rc = $t;
                next;
            }

            $op eq "*" and $rc *= $t;
            $op eq "/" and $rc /= $t;
        }

        return $rc;
    }

    sub _num_compare
    {
        my ( $self, $other, $swapped ) = @_;
        $swapped and return $other <=> $self->_numify;

        blessed $other or return $self->_numify <=> $other;
        return $self->_numify <=> $other->_numify;
    }

    sub _filled
    {
        $_ or return 0 foreach ( @{ $_[0]->values } );
        return 1;
    }

    sub sign
    {
        @{ $_[0]->values } or return 0;
        my $sign = 1;
        foreach my $term ( @{ $_[0]->values } )
        {
            my $s = blessed $term ? $term->sign : $term <=> 0;
            $sign *= $s;
        }
        return $sign;
    }

    sub _abs
    {
        my @v;
        foreach my $term ( @{ $_[0]->values } )
        {
            my $x = blessed $term ? $term->_abs : abs($term);
            push @v, $x;
        }
        return ref( $_[0] )->new(
            operator => $_[0]->operator,
            values   => [@v]
        );
    }
}

{
    package    #
      Power;

    use Moo;
    use overload
      '""'   => "_stringify",
      '0+'   => "_numify",
      'bool' => sub { !!$_[0]->basis },    # 0 ** 7 == 0
      '<=>'  => "_num_compare";

    use Scalar::Util qw/blessed dualvar/;
    use Math::Complex;

    has basis => (
        is       => "ro",
        required => 1
    );

    has exponent => (
        is       => "ro",
        required => 1
    );

    has mode => (
        is      => "rw",
        default => sub { 0 },
    );

    has factor => (
        is      => "ro",
        default => sub { 1 },
    );

    has sign => (
        is => "lazy",
    );

    sub _stringify
    {
        my ( $b, $e, $f, $m ) = ( $_[0]->basis, $_[0]->exponent, $_[0]->factor, $_[0]->mode );
        $b or return "0";
        defined $f or $f = 1;
        $f or return;
        $e == 1 and return $b;
        blessed $e or $e = VulFrac->_build_from_decimal($e);
        my $bn = 1;
        eval { $bn = ( 1 <=> $b ); };
        my $x;
        $m
          and ( $e <=> int($e) ) != 0
          and 0 != $bn
          and $x = sprintf( "\\sqrt%s{%s}",
            $e->denum != 2 ? sprintf( "[%s]", $e->denum ) : "",
            $e->num != 1
            ? sprintf( "{%s}^{%s}", blessed $b ? "\\left($b\{}\\right)" : $b, $e->num )
            : $b );
        defined $x
          or $x = sprintf( "{%s}^{%s}", blessed $b ? "\\left($b\{}\\right)" : $b, $e )
          if 0 != $bn;
        defined $x or $x = "";
        1 != $f
          and $x = sprintf( "%s%s", $f, ( $x and $x !~ m/^\\/ ) ? "\\left($x\{}\\right)" : "$x" );
        $x or $x = "$b";
        return $x;
    }

    sub _numify
    {
        my ( $b, $e, $f ) = ( $_[0]->basis, $_[0]->exponent, $_[0]->factor );
        defined $f or $f = 1;
        blessed $e or $e = VulFrac->_build_from_decimal($e);
        my ( $en, $ed ) = ( $e->num, $e->denum );
        blessed $en and $en = $en->_numify;
        blessed $ed and $ed = $ed->_numify;
        blessed $b  and $b  = $b->_numify;
        blessed $f  and $f  = $f->_numify;
        return $f * root( $b**$en, $ed, 0 );
    }

    sub _num_compare
    {
        my ( $self, $other, $swapped ) = @_;
        $swapped and return $other <=> $self->_numify;

        blessed $other or return $self->_numify <=> $other;
        return $self->_numify <=> $other->_numify;
    }

    sub _reduce
    {
        die "mising";
    }

    sub _build_sign
    {
        #my ( $b, $e ) = ( $_[0]->basis, $_[0]->exponent );
        #blessed $b and $b->sign < 0 and return dualvar( -1, "-" );
        #$b < 0 and return dualvar( -1, "-" ) unless blessed $b;
        # XXX check how to deal with even exponent
        my ($f) = ( $_[0]->factor );
        defined $f and $f < 0 and return dualvar( -1, "-" );
        return dualvar( 1, "" );
    }

    sub _abs
    {
        my ( $b, $e, $f, $m ) = ( $_[0]->basis, $_[0]->exponent, $_[0]->factor, $_[0]->mode );
        $f = blessed $f ? $f->_abs : abs($f);
        return ref( $_[0] )->new(
            basis    => $b,
            exponent => $e,
            factor   => $f,
            mode     => $m
        );
    }
}

{
    package    #
      RomanNum;

    use Moo;

    extends "NatNum";

    use Carp qw/confess/;

    around BUILDARGS => sub {
        my $next   = shift;
        my $class  = shift;
        my $params = $class->$next(@_);
        defined $params->{value}
          and $params->{value} < 1
          and confess( "Roman numerals starts at I - " . $params->{value} . " is to low" );
        defined $params->{value}
          and $params->{value} > 3888
          and confess( "Roman numerals ends at MMMDCCCLXXXVIII - " . $params->{value} . " is to big" );
        return $params;
    };

    my %sizes = (
        M  => 1000,
        CM => 900,
        D  => 500,
        CD => 400,
        C  => 100,
        XC => 90,
        L  => 50,
        XL => 40,
        X  => 10,
        IX => 9,
        V  => 5,
        IV => 4,
        I  => 1,
    );

    sub _stringify
    {
        my $self  = $_[0];
        my $value = $self->value;
        my $str   = "";
        my @order = sort { $sizes{$b} <=> $sizes{$a} } keys %sizes;
        foreach my $sym (@order)
        {
            while ( $value >= $sizes{$sym} )
            {
                $str .= $sym;
                $value -= $sizes{$sym};
            }
        }
        return $str;
    }
}

{
    package    #
      Unit;

    use Moo;
    use overload
      '""'   => "_stringify",
      '0+'   => "_numify",
      'bool' => "_filled",
      '<=>'  => "_num_compare";
    use Scalar::Util qw/blessed/;
    use Math::Complex;

    has type => (
        is       => "ro",
        required => 1
    );
    has begin => (
        is       => "ro",
        required => 1
    );
    has end => (
        is       => "ro",
        required => 1
    );
    has parts => (
        is       => "ro",
        required => 1
    );

    sub _stringify
    {
        my @parts = @{ $_[0]->parts };
        my @res;
        for my $i ( $_[0]->begin .. $_[0]->end )
        {
            my $num = shift @parts;
            $num or next;
            my $un = $_[0]->type->{spectrum}->[$i]->{unit};
            $un = "\\text{$un }";
            push( @res, "$num $un" );
        }
        join( " ", @res );
        #join(" ", @{ $_[0]->parts } );
    }

    sub _numify
    {
        my @parts    = @{ $_[0]->parts };
        my $base     = $_[0]->type->{base};
        my $spectrum = $_[0]->type->{spectrum};
        my $res      = 0;
        for my $i ( $_[0]->begin .. $_[0]->end )
        {
            my $num = shift @parts;
            $num or next;
            my $factor = $spectrum->[$i]->{factor};
            $res = $i <= $base ? $res + $num * $factor : $res + $num / $factor;
        }

        if ( defined $_[1] )
        {
            my $factor = $spectrum->[ $_[1] ]->{factor};
            $res = $_[1] <= $base ? $res / $factor : $res * $factor;
        }

        $res;
    }

    sub _filled
    {
        grep { $_ } @{ $_[0]->parts };
    }

    sub _num_compare
    {
        my ( $self, $other, $swapped ) = @_;
        $swapped and return $other <=> $self->_numify;

        blessed $other or return $self->_numify <=> $other;
        my $rc;
        0 != ( $rc = $other->begin <=> $self->begin )
          and return $rc;    # $self->begin < $other->begin => $self > $other
        return $self->_numify <=> $other->_numify;
    }
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
