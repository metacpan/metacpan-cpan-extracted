#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 4;

# Test set 1 -- can we load the library?
require_ok 'CPANPLUS::Shell::Default::Plugins::Prereqs' 
    or die 'Could not find plugin';

# Is the plugin exposed?
my %plugins = CPANPLUS::Shell::Default::Plugins::Prereqs::plugins();
ok grep( /prereqs/, keys %plugins), 'Exposes the prereq plugin';

my $sub = $plugins{prereqs};
my $help_sub = "${sub}_help";

# Did we implment the help and plugin routine
can_ok 'CPANPLUS::Shell::Default::Plugins::Prereqs', $sub, $help_sub;

# Are we getting the correct help text
my $full_help_sub = 'CPANPLUS::Shell::Default::Plugins::Prereqs::' . $help_sub;

no strict;
like $full_help_sub->(), qr/Install missing prereqs/,
     'Returns plugin documentation';

