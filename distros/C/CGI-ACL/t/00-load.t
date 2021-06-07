#!perl -T

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('CGI::ACL') || print 'Bail out!';
}

require_ok('CGI::ACL') || print 'Bail out!';

diag("Testing CGI::ACL $CGI::ACL::VERSION, Perl $], $^X");
