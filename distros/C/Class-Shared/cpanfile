# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.026';

requires 'Carp';
requires 'Digest::SHA';
requires 'Fcntl';
requires 'File::Basename';
requires 'File::Spec';
requires 'Getopt::Long';
requires 'IO::Socket::INET';
requires 'IO::Socket::UNIX';
requires 'Log::Abstraction', '0.41';
requires 'Object::Configure', '0.26';
requires 'POSIX';
requires 'Params::Get', '0.17';
requires 'Params::Validate::Strict', '0.43';
requires 'Scalar::Util';
requires 'Socket';
requires 'Storable';
requires 'Time::HiRes';
requires 'version';
recommends 'IO::Socket::SSL', '2.0';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';
};

on 'test' => sub {
	requires 'File::Temp';
	requires 'IO::Socket::SSL';
	requires 'Lingua::Conjunction';
	requires 'Net::SSLeay';
	requires 'Test::DescribeMe';
	requires 'Test::Memory::Cycle';
	requires 'Test::Mockingbird';
	requires 'Test::More', '0.98';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::Permissions';
	requires 'Test::Returns';
	requires 'Test::Without::Module';
	suggests 'Database::Abstraction', '0.57';
	suggests 'Date::Manip', '6.00';
	suggests 'Template';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Pod::Github', '0.04';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
	requires 'Test::Synopsis';
};
