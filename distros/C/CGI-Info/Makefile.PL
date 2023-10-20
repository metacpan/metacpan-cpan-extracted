use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES
use File::Spec 3.4;

my $tmpdir = File::Spec->tmpdir();
if(!-w $tmpdir) {
	print STDERR "NA: Your temporary directory '$tmpdir' isn't writable, fix your configuration and try again";
	exit(0);
}

WriteMakefile(
	NAME		=> 'CGI::Info',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM	=> 'lib/CGI/Info.pm',
	ABSTRACT_FROM	=> 'lib/CGI/Info.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'GPL')
	  : ()),
	'LIBS' => [''],	# e.g., '-lm'
	'DEFINE' => '',	# e.g., '-DHAVE_SOMETHING'
	'INC' => '',	# e.g., '-I/usr/include/other'
	PL_FILES	=> {},
	TEST_REQUIRES => {
		'LWP::UserAgent' => 0,
		'Test::Carp' => 0,
		'Test::Compile' => 0,
		'Test::Most' => 0,
		'Test::NoWarnings' => 0,
		'Test::Script' => 1.12,
		'Test::CleanNamespaces' => 0,
		# 'Test::Kwalitee' => 0,
		'autodie' => 0,
		'strict' => 0,
		'warnings' => 0,
		'IPC::System::Simple' => 0,
		'Test::Warn' => 0,
		'Tie::Filehandle::Preempt::Stdin' => 0,
	}, PREREQ_PM => {
		'Carp' => 0,
		'URI::Heuristic' => 0,
		'Sub::Private' => 0,
		'Sys::Hostname' => 0,
		'File::Spec' => 0,
		'Cwd' => 0,
		'Socket' => 0,
		'List::MoreUtils' => 0,
		'HTTP::BrowserDetect' => 3.10,	# Include bingbot
		'File::Basename' => 0,
		'String::Clean::XSS' => 0,
		'Log::Any' => 0,
		'JSON::MaybeXS' => 0,
		# 'JSON::PP' => 4.02,	# Fix http://www.cpantesters.org/cpan/report/78a1401c-42de-11e9-bf31-80c71e9d5857
		# 'String::EscapeCage' => 0.02,
		'Class::Autouse' => 0,
		'namespace::clean' => 0,
		'Sys::Path' => 0,
	},
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean		=> { FILES => 'CGI-Info-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/CGI-Info.git',
				web => 'https://github.com/nigelhorne/CGI-Info',
				repository => 'https://github.com/nigelhorne/CGI-Info',
			}, bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=CGI-Info',
				web => 'https://github.com/nigelhorne/CGI-Info/issues',
				url => 'https://github.com/nigelhorne/CGI-Info/issues',
				mailto => 'bug-CGI-Info@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
