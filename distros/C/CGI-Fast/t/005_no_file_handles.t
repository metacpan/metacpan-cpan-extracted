#!perl

use strict;
use warnings;

use Test::More tests => 4;

use CGI::Fast;

# oook oook! monkey patching to mock FCGI behaviour
no warnings 'redefine';
no warnings 'once';
no warnings 'prototype';
*Accept = sub { 1 };
*FCGI::Request = sub {
	# check we actually pass file handles to FCGI::Request
    isa_ok( $_,'GLOB','no file handle passed to FCGI' )
        foreach @_[0..2];
	return bless({});
};

ok( my $q = CGI::Fast->new,'CGI::Fast->new' );
