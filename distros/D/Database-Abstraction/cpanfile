# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.010';

requires 'Carp';
requires 'Class::Abstract';
requires 'Cwd';
requires 'DBD::CSV', '0.64';   # CSV/PSV/TSV, the default format; 0.64+ (SQL::Statement 1.414+) for SELECT DISTINCT
requires 'DBD::SQLite::Constants';
requires 'DBI', '1.6';
requires 'Data::Reuse';   # Required for result-set memory deduplication; see also RT#100461
requires 'File::Spec';
requires 'File::Temp';
requires 'List::Util', '1.33';
requires 'Log::Abstraction', '0.40';
requires 'Object::Configure', '0.24';
requires 'Params::Get', '0.17';
requires 'Return::Set';
requires 'Scalar::Util';
requires 'Sub::Private', '0.09';
requires 'Sub::Protected';
requires 'Text::xSV::Slurp';   # the CSV/PSV slurp path, taken for every file under max_slurp_size
requires 'XML::Simple';   # XML files
requires 'autodie';
requires 'strict';
requires 'warnings';
recommends 'DBD::Excel';   # .xls (old binary Excel) backend
recommends 'DBD::MariaDB';   # MariaDB/MySQL backend (preferred over DBD::mysql for MariaDB)
recommends 'DBM::Deep';   # .dbm/.deep/magic-byte .db backend
recommends 'File::Slurp::Remote';   # remote host backend (SSH/SCP)
recommends 'Gzip::Faster';   # gzip CSV backend
recommends 'HTML::TableExtract';   # HTML URL backend
recommends 'JSON::MaybeXS';   # JSON backend
recommends 'LWP::UserAgent::Cached';   # URL backend (HTML and JSON)
recommends 'Redis';   # Redis backend (pure-Perl fallback)
recommends 'Redis::Fast';   # Redis backend (XS, preferred)
recommends 'Spreadsheet::ParseXLSX';   # .xlsx (OOXML Excel) backend

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';   # Minimum version for TEST_REQUIRES
};

on 'test' => sub {
	requires 'CHI';
	requires 'DBD::XMLSimple', '0.07';
	requires 'DBM::Deep';
	requires 'Excel::Writer::XLSX';
	requires 'Fcntl';
	requires 'File::Glob';
	requires 'File::Slurp';
	requires 'File::Spec';
	requires 'File::Temp';
	requires 'File::stat';
	requires 'FindBin';
	requires 'Gzip::Faster';
	requires 'HTML::TableExtract';
	requires 'HTTP::Response';
	requires 'IPC::Run';
	requires 'IPC::System::Simple';
	requires 'JSON::MaybeXS';
	requires 'LWP::UserAgent';
	requires 'LWP::UserAgent::Cached';
	requires 'POSIX';
	requires 'Readonly';
	requires 'Spreadsheet::ParseXLSX';
	requires 'Spreadsheet::WriteExcel';
	requires 'Test::Carp';
	requires 'Test::Compile';
	requires 'Test::DescribeMe';
	requires 'Test::Log::Abstraction';
	requires 'Test::Memory::Cycle';
	requires 'Test::Mockingbird', '0.14';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::NoWarnings';
	requires 'Test::Permissions';
	requires 'Test::Returns', '0.05';
	requires 'Test::Warn';
	requires 'Test::Which';
	requires 'Test::Without::Module';
	requires 'Time::HiRes';
	requires 'YAML::XS';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
