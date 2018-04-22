#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use Config::IniFiles;

use lib "./t/lib";

use Config::IniFiles::TestPaths;

my $ini = Config::IniFiles->new(
    -file       => t_file('php-compat.ini'),
    -php_compat => 1
) or die($!);

# Test 1
# strings enclosed with " are processed as double quoted string

# TEST
is_deeply(
    [ scalar( $ini->val( "group1", "val1" ) ) ],
    [q{str"ing}], "value with double-quotes in php_compat",
);

# Test 2
# strings enclosed with ' are processed as single quoted string

# TEST
is_deeply(
    [ $ini->val( "group1", "val2" ) ],
    [q{string}], "value with single-quotes in php_compat",
);

# Test 3
# ignore [] in val-Names

# TEST
is_deeply(
    [ $ini->val( "group2", "val1" ) ],
    [ 1, 2 ],
    "value with php array key in php_compat",
);
