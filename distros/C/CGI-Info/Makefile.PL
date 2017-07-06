use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec;

my $tmpdir = File::Spec->tmpdir();
if(!-w $tmpdir) {
	print STDERR "NA: Your temporary directory '$tmpdir' isn't writable, fix your configuration and try again";
	exit(0);
}

WriteMakefile(
    NAME		=> 'CGI::Info',
    AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM	=> 'lib/CGI/Info.pm',
    ABSTRACT_FROM       => 'lib/CGI/Info.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES	=> {},
    BUILD_REQUIRES => {
	'Test::Most' => 0,
	'Test::NoWarnings' => 0,
	'Test::Script' => 1.12,
	'Test::CleanNamespaces' => 0,
	# 'Test::Kwalitee' => 0,
	'autodie' => 0,
	'IPC::System::Simple' => 0,
	'Tie::Filehandle::Preempt::Stdin' => 0,
    },
    PREREQ_PM => {
	'URI::Heuristic' => 0,
	'Sys::Hostname' => 0,
	'File::Spec' => 0,
	'Cwd' => 0,
	'Carp' => 0,
	'Socket' => 0,
	'List::Member' => 0,
	'HTTP::BrowserDetect' => 3.10,	# Include bingbot
	'File::Basename' => 0,
	'String::Clean::XSS' => 0,
	'Log::Any' => 0,
	'JSON::Parse' => 0,
	# 'String::EscapeCage' => 0.02,
	'Class::Autouse' => 0,
	'namespace::clean' => 0,
    },
    dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean		=> { FILES => 'CGI-Info-*' },
    META_MERGE		=> {
    	'meta-spec' => { version => 2 },
    	resources => {
    		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/CGI-Info.git',
			web => 'https://github.com/nigelhorne/CGI-Info',
    		},
		bugtracker => {
			web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=CGI-Info',
			mailto => 'bug-CGI-Info@rt.cpan.org'
		}
	},
    },
    MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
