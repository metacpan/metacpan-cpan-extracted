# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.010';

requires 'Carp';
requires 'Class::Abstract';
requires 'Cwd';
requires 'DBD::SQLite::Constants';
requires 'DBI', '1.6';
requires 'Data::Reuse';   # Required for result-set memory deduplication; see also RT#100461
requires 'File::Spec';
requires 'File::Temp';
requires 'List::Util', '1.33';
requires 'Log::Abstraction', '0.33';
requires 'Object::Configure', '0.16';
requires 'Params::Get', '0.17';
requires 'Return::Set';
requires 'Scalar::Util';
requires 'Sub::Private';
requires 'Sub::Protected';
requires 'autodie';
requires 'boolean';
requires 'strict';
requires 'warnings';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';   # Minimum version for TEST_REQUIRES
};

on 'test' => sub {
	requires 'CHI';
	requires 'DBD::CSV';
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
	requires 'Test::Memory::Cycle';
	requires 'Test::Mockingbird';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::NoWarnings';
	requires 'Test::Returns';
	requires 'Test::Warn';
	requires 'Test::Which';
	requires 'Test::Without::Module';
	requires 'Text::xSV::Slurp';
	requires 'Time::HiRes';
	requires 'XML::Simple';
	requires 'YAML::XS';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
