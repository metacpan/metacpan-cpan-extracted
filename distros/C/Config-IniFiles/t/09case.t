#!/usr/bin/perl


use strict;
use warnings;

use Test::More tests => 14;

use List::Util qw(first);

use Config::IniFiles;

use lib "./t/lib";

use Config::IniFiles::TestPaths;


my $ini;
my @members;
my $string;

# CASE SENSITIVE CHECKS

# Test 1
# newval and val - Check that correct case brings back the correct value
$ini = Config::IniFiles->new;
$ini->newval("Section", "PaRaMeTeR", "Mixed Case");
$ini->newval("Section", "Parameter", "Title Case");
my $mixed_case = $ini->val("Section", "PaRaMeTeR");
my $title_case = $ini->val("Section", "Parameter");

# TEST
is ($mixed_case, "Mixed Case", "correct case - Mixed Case");

# TEST
is ($title_case, "Title Case", "correct case - Title Case");

# Test 2
# Sections
# Set up a controlled environment
$ini = Config::IniFiles->new;
$ini->newval("Section", "Parameter", "Value");
$ini->newval("section", "parameter", "value");

# TEST
is (scalar($ini->Sections()), 2, "2 sections");

# Test 3
# Deleting values
# Set up a controlled environment

$ini = Config::IniFiles->new;

$ini->newval("Section", "Parameter", "Title Case");
$ini->newval("Section", "parameter", "lower case");
$ini->newval("Section", "PARAMETER", "UPPER CASE");

my $delete_case_check_pass = 1;

@members = $ini->Parameters("Section");

# TEST
is (scalar(@members), 3, "Delete check pass - 3 members");

$ini->delval("Section", "PARAMETER");

@members = $ini->Parameters("Section");

# TEST
is (scalar(@members), 2 , "Delete check pass after delete - 2 members");

# TEST
ok (first { index($_, "Parameter") >= 0 } @members, "Parameter exists");

# TEST
ok (first { index($_, "parameter") >= 0 } @members, "parameter exists");

{
    # Test 4
    # Parameters
    $ini = Config::IniFiles->new;
    $ini->newval("Section", "PaRaMeTeR", "Mixed Case");
    $ini->newval("Section", "Parameter", "Title Case");
    $ini->newval("SECTION", "Parameter", "N/A");
    my @parameter_list = $ini->Parameters("SECTION");
    my $parameters_case_check_pass = 1;
    $parameters_case_check_pass = 0 unless scalar(@parameter_list) == 1;
    $parameters_case_check_pass = 0 unless $parameter_list[0] eq "Parameter";
    @parameter_list = $ini->Parameters("Section");
    $parameters_case_check_pass = 0 unless scalar(@parameter_list) == 2;
    my $parameters = join " ", @parameter_list;
    $parameters_case_check_pass = 0 unless ($parameters =~ /PaRaMeTeR/);
    $parameters_case_check_pass = 0 unless ($parameters =~ /Parameter/);
    # TEST
    ok ($parameters_case_check_pass, "Parameters case check pass");
}

{
    # Test 5
    # Case sensitive handling of groups
    # Set up a controlled environment
    $ini = Config::IniFiles->new;
    $ini->newval("interface foo", "parameter", "foo");
    $ini->newval("interface bar", "parameter", "bar");
    $ini->newval("INTERFACE blurgle", "parameter", "flurgle");
    my $group_case_check_pass = 1;
    # We should have two groups - "interface" and "Interface"
    my $group_case_count = $ini->Groups();
    $group_case_check_pass = 0 unless ($group_case_count == 2);
    # We don't want to get the "interface" entries when we use the wrong case
    @members = $ini->GroupMembers("Interface");
    $group_case_check_pass = 0 unless (scalar(@members) == 0);
    # We *do* want to get the "interface" entries when we use the right case
    @members = $ini->GroupMembers("interface");
    $group_case_check_pass = 0 unless (scalar(@members) == 2);
    $group_case_check_pass = 0 unless (grep {/interface foo/} @members);
    $group_case_check_pass = 0 unless (grep {/interface bar/} @members);
    # TEST
    ok ($group_case_check_pass, "Group cae check pass");
}



# CASE INSENSITIVE CHECKS

{
    # Test 6
    # newval - Check that case-insensitive version returns one value
    $ini = Config::IniFiles->new( -nocase => "1" );
    $ini->newval("Section", "PaRaMeTeR", "Mixed Case");
    $ini->newval("Section", "Parameter", "Title Case");
    my @values = $ini->val("Section", "parameter");

    # TEST
    is_deeply (\@values, ["Title Case"],
        "case-insensitive version returns one value"
    );
}

# Test 7
# Case insensitive handling of groups
$ini = Config::IniFiles->new( -file =>t_file('test.ini'), -nocase => 1 );
# TEST
is_deeply(
    [$ini->GroupMembers("GrOuP")],
    ["group member one", "group member two", "group member three"]
);

$ini = Config::IniFiles->new( -file => t_file("test.ini"), -default => 'test1', -nocase => 1 );
$ini->SetFileName(t_file("test09.ini"));

# test 8
# Case insensitivity in parameters

# TEST
is( scalar($ini->val('test2', 'FOUR')),
    'value4',
    "Case insensitivity in parameters",
);

# test 9
# Case insensitivity in sections

# TEST
is ( scalar($ini->val('TEST2', 'four')),
    'value4',
    "Case insensitivity in sections",
);


# TEST
is (
    scalar($ini->val('mixedcasesect', 'mixedcaseparam')),
    'MixedCaseVal',
    "Mixed case val.",
);

