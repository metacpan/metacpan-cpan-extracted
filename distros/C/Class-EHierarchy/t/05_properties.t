# 05_properties.t
#
# Tests the various property types and scoping

use Test::More tests => 61;

use strict;
use warnings;

package MyPi;

use vars qw(@ISA @_properties);
use Class::EHierarchy qw(:all);

@ISA = qw(Class::EHierarchy);

@_properties = (
    [ CEH_PUB | CEH_SCALAR,   'pi', 3.14 ],
    [ CEH_RESTR | CEH_SCALAR, '2xpi' ],
    [ CEH_PRIV | CEH_SCALAR,  '3xpi' ],
    );

sub _initialize {
    my $self = shift;
    my @args = @_;

    # Initialize the double/triple PIs
    $self->set( '2xpi', $self->get('pi') * 2 );
    $self->set( '3xpi', $self->get('pi') * 3 );

    return 1;
}

sub double {
    my $self = shift;
    return $self->get('2xpi');
}

sub triple {
    my $self = shift;
    return $self->get('3xpi');
}

sub dump {
    my $self = shift;
    return $self->properties;
}

1;

package MySquaredPi;

use vars qw(@ISA @_properties);
use Class::EHierarchy qw(:all);

@ISA = qw(MyPi);

@_properties = (
    [ CEH_PUB | CEH_SCALAR,                'pi',      3.14**2 ],
    [ CEH_PUB | CEH_SCALAR,                'custompi' ],
    [ CEH_PUB | CEH_SCALAR | CEH_NO_UNDEF, 'noundef', 5 ],
    [ CEH_PUB | CEH_REF,                   'ref' ],
    [ CEH_PUB | CEH_GLOB,                  'glob' ],
    [ CEH_PUB | CEH_CODE,                  'code' ],
    [ CEH_PUB | CEH_ARRAY,                 'array' ],
    [ CEH_PUB | CEH_HASH,                  'hash' ],
    );

sub _initialize {
    my $self = shift;
    my @args = @_;

    $self->set( 'custompi', $self->get('pi') * $args[0] );

    return 1;
}

sub double {
    my $self = shift;
    return $self->get('2xpi');
}

sub triple {
    my $self = shift;
    return $self->get('3xpi');
}

sub dynprop {
    my $self = shift;
    _declProperty( $self, '5xpi', CEH_PRIV | CEH_SCALAR );
    return $self->set( '5xpi', $self->get('pi') * 5 );
}

sub quintuple {
    my $self = shift;
    return $self->get('5xpi');
}

sub dump {
    my $self = shift;
    return $self->properties;
}

1;

package MyRedundantPi;

use vars qw(@ISA);
use Class::EHierarchy qw(:all);

@ISA = qw(MyPi);

1;

package main;

my $mypi   = new MyPi;
my $mysqpi = new MySquaredPi 12;
my $myrpi  = new MyRedundantPi;
my $rv;

# Create our objects
ok( defined $mypi,   'class object instantiation - 1' );
ok( defined $mysqpi, 'subclass object instantiation - 1' );
ok( defined $myrpi,  'subclass object instantiation - 2' );

# Check the public property values
is( $mypi->get('pi'),   3.14,    'public property - 1' );
is( $mysqpi->get('pi'), 3.14**2, 'overriden public property - 1' );
is( $myrpi->get('pi'),  3.14,    'inherited public property - 1' );

# Check restricted property values
is( $mypi->get('2xpi'),   undef,       'restricted property - 1' );
is( $mypi->double,        3.14 * 2,    'restricted property - 2' );
is( $mysqpi->get('2xpi'), undef,       'restricted property - 3' );
is( $mysqpi->double,      3.14**2 * 2, 'restricted property - 4' );
is( $myrpi->get('2xpi'),  undef,       'restricted property - 5' );
is( $myrpi->double,       3.14 * 2,    'restricted property - 6' );

# Check private property values
is( $mypi->get('3xpi'),   undef,    'private property - 1' );
is( $mypi->triple,        3.14 * 3, 'private property - 2' );
is( $mysqpi->get('3xpi'), undef,    'private property - 3' );
is( $mysqpi->triple,      undef,    'private property - 4' );
is( $myrpi->get('3xpi'),  undef,    'private property - 5' );
is( $myrpi->triple,       3.14 * 3, 'private property - 6' );

# Safety check
is( $mypi->get('MyPi*3xpi'), undef, 'private property - 7' );

# Check arg initialization code
is( $mysqpi->get('custompi'), 3.14**2 * 12, 'arg init property - 1' );

# Check dynamic property
ok( $mysqpi->dynprop, 'dynamic property - 1' );
is( $mysqpi->get('5xpi'), undef,       'private property - 8' );
is( $mysqpi->quintuple,   3.14**2 * 5, 'private property - 9' );

# Test noundef
ok( !$mysqpi->set( 'noundef', undef ), 'no undef - 1' );
is( $mysqpi->get('noundef'), 5, 'no undef - 2' );
ok( $mysqpi->set( 'noundef', 100 ), 'no undef - 3' );
is( $mysqpi->get('noundef'), 100, 'no undef - 4' );
ok( !$mysqpi->set( 'noundef', $mypi ), 'no ref - 1' );

# Test code refs
my $sub = sub {1};
ok( !$mysqpi->set( 'code', 21 ), 'code - 1' );
ok( $mysqpi->set( 'code', $sub ), 'code - 2' );
is( $mysqpi->get('code'), $sub, 'code - 3' );
ok( $mysqpi->set('code'), 'code - 4' );
is( $mysqpi->get('code'), undef, 'code - 5' );

# Test glob refs
ok( !$mysqpi->set( 'glob', 21 ), 'glob - 1' );
ok( $mysqpi->set( 'glob', \*STDOUT ), 'glob - 2' );
is( $mysqpi->get('glob'), \*STDOUT, 'glob - 3' );
ok( $mysqpi->set('glob'), 'glob - 4' );
is( $mysqpi->get('glob'), undef, 'glob - 5' );

# Test refs
ok( !$mysqpi->set( 'ref', 21 ), 'ref - 1' );
ok( $mysqpi->set( 'ref', \$rv ), 'ref - 2' );
is( $mysqpi->get('ref'), \$rv, 'ref - 3' );
ok( $mysqpi->set('ref'), 'ref - 4' );
is( $mysqpi->get('ref'), undef, 'ref - 5' );

# Test array
my @array = qw(foo bar);
my @rv;
ok( $mysqpi->set( 'array', @array ), 'array - 1' );
@rv = $mysqpi->get('array');
is( scalar @rv, 2,     'array - 2' );
is( $rv[0],     'foo', 'array - 3' );
ok( $mysqpi->set('array'), 'array - 4' );
@rv = $mysqpi->get('array');
is( scalar @rv, 0, 'array - 5' );

# Test hash
my %hash = ( foo => 'one', bar => 'two' );
my %rv;
ok( $mysqpi->set( 'hash', %hash ), 'hash - 1' );
%rv = $mysqpi->get('hash');
is( scalar keys %rv, 2, 'hash - 2' );
ok( exists $rv{foo},      'hash - 3' );
ok( $mysqpi->set('hash'), 'hash - 4' );
%rv = $mysqpi->get('hash');
is( scalar keys %rv, 0, 'hash - 5' );

# Test properties
my @props = $mysqpi->properties;
is( scalar @props, 8, 'property names - 1' );
ok( !grep({ $_ eq '2xpi' } @props), 'property names - 2' );
@props = $mysqpi->dump;
is( scalar @props, 10, 'property names - 3' );
ok( grep({ $_ eq '2xpi' } @props), 'property names - 4' );
ok( !grep({ $_ eq '3xpi' } @props), 'property names - 5' );
@props = $mypi->dump;
is( scalar @props, 3, 'property names - 6' );
ok( grep({ $_ eq '2xpi' } @props), 'property names - 7' );
ok( grep({ $_ eq '3xpi' } @props), 'property names - 8' );
