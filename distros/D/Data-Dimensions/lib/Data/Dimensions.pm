package Data::Dimensions;

use Data::Dimensions::Map;
use Data::Dimensions::SickTie;
use strict;
use vars qw($VERSION @ISA @HANDLER);
@ISA = qw();
$VERSION = '0.05';

# use me baby
sub import {
    my ($class, @stuff) = @_;
    foreach (@stuff) {
	if ($_ eq 'extended') {
	    push_handler(\&Data::Dimensions::Map::parse_other);
	}
	if ($_ eq '&units') {
	    my ($pack) = caller;
	    {
		no strict 'refs';
		*{$pack . '::units'} = \&units;
	    }
	}
    }
}

# These are the vaguely public methods
sub set :lvalue {
    my $self = shift;
    if (@_) {
	$self->natural(@_);
	return $self;
    }
    # I can't stop using this as it exists now
    my $foo;
    tie $foo, 'Data::Dimensions::SickTie', $self, @_;
    $foo;
}

# For, er, symmetry, yes.
sub get {
    my $self = shift;
    return $self->natural;
}

sub new {
    my ($class, $units, $value) = @_;
    $class = ref($class) || $class;
    my $self = {};
    @{$self}{qw(units scale)} = basicate_units($units);
    $self->{base} = $value * $self->{scale}
      if defined ($value);
    return bless $self, $class;
}

sub units {
    Data::Dimensions->new(@_);
}

#### tie() now works? for perl 5.14 so
sub TIESCALAR {
  if ($] < 5.014) {
    croak("Cannot use tie with Data::Dimensions in Perl < 5.14.0, use set \$foo = ... instead");
  }
  my $class = shift;

  my $units = shift || {};
  my $val = shift || undef; # because
  $class->new($units, $val);
}
sub FETCH {
  return $_[0];
}
sub STORE {
  my ($self, $val) = @_;
  if (!ref($val) || !UNIVERSAL::isa($val, 'Data::Dimensions')) { # make a new me from a 'value'
    $self->natural($val);
  }
  else {
    $self->_moan("Storing value with incorrect units")
      unless $self->same_units($val);
    $self->base($val->base);
  }
}



#####  Not so public methods
sub natural {
    my $self = shift;
    if (@_) {
	$self->{base} = $_[0] * $self->{scale};
    }
    else {
	return ($self->{base} / $self->{scale});
    }
}

sub base {
    my $self = shift;
    if (@_) {
	$self->{base} = $_[0];
    }
    else {
	return $self->{base};
    }
}

sub same_units {
    my ($self, $other) = @_;
    my ($ou, $tu) = ($self->{units}, $other->{units});
    my %temp = (%$ou, %$tu);

    {
	local $^W = 0; # look Ma! No warnings.
	foreach (keys %temp) {
	    return 0 if $ou->{$_} != $tu->{$_};
	}
    }
    return 1;
}

sub no_units {
    my $self = shift;
    my $ou = $self->{units};
    foreach (keys %{$ou}) {
	return 0 if $ou->{$_};
    }
    return 1;
}

## debug and death
sub _dump {
    my $self = shift;
    print overload::StrVal($self);
    print " base: ", $self->{base}, " scale:", $self->{scale}, "\n";
    foreach (keys %{$self->{units}}) {
	print " $_ => ", $self->{units}->{$_}, "\n";
    }
}

sub _moan {
    my $i = 0;
    while ((caller($i))[0] =~ /Data.*Dimensions/) {
	$i++;
    }
    my ($pack, $file, $line) = caller($i);
    die($_[1] ." at $file line $line\n");
}

#####  Overloading gubbins
# We use _guard to make sure both arguments are Data::Dimensions objects
# and to reverse arguments before they get any further
# as this simplifies code in the overloading routines

sub _guard {
    my ($one, $two, $r) = @_;
    if ($r) {
	$two = $one->new({}, $two);
	($one, $two) = ($two, $one);
    }
    elsif (!(ref($two) && UNIVERSAL::isa($two, 'Data::Dimensions'))) {
	$two = $one->new({}, $two);
    }
    return ($one, $two);
}

use overload
# these must be between objects with the same units
    '+' => sub {u_arith(sub {$_[0] + $_[1]}, @_)},
    '-' => sub {u_arith(sub {$_[0] - $_[1]}, @_)},
    '%' => sub {u_arith(sub {$_[0] % $_[1]}, @_)},
    '&' => sub {u_arith(sub {$_[0] & $_[1]}, @_)},
    '|' => sub {u_arith(sub {$_[0] | $_[1]}, @_)},
    '^' => sub {u_arith(sub {$_[0] ^ $_[1]}, @_)},
    '<=>' => sub {u_comp(sub {$_[0] <=> $_[1]}, @_)},
    'cmp' => sub {u_comp(sub {$_[0] cmp $_[1]}, @_)},

# these can propogate their units
    '/' => sub {u_div(sub {$_[0] / $_[1]}, &_guard)},
    '*' => sub {u_mul(sub {$_[0] * $_[1]}, &_guard)},

# these need to be careful about basic/natural units
    '++' => sub {$_[0]->natural($_[0]->natural + 1), shift},
    '--' => sub {$_[0]->natural($_[0]->natural - 1), shift},

# These need (some) args with NO units, and need natural units
    '**' => sub {u_exp(&_guard)},
    'cos' => sub {u_nounit(sub {cos $_[0]}, $_[0])},
    'sin' => sub {u_nounit(sub {sin $_[0]}, $_[0])},
    'exp' => sub {u_nounit(sub {exp $_[0]}, $_[0])},
    'log' => sub {u_nounit(sub {log $_[0]}, $_[0])},
    'sqrt' => sub {u_exp(sub {$_[0] ** $_[1]}, _guard($_[0], 0.5, 0))},

# These output, so need to use natural units
    '0+' => sub {$_[0]->natural},
    '""' => sub {$_[0]->natural},
    'bool' => sub {$_[0]->{base}},

    '=' => \&clone;
;
sub clone {
    my $new = $_[0]->new($_[0]->{units});
    $new->{scale} = $_[0]->{scale};
    $new->{base} = $_[0]->{base};
    return $new;
}

# Both args must have same units, return has same units
# try to keep result scaled as $one
sub u_arith {
    my ($op, $one, $two, $r) = @_;
    my $result = $one->new($one->{units});
    $result->{scale} = $one->{scale};
    if ($r) {
	$result->natural(&$op, $two, $one->natural);
    }
    elsif (!(ref($two) && UNIVERSAL::isa($two, 'Data::Dimensions'))) {
      $result->natural(&$op($one->natural, $two));
    }
    else {
	$one->_moan("Mixing different types in arithmetic operation")
	    unless ($one->same_units($two));
	$result->base(&$op($one->base, $two->base));
    }
    return $result;
}

# Must have same units on each side, compare in base units
sub u_comp {
    my ($op, $one, $two, $r) = @_;
    if ($r) {
	return &$op($two, $one->natural);
    }
    elsif (!(ref($two) && UNIVERSAL::isa($two, 'Data::Dimensions'))) {
	return &$op($one->natural, $two);
    }
    else {
	$one->_moan("Mixing different types in comparison operation")
	    unless $one->same_units($two);
	return &$op($one->{base}, $two->{base});
    }
}

# Can have different units, must propogate units and scaling correctly
sub u_div {
    my ($op, $one, $two) = @_;
    my $result = $one->new($one->{units});
    my ($ru, $tu) = ($result->{units}, $two->{units});
    foreach (keys %$tu) {
	$ru->{$_} -= $tu->{$_};
    }
    $result->{scale} = $one->{scale} / $two->{scale};
    $result->{base} = &$op($one->{base}, $two->{base});
    return $result;
}

sub u_mul {
    my ($op, $one, $two) = @_;
    my $result = $one->new($one->{units});
    my ($ru, $tu) = ($result->{units}, $two->{units});
    foreach (keys %$tu) {
	$ru->{$_} += $tu->{$_};
    }
    $result->{scale} = $one->{scale} * $two->{scale};
    $result->{base} = &$op($one->{base}, $two->{base});
    return $result;
}

# a**b, b must not have units, a can and these must propogate
sub u_exp {
    my ($one, $two) = @_;
    $one->_moan("Cannot raise to exponent with units")
	unless $two->no_units;
    my $result = $one->new($one->{units});
    my $ru = $result->{units};
    my $expn = $two->natural;
    foreach (keys %$ru) {
	$ru->{$_} *= $expn;
    }
    $result->{scale} = $one->{scale} ** $expn;
    $result->natural($one->natural ** $expn);
    return $result;
}

# for single arg functions, like cos()
sub u_nounit {
    my ($op, $one) = @_;
    $one->_moan("Value must have no units")
	unless $one->no_units;
    return &$op($one->natural);
}

#####  Stuff to cope with turning natural units into basic units
#   See also Data::Dimensions::Map
BEGIN {
    @HANDLER =( \&Data::Dimensions::Map::parse_SI);
}

sub push_handler { # ok, ok, it shifts... you try foreach backwards
    my $handler = shift;
    $handler = UNIVERSAL::isa($handler, 'CODE') ? $handler : shift;
    unshift @HANDLER, $handler;
}

# Charge through appropriate handlers
sub basicate_units {
    my ($hr) = @_;
    my $scale = 1;
    # prefixes
    ($hr, $scale) = Data::Dimensions::Map::parse_prefix($hr, $scale);
    # everything else
    foreach (@HANDLER) {	
	($hr, $scale) = &$_($hr, $scale);
    }
    return ($hr, $scale);
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!
# Yeah, I'd better had!

=head1 NAME

Data::Dimensions - Strongly type values with physical units

=head1 SYNOPSIS

  use Data::Dimensions qw(extended &units);

  my $energy = Data::Dimensions->new( {joule => 1} );
  # or, more simply...
  my $mass   = units( {kg =>1 } );
  my $c      = units( {m=>1, s=>-1} );

  $mass->set = 10; $c->set = 299_792_458;

  # In perl >= 5.14, you can tie, set continues to work
  tie my $foo, 'Data::Dimensions', {joule => 1};
  $foo = 12;

  # checks that units of mc^2 same as energy, use indirect syntax...
  set $energy = $mass * $c**2;

  # made a mistake on right, so dies with error
  set $energy = $mass * $c**3;

=head1 DESCRIPTION

=head2 Careful with that Equation, Eugene

In many applications type checking will make code more robust as
algorithmic (rather than syntax) errors can be found automatically.
Most languages which implement a type system (eg. C) only go as far as
giving each variable or function a single type property (such as C<int
frobnicate(int x, float y)>) which can be a user defined type (a C
C<typedef>).  This system is useful but falls short of the typing
needed in many applications, for instance it cannot catch the
following error (again, in C):

 PENCE_PER_GALLON unit_price;
 VOLUME           volume;
 PENCE            price;
 
 price = volume / unit_price;

Instead we want I<unit_price> to have a type of I<pence per gallon>,
I<volume> a type of I<gallons> and I<price> a type of I<pence>.  We
also want these types to propogate through expressions so that the
resulting type of C<volume / unit_price> is

 gallons / ( pence / gallons ) == gallons ** 2 / pence

which is clearly not of the same type as I<price> which we can detect
and therefore issue an appropriate error message.

Many scientific applications also require strong typing of this form,
for instance the famous equation C<E == M * C**2> is such that the
type (or units) of Energy (Joule) is identical to the units of Mass
(kg) times the units of the speed of light (m/s) squared, this
provides an indication that the equation is correct, and if we were to
use it as part of a calculation in a program, we can use the units of
the quantities to ensure that we have entered our program correctly.

It is also important to note that in many cases two quantities will
have different units but are used to measure the same underlying
property of something.  For instance, the metric meter and the
Imperial foot both measure the length of an object. As an example, the
volume of wood in a thin plank could be calculated given:

 $length in yards
 $width  in feet
 $depth  in inches
 $volume in cubic feet

We could calculate our volume by carefully converting all the
measurements to have the same units (inches, say) but this introduces
large amounts of code into our application which isn't crucial to the
problem we are attempting to solve (and that's a bad thing, remember).
Instead if our variables are all typed, we can get them to perform
automatic conversion between different units, so that

 $volume = $length * $width * $depth;

is all we need to say.

=head2 Typing to the Rescue

This module allows you to type your values with units.  These values
can then be used throughout your program and will automatically
convert themselves sensibly between measurement systems and ensure
that they are only used appropriately.  A range of popular units are
provided along with this module, and the interface needed to add your
own units is simple (and documented).

=head1 Introducing Types to your Program

=head2 Creating typed values

A typed value is created in the same way as any other object in perl,
using the C<new> method of the Data::Dimensions class or by importing the
C<units> subroutine when loading the module.  The units of the value
should be expressed as a hash reference giving unit => exponent pairs:

 $distance = Data::Dimensions->new( {meter => 1 } );

Optionally, an initial value (in the natural units of the variable)
can be assigned as a second argument:

 $speed  = units( {miles => 1, hour => -1}, 70 );
 $time   = units( {hour => 1}, 2 );

For Perl from C<5.14.0> onwards, you can also tie variables directly
so that you do not need to use the C<<->set()>> trick below:

 tie my $foo, 'Data::Dimensions', {miles => 1, hour => -1}, 70;

=head2 Assignment to a typed value

The typed values can then be used as you would any other variable,
with the exception that assignment to a typed variable must be done
through the variables C<set> method.  (I find it slightly nicer to use
the indirect object syntax shown below.)

 set $distance = $speed * $time;

For Perl from C<5.14.0> you should be able to do this:

 $distance = $speed * $time;

this will set $distance, but will B<not> check that a value with
correct units is being stored in it.)

You can also use the C<set> method to give a value to a variable:

 set $speed = 60; #  "rollers"

This expects a value expressed in the natural units of the variable
(in this case miles per hour), if a typed value is stored then the
base units of the stored value must match those of the variable in
which it is being stored, the natural units can be different and if so
any necessary scaling is performed automatically.

The following is valid (if a little contrived):

 $length = units( {kilo-meter => 1}, 12 );
 $width  = units( {mile => 1}, 3 );
 $area   = units( {acre => 1});
 
 set $area = $length * $width;

When variables are output (converted into numbers, printed, compared
with untyped values etc.), they are always treated as being in their
natural units, so that:

 print $area, "\n";

will output $area in acres.

=head2 Mixing incompatible types

The major point of this module is to detect errors in expressions,
this means, for instance, that both operands of a '+' operator must
have the same basic units, it is ok to add distance to distance, but
nonsense to add volume to speed.  If incorrect units are present in an
expression, the module will die with an appropriate error message.

For arithmetic and comparison operations, any untyped values are
assumed to have the same type as the typed operand, and be expressed
in its natural units, so

 $length = $old_length + 12;

will effectively upgrade 12 to be the same type as $old_length,
also saying:

 if ($length == 15) ...

will work as expected.

=head1 Dimensions and Measurement systems provided

=head2 Prefixes

All units can carry standard prefixes to indicate appropriate
powers of ten, kilometers are specified with "k-m" or "kilo-m".
The following prefixes are available:

 semi- demi-    0.5
 Y- yotta-	1e24
 Z- zetta-	1e21
 E- exa-	1e18
 P- peta-	1e15
 T- tera-	1e12
 G- giga-	1e9
 M- mega-	1e6
 k- kilo-	1e3
 h- hecto-	1e2
 da- deka-	1e1
 d- deci-	1e-1
 c- centi-	1e-2
 m- milli-	1e-3
 u- micro-	1e-6
 n- nano-	1e-9
 p- pico-	1e-12
 f- femto-	1e-15
 a- atto-	1e-18
 z- zopto-	1e-21
 y- yocto-	1e-24

Prefixes are stripped off the unit before any user-defined handlers
are run.

=head2 SI Units

SI units are generally used as the base units for almost all
measurements (with the exception of monetary units, which lack a
common base due to exchange rate fluctuations).  The following
units are those the module most likes to see:

 m   - meter, length
 kg  - kilogram, mass
 s   - second, time
 A   - Ampere, electrical current
 K   - Kelvin, temperature
 mol - mole, amount of substance
 cd  - candela, luminous intensity

 rad - radian, measure of angle
 sr  - sterradian, measure of solid angle

In addition to these, the following are defined and map appropriately
to their actual units, apart from one or two letter units, all
should be specified in lower case:

 meter, kilogram, sec, second, amp, ampere, kelvin, candela, mole,
 radian steradian, sterad, hertz, newton, pascal, joule, watt,
 coulomb, seimens farad, weber, henry, tesla, lumen, becquerel, gray,
 Hz, N, Pa, J, W, coul, V, ohm, S, F, Wb, H, T, lm, Bq, Gy.

=head2 Other Units

The following units are also provided, if you wish to use these you
must specify the C<extended> option when loading the module.

 lb nmile centrigrade foot electronvolt baud brpint arcsec ft arcmin
 deg hr liter inch yr week gram cc day min feet minute year brquart
 hour brgallon mile fermi tonne micron lightyear siderealyear cal gm
 gallon acre erg revolution ounce degree parsec in point block celsius
 barn gal ml byte turn mho quart pint amu arcdeg pound yard yd oz
 angstrom

=head1 Adding your own units

Any units given to the module which it does not understand are simply
left in place, if all you're doing is measuring chickens, then just
use a I<chicken> unit throughout your code.

=head2 Base units, natural units and scaling

To allow for conversion between different measurement systems, it is
necessary to chose one which is better than all the others, one which
forms the base on which all other measurement systems rest and in
whose units all other units can be given.  In scientific systems this
will be SI, where the Joule can be expressed as

 Joule == (kg=>1, m=>2, s=>-2)

and the eV (electron volt, used in particle physics) can be expressed
as:

 1 electron Volt == 1.6E-19 Joule == 1.6E-19 kg=>1, m=>2, s=>-2

Here we say that kg, m and s are the base units of Joules and electron
volts, and that the scaling between Joule and its base form is 1, and
that between eV and its base form is 1.6E-19.  More generally,

 1 natural unit == scaling factor * base unit

Any unit system you want to introduce to your program must be able to
take a set of natural units, convert these into suitable base units
(which may or may not be SI depending on your application) and
calculate the scaling factor which must be used when converting values
from the base unit to the natural unit.

=head2 How to do this

You simply need to write a subroutine which takes as its arguments a
reference to a hash of natural units and the current scaling factor.
It must return a new hash reference with units defined in appropriate
basic units, and a scaling factor.  Any units your routine does not
understand should be left alone as it is possible to chain these
subroutines.  Your subroutine will always be called before those
provided by the module, so it is ok to return nearly basic units like
'Joule'.

You specify the routine when you load Data::Dimensions.  The following
example allows electron Volts to be used:

    use Data::Dimensions qw(&units extended);
    Data::Dimensions->push_handler(\&myunits);

    sub myunits {
	my ($natural, $scale) = @_;
	my %temp;
	foreach (keys %$natural) {
	    if (/^(ev|electronvolts?)$/i) {
		$scale       *= 1.6E-19**($natural->{$_});
		$temp{joule} += $natural->{$_};
	    }
	    else {
		$temp{$_}    += $natural->{$_};
	    }
	}
	return (\%temp, $scale);
    };

You can also add units to the %Data::Dimensions::Map::units hash and
loading the module with the "extended" option, this contains entries
with the following structure:

    $units{unit} = [scale, { basic units }  ];

eg.
    $units{inch} = [2.54 / 100, {m=>1} ];

=head1 Debugging Hooks

If you're getting confused, you can call $variable->_dump to get a
pretty output of the underlying structure.

=head1 Future plans

It would be nice to get this working with Attributes and to rid the
module of the C<set> evil.  More units would be helpful as would
documentation that isn't confusing.  Also add constants with units,
trivial but boring.

=head1 BUGS

The $foo->set is annoying, and must be used for Perl before C<5.14.0>.
Dave Mitchell fixed the bug behind this and gets a biscuit next
time I see him.  Please let me know if there are any problems with
the implementation of tie().

If you discover any bugs in this module, or have features you would
like added, please report them via the CPAN Request Tracker at
rt.cpan.org.  Any other comments are welcome and should be sent
directly to the author.

=head1 AUTHOR

Alex Gough (alex@earth.li) -- Do get in touch, it will make me smile.

=head1 COPYRIGHT

This module is copyright (c) Alex Gough 2001-2002.  This module is
free software, you may use and redistribute it under the same terms as
Perl itself.

=head1 SEE ALSO

perl(1).

=cut
