#!/usr/bin/perl

# Formal testing for Class::Inspector

# Do all the tests on ourself, since we know we will be loaded.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Class::Handle;
use Test::More tests => 36;

# Set up any needed globals
use vars qw{$ch $bad};
BEGIN {
	# To make maintaining this a little faster,
	# $CI is defined as Class::Inspector, and
	# $bad for a class we know doesn't exist.
	$ch = 'Class::Handle';
	$bad = 'Class::Handle::Nonexistant';
}




# Check the good/bad class name code
ok( $ch->new( $ch ), 'Constructor allows known valid' );
ok( $ch->new( $bad ), 'Constructor allows  correctly formatted, but not installed' );
ok( $ch->new( 'A::B::C::D::E' ), 'Constructor allows  long classes' );
ok( $ch->new( '::' ), 'Constructor allows main' );
ok( $ch->new( '::Blah' ), 'Constructor allows main aliased' );
ok( ! $ch->new(), 'Constructor fails for missing class' );
ok( ! $ch->new( '4teen' ), 'Constructor fails for number starting class' );
ok( ! $ch->new( 'Blah::%f' ), 'Constructor catches bad characters' );





# Create a dummy class for the remainder of the test
{
package Class::Handle::Dummy;

use strict;
use base 'Class::Handle';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '12.34';
}

sub dummy1 { 1; }
sub dummy2 { 2; }
sub dummy3 { 3; }
}





# Check a newly returned object
my $DUMMY = $ch->new( 'Class::Handle::Dummy' );
ok( UNIVERSAL::isa( $DUMMY, 'HASH' ), 'New object is a hash reference' );
isa_ok( $DUMMY, 'Class::Handle' );
ok( (scalar keys %$DUMMY == 1), 'Object contains only one key' );
ok( exists $DUMMY->{name}, "The key is named correctly" );
ok( $DUMMY->{name} eq 'Class::Handle::Dummy', "The contents of the key is correct" );
ok( $DUMMY->name eq 'Class::Handle::Dummy', "->name returns class name" );





# Check the UNIVERSAL related methods
is( $ch->VERSION, $Class::Handle::VERSION, '->VERSION in static context returns Class::Handle version' );
ok( $DUMMY->VERSION eq '12.34', '->VERSION in object context returns handle classes version' );
ok( $ch->isa( 'UNIVERSAL' ), 'Static ->isa works' );
ok( $DUMMY->isa( 'Class::Handle::Dummy' ), 'Object ->isa works' );
ok( $ch->can( 'new' ), 'Static ->can works' );
ok( $DUMMY->can( 'dummy1' ), 'Object ->can works' );





# Check the Class::Inspector related methods
my $CI  = Class::Handle->new( 'Class::Inspector' );
my $bad = Class::Handle->new( 'Class::Handle::Nonexistant' );

ok( $CI->loaded, "->loaded detects loaded" );
ok( ! $bad->loaded, "->loaded detects not loaded" );
my $filename = $CI->filename;
is( $filename, File::Spec->catfile( 'Class', 'Inspector.pm' ), "->filename works correctly" );
ok( -f $CI->loaded_filename,
	"->loaded_filename works" );
ok( -f $CI->resolved_filename,
	"->resolved_filename works" );
ok( $CI->installed, "->installed detects installed" );
ok( ! $bad->installed, "->installed detects not installed" );
my $functions = $CI->functions;
ok( (ref($functions) eq 'ARRAY'
	and $functions->[0] eq '_class'
	and scalar @$functions >= 14),
	"->functions works correctly" );
ok( ! $bad->functions, "->functions fails correctly" );
$functions = $CI->function_refs;
ok( (ref($functions) eq 'ARRAY'
	and ref $functions->[0]
	and ref($functions->[0]) eq 'CODE'
	and scalar @$functions >= 14),
	"->function_refs works correctly" );
ok( ! $bad->function_refs, "->function_refs fails correctly" );
ok( $CI->function_exists( 'installed' ),
	"->function_exists detects function that exists" );
ok( ! $CI->function_exists('nsfladf' ),
	"->function_exists fails for bad function" );
ok( ! $CI->function_exists,
	"->function_exists fails for missing function" );

my $CH = $ch->new( $ch );
isa_ok( $CH, $ch );
my $subclasses = $CH->subclasses;
is_deeply( $subclasses, [ 'Class::Handle::Dummy' ],
	'->subclasses returns as expected' );





# Tests for Class::ISA related methods
# missing, ugh
