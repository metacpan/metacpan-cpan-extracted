#!perl -wT

use strict;

use Test::Most tests => 1;

BEGIN {
	use_ok('CGI::Buffer') || print "Bail out!";
}

diag("Testing CGI::Buffer $CGI::Buffer::VERSION, Perl $], $^X");
