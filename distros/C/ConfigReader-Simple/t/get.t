#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

use File::Spec::Functions qw(catfile);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my $class  = 'ConfigReader::Simple';
my $method = 'get';

use_ok( $class );
can_ok( $class, $method );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my @Directives = qw( Test1 Test2 Test3 Test4 );
my $config = $class->new( "t/example.config", \@Directives );
isa_ok( $config, $class );

# get things that do exist
is( $config->get( 'Test3' ), 'foo', 'Test3 has right value' );
is( $config->Test3, 'foo' );

is( $config->get( 'Test2' ), 'Test 2 value', 'Test2 has right value' );
is( $config->Test2, 'Test 2 value' );

# get things that do exist, but look like false values to perl
is( $config->get( 'Zero' ), '0', 'Zero has right value as string' );
is( $config->get( 'Zero' ),  0,, 'Zero has right value as number' );
is( $config->get( 'Undef' ), '', 'Undef has right value (empty)'  );

# get long lines
is( $config->get( 'Test10' ), 'foo bar baz', 'Continuation line has right value');
is( $config->Test10, 'foo bar baz') ;

# get things that do not exist
# using get
my $value = not defined $config->get( 'Test' );
ok( $value, 'Test has no value with get()' );
$value = not defined $config->Test;
ok( $value, 'Test has no value with AUTOLOAD' );

$value = not defined $config->get( 'Test5' );
ok( $value, 'Test5 has no value with get()' );
$value = not defined $config->Test5;
ok( $value, 'Test5 has no value with AUTOLOAD' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # Now try it with multiple files
$config = $class->new_multiple(
	Files => [ qw( t/global.config t/example.config ) ] );
isa_ok( $config, $class );

# get things that do exist
is( $config->get( 'Test3' ), 'foo',
	'Test3 has right value with AUTOLOAD' );
is( $config->get( 'Scope' ), 'Global',
	'Scope has right value with AUTOLOAD' );
is( $config->get( 'Test2' ), 'Test 2 value',
	'Test2 has right value with AUTOLOAD' );
is( $config->get( 'Test10'), 'foo bar baz',
       'Test10 has right value with AUTOLOAD' );

# try it one at a time
{
my $config = $class->new( "t/example.config" );

is( $config->get( 'Test3' ), 'foo',
	'Test3 has right value with get(), before global' );
is( $config->get( 'Test2' ), 'Test 2 value',
	'Test2 has right value with get(), before global' );
is( $config->get( 'Test10' ), 'foo bar baz',
       'Test10 has right value with get), before global' );

my $global = catfile( qw( t global.config ) );
ok( -e $global, "$global exists" );
ok( $config->add_config_file( $global), "Added $global" );
is( $config->get( 'Scope' ), 'Global',
	"Scope has right value after adding $global" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # Now try it with multiple files with one missing
$config = $class->new_multiple(
	Files => [ qw( t/missing.config t/global.config ) ] );
isa_ok( $config, $class );

# get things that do exist
is( $config->get( 'Scope' ), 'Global',
	'Scope has right value with AUTOLOAD, missing file' );

# config should be undef
$config = eval {
	no strict 'refs';
	${ "${class}::Die" } = 1;
	$class->new_multiple(
		Files => [ qw( t/missing.config t/example.config ) ] );
	};
like( $@, qr|\QCould not open configuration file [t/missing.config]| );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # Now try it with a string
{
my $string = <<'STRING';
TestA Lear
TestB MacBeth
TestC Richard
STRING

$config = $class->new_string(
	Strings => [ \$string ] );
isa_ok( $config, $class );

is( $config->get( 'TestA' ), 'Lear',
	'TestA has right value (from string)' );
is( $config->get( 'TestB' ), 'MacBeth',
	'TestB has right value (from string)' );
is( $config->get( 'TestC' ), 'Richard',
	'TestC has right value (from string)' );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # Now try it with a string with a continuation line
{
my $string = <<'STRING';
TestA King \
Lear
TestB MacBeth
TestC Richard
STRING

$config = $class->new_string(
	Strings => [ \$string ] );
isa_ok( $config, $class );

is( $config->get( 'TestA' ), 'King Lear',
	'TestA has right value (from string)' );
is( $config->get( 'TestB' ), 'MacBeth',
	'TestB has right value (from string)' );
is( $config->get( 'TestC' ), 'Richard',
	'TestC has right value (from string)' );
}
