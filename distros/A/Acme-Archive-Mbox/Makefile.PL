use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::Archive::Mbox',
    AUTHOR              => 'Ian Kilgore <iank@cpan.org>',
    VERSION_FROM        => 'lib/Acme/Archive/Mbox.pm',
    ABSTRACT_FROM       => 'lib/Acme/Archive/Mbox.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    EXE_FILES           => [ 'bin/mboxify',
                             'bin/mboxextract' ],
    PREREQ_PM => {
        'Test::More' => 0,
        'Mail::Box'  => 0,
        'File::Spec' => 0,
        'File::Path' => 0,
        'File::Temp' => 0,
        'File::Slurp' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-Archive-Mbox-*' },
);
