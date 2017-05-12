use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DateTime::Event::Jewish',
    AUTHOR              => q{Raphael Mankin <rapmankin@cpan.org>},
    VERSION_FROM        => 'lib/DateTime/Event/Jewish.pm',
    ABSTRACT_FROM       => 'lib/DateTime/Event/Jewish.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'	=> 0,
	'DateTime'	=> 0,
	'DateTime::Duration'	=> 0,
	'DateTime::Calendar::Hebrew'	=> '0.04',
	'Math::Trig'	=> 0,
	'Params::Validate'	=> 0,
	'DateTime::Locale'	=> '0.4',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DateTime-Event-Jewish-*' },
);
