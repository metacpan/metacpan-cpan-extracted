use strict;
use warnings;
use ExtUtils::MakeMaker;

use Apache::TestMM qw(test clean);

our @SCRIPTS = qw(t/TEST);

Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

WriteMakefile(
    NAME                => 'Apache2::SQLRequest',
    AUTHOR              => 'dorian taylor <dorian@icrystal.com>',
    VERSION_FROM        => 'lib/Apache2/SQLRequest.pm',
    ABSTRACT_FROM       => 'lib/Apache2/SQLRequest.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'mod_perl2'     => 1.99,
        'Apache::Test'  => 0,
        'Test::More'    => 0,
        'DBI'           => 1.45,
        #'Clone'         => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { 
            FILES => "Apache2-SQLRequest-* " . join(' ', @SCRIPTS)},
);
