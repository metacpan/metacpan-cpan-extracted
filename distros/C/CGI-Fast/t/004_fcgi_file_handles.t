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
    is( $_,'some file handle','file handle passed to FCGI' )
        foreach @_[0..2];
	return bless({});
};

CGI::Fast->file_handles({
	# really here you would use IO::Handle or some equivalent
	fcgi_input_file_handle  => 'some file handle',
	fcgi_output_file_handle => 'some file handle',
	fcgi_error_file_handle  => 'some file handle',
});

ok( my $q = CGI::Fast->new,'CGI::Fast->new' );
