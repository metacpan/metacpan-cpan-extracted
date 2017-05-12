use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::SafetyGoggles',
    AUTHOR              => q{Marty O'Brien <mob@cpan.org>},
    VERSION_FROM        => 'lib/Acme/SafetyGoggles.pm',
    ABSTRACT_FROM       => 'lib/Acme/SafetyGoggles.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ('LICENSE'=> 'perl')
        : ()),
    META_MERGE          => {
	no_index => {
	    package => [
		'Filter::Simple',
		'Filter::Util::Call',
	    ],
        }
    },
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Filter::Simple' => 0,
	'Filter::Util::Call' => 0,
	'Text::Diff' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-SafetyGoggles-*' },
);
