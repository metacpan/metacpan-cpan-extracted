use 5.008;
use strict;
use warnings;
use Module::Build;

#
# this is pretty much borrowed from GTERMARS A2::Filter::Minifer::*'s Build.PL
#
#

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

my $build_pkg = $HAVE_APACHE_TEST 
    ? 'Apache::TestMB' : 'Module::Build';

my $configure_requires = {
    'Apache::Test' => '1.12',
};

my $build = $build_pkg->new(
    module_name         => 'Apache2::Filter::TagAware',
    license             => 'perl',
    create_readme       => 1,
    dist_author         => 'Adam Prime (adam.prime@utoronto.ca)',
    requires            => {
        'mod_perl2'     => 2.0,
    },
    build_requires      => $configure_requires,
#    'meta_add'          => {
#        'configure_requires' => $configure_requires,
#    },
);

$build->create_build_script();
