use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Archive::SimpleExtractor',
    AUTHOR              => q{Sergey Tomoulevitch <phoinix.public@gmail.com>},
    VERSION_FROM        => 'lib/Archive/SimpleExtractor.pm',
    ABSTRACT_FROM       => 'lib/Archive/SimpleExtractor.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Cwd'                           => '3.0',
        'Module::Load'                  => '0.16',
        'Module::Load::Conditional'     => '0.30',
        'Test::More'                    => '0.90',
        'Archive::Rar'                  => '2.02',
        'Archive::Tar'                  => '1.54',
        'Archive::Zip'                  => '1.30',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Archive-SimpleExtractor-*' },
);
