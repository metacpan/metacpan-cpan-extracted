# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.10.0';

requires 'Carp';
requires 'Config::Auto';
requires 'Config::IniFiles';
requires 'File::Basename';
requires 'File::Slurp';
requires 'File::Spec';
requires 'Getopt::Long';
requires 'Hash::Flatten';
requires 'Hash::Merge';
requires 'JSON::MaybeXS';
requires 'JSON::Parse';
requires 'Params::Get', '0.14';
requires 'Params::Validate::Strict', '0.11';
requires 'Pod::Usage';
requires 'Scalar::Util';
requires 'XML::PP', '0.06';
requires 'YAML::XS';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';
};

on 'test' => sub {
	requires 'File::Glob';
	requires 'File::stat';
	requires 'IPC::System::Simple';
	requires 'POSIX';
	requires 'Readonly';
	requires 'Test::DescribeMe';
	requires 'Test::Mockingbird';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::TempDir::Tiny';
	requires 'Test::Without::Module';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
