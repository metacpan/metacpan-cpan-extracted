#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use Config::IniFiles;

use lib "./t/lib";

use Config::IniFiles::TestPaths;

my $ini = Config::IniFiles->new( -file => t_file('test.ini') );
my $members;

# Test 1
# Group members with spaces

# TEST
is_deeply(
    [$ini->GroupMembers("group")],
    ["group member one", "group member two", "group member three"],
    "Group members with spaces",
);

# Test 2
# Adding a new section - updating groups list

# Test 3
# Deleting a section - updating groups list
