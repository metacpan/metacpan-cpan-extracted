use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec;

my $tmpdir = File::Spec->tmpdir();
if(!-w $tmpdir) {
	print STDERR "NA: Your temporary directory '$tmpdir' isn't writable, fix your configuration and try again";
	exit(0);
}

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME		=> 'CGI::Info',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM	=> 'lib/CGI/Info.pm',
	ABSTRACT_FROM	=> 'lib/CGI/Info.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	'LIBS' => [''],	# e.g., '-lm'
	'DEFINE' => '',	# e.g., '-DHAVE_SOMETHING'
	'INC' => '',	# e.g., '-I/usr/include/other'
	PL_FILES	=> {},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, TEST_REQUIRES => {
		'File::Temp' => 0,
		'LWP::UserAgent' => 0,
		'JSON::PP' => 4.02,	# Fix http://www.cpantesters.org/cpan/report/78a1401c-42de-11e9-bf31-80c71e9d5857
		'Test::Carp' => 0,
		'Test::Compile' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::NoWarnings' => 0,
		'Test::Script' => 1.12,
		'Test::CleanNamespaces' => 0,
		# 'Test::Kwalitee' => 0,
		'autodie' => 0,
		'strict' => 0,
		'warnings' => 0,
		'IPC::System::Simple' => 0,
		'Taint::Runtime' => 0,
		'Test::Returns' => 0,
		'Test::Warn' => 0,
		'Tie::Filehandle::Preempt::Stdin' => 0,
	}, PREREQ_PM => {
		'boolean' => 0,
		'Carp' => 0,
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
		'File::Spec' => 3.4,
		'Log::Abstraction' => 0.10,
		'Net::CIDR' => 0,
		'Object::Configure' => 0.12,
		'Params::Get' => 0.13,
		'Params::Validate::Strict' => 0.02,
		'Return::Set' => 0,
		'Scalar::Util' => 0,
		'Sys::Hostname' => 0,
		'URI::Heuristic' => 0,
		# 'Sub::Private' => 0,
		'Cwd' => 0,
		'Socket' => 0,
		'List::Util' => 1.33,
		'HTTP::BrowserDetect' => 3.10,	# Include bingbot
		'File::Basename' => 0,
		'IO::Interactive' => 0,
		'String::Clean::XSS' => 0,
		'Log::Any' => 0,
		'JSON::MaybeXS' => 0,
		# 'String::EscapeCage' => 0.02,
		# 'Class::Autouse' => 0,
		'namespace::clean' => 0,
		'Sys::Path' => 0
	}, dist => $dist,
	clean		=> { FILES => 'CGI-Info-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/CGI::Info',
			repository => {
				repository => 'https://github.com/nigelhorne/CGI-Info',
				type => 'git',
				url => 'git://github.com/nigelhorne/CGI-Info.git',
				web => 'https://github.com/nigelhorne/CGI-Info',
				# license    => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				mailto => 'bug-CGI-Info@rt.cpan.org',
				url => 'https://github.com/nigelhorne/CGI-Info/issues',
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=CGI-Info',
				web => 'https://github.com/nigelhorne/CGI-Info/issues'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
