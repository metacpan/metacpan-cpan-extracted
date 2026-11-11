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
	MIN_PERL_VERSION => '5.028000',	# sub NAME :Attr ($sig) -- attributes before the signature -- needs 5.28
	EXE_FILES	=> [qw(script/database-bi script/bi-extract script/bi-geocode script/bi-alert)],	# each has POD, so each gets a man page
	PREREQ_PM => {
		'Carp'		=> 0,
		'Cwd'		=> 0,		# For realpath() in the data_dir guard (Dashboard.pm)
		'CHI'			=> 0,
		'CGI::Info'	=> 0,
		'CGI::Lingua'		=> '0.88',	# 0.88 reads the locale (LC_ALL, then LC_MESSAGES, then LANG), which the scripts' messages follow
		'Database::Abstraction'	=> '0.56',	# 0.56 reads "" inside a quoted field as one quote; 0.55 requires the CSV and XML readers it loads (DBD::CSV, Text::xSV::Slurp, XML::Simple); 0.54 reads a table named data (Export > SQLite); 0.50 added redis_key + standalone-key support; 0.49 added aggregate(); 0.48 added limit/offset support in selectall_arrayref
		'Database::Join' => '0.011.1',	# 0.011.1: a driver failure always has a message; 0.011.0 added Database::Join::Catalog, through which every table list, column list and SQLite write goes; 0.009.0 added aggregate(), limit/offset/sort_by, dbi_source(); 0.004.0 added backend=>'auto' SQLite spill
		'Net::SFTP::Foreign' => 0,
		'Object::Configure'	=> '0.25',	# cache_dir for each object that keeps a cache (Database::BI::CacheDir); 0.25: configure($class, \%params), and logger => [] keeps a syslog universal.yml from opening
		'File::Path'	=> '2.07',	# For remove_tree in Dashboard.pm at runtime
		'File::Spec'	=> '3.40',
		'List::Util'	=> '1.40',
		'Statistics::LineFit'	=> '0.06',	# the line graph's trend line
		'Statistics::Lite'	=> '3.62',	# the line graph's min, max and mean when not pushed to SQL
		'IPC::System::Simple' => 0,	# For autodie (:all) in DataSource.pm at runtime
		'HTML::D3' => '0.30',	# 0.30 puts a Content-Security-Policy nonce on its scripts; 0.29 colours treemap tiles by a measure, takes a combo scheme and escapes tooltip text; 0.27 stops a label ending the script it is written into; 0.20 added radius_range support for render_scatter_chart_snippet; 0.19 added scatter/stacked/combo/treemap/histogram snippets
		'HTML::TagCloud' => '0.38',	# word cloud page (/wordcloud)
		'HTML::TableExtract'	=> 0,
		'HTTP::Request'			=> 0,		# Used by Ask.pm and Summary.pm for LLM API calls (ships with libwww-perl but not core)
		'HTTP::Message'			=> 0,		# HTTP::Response, for SafeUA's refusals (the dist HTTP::Request comes from)
		'URI'				=> 0,		# _is_safe_url's early check of an import URL
		'Encode'			=> 0,		# Extract.pm and Summary.pm (core, listed for completeness)
		'Unicode::Normalize'	=> 0,		# Dashboard.pm's table sort folds accents (core)
		'LWP::UserAgent'		=> 0,		# Needed for Test::Mojo HTTP testing; LWP::UserAgent::Cached is used by D::A url fetch path
		'LWP::UserAgent::Cached'	=> 0,		# Used by Database::Abstraction for URL-backed tables (import_url)
		'Scalar::Util'			=> 0,		# Used in DataSource.pm (blessed, looks_like_number)
		'JSON::PP'			=> 0,		# Boundary.pm reads Nominatim's replies with it (core, declared for completeness)
		'DB_File'			=> 0,		# Used in DataSource.pm for Berkeley DB magic-byte detection
		'Mojolicious'	=> '9.49',
		'Mojolicious::Plugin::Buffer'          => '0.001.1',
		'Mojolicious::Plugin::TemplateToolkit' => 0,
		'Params::Get'	=> 0.17,
		'Params::Validate::Strict'	=> '0.41',
		'Crypt::URandom'	=> 0,		# The login's password salt (script/database-bi password); Windows has no /dev/urandom
		'Digest::MD5'		=> 0,		# For Extract.pm fingerprinting (Phase 4.1)
		'Digest::SHA'		=> 0,		# HMAC-SHA256 share tokens, and the login's PBKDF2 password hash (core since Perl 5.10)
		'MIME::Base64'		=> '3.11',	# encode_base64url/decode_base64url in share tokens; the stored password hash
		'Readonly'		=> 0,
		'Socket'	=> '2.010',
		'Excel::Writer::XLSX'	=> '1.07',
		'POSIX'			=> 0,		# For floor/ceil in Calc.pm (core module, listed for completeness)
		'Spreadsheet::ParseXLSX'	=> 0,
		'Sub::Protected' => 0.03,
		'Text::CSV'	=> 0,		# Files with no header row; script/bi-alert's fallback reader when Database::Abstraction cannot open the file
		'version'        => '0.77',
	}, TEST_REQUIRES => {
		'DBI' => 0,	# SQLite fixtures; the application itself uses Database::Join::Catalog
		'DBD::CSV' => 0,
		'JSON::MaybeXS' => 0,	# The browser tests speak Marionette and decode its frames
		'Test::DescribeMe' => 0,	# Author tests (t/pod.t, t/manifest.t, t/version.t) declare themselves with this; the tools they need are optional and skipped without them
		'Test::Memory::Cycle' => 0,
		'Test::Mockingbird' => 0.14,
		'Test::Most' => 0,
		'Test::Mojo' => 0,
		'Test::Needs' => 0,
		'Test::Permissions' => '0.001.2',
		'Test::Returns' => 0.005,
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
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Database-BI',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Database-BI',
				# web => 'https://github.com/nigelhorne/Database-BI/issues',
				mailto => 'bug-Database-BI@rt.cpan.org'
			}
		}, prereqs => {
			runtime => {
				recommends => {
					# Geocoding a dataset's location column (Phase 6.2).  Loaded with a
					# runtime require, never a hard prerequisite: 0.46 added
					# valid_location() and 0.47 added geocode_many(), 0.48 added the
					# per-lookup read counts the app reports as lookups, and the app
					# installs, starts and tests without the module, hiding the
					# location option and saying which version is needed.  The floor
					# is named once, in Database::BI::Model::Geocode's
					# $MIN_GEOCODER_VERSION and in the messages that quote it;
					# t/recommended-versions.t holds all three to this entry.
					'Geo::Coder::Free' => '0.48',
					# The chain the lookups go through (Geo::Coder::List; 0.39 keeps
					# the log() that tells a place Nominatim does not know from a
					# Nominatim that did not answer), and OpenStreetMap's Nominatim for
					# the places Geo::Coder::Free does not know, kept to one request a
					# second by LWP::UserAgent::Throttled.  Without the list there is no
					# geocoding; without the other two it is local only.
					'Geo::Coder::List' => '0.39',
					'Geo::Coder::OSM' => '0.03',
					'LWP::UserAgent::Throttled' => '0.14',
					# The mariadb: data source, looked for when a server is opened.
					# DBD::mysql serves in its place.
					'DBD::MariaDB' => 0,
					# Rendering the map itself (Phase 6.1).  Also runtime-required: the
					# rest of the application installs, starts and tests without it.
					# 0.14 is the oldest that draws a map.  County outlines use more as
					# it is there, and do without otherwise: the checkbox that hides
					# them (0.15), the key to their colours (0.16), lines side by side
					# (0.17), a key of boxes for Colour shade (0.18), and the marker key
					# coming back while they are hidden (0.19).  The floor stays 0.14:
					# t/recommended-versions.t holds every test and message to this entry.
					'HTML::OSM' => '0.14',
					# script/bi-alert reads CSV faster with it, and falls back to Text::CSV.
					'Text::CSV_XS' => 0
				}
			}, test => {
				recommends => {
					'DBD::MariaDB' => 0,
					'Redis' => 0
				}
			}
		},
	},
);
