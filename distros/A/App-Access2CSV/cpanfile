# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.014';

requires 'Carp';
requires 'Config';
requires 'Encode';
requires 'Fcntl';
requires 'File::Path';
requires 'File::Spec';
requires 'File::Temp';
requires 'File::Which';
requires 'Getopt::Long';
requires 'IPC::Run3';
requires 'IPC::System::Simple';   # needed by autodie qw(:all)
requires 'Log::Abstraction';
requires 'Params::Get';
requires 'Params::Validate::Strict', '0.40';
requires 'Pod::Usage';
requires 'Readonly';
requires 'Return::Set';
requires 'Scalar::Util';
requires 'Sub::Private', '0.05';   # first version with enforce mode
requires 'Sub::Protected';
requires 'autodie';
requires 'parent';

on 'test' => sub {
	requires 'Capture::Tiny';
	requires 'Cwd';
	requires 'Errno';
	requires 'Exporter';
	requires 'File::Copy';
	requires 'FindBin';
	requires 'POSIX';
	requires 'Storable';
	requires 'Test::Memory::Cycle';
	requires 'Test::Mockingbird', '0.13';   # mock_scoped multi-method form
	requires 'Test::Most';
	requires 'Test::Returns';
	requires 'Test::Without::Module';
	requires 'Time::HiRes';
	recommends 'IO::Pty';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
