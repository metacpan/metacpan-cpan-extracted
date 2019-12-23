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
    BUILD_REQUIRES => {
	'Test::Most' => 0,
	'Test::More' => 0.82,      # Need new_ok()
	'Test::NoWarnings' => 0,
	# 'Test::Kwalitee' => 0,
    },
    PREREQ_PM => {
	'CGI::Untaint' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Untaint-CountyStateProvince-*' },
    META_MERGE		=> {
    	'meta-spec' => { version => 2 },
    	resources => {
    		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/CGI-Untaint-CountyStateProvince.git',
			web => 'https://github.com/nigelhorne/CGI-Untaint-CountyStateProvince',
    		},
		bugtracker => {
			web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=CGI-Untaint-CountyStateProvince',
			mailto => 'bug-CGI-Untaint-CountyStateProvince@rt.cpan.org'
		}
	},
    },
);
