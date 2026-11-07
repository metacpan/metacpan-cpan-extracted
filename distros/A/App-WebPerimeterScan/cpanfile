# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.026';

requires 'Carp';
requires 'Cwd';
requires 'Data::Validate::IP', '0.31';
requires 'Digest::MD5';
requires 'Encode';
requires 'Errno';
requires 'Fcntl';
requires 'File::Find';
requires 'File::Spec';
requires 'FindBin';   # bin/webperimeter
requires 'Getopt::Long', '2.50';
requires 'HTML::Parser', '3.71';   # also provides HTML::Entities
requires 'HTML::SimpleLinkExtor', '1.20';
requires 'IO::Select', '1.17';
requires 'IO::Socket::INET', '1.31';
requires 'IO::Socket::SSL', '2.000';
requires 'IPC::System::Simple', '1.30';   # autodie :all needs it for system()
requires 'JSON::PP', '4.00';
requires 'Net::SSLeay', '1.92';
requires 'Object::Configure', '0.24';
requires 'POSIX';
requires 'Params::Get', '0.17';
requires 'Params::Validate::Strict', '0.41';
requires 'Readonly', '2.05';
requires 'Scalar::Util';
requires 'Socket', '2.020';
requires 'Sub::Private', '0.09';
requires 'Sub::Protected', '0.03';
requires 'Term::ANSIColor';
requires 'Time::HiRes', '1.97';
requires 'Time::Local', '1.28';
requires 'URI', '1.70';
requires 'autodie', '2.37';
requires 'parent';
requires 'version', '0.77';   # version->declare

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';
};

on 'test' => sub {
	requires 'File::Temp';
	requires 'Test::DescribeMe';
	requires 'Test::Fatal';
	requires 'Test::Most';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Pod::Coverage', '0.18';
	requires 'Test::Pod', '1.22';
	requires 'Test::Pod::Coverage', '1.08';
};
