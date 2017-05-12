#!perl -Tw

use strict;
use warnings;
use Test::Most;

eval 'use autodie qw(:all)';	# Test for open/close failures

LOGGER: {
	eval 'use Log::Log4perl';

	if($@) {
		plan skip_all => "Log::Log4perl required for checking logger";
	} else {
		eval 'use Test::Log4perl';

		if($@) {
			plan skip_all => "Test::Log4perl required for checking logger";
		} else {
			plan tests => 11;

			use_ok('CGI::Lingua');

			Log::Log4perl->easy_init({ level => $Log::Log4perl::DEBUG });

			# Yes, I know the manual says it would be logged
			# under CGI::Lingua, but it's acutally logged under
			# CGI.Lingua
			my $logger = Log::Log4perl->get_logger('CGI.Lingua');

			delete $ENV{'LANGUAGE'};
			delete $ENV{'LC_ALL'};
			delete $ENV{'LC_MESSAGES'};
			delete $ENV{'LANG'};
			if($^O eq 'MSWin32') {
				$ENV{'IGNORE_WIN32_LOCALE'} = 1;
			}
			$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-zz';
			$ENV{'REMOTE_ADDR'} = '74.92.149.57';

			my $l = new_ok('CGI::Lingua' => [
				supported => [ 'en-gb' ],
				logger => $logger,
			]);

			my $tlogger = Test::Log4perl->get_logger('CGI.Lingua');

			Test::Log4perl->start();

			$tlogger->debug('language wanted: en-zz');
			$tlogger->debug('l: en');
			$tlogger->debug('_slanguage: English');

			ok($l->language() eq 'English');
			ok(!defined($l->sublanguage_code_alpha2()));

			# Test logger and cache together
			my $cache;

			eval {
				require CHI;

				CHI->import;
			};

			if($@) {
				diag('CHI not installed');
			} else {
				diag("Using CHI $CHI::VERSION");
				my $hash = {};
				$cache = CHI->new(driver => 'Memory', datastore => $hash);
				$tlogger->debug('Looking in cache for 74.92.149.57/en-us/en-us');
			}

			$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-us';

			$tlogger->debug('language wanted: en-us');
			$tlogger->debug('l: en-us');
			$tlogger->debug('accepts: en-us');
			$tlogger->debug('_rlanguage: English');
			$tlogger->debug('Find the country code for us');
			$tlogger->debug('variety name United States');
			$tlogger->debug('Set us to English=en');

			$l = new_ok('CGI::Lingua' => [
				supported => [ 'en-us' ],
				logger => $logger,
				cache => $cache,
			]);
			is($l->language(), 'English', 'Language is English');
			is($l->sublanguage_code_alpha2(), 'us', 'Variety is American English');

			# Doing the same thing should read from the cache
			$l = undef;	# Ensure it's stored in the cache before we look
			$l = new_ok('CGI::Lingua' => [
				supported => [ 'en-us' ],
				logger => $logger,
				cache => $cache,
			]);

			$tlogger->debug('Looking in cache for 74.92.149.57/en-us/en-us');
			is($l->language(), 'English', 'Language is English');
			is($l->sublanguage_code_alpha2(), 'us', 'Variety is American English');

			$tlogger->debug('Found - thawing');
			Test::Log4perl->end('Test logs all OK');
		}
	}
}
