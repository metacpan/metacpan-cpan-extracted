# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.014';

requires 'File::HomeDir';
requires 'IPC::System::Simple';
requires 'Params::Get', '0.17';
requires 'Path::Tiny', '0.034';   # errors as Path::Tiny::Error objects
requires 'Readonly';
requires 'Text::Diff';
requires 'YAML::Tiny';
requires 'autodie';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';   # Minimum version for TEST_REQUIRES
};

on 'test' => sub {
	requires 'Capture::Tiny';
	requires 'File::Temp';
	requires 'Module::CPANfile';
	requires 'Test::DescribeMe';
	requires 'Test::Memory::Cycle';
	requires 'Test::Mockingbird', '0.13';   # around, mock_scoped, spy, unmock, restore
	requires 'Test::Most';
	requires 'Test::Returns', '0.04';
	requires 'Test::Without::Module';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::EOF';   # t/eof.t (author test)
	requires 'Test::EOL';   # t/eol.t (author test)
	requires 'Test::Kwalitee';   # t/kwalitee.t (author test)
	requires 'Test::Needs';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
