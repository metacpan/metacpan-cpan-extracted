#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use Config::IniFiles;

use lib "./t/lib";

use Config::IniFiles::TestPaths;

my ( $ini, $value );

t_unlink("test07.ini");

# Test 1
# Multiple equals in a parameter - should split on the first
$ini = Config::IniFiles->new( -file => t_file('test.ini') );

# TEST
is(
    scalar( $ini->val( 'test7', 'criterion' ) ),
    'price <= maximum',
    "Multiple equals in a parameter - should split on the first",
);

# Test 2
# Parameters whose name is a substring of existing parameters should be loaded
$value = $ini->val( 'substring', 'boot' );

# TEST
is( $value, 'smarty',
"Parameters whose name is a substring of existing parameters should be loaded"
);

# test 3
# See if default option works
$ini = Config::IniFiles->new(
    -file    => t_file("test.ini"),
    -default => 'test1',
    -nocase  => 1
);
$ini->SetFileName( t_file("test07.ini") );
$ini->SetWriteMode("0666");

# TEST
ok( defined($ini), "default option works - \$ini works." );

# TEST
is( scalar( $ini->val( 'test2', 'three' ) ),
    'value3', "default option works - ->val" );

# Test 4
# Check that Config::IniFiles respects RO permission on original INI file
$ini->WriteConfig( t_file("test07.ini") );
chmod 0444, t_file("test07.ini");

SKIP:
{
    if ( -w t_file("test07.ini") )
    {
        skip( 'RO Permissions not settable.', 1 );
    }
    else
    {
        $ini->setval( 'test2', 'three', 'should not be here' );
        $value = $ini->WriteConfig( t_file("test07.ini") );
        warn "Value is $value!" if ( defined $value );

        # TEST
        ok( !defined($value), "Value is undefined." );
    }    # end if
}

# Clean up when we're done
t_unlink("test07.ini");

