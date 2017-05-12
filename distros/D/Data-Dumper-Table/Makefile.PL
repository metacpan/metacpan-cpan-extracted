use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::Dumper::Table',
    AUTHOR              => q{Paul Bennett <paul.w.bennett@gmail.com>},
    VERSION_FROM        => 'lib/Data/Dumper/Table.pm',
    ABSTRACT_FROM       => 'lib/Data/Dumper/Table.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Exporter' => '0',
        'Scalar::Util' => '0',
        'Text::Table' => '0',
        'utf8' => '0',
    },
    TEST_REQUIRES => { 'Test::More' => 0, },
    MIN_PERL_VERSION => '5.018000',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-Dumper-Table-*' },
);
