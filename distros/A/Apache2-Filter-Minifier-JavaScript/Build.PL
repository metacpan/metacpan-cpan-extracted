use 5.006;
use strict;
use warnings;
use Module::Build;

###############################################################################
# Check for presence of Apache::Test.
#
# If its not installed, we're going to abort the build entirely as we'll be
# unable to run our test suites (which need to be set up -NOW- and not when you
# run "./Build").  The joys of "configure requirements"...
#
# Fortunately, Apache::Test comes -with- mod_perl2, so anyone who actually
# wants to use this module probably already has it installed.  If not, we abort
# -before- we write out "Build", so that CPAN(PLUS) won't file CPAN Tester
# "failure" reports; even if they were to install Apache::Test as a dependency
# we'd still fail our tests... its a -configuration-requirement-.
my $HAVE_APACHE_TEST = eval {
        require Apache::TestMB
        };
unless ($HAVE_APACHE_TEST) {
    # show warning
    warn q{
###
### This module requires that you have Apache::Test installed -before-
### you run "perl Build.PL", so that test suites can be properly
### configured.
###
### Please go install Apache::Test and re-run "perl Build.PL".
###
};
    # abort, before writing Build script
    exit 0;
}

###############################################################################
# Packages we require at -configuration- time
our %configure_requires = (
    'Apache::Test'  => 1.12,
    );

###############################################################################
# Write Build script
my $build_pkg = $HAVE_APACHE_TEST
                    ? 'Apache::TestMB'
                    : 'Module::Build';
$build_pkg->new(
    'module_name'       => 'Apache2::Filter::Minifier::JavaScript',
    'license'           => 'perl',
    'dist_author'       => 'Graham TerMarsch (cpan@howlingfrog.com)',
    'requires'          => {
        'JavaScript::Minifier'  => 0,
        'mod_perl2'             => 2.0,
        'Time::HiRes'           => 0,
        'perl'                  => '5.6.0',
        },
    'recommends'        => {
        'JavaScript::Minifier::XS' => 0,
        },
    # add configuration requirements both to build_requires and to META.yml,
    # until M::B supports "configure_requires" directly.
    'build_requires'    => { %configure_requires },
    'meta_add'          => {
        'configure_requires' => { %configure_requires },
        },
    )->create_build_script();
