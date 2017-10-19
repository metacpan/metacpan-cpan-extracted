use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

WriteMakefile(
    NAME                => 'CGI::Untaint::CountyStateProvince::US',
    AUTHOR              => q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM        => 'lib/CGI/Untaint/CountyStateProvince/US.pm',
    ABSTRACT_FROM        => 'lib/CGI/Untaint/CountyStateProvince/US.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES            => {},
    TEST_REQUIRES => {
	'Test::Most' => 0,
    },
    PREREQ_PM => {
	'CGI::Untaint' => 0,
	'CGI::Untaint::CountyStateProvince' => 0.04,
	'Locale::SubCountry' => 1.47,	# Needs new() on two character codes
	'Test::NoWarnings' => 0,
	# 'Test::Kwalitee' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Untaint-CountyStateProvince-US*' },
);
