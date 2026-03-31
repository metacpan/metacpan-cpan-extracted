# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.008';

requires 'File::HomeDir';
requires 'IPC::System::Simple';
requires 'Path::Tiny';
requires 'YAML::Tiny';
requires 'autodie';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';
};

on 'test' => sub {
	requires 'File::Slurp';
	requires 'File::Temp';
	requires 'Test::Carp';
	requires 'Test::Compile';
	requires 'Test::DescribeMe';
	requires 'Test::Most';
	requires 'Test::NoWarnings';
	requires 'Test::RequiresInternet';
	requires 'Test::Returns';
	requires 'Test::Warn';
	requires 'Test::Which';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
