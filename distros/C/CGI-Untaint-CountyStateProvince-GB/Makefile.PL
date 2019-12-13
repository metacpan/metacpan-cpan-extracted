use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::Untaint::CountyStateProvince::GB',
    AUTHOR              => q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM        => 'lib/CGI/Untaint/CountyStateProvince/GB.pm',
    ABSTRACT_FROM        => 'lib/CGI/Untaint/CountyStateProvince/GB.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES            => {},
    BUILD_REQUIRES => {
	'Test::Most' => 0,
	'Test::NoWarnings' => 0,
	# 'Test::Kwalitee' => 0,
    },
    PREREQ_PM => {
	'CGI::Untaint' => 0,
	'CGI::Untaint::CountyStateProvince' => 0.04,
	'Locale::SubCountry' => 1.63,
	'Carp' => 0,
	'Test::Requires' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Untaint-CountyStateProvince-GB*' },
    META_MERGE		=> {
    	'meta-spec' => { version => 2 },
    	resources => {
    		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/CGI-Untaint-CountyStateProvince-GB.git',
			web => 'https://github.com/nigelhorne/CGI-Untaint-CountyStateProvince-GB',
    		},
	},
    },
    MIN_PERL_VERSION	=> 5.6.2	# Probably would work, but never tested on earlier versions than this
);
