# Generated from Makefile.PL using makefilepl2cpanfile

requires 'Carp';
requires 'Compress::Raw::Zlib';
requires 'Config::Abstraction';
requires 'Digest::SHA';
requires 'Encode';
requires 'Exporter';
requires 'Fcntl';
requires 'File::Basename';
requires 'File::Copy';
requires 'File::Path';
requires 'File::Spec';
requires 'File::Temp';
requires 'Getopt::Long';
requires 'IO::Handle';
requires 'IPC::Open3';
requires 'JSON::PP';
requires 'Log::Abstraction';
requires 'Object::Configure';
requires 'POSIX';
requires 'Time::HiRes';
requires 'Time::Local';

on 'test' => sub {
	requires 'File::Temp';
	requires 'Test::Deep';
	requires 'Test::Exception';
	requires 'Test::Mockingbird::TimeTravel', '0.14';
	requires 'Test::Most';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
