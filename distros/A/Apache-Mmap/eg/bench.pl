#!/usr/bin/perl
##
## Apache::Mmap benchmark script
## 
## Mike Fletcher <lemur1@mindspring.com>
##

##
## $Id: bench.pl,v 1.3 1997/09/09 06:21:18 fletch Exp $
##

use strict;
use vars qw($ua);
use Carp;

use Benchmark;
use LWP::UserAgent;

$ua = new LWP::UserAgent;
my $times = shift @ARGV || 100;

##
## NOTE: The urls below need to be replaced as follows.
##
## 1) Should be the URL of a plain file (not a CGI/Apache::Registry/directory,
##    just a plain old vanilla file).
## 2) Should be the URL of a CGI/Apache::Registry script which returns the
##    contents of the same file as #1 above.
## 3) Should be a URL configured with Apache::Mmap as shown in the perldoc
##    for Apache::Mmap with the same contents as #1 above.
##
## Of course if you're running this script from a machine other than the
## one apache's running on adjust the URL appropriately.
##

timethese( $times, {
		'1: Straight file' => q~
		my $req = new HTTP::Request( 'GET', 
					     'http://localhost/file.html' );
		my $response = $ua->request($req); 
		carp "problem\n" unless $response->is_success();
		~,
		'2: open/print while <INFILE>/close' => q~
		my $req = new HTTP::Request( 'GET', 
					     'http://localhost/perl/foo' );
		my $response = $ua->request($req); 
		carp "problem\n" unless $response->is_success();
		~,
		'3: Mmapped' => q~
		my $req = new HTTP::Request( 'GET', 
					     'http://localhost/mmapped.html' );
		my $response = $ua->request($req); 
		carp "problem\n" unless $response->is_success();
		~,
		} );
