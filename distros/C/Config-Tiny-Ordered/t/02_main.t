#!/usr/bin/perl -w

# Main testing script for Config::Tiny::Ordered

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use UNIVERSAL;
use Test::More tests => 24;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.02';
}



# Check their perl version
BEGIN {
	ok( $] >= 5.004, "Your perl is new enough" );
	use_ok('Config::Tiny::Ordered');
}
is( $Config::Tiny::Ordered::VERSION, $VERSION, 'Loaded correct version of Config::Tiny::Ordered' );

# Test trivial creation
my $Trivial = Config::Tiny::Ordered->new();
ok( $Trivial, '->new returns true' );
ok( ref $Trivial, '->new returns a reference' );
# Legitimate use of UNIVERSAL::isa
ok( UNIVERSAL::isa( $Trivial, 'HASH' ), '->new returns a hash reference' );
isa_ok( $Trivial, 'Config::Tiny::Ordered' );
ok( scalar keys %$Trivial == 0, '->new returns an empty object' );

# Try to read in a config
my $Config = Config::Tiny::Ordered->read( 'test.conf' );
ok( $Config, '->read returns true' );
ok( ref $Config, '->read returns a reference' );
# Legitimate use of UNIVERSAL::isa
ok( UNIVERSAL::isa( $Config, 'HASH' ), '->read returns a hash reference' );
isa_ok( $Config, 'Config::Tiny::Ordered' );

# Check the structure of the config
my $expected = {
	'_' => [
		{key => 'root', value => 'something'},
		],
	section => [
		{key => 'one', value => 'two'},
		{key => 'one', value => 'three'},
		{key => 'Foo', value => 'Bar'},
		{key => 'this', value => 'Your Mother!'},
		{key => 'blank', value => ''},
		],
	'Section Two' => [
		{key => 'something else', value => 'blah'},
		{key => 'remove', value => 'whitespace'},
		],
	};
bless $expected, 'Config::Tiny::Ordered';
is_deeply( $Config, $expected, 'Config structure matches expected' );

# Add some stuff to the trivial config

$Trivial->{_} = [ {key => 'root1', value => 'root2'} ];
$Trivial->{section} = [
	{key => 'foo', value => 'bar'},
	{key => 'this', value => 'that'},
	{key => 'blank', value => ''},
	];
$Trivial->{section2} = [
	{key => 'this little piggy', value => 'went to market'}
	];
my $string = <<END;
root1=root2

[section]
foo=bar
this=that
blank=

[section2]
this little piggy=went to market
END

# Test read_string
my $Read = Config::Tiny::Ordered->read_string( $string );
ok( $Read, '->read_string returns true' );
is_deeply( $Read, $Trivial, '->read_string returns expected value' );

END {
	# Clean up
	unlink 'test2.conf';
}





#####################################################################
# Bugs that happened we don't want to happen again

{
# Reading in an empty file, or a defined but zero length string, should yield
# a valid, but empty, object.
my $Empty = Config::Tiny::Ordered->read_string('');
isa_ok( $Empty, 'Config::Tiny::Ordered' );
is( scalar(keys %$Empty), 0, 'Config::Tiny::Ordered object from empty string, is empty' );
}



{
# A Section header like [ section ] doesn't end up at ->{' section '}.
# Trim off whitespace from the section header.
my $string = <<'END';
# The need to trim off whitespace makes a lot more sense
# when you are trying to maximise readability.
[ /path/to/file.txt ]
this=that

[ section2]
this=that

[section3 ]
this=that

END

my $Trim = Config::Tiny::Ordered->read_string($string);
isa_ok( $Trim, 'Config::Tiny::Ordered' );
ok( exists $Trim->{'/path/to/file.txt'}, 'First section created' );
is( $Trim->{'/path/to/file.txt'}->[0]{key}, 'this', 'First section created properly' );
ok( exists $Trim->{section2}, 'Second section created' );
is( $Trim->{section2}->[0]{value}, 'that', 'Second section created properly' );
ok( exists $Trim->{section3}, 'Third section created' );
is( $Trim->{section3}->[0]{key}, 'this', 'Third section created properly' );
}
