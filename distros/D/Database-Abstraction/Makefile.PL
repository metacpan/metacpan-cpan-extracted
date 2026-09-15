use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME		=> 'Database::Abstraction',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM	=> 'lib/Database/Abstraction.pm',
	ABSTRACT_FROM	=> 'lib/Database/Abstraction.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'gpl_2')
		: ()),
	'LIBS' => [''],	# e.g., '-lm'
	'DEFINE' => '',	# e.g., '-DHAVE_SOMETHING'
	'INC' => '',	# e.g., '-I/usr/include/other'
	PL_FILES	=> {},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, PREREQ_PM => {
		'autodie' => 0,
		'boolean' => 0,
		'strict' => 0,
		'warnings' => 0,
		'Carp' => 0,
		'Class::Abstract' => 0,
		'Cwd' => 0,
		'DBI' => 1.6,
		'Data::Reuse' => 0,	# Required for result-set memory deduplication; see also RT#100461
		# 'Error' => 0,
		'DBD::SQLite::Constants' => 0,
		'File::Spec' => 0,
		'File::Temp' => 0,
		'List::Util' => 1.33,
		'Log::Abstraction' => 0.33,
		'Object::Configure' => 0.16,
		'Params::Get' => 0.17,
		'Return::Set' => 0,
		'Scalar::Util' => 0,
		'Sub::Private' => 0,
		'Sub::Protected' => 0,
		# Core modules required lazily at runtime — not listed as deps because
		# MIN_PERL_VERSION (5.010) guarantees their presence on all targets:
		#   DB_File      (core since 5.004; used by BerkeleyDB backend)
		#   Sys::Hostname (core since 5.006; used by _is_local_host)
		#   IO::Compress::Gzip (core since 5.9.4; used in t/ fixture creation)
	}, TEST_REQUIRES => {
		'CHI' => 0,
		'DBD::CSV' => 0,
		'DBD::XMLSimple' => 0.07,
		'DBM::Deep' => 0,
		'Excel::Writer::XLSX' => 0,
		'Fcntl' => 0,
		'File::Glob' => 0,
		'File::Slurp' => 0,
		'File::Spec' => 0,
		'File::stat' => 0,
		'File::Temp' => 0,
		'FindBin' => 0,
		'Gzip::Faster' => 0,
		'HTML::TableExtract' => 0,
		'HTTP::Response' => 0,
		'IPC::Run' => 0,
		'IPC::System::Simple' => 0,
		'JSON::MaybeXS' => 0,
		'LWP::UserAgent' => 0,
		'LWP::UserAgent::Cached' => 0,
		'POSIX' => 0,
		'Readonly' => 0,
		'Spreadsheet::ParseXLSX' => 0,
		'Spreadsheet::WriteExcel' => 0,
		'Test::Carp' => 0,
		'Test::Compile' => 0,
		'Test::DescribeMe' => 0,
		'Test::Memory::Cycle' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::Mockingbird' => 0,
		'Test::NoWarnings' => 0,
		'Test::Returns' => 0,
		'Test::Warn' => 0,
		'Test::Which' => 0,
		'Test::Without::Module' => 0,
		'Text::xSV::Slurp' => 0,
		'Time::HiRes' => 0,
		'XML::Simple' => 0,
		'YAML::XS' => 0,
	}, dist => $dist,
	clean		=> { FILES => 'Database-Abstraction-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		recommends => {
			# Optional runtime backends — lazy-loaded; install for full functionality
			'DBD::Excel' => 0,		# .xls (old binary Excel) backend
			'DBM::Deep' => 0,		# .dbm/.deep/magic-byte .db backend
			'File::Slurp::Remote' => 0,	# remote host backend (SSH/SCP)
			'Gzip::Faster' => 0,		# gzip CSV backend
			'Spreadsheet::ParseXLSX' => 0,	# .xlsx (OOXML Excel) backend
			'Text::xSV::Slurp' => 0,	# CSV/PSV slurp backend
			'XML::Simple' => 0,		# XML backend
		},
		resources => {
			repository => {
				repository => 'https://github.com/nigelhorne/Database-Abstraction',
				type => 'git',
				url => 'git://github.com/nigelhorne/Database-Abstraction.git',
				web => 'https://github.com/nigelhorne/Database-Abstraction',
				# license    => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				web    => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Database-Abstraction',
				mailto => 'bug-Database-Abstraction@rt.cpan.org',
			}
		},
	},
	MIN_PERL_VERSION	=> '5.010'
);
