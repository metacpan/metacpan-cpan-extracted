#!/usr/bin/perl

my $mod_perl;
BEGIN {
	local $@;
	eval { require Apache::testold };
	$mod_perl = $@ ? 0 : 1;
}  

# Skip this test if Apache::testold is not installed
unless ( $mod_perl ) {
	print "1..0\n";
	exit 0;
}

Apache::testold->skip_test unless Apache::testold->have_httpd;

use strict;
use vars qw($TEST_NUM);

my %requests = (
   # mod_perl test module: should succeed with session cookie tracking
	1  => { 
	        uri     => '/session',
	        method  => 'GET',
	       },
   # mod_perl test module: should succeed with session URI tracking
	2  => { 
	        uri     => '/uri-session',
	        method  => 'GET',
	       },
   # mod_perl test module: should succeed with cookie session tracking
	3  => { 
	        uri     => '/session-bh',
	        method  => 'GET',
	       },
   # mod_perl test module: should succeed without session tracking
	4  => { 
	        uri     => '/no-session',
	        method  => 'GET',
	       },
   # mod_perl test module: authentication
	5  => { 
	        uri     => '/session-auth',
	        method  => 'GET',
	       },
   # mod_perl test module: should succeed with session cookie tracking (OO Apache::SessionManager interface)
	6  => { 
	        uri     => '/session-OO',
	        method  => 'GET',
	       },
   # mod_perl test module: should succeed with session cookie tracking (OO Apache::SessionManager interface)
	7  => { 
	        uri     => '/session-header_exclude',
	        method  => 'GET',
	       },
   # mod_perl test module: should succeed without session cookie tracking 
	8  => { 
	        uri     => '/session-ip_exclude',
	        method  => 'GET',
	       },
);

print "1.." . (keys %requests) . "\n";

for ( 1..(keys %requests) ) { 
	Apache::testold->test(++$TEST_NUM, 1);
}

foreach my $testnum (sort {$a <=> $b} keys %requests) {
	my $response = Apache::testold->fetch($requests{$testnum});
	my $content = $response->content;
	print "$content\n" if $ENV{TEST_VERBOSE};
}

