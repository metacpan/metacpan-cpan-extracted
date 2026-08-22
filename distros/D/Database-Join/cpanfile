# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.010001';

requires 'Carp';
requires 'Database::Abstraction', '0.37';
requires 'List::Util', '1.33';
requires 'Object::Configure';
requires 'Params::Get', '0.13';
requires 'Params::Validate::Strict', '0.38';
requires 'Readonly', '2.00';
requires 'Scalar::Util';
requires 'Sub::Protected';
requires 'autodie';

on 'test' => sub {
	requires 'DBD::CSV';
	requires 'DBD::SQLite', '1.70';
	requires 'DBI';
	requires 'File::Temp';
	requires 'IPC::System::Simple';
	requires 'Test::Exception';
	requires 'Test::Memory::Cycle';
	requires 'Test::Mockingbird', '0.13';
	requires 'Test::Most';
	requires 'Test::NoWarnings';
	requires 'Test::Returns', '0.04';
	requires 'Test::Without::Module';
	requires 'Text::xSV::Slurp';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
