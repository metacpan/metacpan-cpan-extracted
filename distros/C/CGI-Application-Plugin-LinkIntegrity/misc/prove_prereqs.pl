#!/usr/bin/perl

=pod

This script allows you to run the test suite, simulating the absense of
a particular set of Perl modules, even if they are installed on your
system.

To run the test suite multiple times in a row, each tie multiple times
(each with a different selection of absent modules), run:

    $ perl misc/prove_prereqs.pl t/*.t

To add a new set of absent modules, make a subdir under t/prereq_scenarios, and
add a dummy perl module for every module you want to skip.  This file
should be empty.  For instance if you wanted to simulate the absense of
XML::Complicated and Config::Obscure, you would do the following:

    $ mkdir t/prereq_scenarios/skip_xc+co
    $ mkdir t/prereq_scenarios/skip_xc+co/XML
    $ touch t/prereq_scenarios/skip_xc+co/XML/Complicated.pm
    $ mkdir t/prereq_scenarios/skip_xc+co/Config
    $ touch t/prereq_scenarios/skip_xc+co/Config/Obscure.pm

Finally, add this directory to the @Scenarios array below.

=cut

my @Scenarios = qw(
    t/prereq_scenarios/cgi-3.10
    t/prereq_scenarios/cgi-3.11
    t/prereq_scenarios/cgi-3.20
);

###################################################################
use strict;
use File::Find;

unless (@ARGV) {
    die "Usage: $0 [args to prove]\n";
}

my %Skip_Modules;
my $errors;
foreach my $prereq_scenarios_dir (@Scenarios) {
    if (!-d $prereq_scenarios_dir) {
        $errors = 1;
        warn "Skip lib dir does not exist: $prereq_scenarios_dir\n";
        next;
    }
    my @modules;
    find(sub {
        return unless -f;
        my $dir = "$File::Find::dir/$_";
        $dir =~ s/^\Q$prereq_scenarios_dir\E//;
        $dir =~ s/\.pm$//;
        $dir =~ s{^/}{};
        $dir =~ s{/}{::}g;
        push @modules, $dir;
    }, $prereq_scenarios_dir);
    $Skip_Modules{$prereq_scenarios_dir} = \@modules;
}
die "Terminating." if $errors;

foreach my $prereq_scenarios_dir (@Scenarios) {
    my $modules = join ', ', sort @{ $Skip_Modules{$prereq_scenarios_dir} };
    $modules ||= 'none';
    print "\n##############################################################\n";
    print "Running tests.  Old (or absent) modules in this scenario:\n";
    print "$modules\n";
    my @prove_command = ('prove', '-Ilib', "-I$prereq_scenarios_dir", @ARGV);
    system(@prove_command) && do {
        die <<EOF;
##############################################################
One or more tests failed.  The old or absent modules were:
    $modules

The command was:
    @prove_command

Terminating.
##############################################################
EOF
    };
}

