#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 19;

use Config::IniFiles;

use lib "./t/lib";

use Config::IniFiles::TestPaths;

my %ini;
my ( $ini, $value );
my (@value);

# Get files from the 't' directory, portably
t_unlink("test05.ini");

# Test 1
# Tying a hash.
# TEST
ok(
    (
        tie %ini, 'Config::IniFiles',
        ( -file => t_file("test.ini"), -default => 'test1', -nocase => 1 )
    ),
    "Tie to test.ini was successful."
);

tied(%ini)->SetFileName( t_file("test05.ini") );
tied(%ini)->SetWriteMode("0666");

# Test 2
# Retrieve scalar value
$value = $ini{test1}{one};

# TEST
is( $value, 'value1', "Value is value1" );

# Test 3
# Retrieve array reference
$value = $ini{test1}{mult};

# TEST
is( ref($value), 'ARRAY', "test1/mult is an array." );

# Test 4
# Creating a scalar value using tied hash
$ini{'test2'}{'seven'} = 'value7';
tied(%ini)->RewriteConfig;
tied(%ini)->ReadConfig;
$value = $ini{'test2'}{'seven'};

# TEST
is( $value, 'value7', "test2/seven is value7" );

# Test 5
# Deleting a scalar value using tied hash
delete $ini{test2}{seven};
tied(%ini)->RewriteConfig;
tied(%ini)->ReadConfig;
$value = '';
$value = $ini{test2}{seven};

# TEST
ok( !defined($value), "test2/seven does not exist" );

# Test 6
# Testing default values using tied hash
# TEST
is( $ini{test2}{three}, 'value3', "test2/three is equal to value3" );

# Test 7
# Case insensitivity in a hash parameter
# TEST
is( $ini{test2}{FOUR}, 'value4', "test2/FOUR is value4 - case insensitivity" );

# Test 8
# Case insensitivity in a hash section
# TEST
is( $ini{TEST2}{four}, 'value4', "TEST2/four is value4 - case insensitivity" );

# Test 9
# Listing section names using keys
$ini = Config::IniFiles->new(
    -file    => t_file("test.ini"),
    -default => 'test1',
    -nocase  => 1
);
$ini->SetFileName( t_file("test05b.ini") );
{
    my @S1 = $ini->Sections;
    my @S2 = keys %ini;

    # TEST
    is_deeply( \@S1, \@S2, "All sections OK." );
}

# Test 10
# Listing parameter names using keys
{
    my @S1 = sort { $a cmp $b } $ini->Parameters('test1');
    my @S2 = sort { $a cmp $b } keys %{ $ini{test1} };

    # TEST
    is_deeply( \@S1, \@S2, "All keys of section 'test1' are OK." );
}

# Test 11
# Copying a section using tied hash
my %bak = %{ $ini{test2} };

# TEST
is( $bak{six}, "value6", "Copied value is OK." );

# Test 12
# Deleting a whole section using tied hash
delete $ini{test2};
$value = $ini{test2};

# TEST
ok( ( !$value ), "test2 section was deleted" );

# Test 13
# Creating a section and parameters using a hash
$ini{newsect} = {};
%{ $ini{newsect} } = %bak;
$value = $ini{newsect}{four} || '';

# TEST
is( $value, 'value4', "Creating a section and parameters using a hash" );

# Test 14
# Checking use of default values for newly created section
$value = $ini{newsect}{one};

# TEST
is( $value, "value1",
    "Checking use of default values for newly created section" );

# Test 15
# print "Store new section in hash ........ ";
tied(%ini)->RewriteConfig;
tied(%ini)->ReadConfig;
$value = $ini{newsect}{four};

# TEST
is( $value, 'value4', "Store new section in hash" );

# Test 16
# Writing 2 line multivalue and returning it
$ini{newsect} = {};
$ini{test1}{multi_2} = [ 'line 1', 'line 2' ];
tied(%ini)->RewriteConfig;
tied(%ini)->ReadConfig;
@value = @{ $ini{test1}{multi_2} };

# TEST
is_deeply(
    \@value,
    [ 'line 1', 'line 2' ],
    "Writing 2 line multivalue and returning it"
);

# Test 17
# Getting a default value not in the file
tie %ini, 'Config::IniFiles',
    ( -file => t_file("test.ini"), -default => 'default', -nocase => 1 );
$ini{default}{cassius} = 'clay';
$value = $ini{test1}{cassius};

# TEST
is( $value, 'clay', "Getting a default value not in the file" );

# Test 18
# Setting value to number of elements in array
my @thing = ( "one", "two", "three" );
$ini{newsect}{five} = @thing;
$value = $ini{newsect}{five};

# TEST
is( $value, 3, "Setting value to number of elements in array" );

# Test 19
# Setting value to number of elements in array
@thing              = ("one");
$ini{newsect}{five} = @thing;
$value              = $ini{newsect}{five};

# TEST
is( $value, 1, "Testing that value is 1." );

# Clean up when we're done
t_unlink("test05.ini");

