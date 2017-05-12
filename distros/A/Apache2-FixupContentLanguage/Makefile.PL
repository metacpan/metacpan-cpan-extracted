use strict;
use warnings;
use ExtUtils::MakeMaker;

use Apache::TestMM  qw(test clean);

Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

WriteMakefile(
    NAME                => 'Apache2::FixupContentLanguage',
    AUTHOR              => 'dorian taylor <dorian@cpan.org>',
    VERSION_FROM        => 'lib/Apache2/FixupContentLanguage.pm',
    ABSTRACT_FROM       => 'lib/Apache2/FixupContentLanguage.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'mod_perl2'         => 1.999023,
        'Apache::Test'      => 1.24,
        'Apache2::DebugLog' => 0.03,
        'Test::More'        => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Apache2-FixupContentLanguage-* t/TEST' },
);
