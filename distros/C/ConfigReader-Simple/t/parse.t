#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';
use Test::Output;

use File::Spec::Functions qw(catfile);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my $class  = 'ConfigReader::Simple';
my $method = 'parse';

use_ok( $class );
can_ok( $class, $method );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try it with a missing file, Warn off, Die off
# should return nothing, but with no warning
{
my $missing = 'a/b/c';
ok( ! -e $missing, "Missing file is actually missing" );

local $ConfigReader::Simple::Warn = 0;
local $ConfigReader::Simple::Die  = 0;

my $mock = bless {}, $class;
isa_ok( $mock, $class );
can_ok( $mock, $method );

ok( ! $mock->parse( $missing ), 
	'parse fails with missing file, $Warn and $Die off' );
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try it with a missing file, Warn off, Die on
# should return nothing, but with no warning
{
my $missing = 'a/b/c';
ok( ! -e $missing, "Missing file is actually missing" );

local $ConfigReader::Simple::Warn = 0;
local $ConfigReader::Simple::Die  = 1;

my $mock = bless {}, $class;
isa_ok( $mock, $class );
can_ok( $mock, $method );

ok( ! $mock->parse( $missing ), 
	'parse fails with missing file, $Warn and $Die off' );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try it with a missing file, Warn on, Die off
# should return nothing, but with a warning
{
my $missing = 'a/b/c';
ok( ! -e $missing, "Missing file is actually missing" );

local $ConfigReader::Simple::Warn = 1;
local $ConfigReader::Simple::Die  = 0;
local $SIG{__WARN__} = sub { print STDERR @_ };

my $mock = bless {}, $class;
isa_ok( $mock, $class );
can_ok( $mock, $method );

stderr_like
	{ $mock->parse( $missing ) }
	qr/Could not open/,
	"parse fails with missing file";
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try it with a missing file, Warn on, Die on
# should return nothing, but with a warning
{
my $missing = 'a/b/c';
ok( ! -e $missing, "Missing file is actually missing" );

local $ConfigReader::Simple::Warn = 1;
local $ConfigReader::Simple::Die  = 1;
local $SIG{__WARN__} = sub { print STDERR @_ };

my $mock = bless {}, $class;
isa_ok( $mock, $class );
can_ok( $mock, $method );

stderr_like
	{ $mock->parse( $missing ) }
	qr/Could not open/,
	"parse fails with missing file";
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try it with a file that ends on a continuation line that is uncontinued
# should still work
{
my $file = catfile( qw(t eof.config) );
ok( -e $file, "File exists" );

my $mock = bless {}, $class;
isa_ok( $mock, $class );
can_ok( $mock, $method );

ok( $mock->parse( $file ), 'parsing file is just fine' );
}


