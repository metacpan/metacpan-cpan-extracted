use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::Untaint::Twitter',
    AUTHOR              => q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM        => 'lib/CGI/Untaint/Twitter.pm',
    ABSTRACT_FROM        => 'lib/CGI/Untaint/Twitter.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::Most' => 0,
	'CGI::Untaint' => 0,
	'Test::NoWarnings' => 0,
	'Net::Twitter::Lite::WithAPIv1_1' => 0,
	# 'Test::Kwalitee' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Untaint-Twitter-*' },
    META_MERGE		=> {
    	'meta-spec' => { version => 2 },
    	resources => {
    		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/CGI-Untaint-Twitter.git',
			web => 'https://github.com/nigelhorne/CGI-Untaint-Twitter',
    		},
	},
    },
    MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
