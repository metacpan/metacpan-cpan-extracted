#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker;
use Getopt::Long;	# Technique inspired by IO::Lambda
use IO::Socket::INET;

my $online_tests;

# Test for broken smokers that don't set AUTOMATED_TESTING
if(my $reporter = $ENV{'PERL_CPAN_REPORTER_CONFIG'}) {
	if($reporter =~ /smoker/i) {
		warn 'AUTOMATED_TESTING added for you' if(!defined($ENV{'AUTOMATED_TESTING'}));
		$ENV{'AUTOMATED_TESTING'} = 1;
	}
}

if(defined($ENV{'GITHUB_ACTION'}) || defined($ENV{'CIRCLECI'}) || defined($ENV{'TRAVIS_PERL_VERSION'}) || defined($ENV{'APPVEYOR'})) {
	# Prevent downloading and installing stuff
	warn 'AUTOMATED_TESTING added for you' if(!defined($ENV{'AUTOMATED_TESTING'}));
	$ENV{'AUTOMATED_TESTING'} = 1;
	$ENV{'NO_NETWORK_TESTING'} = 1;
}

if($ENV{'AUTHOR_TESTING'}) {
	$online_tests = are_online();
} else {
	Getopt::Long::GetOptions('online-tests!' => \$online_tests);

	if(!defined($online_tests)) {
		$online_tests = are_online();
	}
	if(!$online_tests) {
		print "On-line tests have been disabled\n";
	}
}

if(eval 'require IP::Country') {
	my $v = IP::Country->VERSION;
	print "You have IP::Country version $v installed, so CGI::Lingua can work fast\n";
	# It also shouldn't need to do anything with the Internet,
	# so we can do all tests
	$online_tests = 1;
} elsif(eval 'require Geo::IP') {
	my $v = Geo::IP->VERSION;
	if(($^O ne 'MSWin32') && (! -r '/usr/local/share/GeoIP/GeoIP.dat')) {
		print "Warning: Can't find your GeoIP.dat file for Geo::IP, disabling that module\n";
		if(!defined($online_tests)) {
			$online_tests = are_online();
		}
	} else {
		print "You have Geo::IP version $v installed, so CGI::Lingua can work fast\n";
		# It also shouldn't need to do anything with the Internet,
		# so we can do all tests
		$online_tests = 1;
	}
} elsif(eval 'require Geo::IPfree') {
	my $v = Geo::IPfree->VERSION;
	print "You have Geo::IPfree version $v installed, so CGI::Lingua can work fast\n";
	# It also shouldn't need to do anything with the Internet,
	# so we can do all tests
	$online_tests = 1;
} elsif(!defined($online_tests)) {
	$online_tests = are_online();
}

my $test_requires = {
	'File::Temp' => 0,
	'Test::Carp' => 0,
	'Test::DescribeMe' => 0,
	'Test::Most' => 0,
	'Test::Needs' => 0,
	'Test::NoWarnings' => 0,
	'Test::Requires' => 0,
	# 'Test::Kwalitee' => 0,
	'autodie' => 0,
	'IPC::System::Simple' => 0,
	'Test::Compile' => 0,
	'Test::Without::Module' => 0
};

if($online_tests) {
	open(my $enabled, '>', 't/online.enabled') || die "Can't touch t/online.enabled $!";
	close($enabled) || die "Can't touch t/online.enabled $!";
	$test_requires->{'LWP::Simple::WithCache'} = 0.04;
} else {
	unlink('t/online.enabled');
}

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
    NAME                => 'CGI::Lingua',
    AUTHOR              => q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM        => 'lib/CGI/Lingua.pm',
    ABSTRACT_FROM       => 'lib/CGI/Lingua.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
	PL_FILES	=> {}, CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
    }, TEST_REQUIRES => $test_requires,
    PREREQ_PM => {
	'DBD::SQLite' => 0,	# Locale::Object doesn't declare this prerequisite
	'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	'Locale::Object::Country' => 0.78,	# Fix for RT#79214
	'Locale::Object' => 0.80,	# Fix for RT#131347
	'I18N::AcceptLanguage' => 0,
	'Locale::Language' => 0,
	'I18N::LangTags::Detect' => 1.04,
	'Data::Validate::IP' => 0.25,	# For is_private_ip
	'Locale::Codes' => 3.59,	# Silence noisy warn messages in perl 5.28
	'Log::Abstraction' => 0.05,
	'Net::Whois::IANA' => 0,
	'Net::Whois::IP' => 0,
	'NetAddr::IP' => 0,
	'Object::Configure' => 0,
	'Params::Get' => 0,
	'Class::Load' => 0,
	'CGI::Info' => 0.60, # For AUTOLOAD
	'Sys::Syslog' => 0,
	'HTTP::BrowserDetect' => 0,
	'Net::Subnet' => 0,
	'Class::Autouse' => 0
    }, dist => $dist,
    clean               => { FILES => 'CGI-Lingua-* t/online.enabled' },
    META_MERGE		=> {
    	'meta-spec' => { version => 2 },
    	resources => {
		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/CGI-Lingua.git',
			web => 'https://github.com/nigelhorne/CGI-Lingua',
			repository => 'https://github.com/nigelhorne/CGI-Lingua',
		}, bugtracker => {
			# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=CGI-Lingua',
			web => 'https://github.com/nigelhorne/CGI-Lingua/issues',
			url => 'https://github.com/nigelhorne/CGI-Lingua/issues',
			mailto => 'bug-CGI-Lingua@rt.cpan.org'
		}
	},
    },
    MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);

sub are_online
{
	return 0 if($ENV{'NO_NETWORK_TESTING'} || $ENV{'CIRCLECI'} || $ENV{'TRAVIS_PERL_VERSION'} || $ENV{'AUTOMATED_TESTING'} || $ENV{'NONINTERACTIVE_TESTING'} || (!-t STDIN));

	if(my $s = IO::Socket::INET->new(
		# PeerAddr => 'www.ripe.net:43',
		PeerAddr => 'whois.apnic.net:43',
		Timeout => 5
	)) {
		if($ENV{'PERL_MM_USE_DEFAULT'}) {
			close($s);
			return 1;
		}

		# FIXME: should test if any of the modules has been installed
		if((-r '/usr/local/share/GeoIP/GeoIP.dat') ||
		   (-r '/usr/share/GeoIP/GeoIP.dat')) {
			print <<EOF;

You appear to be directly connected to the Internet.  I have some tests
that try to query Whois servers.
These tests will be slow, consider installing IP::Country, Geo::IPfree or
Geo::IP.

EOF
		} else {
			print <<EOF;

You appear to be directly connected to the Internet.  I have some tests
that try to query Whois servers.
These tests will be slow, consider installing either IP::Country or Geo::IPfree.

EOF
		}
		close($s);

		# Timeout inspired by Mail::IMAPClient
		my $rc;
		eval {
			local $SIG{ALRM} = sub { die 'alarm' };
			alarm(60);
			$rc = prompt('Do you want to enable these tests?', 'y') =~ /^y/i ? 1 : 0;
			alarm(0);
		};
		if($@) {
			print "\n";
			return 1;	# The default is 'y'
		}
		return $rc;
	}
	print "On-line tests disabled because I couldn't detect an Internet connexion\n",
		"Consider installing IP::Country, Geo::IPfree or Geo::IP\n";
	return 0;
}
