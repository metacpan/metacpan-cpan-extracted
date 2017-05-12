#!/usr/bin/perl

# Formal testing for Class::Default

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 20;

# Set up any needed globals
use vars qw{$cd $cdt};
BEGIN {
	$cd  = 'Class::Default';
	$cdt = 'Class::Default::Test1';
}





# Basic API existance
ok( Class::Default->can( '_self' ), "Class::Default->_self exists" );
ok( Class::Default->can( '_get_default' ), "Class::Default->_get_default exists" );
ok( Class::Default->can( '_create_default_object' ), "Class::Default->_create_default_object exists" );
ok( Class::Default::Test1->can( '_self' ), "Class::Default::Test1->_self exists" );
ok( Class::Default::Test1->can( '_get_default' ), "Class::Default::Test1->_get_default exists" );
ok( Class::Default::Test1->can( '_create_default_object' ),
	"Class::Default::Test1->_create_default_object exists" );

# Object gets created...
my $object = Class::Default::Test1->new();
isa_ok( $object, "Class::Default::Test1" );
isa_ok( $object, "Class::Default" );
ok( ! scalar keys %Class::Default::DEFAULT, "DEFAULT hash remains empty after normal object creation" );

# Default gets created
my $default1 = Class::Default::Test1->_get_default;
ok( $default1, "->_get_default returns something" );
ok( (ref $default1 eq $cdt), "->_get_default returns the correct object type" );
ok( scalar keys %Class::Default::DEFAULT, "DEFAULT hash contains something after _get_default" );
ok( (scalar keys %Class::Default::DEFAULT == 1), "DEFAULT hash contains only one thing after _get_default" );
ok( exists $Class::Default::DEFAULT{$cdt}, "DEFAULT hash contains the correct key after _get_Default" );
ok( "$Class::Default::DEFAULT{$cdt}" eq "$default1",
	"DEFAULT hash entry matches that returned" );

# Get another object and see if they match
my $default2 = Class::Default::Test1->_get_default;
ok( "$default1" eq "$default2", "Second object matches the first object" );

# Check the response of a typical method as compared to the static
ok( $object->hash eq "$object", "Result of basic object method matchs" );
ok( Class::Default::Test1->hash eq "$default1", "Result of basic static method matchs" );

# Check the result of the _class method
ok( Class::Default::Test1->class eq 'Class::Default::Test1', "Static ->_class returns the class" );
ok( $default1->class eq 'Class::Default::Test1', "Object ->_class returns the class" );






# Define the testing package
package Class::Default::Test1;

use Class::Default ();
BEGIN {
	@Class::Default::Test1::ISA = 'Class::Default';
}

sub new {
	my $class = shift;
	my $self = {
		name => undef,
		};
	bless $self, $class;
}

sub setName {
	my $self = shift->_self;
	my $value = shift;
	$self->{name} = $value;
	1;
}
sub getName {
	my $self = shift->_self;
	$self->{name};
}

sub hash {
	my $self = shift->_self;
	"$self";
}

sub class {
	my $class = shift->_class;
	$class;
}

1;
