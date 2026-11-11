# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.028000';

requires 'CGI::Info';
requires 'CGI::Lingua', '0.88';   # 0.88 reads the locale (LC_ALL, then LC_MESSAGES, then LANG), which the scripts' messages follow
requires 'CHI';
requires 'Carp';
requires 'Crypt::URandom';   # The login's password salt (script/database-bi password); Windows has no /dev/urandom
requires 'Cwd';   # For realpath() in the data_dir guard (Dashboard.pm)
requires 'DB_File';   # Used in DataSource.pm for Berkeley DB magic-byte detection
requires 'Database::Abstraction', '0.56';   # 0.56 reads "" inside a quoted field as one quote; 0.55 requires the CSV and XML readers it loads (DBD::CSV, Text::xSV::Slurp, XML::Simple); 0.54 reads a table named data (Export > SQLite); 0.50 added redis_key + standalone-key support; 0.49 added aggregate(); 0.48 added limit/offset support in selectall_arrayref
requires 'Database::Join', '0.011.1';   # 0.011.1: a driver failure always has a message; 0.011.0 added Database::Join::Catalog, through which every table list, column list and SQLite write goes; 0.009.0 added aggregate(), limit/offset/sort_by, dbi_source(); 0.004.0 added backend=>'auto' SQLite spill
requires 'Digest::MD5';   # For Extract.pm fingerprinting (Phase 4.1)
requires 'Digest::SHA';   # HMAC-SHA256 share tokens, and the login's PBKDF2 password hash (core since Perl 5.10)
requires 'Encode';   # Extract.pm and Summary.pm (core, listed for completeness)
requires 'Excel::Writer::XLSX', '1.07';
requires 'File::Path', '2.07';   # For remove_tree in Dashboard.pm at runtime
requires 'File::Spec', '3.40';
requires 'HTML::D3', '0.30';   # 0.30 puts a Content-Security-Policy nonce on its scripts; 0.29 colours treemap tiles by a measure, takes a combo scheme and escapes tooltip text; 0.27 stops a label ending the script it is written into; 0.20 added radius_range support for render_scatter_chart_snippet; 0.19 added scatter/stacked/combo/treemap/histogram snippets
requires 'HTML::TableExtract';
requires 'HTML::TagCloud', '0.38';   # word cloud page (/wordcloud)
requires 'HTTP::Message';   # HTTP::Response, for SafeUA's refusals (the dist HTTP::Request comes from)
requires 'HTTP::Request';   # Used by Ask.pm and Summary.pm for LLM API calls (ships with libwww-perl but not core)
requires 'IPC::System::Simple';   # For autodie (:all) in DataSource.pm at runtime
requires 'JSON::PP';   # Boundary.pm reads Nominatim's replies with it (core, declared for completeness)
requires 'LWP::UserAgent';   # Needed for Test::Mojo HTTP testing; LWP::UserAgent::Cached is used by D::A url fetch path
requires 'LWP::UserAgent::Cached';   # Used by Database::Abstraction for URL-backed tables (import_url)
requires 'List::Util', '1.40';
requires 'MIME::Base64', '3.11';   # encode_base64url/decode_base64url in share tokens; the stored password hash
requires 'Mojolicious', '9.49';
requires 'Mojolicious::Plugin::Buffer', '0.001.1';
requires 'Mojolicious::Plugin::TemplateToolkit';
requires 'Net::SFTP::Foreign';
requires 'Object::Configure', '0.25';   # cache_dir for each object that keeps a cache (Database::BI::CacheDir); 0.25: configure($class, \%params), and logger => [] keeps a syslog universal.yml from opening
requires 'POSIX';   # For floor/ceil in Calc.pm (core module, listed for completeness)
requires 'Params::Get', '0.17';
requires 'Params::Validate::Strict', '0.41';
requires 'Readonly';
requires 'Scalar::Util';   # Used in DataSource.pm (blessed, looks_like_number)
requires 'Socket', '2.010';
requires 'Spreadsheet::ParseXLSX';
requires 'Statistics::LineFit', '0.06';   # the line graph's trend line
requires 'Statistics::Lite', '3.62';   # the line graph's min, max and mean when not pushed to SQL
requires 'Sub::Protected', '0.03';
requires 'Text::CSV';   # Files with no header row; script/bi-alert's fallback reader when Database::Abstraction cannot open the file
requires 'URI';   # _is_safe_url's early check of an import URL
requires 'Unicode::Normalize';   # Dashboard.pm's table sort folds accents (core)
requires 'version', '0.77';
recommends 'DBD::MariaDB';
recommends 'Geo::Coder::Free', '0.48';
recommends 'Geo::Coder::List', '0.39';
recommends 'Geo::Coder::OSM', '0.03';
recommends 'HTML::OSM', '0.14';
recommends 'LWP::UserAgent::Throttled', '0.14';
recommends 'Text::CSV_XS';

on 'test' => sub {
	requires 'DBD::CSV';
	requires 'DBI';   # SQLite fixtures; the application itself uses Database::Join::Catalog
	requires 'JSON::MaybeXS';   # The browser tests speak Marionette and decode its frames
	requires 'Test::DescribeMe';   # Author tests (t/pod.t, t/manifest.t, t/version.t) declare themselves with this; the tools they need are optional and skipped without them
	requires 'Test::Memory::Cycle';
	requires 'Test::Mockingbird', '0.14';
	requires 'Test::Mojo';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::Permissions', '0.001.2';
	requires 'Test::Returns', '0.005';
	requires 'Test::Without::Module';
	requires 'Text::xSV::Slurp';
	requires 'XML::Simple';
	recommends 'DBD::MariaDB';
	recommends 'Redis';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::CheckManifest';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
	requires 'Test::Version';
};
