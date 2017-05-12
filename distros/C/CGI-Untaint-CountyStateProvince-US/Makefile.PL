use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::Untaint::CountyStateProvince::US',
    AUTHOR              => q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM        => 'lib/CGI/Untaint/CountyStateProvince/US.pm',
    ABSTRACT_FROM        => 'lib/CGI/Untaint/CountyStateProvince/US.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0.82,	# Need new_ok()
	'CGI::Untaint' => 0,
	'CGI::Untaint::CountyStateProvince' => 0.04,
	'Locale::SubCountry' => 0,
	'Test::NoWarnings' => 0,
	'Test::Kwalitee' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Untaint-CountyStateProvince-US*' },
);
