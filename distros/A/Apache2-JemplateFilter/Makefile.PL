use strict;
use warnings;
use ExtUtils::MakeMaker;

use mod_perl2();
use ModPerl::MM ();
use Apache::TestMM qw(test clean);
use Apache::TestRunPerl ();

Apache::TestMM::filter_args();

# provide the test harness
Apache::TestRunPerl->generate_script();

# now, write out the Makefile
ModPerl::MM::WriteMakefile(
    NAME          => 'Apache2::JemplateFilter',
    AUTHOR        => 'Fujiwara Shunichiro <fujiwara@topicmaker.com>',
    VERSION_FROM  => 'lib/Apache2/JemplateFilter.pm',
    ABSTRACT_FROM => 'lib/Apache2/JemplateFilter.pm',
    PL_FILES      => {},
    VERSION       => '0',
    PREREQ_PM     => {
        'Test::More' => 0,
        'Jemplate'   => '0.12',
        'mod_perl2'  => 0,
        'APR::Finfo' => 0,
    },
    DIST  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    CLEAN => { FILES    => 'Apache2-JemplateFilter-*' },
);

