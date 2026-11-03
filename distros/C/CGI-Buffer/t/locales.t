#!perl -w

# CGI::Buffer under different system locales.  Its only message that contains
# an operating system error is when it can't read the script's file to find
# its age.  CGI::Buffer isn't compiled under "use locale", so Perl gives $! in
# the C locale whatever LC_ALL says; this checks that the message, and the
# errors that init() gives, are the same in each locale, and that the page is
# still sent.
#
# There are no geographic (GeoIP) tests: CGI::Buffer does nothing that depends
# on where the client is

use strict;
use warnings;
use Errno qw(ENOENT);
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::Most;
use Test::Needs 'CHI';
use Test::CGIBuffer qw(run_script);

# A Western European, a German and an East Asian locale.  They needn't be
# installed: the point is that the output doesn't depend on them
my @LOCALES = ('en_US.UTF-8', 'de_DE.UTF-8', 'ja_JP.UTF-8');

# The text of ENOENT as Perl gives it, rather than POSIX::strerror, which
# would come from the C library and could differ
my $enoent = do { local $! = ENOENT; "$!" };

foreach my $locale(@LOCALES) {
	subtest "LC_ALL=$locale" => sub {
		my $r = run_script(
			# The script's file isn't there, so its age can't be found
			env => {
				LC_ALL => $locale,
				LANG => $locale,
				PERL_BADLANG => 0,	# Don't warn about locales that aren't installed
				SCRIPT_FILENAME => '/nonexistent/cgi-bin/script.pl',
			},
			code => q{
				package StderrLogger;
				sub new { bless {}, shift }
				sub AUTOLOAD { our $AUTOLOAD; print STDERR "$AUTOLOAD: @_[1..$#_]\n" unless($AUTOLOAD =~ /DESTROY/) }
				package main;
				use CHI;
				use Storable;

				# Something in the cache, so that is_cached() looks for the script's age
				my $cache = CHI->new(driver => 'Memory', global => 1);
				$cache->set('k', Storable::freeze({ body => 'cached', headers => 'Content-Type: text/plain' }));
				CGI::Buffer::init(
					logger => StderrLogger->new(),
					cache => $cache,
					cache_key => 'k',
					colour => 'blue',
				);
				my $cached = CGI::Buffer::is_cached();
				print "Content-Type: text/plain\n\ncached=$cached";
			}
		);
		like($r->{stderr},
			qr/\QCGI::Buffer: Can't determine the age of \/nonexistent\/cgi-bin\/script.pl: $enoent\E/,
			'the operating system error is in the message');
		like($r->{stderr}, qr/CGI::Buffer: init: unknown option colour ignored/, 'init() gives its error');
		is($r->{body}, 'cached=0', 'the page is not taken from the cache, and is sent');
	};
}

done_testing();
