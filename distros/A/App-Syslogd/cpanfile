# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.014';

requires 'Carp';
requires 'Fcntl';
requires 'FindBin';
requires 'Getopt::Long';
requires 'IO::Handle';
requires 'IO::Socket::IP';
requires 'IPC::System::Simple';   # needed by autodie qw(:all)
requires 'Locale::Maketext';
requires 'Object::Configure', '0.24';
requires 'Params::Get', '0.17';
requires 'Params::Validate::Strict', '0.40';
requires 'Readonly';
requires 'Socket', '2.000';   # getnameinfo and NIx_NOSERV
requires 'Sub::Private', '0.05';   # first version with enforce mode
requires 'Sub::Protected', '0.02';
requires 'Text::CSV';
requires 'autodie';
requires 'parent';

on 'test' => sub {
	requires 'Config';
	requires 'Cwd';
	requires 'Errno';
	requires 'File::Spec';
	requires 'File::Temp';
	requires 'IPC::Open3';
	requires 'POSIX';
	requires 'Scalar::Util';
	requires 'Symbol';
	requires 'Test::DescribeMe';
	requires 'Test::Memory::Cycle';
	requires 'Test::Mockingbird', '0.14';   # mock_scoped multi-method form
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::Returns', '0.04';
	requires 'Test::Warn';
	requires 'Test::Without::Module';
	requires 'Text::CSV_PP';   # t/integration.t compares both backends
	requires 'Time::HiRes';
	recommends 'CGI::ACL';
	recommends 'CHI';
	recommends 'IP::Country::Fast';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
