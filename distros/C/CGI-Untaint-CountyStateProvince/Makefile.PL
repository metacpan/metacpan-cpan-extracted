use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::Untaint::CountyStateProvince',
    AUTHOR              => q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM        => 'lib/CGI/Untaint/CountyStateProvince.pm',
    ABSTRACT_FROM        => 'lib/CGI/Untaint/CountyStateProvince.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0.82,	# Need new_ok()
	'CGI::Untaint' => 0,
	'Test::NoWarnings' => 0,
	'Test::Kwalitee' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Untaint-CountyStateProvince-*' },
);
