use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec;

WriteMakefile(
    NAME		=> 'CGI::ACL',
    AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM	=> 'lib/CGI/ACL.pm',
    ABSTRACT_FROM       => 'lib/CGI/ACL.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES	=> {},
    BUILD_REQUIRES => {
	'Test::Carp' => 0,
	'Test::Most' => 0,
	'File::Spec' => 0,
	'Test::NoWarnings' => 0,
	'Test::CleanNamespaces' => 0,
	# 'Test::Kwalitee' => 0,
	'autodie' => 0,
	'IPC::System::Simple' => 0,
	'CGI::Info' => 0,
	'CGI::Lingua' => 0.15,
    },
    PREREQ_PM => {
	'Carp' => 0,
	'namespace::clean' => 0,
	'Net::CIDR' => 0,
    },
    dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean		=> { FILES => 'CGI-ACL-*' },
    META_MERGE		=> {
    	'meta-spec' => { version => 2 },
    	resources => {
    		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/CGI-ACL.git',
			web => 'https://github.com/nigelhorne/CGI-ACL',
    		},
		bugtracker => {
			web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=CGI-ACL',
			mailto => 'bug-CGI-ACL@rt.cpan.org'
		}
	},
    },
    MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
