#!/usr/bin/perl

=pod

This script allows you to run the test suite, simulating the absense of
a particular set of Perl modules, even if they are installed on your
system.

To run the test suite multiple times in a row (each with a different 
selection of absent modules), run:

    $ perl misc/prove_prereqs.pl t/prereq_scenarios -Ilib t/

To add a new set of absent modules, make a subdir under t/prereq_scenarios, 
and add a dummy perl module for every module you want to skip.  This file
should be empty.  For instance if you wanted to simulate the absense of
Text::Template and Text::TagTemplate, you would do the following:

    $ mkdir t/prereq_scenarios/skip_tt+ttt
    $ mkdir t/prereq_scenarios/skip_tt+ttt/Text
    $ touch t/prereq_scenarios/skip_tt+ttt/Text/Template.pm
    $ touch t/prereq_scenarios/skip_tt+ttt/Text/TagTemplate.pm

Note that this technique only works because of how AnyTemplate and its
test suite are written.  The AnyTemplate drivers each provide a method
returning the list of modules they depend on.  Each test script gets the
list of modules and attempts to load them:

    my @required_modules = $driver_module->required_modules;

    foreach (@required_modules) {
        eval "require $_;";
        if ($@) {
            return;
        }
    }
    return 1;

If any of the modules fail to load, then the test script skips the tests
associated with that module.

=cut

use strict;
use warnings;

use File::Find;

unless (@ARGV > 1) {
    die "Usage: $0 [prereq_scenarios_dir] [args to prove]\n";
}

my $scenarios_dir = shift;

my %scenario_modules;
my $errors;

my @scenarios = grep { -d } <$scenarios_dir/*>;
foreach my $lib_dir (@scenarios) {
    if (!-d $lib_dir) {
        $errors = 1;
        warn "lib dir does not exist: $lib_dir\n";
        next;
    }
    my @modules;
    find(sub {
        return unless -f;
        my $dir = "$File::Find::dir/$_";
        $dir =~ s/^\Q$lib_dir\E//;
        $dir =~ s/\.pm$//;
        $dir =~ s{^/}{};
        $dir =~ s{/}{::}g;
        push @modules, $dir;
    }, $lib_dir);
    $scenario_modules{$lib_dir} = \@modules;
}
die "Terminating." if $errors;

foreach my $lib_dir (@scenarios) {
    my $modules = join ', ', sort @{ $scenario_modules{$lib_dir} };
    $modules ||= 'none';
    print "\n##############################################################\n";
    print "Running tests.  Old (or absent) modules in this scenario:\n";
    print "$modules\n";
    my @prove_command = ('prove', '-Ilib', "-I$lib_dir", @ARGV);
    system(@prove_command) && do {
        die <<EOF;
##############################################################
One or more tests failed in scenario $lib_dir.
The old or absent modules were:
    $modules

The command was:
    @prove_command

Terminating.
##############################################################
EOF
    };
}

