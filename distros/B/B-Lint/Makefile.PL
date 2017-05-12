require 5.006000;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'B::Lint',
    AUTHOR        => 'Joshua ben Jore <jjore@cpan.org>',
    VERSION_FROM  => 'lib/B/Lint.pm',
    ABSTRACT_FROM => 'lib/B/Lint.pm',
    PREREQ_PM     => { 'Module::Pluggable' => 0, 'if' => 0 },
    LICENSE       => 'perl',
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'B-Lint-*' },

    # B::Lint is a dual-life module. Must install over core for pre-5.12 perls.
    INSTALLDIRS => $] < 5.012 ? 'perl' : 'site',
    PM          => {
        'lib/B/Lint.pm'       => '$(INST_ARCHLIB)/B/Lint.pm',
        'lib/B/Lint/Debug.pm' => '$(INST_ARCHLIB)/B/Lint/Debug.pm',
    },
);
