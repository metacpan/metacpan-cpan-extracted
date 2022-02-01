#!/usr/bin/env perl

use strict;
use warnings;

use App::CPAN::Get::Utils qw(process_module_name_and_version);

if (@ARGV < 1) {
        print STDERR "Usage: $0 module_name[\@module_version]\n";
        exit 1;
}
my $module_name_and_version = $ARGV[0];

my ($module_name, $module_version_range) = process_module_name_and_version($module_name_and_version);

print "Module string from input: $module_name_and_version\n";
print "Module name: $module_name\n";
if (defined $module_version_range) {
        print "Module version range: $module_version_range\n";
}

# Output for 'Module':
# Module string from input: Module
# Module name: Module

# Output for 'Module@1.23':
# Module string from input: Module@1.23
# Module name: Module
# Module version range: == 1.23