# -*- perl -*-
use strict;
use Module::Metadata;
use Getopt::Long qw(:config gnu_getopt no_ignore_case pass_through);
use ExtUtils::MakeMaker;

my %makefile_args = (
    NAME      =>      'App::Acmeman',
    ABSTRACT  =>      'manages ACME certificates',
    VERSION_FROM =>   'lib/App/Acmeman.pm',
    AUTHOR    =>      'Sergey Poznyakoff <gray@gnu.org>',
    LICENSE   =>      'gpl_3',
    EXE_FILES =>      [ 'acmeman' ],
    PREREQ_PM => {
	'Getopt::Long' => 2.34,
	'File::Path'   => 2.08,
	'File::Basename' => 2.84,
	'Test::NoWarnings' => 0,
	'Crypt::RSA::Parse' => 0.043,
	'Protocol::ACME' => 1.01,
	'Protocol::ACME::Challenge::LocalFile' => 1.01,
	'Crypt::Format' => 0.06,
	'Crypt::OpenSSL::PKCS10' => 0.16,
	'Crypt::OpenSSL::RSA' => 0.28,
	'Crypt::OpenSSL::X509' => 1.804,
	'DateTime::Format::Strptime' => 1.42,
	'LWP::UserAgent' => 6.05,
	'LWP::Protocol::https' => 6.04,
	'Pod::Usage' => 1.51,
	'Pod::Man' => 2.25,
	'Text::ParseWords' => 3.27,
	'Data::Dumper' => 0,
	'Socket' => 0,
        'Sys::Hostname' => 1.16,
	'Apache::Defaults' => 1.02,
	'Apache::Config::Preproc' => 1.03,
        'Config::Parser' => 1.03
    },
    MIN_PERL_VERSION => 5.016001,
    META_MERGE => {
	'meta-spec' => { version => 2 },
	resources => {
	    repository => {
		type => 'git',
		url => 'git://git.gnu.org.ua/acmeman.git',
		web => 'http://git.gnu.org.ua/cgit/acmeman.git/',
	    },
	},
	provides => Module::Metadata->provides(version => '1.4',
					       dir => 'lib')
    }
);

my $no_autoinstall;
GetOptions('no-autoinstall|N' => \$no_autoinstall) or exit(1);
unless ($no_autoinstall) {
    eval {
	require ExtUtils::AutoInstall;
	ExtUtils::AutoInstall->import(-core => $makefile_args{PREREQ_PM});
	delete $makefile_args{PREREQ_PM};
    };
} 

WriteMakefile(%makefile_args);
