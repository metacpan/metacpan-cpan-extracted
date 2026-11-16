# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.014';

requires 'Carp';
requires 'Compress::Raw::Zlib';
requires 'Config::Abstraction', '0.41';   # explain_sources()
requires 'Cwd';
requires 'Digest::SHA';
requires 'Exporter';
requires 'Fcntl';
requires 'File::Basename';
requires 'File::Copy';
requires 'File::Path';
requires 'File::Spec';
requires 'File::Temp';
requires 'FindBin';
requires 'Getopt::Long';
requires 'IO::Handle';
requires 'IPC::Open3';
requires 'IPC::System::Simple', '1.30';
requires 'JSON::MaybeXS', '1.004';   # pulls in Cpanel::JSON::XS given a compiler
requires 'JSON::PP';
requires 'List::Util', '1.54';
requires 'Log::Abstraction', '0.36';   # structured fields
requires 'Object::Configure';
requires 'Params::Get', '0.17';
requires 'Params::Validate::Strict', '0.41';
requires 'POSIX';
requires 'Readonly', '2.05';
requires 'Scalar::Util';
requires 'Sub::Private', '0.07';
requires 'Sub::Protected', '0.03';
requires 'Sys::Hostname';
requires 'Time::HiRes';
requires 'Time::Local';
requires 'autodie', '2.37';
requires 'version', '0.77';

recommends 'Cpanel::JSON::XS';   # JSON::MaybeXS adds it given a compiler

if ($^O eq 'MSWin32') {
	requires 'Win32API::File';   # Process: pipe ends the child must not inherit
}

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';   # first to honour TEST_REQUIRES
};

on 'test' => sub {
	requires 'Errno';
	requires 'File::Find';
	requires 'File::Temp';
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
