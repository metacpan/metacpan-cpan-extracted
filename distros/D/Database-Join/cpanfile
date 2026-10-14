# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.010001';

requires 'Carp';
requires 'DBD::SQLite', '1.70';
requires 'DBI';
requires 'Database::Abstraction', '0.51';
requires 'File::Spec';
requires 'File::Temp';
requires 'JSON::MaybeXS';
requires 'List::Util', '1.33';
requires 'Log::Abstraction', '0.33';
requires 'Object::Configure';
requires 'Params::Get', '0.13';
requires 'Params::Validate::Strict', '0.40';
requires 'Readonly', '2.00';
requires 'Scalar::Util';
requires 'Sub::Protected';
requires 'autodie';
recommends 'DBD::Excel', '0.06';
recommends 'Excel::Writer::XLSX', '1.09';
recommends 'threads';

on 'test' => sub {
	requires 'DBD::CSV';
	requires 'Test::DescribeMe';
	requires 'Test::Exception';
	requires 'Test::Memory::Cycle';
	requires 'Test::Mockingbird', '0.13';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::NoWarnings';
	requires 'Test::Returns', '0.04';
	requires 'Test::Warn';
	requires 'Test::Without::Module';
	requires 'Text::xSV::Slurp';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
