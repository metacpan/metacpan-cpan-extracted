require 5.6.1;
use ExtUtils::MakeMaker;
use lib qw(../blib/lib lib );
use Cwd;

push @ARGV, '-maxclients', '2';

my $mod_perl_ok = 0;
my $mod_perl_version = 'unknown or uninstalled';
eval 'use Apache';
unless ($@) {
	$mod_perl_version = $Apache::VERSION;
	$mod_perl_ok = 1 if (($mod_perl_version < 1.99) and ($mod_perl_version >= 1.26));
}

unless ($mod_perl_ok) {
	print <<__MSG__;

These modules are designed to work under Apache 1.X using mod_perl 1.26
or greater (but not mod_perl 1.99 or better).  This does not seem to be
an appropriate platform.  If you know what you're doing, or if you just
want to examine these modules, you can opt to continue.  Otherwise,
please install the appropriate software before continuing.  See
http://perl.apache.org for details.

__MSG__
	my $ok = prompt('Continue (y/n)?', 'n');
	if (lc($ok) ne 'y') {
		print "OK, aborting...\n\n";
		exit 0;
	}
}

my $have_atest = 1;
my $atest_version = 0;
eval 'use Apache::Test';
unless ($@) {
	eval 'use Apache::Test';
	$atest_version = $Apache::Test::VERSION;
}

eval ('use Apache::TestMM qw(test clean)') if ($atest_version >= 1.08);
if ($@ or ($atest_version < 1.08)) {
	$have_atest = 0;
	print <<__MSG__;

The test suite for this module requires Apache::Test version 1.08 or
better, which is apparently not available.  It is highly recommended
that you run the test suite, but it is not absolutely required.  If you
choose to continue, you may install Apache::Wyrd, but it may be
unusable.  Do you want to continue?

__MSG__
	my $ok = prompt('Continue (y/n)?', 'n');
	if (lc($ok) ne 'y') {
		print "OK, aborting...\n\n";
		exit 0;
	} else {
		print <<__MSG__;

OK. Tests will fail if you 'make test', but this will not necessarily
mean the modules are unusable.  However, if you run into problems,
please install Apache::Test v 1.08+ and run the complete test suite
(make test) before contacting the author for support.

__MSG__
		sleep 5;
	}
}

my $blowfish = 'Crypt::Blowfish';
my $cgi = 'Apache::Request';
my $cookie = 'Apache::Cookie';

if (!$ENV{AUTOMATED_TESTING}) {
	
	print "\nWyrds require Blowfish Crypto, which comes in xs or pure perl.\n";
	print "Checking for (faster, preferred) xs version...\n";
	eval ('use Crypt::Blowfish');
	if ($@) {
		print "Falling back on pure perl version.\n";
		eval('use Crypt::Blowfish_PP');
		$blowfish .= '_PP' unless ($@);
		print "No Blowfish Crypto found!\n" if ($@);
	} else {
		print "Good. You have Crypt::Blowfish\n";
	}
	
	print "\nWyrds require a CGI interpreter, either libapreq or CGI.\n";
	print "Checking for (faster, preferred) libapreq...\n";
	eval ('use Apache::Request');
	if ($@) {
		print "Falling back on CGI.\n";
		eval('use CGI');
		$cgi = 'CGI' unless ($@);
		print "But I can't find either!\n" if ($@);
	} else {
		print "Good. You have Apache::Request\n";
	}
	
	print "\nWyrds require a Cookie module.\n";
	print "Checking for (faster, preferred) Apache::Cookie...\n";
	eval ('use Apache::Cookie');
	if ($@) {
		print "Falling back on CGI::Cookie.\n";
		eval('use CGI::Cookie');
		$cookie = 'CGI::Cookie' unless ($@);
		print "But I can't find either!\n" if ($@);
	} else {
		print "Good. You have Apache::Cookie\n";
	}

}
	
if ($have_atest) {
	print "\nOK... Generating Makefile and TEST...\n";
	Apache::TestMM::filter_args();
	Apache::TestMM::generate_script('t/TEST');
} else {
	use Config;
	print "\nOK... Generating Makefile...\n";
};

my $makefile = WriteMakefile(
	'NAME'		=> 'Apache::Wyrd',
	'VERSION_FROM'	=> 'Wyrd.pm',
	'PREREQ_PM'		=> {
		Apache					=>	1.26,
		Apache::Constants		=>	0,
		Apache::URI				=>	0,
		Apache::Util			=>	0,
		BerkeleyDB				=>	.23,
		Class::Singleton		=>	0,
		DBI						=>	0,
		Digest::SHA			=>	0,
		HTML::Entities			=>	0,
		HTTP::Request::Common	=>	0,
		LWP::UserAgent			=>	0,
		MIME::Base64			=>	0,
		XML::Dumper				=>	.67,
		$blowfish				=>	0,
		$cgi					=>	0,
		$cookie					=>	0
	},
	AUTHOR			=> 'barry king <wyrd@nospam.wyrdwright.com>',
	clean			=> {
			FILES	=> q(
				t/TEST
				t/data/testindex.db
				t/data/testindex2.db
				t/data/testindex3.db
				t/data/testindex2_big.db
				t/data/ticketbook.db
				t/data/cookies.txt
				t/data/__db.???
				t/logs
				t/conf/modperl_startup.pl
				t/htdocs/index.html
			)
	}
);

my $wyrd_version = $makefile->{VERSION};
my $perl_version = $];
my $os = $^O;
my $bdb = $BerkeleyDB::db_version;
my $error = 0;
my $ua = undef;
my $url = 'http://www.wyrdwright.com/wyrd/wyrd_counter.html';

eval('use LWP::UserAgent');
$error ||= $@;
eval('use HTTP::Request::Common');
$error ||= $@;
eval('$ua = LWP::UserAgent->new');
$error ||= $@;
eval('$ua->timeout(20)');
$error ||= $@;

exit 0 if ($error);

print <<__MSG__;

==================
  SURVEY REQUEST
==================

The author of Apache::Wyrd would like to know what version of perl and
the operating system you are using to better support your system. The
information would be sent by HTTP to the www.wyrdwright.com site which
will log the time and the source of the information (IP address).  NO
OTHER SYSTEM INFORMATION WILL BE SENT THAN THE FOLLOWING:

	Apache::Wyrd version: $wyrd_version
	perl version: $perl_version
	Operating System: $os
	mod_perl version: $mod_perl_version
	Berkeley DB version: $bdb

May I send this information to the Author?

__MSG__

my $ok = prompt('Send info (y/n)?', 'y');
if (lc($ok) ne 'y') {
	print "OK, I won't send it...\n\n";
	exit 0;
} else {
	print "Thanks.  Sending...\n\n";
	eval '
	use LWP::UserAgent;
	use HTTP::Request::Common;
	$ua = LWP::UserAgent->new;
	$ua->timeout(20);
	$ua->request(POST $url,
		[
			perl		=>	$perl_version,
			mod_perl	=>	$mod_perl_version,
			os			=>	$os,
			bdb			=>	$bdb,
			wyrds		=>	$wyrd_version
		]
	);
	';
}
