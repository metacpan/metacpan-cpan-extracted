use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bio::KEGGI',
    AUTHOR              => q{Haizhou Liu <zeroliu@gmail.com>},
    VERSION_FROM        => 'lib/Bio/KEGGI.pm',
    ABSTRACT            => 'Module to handle KEGG genome, ko and pathway files',
#    ABSTRACT_FROM       => 'lib/Bio/KEGGI.pm',
#    ($ExtUtils::MakeMaker::VERSION >= 6.3002
#      ? ('LICENSE'=> 'perl')
#      : ()),
    LICENSE             => 'perl',
    INSTALLDIRS         => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Switch'     => 0,
        'Text::Trim' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bio-KEGGI-*' },
);
