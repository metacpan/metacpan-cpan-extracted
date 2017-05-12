use strict;
use warnings;
use ExtUtils::MakeMaker;

use Apache::TestMM  qw(test clean);

Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

WriteMakefile(
    NAME                => 'Apache2::FixRemote',
    AUTHOR              => 'Dorian Taylor <dorian@cpan.org>',
    VERSION_FROM        => 'lib/Apache2/FixRemote.pm',
    ABSTRACT_FROM       => 'lib/Apache2/FixRemote.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'mod_perl2'     => 2.0,
        'Apache::Test'  => 1.25,
        'Test::More'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Apache2-FixRemote-* t/TEST' },
);
