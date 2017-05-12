use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DNS::RName::Converter',
    AUTHOR              => q{Ken Peng <yhpeng@cpan.org>},
    VERSION_FROM        => 'lib/DNS/RName/Converter.pm',
    ABSTRACT_FROM       => 'lib/DNS/RName/Converter.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Data::Validate::Email' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DNS-RName-Converter-*' },
);
