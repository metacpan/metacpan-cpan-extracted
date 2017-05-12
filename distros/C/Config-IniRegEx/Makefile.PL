use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Config::IniRegEx',
    AUTHOR              => 'sasikala <sasi.asterisk>',
    VERSION_FROM        => 'lib/Config/IniRegEx.pm',
    ABSTRACT_FROM       => 'lib/Config/IniRegEx.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'Config::IniFiles' => 2.39,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Config-IniRegEx-*' },
);
