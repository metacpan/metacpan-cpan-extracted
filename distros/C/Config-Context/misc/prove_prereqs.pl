#!/usr/bin/perl

=pod

This script allows you to run the test suite, simulating the absense of
a particular set of Perl modules, even if they are installed on your
system.

To run the test suite multiple times in a row, each tie multiple times
(each with a different selection of absent modules), run:

    $ perl misc/prove_without_modules.pl t/*.t

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

Note that this technique only works because of how Config::Context
and its test suite are written.  The Config::Context drivers each
provide a method returning the list of modules they depend on.  Each
test script gets the list of modules and attempts to load them:

    my @required_modules = $driver_module->config_modules;

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

my @Scenarios = qw(
    t/prereq_scenarios/skip_config_general
    t/prereq_scenarios/skip_config_scoped
    t/prereq_scenarios/skip_xml_simple
    t/prereq_scenarios/skip_xml_simple+config_scoped
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


__END__
if [ "$*" == "" ]; then
    echo Usage: prove_without_modules [args to prove]
    exit 255
fi

echo
echo "##############################################################"
echo Running tests with all templating modules installed
if ! prove -Ilib $*; then
    echo
    echo There were errors!  Terminating.
    exit;
fi

echo
echo "##############################################################"
echo Running tests with HTML::Template not installed
if ! prove -It/prereq_scenarios/skip_ht -Ilib $*; then
    echo
    echo There were errors!  Terminating.
    exit;
fi

echo
echo "##############################################################"
echo Running tests with HTML::Template::Pluggable not installed
if ! prove -It/prereq_scenarios/skip_htp -Ilib $*; then
    echo
    echo There were errors!  Terminating.
    exit;
fi

echo
echo "##############################################################"
echo Running tests with HTML::Template::Expr not installed
if ! prove -It/prereq_scenarios/skip_hte -Ilib $*; then
    echo
    echo There were errors!  Terminating.
    exit;
fi

echo
echo "##############################################################"
echo Running tests with Template not installed
if ! prove -It/prereq_scenarios/skip_tt -Ilib $*; then
    echo
    echo There were errors!  Terminating.
    exit;
fi

echo
echo "##############################################################"
echo Running tests with Petal not installed
if ! prove -It/prereq_scenarios/skip_petal -Ilib $*; then
    echo
    echo There were errors!  Terminating.
    exit;
fi

echo
echo "##############################################################"
echo Running tests with no templating modules installed
if ! prove -It/prereq_scenarios/skip_ht+hte+htp+petal+template -Ilib $*; then
    echo
    echo There were errors!  Terminating.
    exit;
fi

echo
echo "##############################################################"
echo Running tests with only HTML::Template installed
if ! prove -It/prereq_scenarios/skip_hte+htp+petal+tt -Ilib $*; then
    echo
    echo There were errors!  Terminating.
    exit;
fi
