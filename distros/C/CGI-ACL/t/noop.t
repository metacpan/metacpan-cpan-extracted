#!perl -wT

use strict;
use warnings;
use Test::Most tests => 6;
use Test::NoWarnings;

BEGIN {
	use_ok('CGI::ACL');
	use_ok('CGI::Lingua');
}

NOOP: {
	my $acl = new_ok('CGI::ACL');

	ok(!$acl->all_denied(lingua => new_ok('CGI::Lingua', [ supported => [ 'en' ] ])));
}
