#!/usr/bin/perl

=pod

This script allows you to run the test suite against old versions of
prerequisite modules, or absent prerequisites.

It is able to simulate the absense of a particular set of Perl modules,
even if they are installed on your system.

To run the test suite multiple times in a row, each tie multiple times
(each with a different selection of absent modules), run:

    $ perl misc/prove_prereqs.pl t/*.t

To add a new set of absent modules, make a subdir under t/skip_lib, and
add a dummy perl module for every module you want to skip.  This file
should be empty.  For instance if you wanted to simulate the absense of
Text::Template and Text::TagTemplate, you would do the following:

    $ mkdir t/prereq_scenarios/old_autorunmode
    $ mkdir t/prereq_scenarios/old_cgiapp

Finally, add this directory to the @Scenarios array below.

=cut

my @Scenarios = qw(
    t/prereq_scenarios/old_autorunmode-0.08
    t/prereq_scenarios/old_autorunmode-0.09
    t/prereq_scenarios/old_autorunmode-0.10
    t/prereq_scenarios/old_cgiapp
    t/prereq_scenarios/normal
);

###################################################################
use strict;
use File::Find;

unless (@ARGV) {
    die "Usage: $0 [args to prove]\n";
}

my %Skip_Modules;
my $errors;
foreach my $skip_lib_dir (@Scenarios) {
    if (!-d $skip_lib_dir) {
        $errors = 1;
        warn "Skip lib dir does not exist: $skip_lib_dir\n";
        next;
    }
    my @modules;
    find(sub {
        return unless -f;
        my $dir = "$File::Find::dir/$_";
        $dir =~ s/^\Q$skip_lib_dir\E//;
        $dir =~ s/\.pm$//;
        $dir =~ s{^/}{};
        $dir =~ s{/}{::}g;
        push @modules, $dir;
    }, $skip_lib_dir);
    $Skip_Modules{$skip_lib_dir} = \@modules;
}
die "Terminating." if $errors;

foreach my $skip_lib_dir (@Scenarios) {
    my $modules = join ', ', sort @{ $Skip_Modules{$skip_lib_dir} };
    $modules ||= 'none';
    print "\n##############################################################\n";
    print "Running tests.  Special Modules: $modules\n";
    my @prove_command = ('prove', '-Ilib', "-I$skip_lib_dir", @ARGV);
    system(@prove_command) && do {
        die <<EOF;
##############################################################
One or more tests failed while skipping these modules:
    $modules

The command was:
    @prove_command

Terminating.
##############################################################
EOF
    };
}


