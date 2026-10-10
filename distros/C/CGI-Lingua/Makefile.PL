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

if(eval { require IP::Country; 1 }) {
	my $v = IP::Country->VERSION;
	print "You have IP::Country version $v installed, so CGI::Lingua can work fast\n";
	# It also shouldn't need to do anything with the Internet,
	# so we can do all tests
	$online_tests = 1;
} elsif(eval { require Geo::IP; 1 }) {
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
} elsif(eval { require Geo::IPfree; 1 }) {
	my $v = Geo::IPfree->VERSION;
	print "You have Geo::IPfree version $v installed, so CGI::Lingua can work fast\n";
	# It also shouldn't need to do anything with the Internet,
	# so we can do all tests
	$online_tests = 1;
} elsif(!defined($online_tests)) {
	$online_tests = are_online();
}

my $test_requires = {
	'CGI::Info' => 1.14,	# t/language.t uses it directly; it is only recommended at run time
	'CHI' => 0,
	'IPC::System::Simple' => 0,
	'IPC::Run3' => 0,
	'File::Temp' => 0,
	'FindBin' => 0,
	# Needed so the geoplugin and ip-api.com code paths are tested at all;
	# they are optional at run time (see the web_lookups feature below)
	'JSON::Parse' => 0,
	'LWP::Simple::WithCache' => 0.04,
	'Test::Compile' => 0,
	'Test::DescribeMe' => 0,
	'Test::Log::Abstraction' => 0,
	'Test::Memory::Cycle' => 0,
	'Test::Mockingbird' => 0.14,	# spy on inherited methods; unmock peels one layer
	'Test::More' => 0,
	'Test::Most' => 0,
	'Test::Needs' => 0,
	'Test::Permissions' => 0,	# permission-drop tests; they skip where chmod cannot revoke access
	'Test::NoWarnings' => 0,
	'Test::Requires' => 0,
	'Test::RequiresInternet' => 0,
	'Test::Returns' => 0,
	'Test::Which' => 0,
	'Test::Without::Module' => 0
};

if($online_tests) {
	open(my $enabled, '>', 't/online.enabled') || die "Can't touch t/online.enabled $!";
	close($enabled) || die "Can't touch t/online.enabled $!";
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
	AUTHOR              => q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM        => 'lib/CGI/Lingua.pm',
	ABSTRACT_FROM       => 'lib/CGI/Lingua.pm',
	LICENSE          => 'gpl_2',
	PL_FILES	=> {},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, TEST_REQUIRES => $test_requires,
	PREREQ_PM => {
		'autodie' => 0,		# used at compile time: use autodie qw(:all)
		'Carp' => 0,
		'Class::Autouse' => 0,
		'DBD::SQLite' => 0,	# Locale::Object doesn't declare this prerequisite
		'HTTP::BrowserDetect' => 0,
		'I18N::AcceptLanguage' => 0,
		'JSON::PP' => 2.27,	# cache serialisation; in core from 5.13.9, explicit for 5.10/5.12 compat
		'Locale::Codes' => 3.59,	# Silence noisy warn messages in perl 5.28
		'Locale::Language' => 0,
		'Locale::Object' => 0.80,	# Fix for RT#131347
		'Locale::Object::Country' => 0.78,	# Fix for RT#79214
		'Log::Abstraction' => 0.33,	# used by Object::Configure for logger conversion
		'Net::Whois::IANA' => 0,
		'Net::Whois::IP' => 0,
		'Object::Configure' => 0.24,
		'Params::Get' => 0.17,	# 0.15 fast-path: unblessed hashref arg returned directly (not stored under default key)
		'Readonly' => 0,
		'Scalar::Util' => 0,
		'Socket' => 0,	# inet_pton for the pure-Perl IPv6 check
	}, dist => $dist,
	clean => { FILES => 'CGI-Lingua-* t/online.enabled' },
	META_MERGE => {
		'meta-spec' => { version => 2 },
		optional_features => {
			local_geo_databases => {
				description => 'Look up the country from a local database (fastest, no network): IP::Country, Geo::IP (needs a GeoIP.dat) or Geo::IPfree',
				prereqs => { runtime => { recommends => { 'IP::Country' => 0, 'Geo::IP' => 0, 'Geo::IPfree' => 0 } } },
			},
			baidu_subnet_detection => {
				description => 'Detect Baidu crawler IPs that misreport as EU (RT-86809); not available on Windows due to Socket6 build dependency',
				prereqs => { runtime => { recommends => { 'Net::Subnet' => 0 } } },
			},
			precise_ip_validation => {
				description => 'More rigorous IPv6 private-range detection via Data::Validate::IP; not available on Windows because NetAddr::IP (its dep) fails to build there',
				prereqs => { runtime => { recommends => { 'Data::Validate::IP' => 0.25, 'NetAddr::IP' => 0 } } },
			},
			web_lookups => {
				description => 'Look up the country (geoplugin.net) and time zone (ip-api.com) over the web when no local geo database answers; JSON::Parse and LWP::Simple::WithCache (or LWP::Simple) are needed',
				prereqs => { runtime => { recommends => { 'JSON::Parse' => 0, 'LWP::Simple::WithCache' => 0.04, 'LWP::Simple' => 0 } } },
			},
			local_time_zone => {
				description => 'Detect local time zone via DateTime::TimeZone::Local for time_zone() when running non-CGI (CLI); not available on all Windows Perl builds',
				prereqs => { runtime => { recommends => { 'DateTime::TimeZone' => 0 } } },
			},
			lang_parameter => {
				description => 'Let a lang= query parameter choose the language, through the info argument to new()',
				prereqs => { runtime => { recommends => { 'CGI::Info' => 1.14 } } },	# 1.14: lang() via AUTOLOAD
			},
		}, resources => {
			repository => {
				type => 'git',
				url => 'https://github.com/nigelhorne/CGI-Lingua.git',
				web => 'https://github.com/nigelhorne/CGI-Lingua',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=CGI-Lingua',
				# web => 'https://github.com/nigelhorne/CGI-Lingua/issues',
				mailto => 'bug-CGI-Lingua@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.10.1'	# autodie bundled into core from 5.10.1; //= and defined-or used throughout
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
