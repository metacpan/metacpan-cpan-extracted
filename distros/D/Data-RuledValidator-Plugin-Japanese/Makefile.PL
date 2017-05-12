use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::RuledValidator::Plugin::Japanese',
    AUTHOR              => 'Ktat <ktat@cpan.org>',
    VERSION_FROM        => 'lib/Data/RuledValidator/Plugin/Japanese.pm',
    ABSTRACT_FROM       => 'lib/Data/RuledValidator/Plugin/Japanese.pm',
    PL_FILES            => {},
    PREREQ_FATAL        => 1,
    PREREQ_PM => {
        'Test::More' => "",
	'Data::FormValidator::Constraints::Japanese' => 0.04,
	'Data::RuledValidator' => 0.10,
	'Number::Phone::JP'    => "",
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-RuledValidator-Plugin-Japanese-*' },
);
