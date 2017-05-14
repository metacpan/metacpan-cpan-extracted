package CORBA::Fixed;
use Math::BigInt;

use overload 
     '+' => \&add,
     '-' => \&subtract,
     '*' => \&mul,
     '/' => \&div,
     '<=>' => \&compare,
     '""' => \&stringify;

sub _construct {
    my ($class, $value, $scale) = @_;

    bless {
	    v  => $value,
	   's' => $scale,
	  }, $class;
}

sub from_string {
    my ($class, $str) = @_;

    my ($leading,$rest) = $str =~ /^(\s*[+-]?\d+)(?:\.(\d+)*)?/;

    if (!defined $leading) {
	return CORBA::Fixed->_construct(new Math::BigInt("0"),0);
    } else {
	$rest = defined $rest ? $rest : "";
        $str = $leading.$rest;
        my $n = 0;
        if ($str =~ /(0+)$/) {
            $n = length($1);
            if ($str =~ /^\s*[+-]?0+$/) { # Don't trim off the only zero
                $n--;
            }
            substr($str,-$n,$n) = "";
        }

	return CORBA::Fixed->_construct (Math::BigInt->new($str), length($rest)-$n);
    }
}

sub new {
    my ($class, $v, $scale) = @_;
    CORBA::Fixed->_construct (Math::BigInt->new($v), $scale);
}

sub add {
    my ($a, $b) = @_;

    if (!UNIVERSAL::isa($b, "CORBA::Fixed")) {
	$b = CORBA::Fixed->from_string($b);
    }

    my ($v, $s);
    
    if ($a->{'s'} > $b->{'s'}) {
	$s = $a->{'s'};
        my $z = $b->{v}->copy;
	$v = $a->{v} + ($z->blsft($a->{'s'} - $b->{'s'},10));
    } else {
	$s = $b->{'s'};
        my $z = $a->{v}->copy;
	$v = $b->{v} + ($z->blsft($b->{'s'} - $a->{'s'},10));
    }

    CORBA::Fixed->_construct ($v, $s);
}

sub subtract {
    my ($a, $b, $reverse) = @_;
    
    if (!UNIVERSAL::isa($b, "CORBA::Fixed")) {
	$b = CORBA::Fixed->from_string($b);
    }

    if ($reverse) {
	($a, $b) = ($b, $a);
    }
    
    my ($v, $s);

    if ($a->{'s'} > $b->{'s'}) {
        $s = $a->{'s'};
        my $z = $b->{v}->copy;
        $v = $a->{v} - ($z->blsft($a->{'s'} - $b->{'s'},10));
    } else {
        $s = $b->{'s'};
        my $z = $a->{v}->copy;
        $v = ($z->blsft($b->{'s'} - $a->{'s'},10)) - $b->{v};
    }
    CORBA::Fixed->_construct ($v, $s);
}

sub compare {
    my ($a, $b, $reverse) = @_;
    
    if (!UNIVERSAL::isa($b, "CORBA::Fixed")) {
	$b = CORBA::Fixed->from_string($b);
    }

    if ($reverse) {
	($a, $b) = ($b, $a);
    }
    
    if ($a->{'s'} > $b->{'s'}) {
        my $z = $b->{v}->copy;
        $z->blsft($a->{'s'} - $b->{'s'},10);
	$a->{v} <=> $z;
    } else {
        my $z = $a->{v}->copy;
        $z->blsft($b->{'s'} - $a->{'s'},10);
	$z <=> $b->{v};
    }
}

sub mul {
    my ($a, $b) = @_;

    if (!UNIVERSAL::isa($b, "CORBA::Fixed")) {
	$b = CORBA::Fixed->from_string($b);
    }

    CORBA::Fixed->_construct ($a->{v}*$b->{v}, $a->{'s'}+$b->{'s'});
}

sub div {
    my ($a, $b) = @_;

    if (!UNIVERSAL::isa($b, "CORBA::Fixed")) {
	$b = CORBA::Fixed->from_string($b);
    }

    # calculate to 31 places

    my $s = ($a->{'s'} - $b->{'s'});

    my $v1 = $a->{v};
    my $v2 = $b->{v};

    my $pad = 31 - $v1->length - $v2->length;

    if ($pad > 0) {
        $v1->blsft( $pad, 10 );
	$s += $pad;
    }

    CORBA::Fixed->_construct ($v1/$v2, $s);
}

# Turn the number into a form suitable for turning into a 
#    MICO FixedValue

sub to_digits {
    my ($self, $ndigits, $scale) = @_;

    my $value = $self->{v}->copy;
    if( $self->{'s'} <= $scale ) {
        $value->blsft( $scale - $self->{'s'}, 10 );
    } else {
        $value->brsft( $self->{'s'} - $scale, 10 );
    }
    my $vstr = (($value->sign eq '+') ? '+' : '') . $value->bstr();

    # pad or truncate to the requested number of digits
    my $len = length ($vstr) - 1;
    if ($len < $ndigits) {
       return substr($vstr,0,1) . ('0' x ($ndigits - $len) ) . substr($vstr,1);
    } else {
       return substr($vstr,0,1) . substr($vstr,-$ndigits);
    }
}

sub stringify {
    my $self = shift;

    my $vstr = $self->{v}->bstr();
    my $scale = $self->{'s'};

    if ($scale > 0) {
       return substr($vstr,0,length($vstr)-$scale).".".substr($vstr,-$scale);
    } else {
       return $vstr . ('0' x -$scale);
    }
}

1;

=head1 NAME

CORBA::MICO::Fixed - Fixed point arithmetic for CORBA.

=head1 SYNOPSIS

 use CORBA:::MICO::Fixed;

 $a = new CORBA::Fixed "+123454", 3
 print $a + 1.0                            # produces "+124.454"

=head1 DESCRIPTION

CORBA::MICO::Fixed implements arithmetic operations on fixed point 
numbers. It is meant to be used in conjuction with the CORBA::MICO
module, but could conceivable be useful otherwise. Note that
the file is called C<CORBA::MICO::Fixed>, but it implements the
generic package C<CORBA::Fixed>.

=head1 Internal representation

Internally, numbers are as represented as a pair of a C<Math::BigInt> 
multiple precision integer, and a integer scale. (positive or
negative).

=head1 Arithmetic operations

Addition, subtraction, and multiplication are carried out 
precisely. For adddition and subtraction, of two numbers
with scales C<s1> and C<s2>, the resulting scale is C<MAX(s1,s2)>.
For multiplication the resulting scale is C<s1+s2>.

Division is carried out to 31 decimals places, with additional
digits truncated without rounding.

=head1 Methods in C<CORBA::MICO::Fixed>

=over 4

Aside from overloaded C<+>, C<->, C<*>, C</> C<<=>> and C<""> 
operations, C<CORBA::MICO::Fixed> provides the following methods:

=item new STRING SCALE

Given a string (as suitable for input to C<Math::BigInt>), and
a scale, create a fixed-point value with the digits and sign
of STRING, and the scale SCALE.

=item from_string STRING

Create a CORBA::Fixed object from a string according to the
rules in the CORBA manual for fixed literals. That is,
the scale is given by the number of digits to the right
of the decimal point, I<ignoring trailing zeros>. If the
number has no non-zero digits to the right of the decimal
point, the scale will be the negative of the number of
trailing zeros to the left of the decimal point.

=item to_digits ( NDIGITS, SCALE )

Gives the digits (with a leading C<+> or C<-> sign) of the
the object's value, rounded to the SCALE, and padded to
NDIGITS.

=item 

=back

=head1 AUTHOR

Owen Taylor <otaylor@gtk.org>

=head1 SEE ALSO

perl(1).

=cut
