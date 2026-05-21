######################################################################
#
# 04_sorting.pl - CSV::LINQ sorting examples
#
######################################################################
use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings;
local $^W = 1;

BEGIN { pop @INC if $INC[-1] eq '.' }

use CSV::LINQ;

my @employees = (
    { name => 'Carol', dept => 'Sales',   salary => 75000, years => 8 },
    { name => 'Alice', dept => 'Eng',     salary => 95000, years => 5 },
    { name => 'Dave',  dept => 'Sales',   salary => 68000, years => 3 },
    { name => 'Bob',   dept => 'Eng',     salary => 88000, years => 7 },
    { name => 'Eve',   dept => 'HR',      salary => 72000, years => 6 },
);

# OrderByStr
print "=== OrderByStr (name) ===\n";
CSV::LINQ->From([@employees])
    ->OrderByStr(sub { $_[0]{name} })
    ->ForEach(sub { printf "  %-6s %s\n", $_[0]{name}, $_[0]{dept} });

# OrderByNumDescending
print "\n=== OrderByNumDescending (salary) ===\n";
CSV::LINQ->From([@employees])
    ->OrderByNumDescending(sub { $_[0]{salary} })
    ->ForEach(sub { printf "  %-6s %d\n", $_[0]{name}, $_[0]{salary} });

# ThenBy multi-key sort
print "\n=== OrderByStr(dept) + ThenByNumDescending(salary) ===\n";
CSV::LINQ->From([@employees])
    ->OrderByStr(sub { $_[0]{dept} })
    ->ThenByNumDescending(sub { $_[0]{salary} })
    ->ForEach(sub { printf "  %-5s %-6s %d\n", $_[0]{dept}, $_[0]{name}, $_[0]{salary} });

# Reverse
print "\n=== Reverse ===\n";
CSV::LINQ->From([@employees])
    ->OrderByStr(sub { $_[0]{name} })
    ->Reverse()
    ->ForEach(sub { print "  $_[0]{name}\n" });
