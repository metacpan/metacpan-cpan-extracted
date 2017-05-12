use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'BERT',
    AUTHOR              => q{Sherwin Daganato <sherwin@daganato.com>},
    VERSION_FROM        => 'lib/BERT.pm',
    ABSTRACT_FROM       => 'lib/BERT.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    MIN_PERL_VERSION => '5.008',
    META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/sherwind/perl-BERT/issues',
            repository  => 'https://github.com/sherwind/perl-BERT.git',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'BERT-*' },
);
