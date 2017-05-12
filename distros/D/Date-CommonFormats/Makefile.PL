use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Date::CommonFormats',
    AUTHOR              => q{Chris Fulton <chris@masonqm.com>},
    VERSION_FROM        => 'lib/Date/CommonFormats.pm',
    ABSTRACT_FROM       => 'lib/Date/CommonFormats.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Date::Calc' => 0,
        'Date::Format' => 0,
        'Date::Parse' => 0,
	'DateTime::Format::MySQL' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Date-CommonFormats-*' },
);
