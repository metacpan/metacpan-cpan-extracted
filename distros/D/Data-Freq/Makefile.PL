use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::Freq',
    AUTHOR              => q{Mahiro Ando <mahiro@cpan.org>},
    VERSION_FROM        => 'lib/Data/Freq.pm',
    ABSTRACT_FROM       => 'lib/Data/Freq.pm',
    EXE_FILES           => ['bin/data-freq'],
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Date::Parse'  => '1.20',
        'List::Util'   => '1.22',
        'Pod::Usage'   => '1.36',
        'Scalar::Util' => '1.22',
        'Test::More'   => '0.94',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-Freq-*' },
);
