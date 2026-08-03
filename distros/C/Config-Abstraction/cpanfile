# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.10.0';

requires 'Carp';
requires 'Config::Auto';
requires 'Config::IniFiles';
requires 'CryptX';
requires 'File::Basename';
requires 'File::Slurp';
requires 'File::Spec';
requires 'File::Temp';   # INI parsing of remote config strings
requires 'Getopt::Long';
requires 'Hash::Flatten', '0.05';   # earlier versions mishandle keys containing dots
requires 'Hash::Merge';
requires 'JSON::MaybeXS';
requires 'JSON::Parse';
requires 'Params::Get', '0.15';
requires 'Params::Validate::Strict', '0.37';
requires 'Pod::Usage';
requires 'Readonly';   # used at module load time for AES-256-GCM size constants
requires 'Scalar::Util';
requires 'TOML::Tiny';
requires 'XML::PP', '0.06';
requires 'YAML::XS', '0.80';   # _sanitize_yaml_values guards against !!perl/code in any version

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';   # Minimum version for TEST_REQUIRES
};

on 'test' => sub {
	requires 'File::Glob';
	requires 'File::stat';
	requires 'IPC::System::Simple';   # for scripts/generate_index
	requires 'POSIX';
	requires 'Test::DescribeMe';
	requires 'Test::Memory::Cycle';
	requires 'Test::Mockingbird', '0.12';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::Returns', '0.03';
	requires 'Test::TempDir::Tiny';
	requires 'Test::Without::Module';
	requires 'autodie';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
