#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker;
use Getopt::Long;	# Technique inspired by IO::Lambda
use IO::Socket::INET;

my $online_tests;

if($ENV{RELEASE_TESTING}) {
	$online_tests = are_online();
} elsif($ENV{AUTOMATED_TESTING} || $ENV{NO_NETWORK_TESTING}) {
	$online_tests = 0;
} else {
	Getopt::Long::GetOptions('online-tests!' => \$online_tests);

	if(eval { require IP::Country; }) {
		my $v = IP::Country->VERSION;
		print "You have IP::Country version $v installed, so CGI::Lingua can work fast\n";
		# It also shouldn't need to do anything with the Internet,
		# so we can do all tests
		$online_tests = 1;
	} elsif(eval { require Geo::IP; }) {
		my $v = Geo::IP->VERSION;
		if(($^O ne 'MSWin32') && (! -r '/usr/local/share/GeoIP/GeoIP.dat')) {
			print "Can't find your GeoIP.dat file for Geo::IP\n";
			$online_tests = are_online();
		} else {
			print "You have Geo::IP version $v installed, so CGI::Lingua can work fast\n";
			# It also shouldn't need to do anything with the Internet,
			# so we can do all tests
			$online_tests = 1;
		}
	} elsif(eval { require Geo::IPfree; }) {
		my $v = Geo::IPfree->VERSION;
		print "You have Geo::IPfree version $v installed, so CGI::Lingua can work fast\n";
		# It also shouldn't need to do anything with the Internet,
		# so we can do all tests
		$online_tests = 1;
	} elsif(!defined($online_tests)) {
		$online_tests = are_online();
	}
}

if($online_tests) {
	open(my $enabled, '>', 't/online.enabled') || die "Can't touch t/online.enabled $!";
	close($enabled) || die "Can't touch t/online.enabled $!";
} else {
	unlink('t/online.enabled');
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
    PL_FILES            => {},
    BUILD_REQUIRES => {
	'Test::Most' => 0,
	'Test::NoWarnings' => 0,
	'Test::Requires' => 0,
	# 'Test::Kwalitee' => 0,
	'autodie' => 0,
	'IPC::System::Simple' => 0,
	'Test::Compile' => 0,
    },
    PREREQ_PM => {
	'DBD::SQLite' => 0,	# Locale::Object doesn't declare this prerequisite
	'Locale::Object::Country' => 0,
	'I18N::AcceptLanguage' => 0,
	'Locale::Language' => 0,
	'I18N::LangTags::Detect' => 1.04,
	'Data::Validate::IP' => 0,
	'Net::Whois::IANA' => 0,
	'Net::Whois::IP' => 0,
	'Class::Load' => 0,
	'CGI::Info' => 0.60, # For AUTOLOAD
	'Sys::Syslog' => 0,
	'HTTP::BrowserDetect' => 0,
	'Net::Subnet' => 0,
	'Class::Autouse' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Lingua-* t/online.enabled' },
    META_MERGE		=> {
    	'meta-spec' => { version => 2 },
    	resources => {
    		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/CGI-Lingua.git',
			web => 'https://github.com/nigelhorne/CGI-Lingua',
    		},
	},
    },
    MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);

sub are_online
{
	my $s = IO::Socket::INET->new(
		# PeerAddr => 'www.ripe.net:43',
		PeerAddr => 'whois.apnic.net:43',
		Timeout => 5
	);
	if($s) {
		print <<EOF;

You appear to be directly connected to the Internet.  I have some tests
that try to query Whois servers.
These tests will be slow, consider installing IP::Country, Geo::IPfree or
Geo::IP

EOF
		close($s);

		# Timeout inspired by Mail::IMAPClient
		my $rc;
		eval {
			local $SIG{ALRM} = sub { die "alarm\n" };
			alarm(60);
			$rc = prompt('Do you want to enable these tests?', 'y') =~ /^y/i ? 1 : 0;
			alarm(0);
		};
		if($@) {
			print "\n";
			return 1;	# The default is 'y'
		}
		return $rc;
	} else {
		print "On-line tests disabled because I couldn't detect an Internet connexion\n";
		print "Consider installing IP::Country, Geo::IPfree or Geo::IP\n";
		return 0;
	}
}
