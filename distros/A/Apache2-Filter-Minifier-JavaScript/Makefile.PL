use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

###############################################################################
# Check for presence of Apache::Test.
#
# If its not installed, we're going to abort the build entirely as we'll be
# unable to run our test suites (which need to be set up -NOW- and not when you
# run "make").  The joys of "configure requirements"...
#
# Fortunately, Apache::Test comes -with- mod_perl2, so anyone who actually
# wants to use this module probably already has it installed.  If not, we abort
# -before- we write out "Makefile", so that CPAN(PLUS) won't file CPAN Tester
# "failure" reports; even if they were to install Apache::Test as a dependency
# we'd still fail our tests... its a -configuration-requirement-.
my $HAVE_APACHE_TEST = eval {
    require Apache::TestMM;
    require Apache::TestRunPerl;
    # import test harness over-rides
    Apache::TestMM->import(qw( test clean ));
    # configure tests based on incoming args
    Apache::TestMM::filter_args();
    # create the test driver script
    Apache::TestRunPerl->generate_script();
};
unless ($HAVE_APACHE_TEST) {
    # show warning
    warn q{
###
### This module requires that you have Apache::Test installed -before-
### you run "perl Makefile.PL", so that test suites can be properly
### configured.
###
### Please go install Apache::Test and re-run "perl Makefile.PL".
###
};
    # abort, before writing a Makefile
    exit 0;
}

###############################################################################
# Write Makefile
WriteMakefile(
    'NAME'              => 'Apache2::Filter::Minifier::JavaScript',
    'VERSION_FROM'      => 'lib/Apache2/Filter/Minifier/JavaScript.pm',
    'AUTHOR'            => 'Graham TerMarsch (cpan@howlingfrog.com)',
    'PREREQ_PM'         => {
        'JavaScript::Minifier'  => 0,
        'mod_perl2'             => 2.0,
        'Time::HiRes'           => 0,
        # really a configuration requirement, but EU::MM doesn't support that
        'Apache::Test'          => 1.12,
        },
    );
