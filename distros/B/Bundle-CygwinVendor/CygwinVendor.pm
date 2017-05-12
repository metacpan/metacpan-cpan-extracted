package Bundle::CygwinVendor;

$VERSION = '0.02';

1;

__END__

=head1 NAME

Bundle::CygwinVendor - Bundle for cygwin default vendor packages

=head1 SYNOPSIS

For all Perl versions:

  $ cpan Bundle::CygwinVendor

=head1 CONTENTS

Pod::Escapes		1.06

Pod::Simple		3.28

Test::Pod		1.48

Devel::Symdump		2.11

Pod::Coverage		0.23

Test::Pod::Coverage	1.08

Compress::Raw::Bzip2	2.064

IO::Compress::Bzip2	2.064

Compress::Bzip2		2.17

IO::String		1.08

Archive::Zip		1.37

Term::ReadKey		2.31

Term::ReadLine::Perl	1.0303

Term::ReadLine::Gnu	1.24

XML::NamespaceSupport	1.11

XML::SAX::Base		1.08

XML::SAX		0.99

XML::LibXML		2.0116

XML::Parser		2.41

Proc::ProcessTable	0.50

YAML			0.71

YAML::LibYAML		0.41

Config::Tiny		2.20

File::Copy::Recursive	0.38

IPC::Run3		0.048

Probe::Perl		0.03

Tee			0.14

IO::CaptureOutput	1.1103

File::pushd		1.006

File::HomeDir		1.00

Digest::SHA		5.89

Module::Signature	0.73

URI			1.60

HTML::Tagset		3.20

HTML::Parser		3.71

LWP			6.06

CPAN			2.05

Net::IP			1.26

Net::DNS		0.74

Test::Reporter		1.60

Net::SSLeay		1.58

IO::Socket::SSL		1.981

LWP::Protocol::https	6.04

common::sense		3.72

Types::Serialiser	1.0

JSON::XS		3.01

JSON			2.90

Metabase::Client::Simple 0.009

Data::UUID		1.219

Data::GUID		0.048

CPAN::DistnameInfo	0.12

Metabase::Fact		0.024

Config::Perl::V		0.20

CPAN::Testers::Report	1.999001

Test::Reporter::Transport::Metabase	1.999008

CPAN::Reporter		1.2011

Text::Glob		0.09

Number::Compare		0.03

File::Find::Rule	0.33

Data::Compare		1.24

CPAN::Checksums		2.09

File::Remove		1.52

File::chmod		0.40

Params::Util		1.07

Test::Script		1.07

CPAN::Inject		1.14

Net::Telnet		3.04

Module::ScanDeps	1.13

PAR::Dist		0.49

ExtUtils::CBuilder	0.280216

ExtUtils::ParseXS	3.24

Software::License	0.103010

Module::Build		0.4205

Socket6			0.25

IO::Socket::INET6	2.72

IO::Socket::IP		0.29

B::Generate		1.48

PadWalker		1.98

Data::Alias		1.18


=head1 DESCRIPTION

The official cygwin perl package contains modules in vendor to be able
to use CPAN out of the box, and every user should be able to install
any CPAN package by herself, without setup.exe.

Cygwin packaging does not want to maintain all its dependencies extra,
CPAN is good enough.  Not all packages required for CPAN are bundled
with the default perl.

=head1 AUTHOR

Reini Urban
