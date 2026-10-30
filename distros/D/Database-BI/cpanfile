# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.028000';

requires 'CGI::Info';
requires 'CGI::Lingua', '0.85';
requires 'CHI';
requires 'Carp';
requires 'Cwd';   # For realpath() in the data_dir guard (Dashboard.pm)
requires 'DBI';
requires 'DB_File';   # Used in DataSource.pm for Berkeley DB magic-byte detection
requires 'Database::Abstraction', '0.51';   # 0.50 added redis_key + standalone-key support; 0.49 added aggregate(); 0.48 added limit/offset support in selectall_arrayref
requires 'Database::Join', '0.009.0';   # 0.009.0 added aggregate(), limit/offset/sort_by, dbi_source(); 0.004.0 added backend=>'auto' SQLite spill
requires 'Digest::MD5';   # For Extract.pm fingerprinting (Phase 4.1)
requires 'Digest::SHA';   # For HMAC-SHA256 share tokens in Dashboard.pm (Phase 4.6; core since Perl 5.10)
requires 'Excel::Writer::XLSX', '1.07';
requires 'File::Path', '2.07';   # For remove_tree in Dashboard.pm at runtime
requires 'File::Spec', '3.40';
requires 'File::Temp', '0.22';
requires 'HTML::D3', '0.23';   # 0.20 added radius_range support for render_scatter_chart_snippet; 0.19 added scatter/stacked/combo/treemap/histogram snippets
requires 'HTML::TableExtract';
requires 'HTML::TagCloud', '0.38';   # word cloud page (/wordcloud)
requires 'HTTP::Request';   # Used by Ask.pm and Summary.pm for LLM API calls (ships with libwww-perl but not core)
requires 'IPC::System::Simple';   # For autodie (:all) in DataSource.pm at runtime
requires 'LWP::UserAgent';   # Needed for Test::Mojo HTTP testing; LWP::UserAgent::Cached is used by D::A url fetch path
requires 'LWP::UserAgent::Cached';   # Used by Database::Abstraction for URL-backed tables (import_url)
requires 'List::Util', '1.40';
requires 'MIME::Base64', '3.11';   # For encode_base64url/decode_base64url in share tokens (Phase 4.6)
requires 'Mojo::Base';
requires 'Mojo::JSON';
requires 'Mojolicious', '9.49';
requires 'Mojolicious::Plugin::Buffer';
requires 'Mojolicious::Plugin::TemplateToolkit';
requires 'Net::SFTP::Foreign';
requires 'POSIX';   # For floor/ceil in Calc.pm (core module, listed for completeness)
requires 'Params::Get', '0.17';
requires 'Params::Validate::Strict', '0.41';
requires 'Readonly';
requires 'Scalar::Util';   # Used in DataSource.pm (blessed, looks_like_number)
requires 'Socket', '2.010';
requires 'Spreadsheet::ParseXLSX';
requires 'Sub::Protected', '0.03';
requires 'Text::CSV';   # script/bi-alert's fallback reader when Database::Abstraction cannot open the file
requires 'version', '0.77';
recommends 'Geo::Coder::Free', '0.48';
recommends 'HTML::OSM', '0.12';

on 'test' => sub {
	requires 'DBD::CSV';
	requires 'Encode';
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
