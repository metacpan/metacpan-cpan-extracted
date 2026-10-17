use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME			 => 'Database::BI',
	VERSION_FROM	 => 'lib/Database/BI.pm',
	ABSTRACT_FROM => 'lib/Database/BI.pm',
	AUTHOR		=> 'Nigel Horne <njh@nigelhorne.com>',
	LICENSE		  => 'gpl_2',
	MIN_PERL_VERSION => '5.020000',
	EXE_FILES	=> ['script/database-bi'],
	PREREQ_PM => {
		'Carp'		=> 0,
		'CHI'			=> 0,
		'CGI::Info'	=> 0,
		'CGI::Lingua'		=> '0.85',
		'Database::Abstraction'	=> '0.51',	# 0.50 added redis_key + standalone-key support; 0.49 added aggregate(); 0.48 added limit/offset support in selectall_arrayref
		'Database::Join' => '0.009.0',	# 0.009.0 added aggregate(), limit/offset/sort_by, dbi_source(); 0.004.0 added backend=>'auto' SQLite spill
		'DBI'		=> 0,
		'Net::SFTP::Foreign' => 0,
		'File::Path'	=> '2.07',	# For remove_tree in Dashboard.pm at runtime
		'File::Spec'	=> '3.40',
		'File::Temp'	=> '0.22',
		'List::Util'	=> '1.40',
		'IPC::System::Simple' => 0,	# For autodie (:all) in DataSource.pm at runtime
		'Mojo::Base' => 0,
		'Mojo::JSON' => 0,
		'HTML::D3' => '0.20',	# 0.20 added radius_range support for render_scatter_chart_snippet; 0.19 added scatter/stacked/combo/treemap/histogram snippets
		'HTML::TableExtract'	=> 0,
		'LWP::UserAgent'		=> 0,		# Needed for Test::Mojo HTTP testing; LWP::UserAgent::Cached is used by D::A url fetch path
		'LWP::UserAgent::Cached'	=> 0,		# Used by Database::Abstraction for URL-backed tables (import_url)
		'Scalar::Util'			=> 0,		# Used in DataSource.pm (blessed, looks_like_number)
		'DB_File'			=> 0,		# Used in DataSource.pm for Berkeley DB magic-byte detection
		'Mojolicious'	=> '9.49',
		'Mojolicious::Plugin::TemplateToolkit' => 0,
		'Params::Get'	=> 0,
		'Params::Validate::Strict'	=> '0.39',
		'Readonly'		=> 0,
		'Socket'	=> '2.010',
		'POSIX'			=> 0,		# For floor/ceil in Calc.pm (core module, listed for completeness)
		'Spreadsheet::ParseXLSX'	=> 0,
		'Sub::Protected'	=> 0,
		'Excel::Writer::XLSX'	=> '1.07',
	}, TEST_REQUIRES => {
		'DBD::CSV' => 0,
		'Encode' => 0,
		'Test::DescribeMe' => 0,	# Author tests (t/pod.t, t/manifest.t, t/version.t) declare themselves with this; the tools they need are optional and skipped without them
		'Test::Memory::Cycle' => 0,
		'Test::Mockingbird' => 0,
		'Test::Most' => 0,
		'Test::Mojo' => 0,
		'Test::Needs' => 0,
		'Test::Returns' => 0,
		'Test::Without::Module' => 0,
		'Text::xSV::Slurp' => 0,
		'XML::Simple' => 0,
	}, dist => $dist,
	clean	=> { FILES => 'Database-BI-*' },
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'https://github.com/nigelhorne/Database-BI.git',
				web => 'https://github.com/nigelhorne/Database-BI',
			}, bugtracker => {
				web => 'https://github.com/nigelhorne/Database-BI/issues',
			}
		},		prereqs => {
			runtime => {
				recommends => {
					# Geocoding a dataset's location column (Phase 6.2).  Loaded with a
					# runtime require, never a hard prerequisite: 0.46 added
					# valid_location() and 0.47 added geocode_many(), and the app
					# installs, starts and tests without the module, hiding the
					# location option and saying which version is needed.
					'Geo::Coder::Free' => '0.47'
				}
			},
			test => {
				recommends => {
					'Redis' => 0
				}
			}
		},
	},
);
