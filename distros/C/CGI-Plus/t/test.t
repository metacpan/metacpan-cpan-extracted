#!/usr/bin/perl -w
use strict;
use Carp 'croak';

# TESTING
# BEGIN { system '/usr/bin/clear' }
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;
# forcetext();

# use the module
use CGI::Plus;

# plan tests
use Test::More;
plan tests => 37;

# general purpose variable
my ($val, $org, $new, $got, $should);


# stubs for comparison subroutines
sub err;
sub comp;
sub comp_bool;
sub is_def;


#------------------------------------------------------------------------------
# test environment variables
#
$ENV{'CONTEXT_DOCUMENT_ROOT'} = '/var/www/html';
$ENV{'CONTEXT_PREFIX'} = '';
$ENV{'DOCUMENT_ROOT'} = '/var/www/html';
$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
$ENV{'HTTP_ACCEPT'} = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8';
$ENV{'HTTP_ACCEPT_ENCODING'} = 'gzip, deflate';
$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-us,en;q=0.5';
$ENV{'HTTP_CONNECTION'} = 'keep-alive';
$ENV{'HTTP_COOKIE'} = 'cookie_single_val=pH3FdqRbvd; cookie_multiple_vals=v&xD5wnHLJNv&j&3';
$ENV{'HTTP_HOST'} = 'www.example.com';
$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:14.0) Gecko/20100101 Firefox/14.0.1';
$ENV{'LD_LIBRARY_PATH'} = '/usr/local/apache2/lib';
$ENV{'MACHINE_NAME'} = 'Idocs';
$ENV{'PATH'} = '';
$ENV{'QUERY_STRING'} = 'x=2&y=1&y=2';
$ENV{'REMOTE_ADDR'} = '999.999.999.999';
$ENV{'REMOTE_PORT'} = '39177';
$ENV{'REQUEST_METHOD'} = 'GET';
$ENV{'REQUEST_SCHEME'} = 'http';
$ENV{'REQUEST_URI'} = '/cgi-plus/?x=2&y=1&y=2';
$ENV{'SCRIPT_FILENAME'} = '/var/www/html/miko/self_link/index.pl';
$ENV{'SCRIPT_NAME'} = '/miko/self_link/index.pl';
$ENV{'SERVER_ADDR'} = '64.124.102.16';
$ENV{'SERVER_ADMIN'} = 'miko@example.com';
$ENV{'SERVER_NAME'} = 'www.example.com';
$ENV{'SERVER_PORT'} = '80';
$ENV{'SERVER_PROTOCOL'} = 'HTTP/1.1';
$ENV{'SERVER_SIGNATURE'} = '';
$ENV{'SERVER_SOFTWARE'} = 'Apache/2.4.2 (Unix)';
$ENV{'SHOWSTUFF'} = '1';
#
# test environment variables
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# main body
#
do {

	#------------------------------------------------------------------------------
	##- get cgi object
	#
	do {
		my ($cgi);
		my $name = 'get cgi object';
		
		$cgi = CGI::Plus->new();
		is_def '$cgi', $cgi, $name;
	};
	#
	# get cgi object
	#------------------------------------------------------------------------------
	
	
	#------------------------------------------------------------------------------
	##- params
	#
	do {
		my (@ys, $cgi);
		$cgi = CGI::Plus->new();
		my $name = 'params';
		
		# single param
		comp $cgi->param('x'), 2, "$name: single param";
		
		# multiple params
		@ys = $cgi->param('y');
		comp scalar(@ys), 2, "$name: multiple params";
	};
	#
	# params
	#------------------------------------------------------------------------------


	#------------------------------------------------------------------------------
	##- csrf
	#
	do {
		my ($csrf_value, $cgi, $secondary_name);
		$cgi = CGI::Plus->new();
		my $name = 'csrf';
		
		$secondary_name = 'set csrf';
		comp_bool $cgi->csrf(),  0, "$name, $secondary_name: [1]";
		comp_bool $cgi->csrf(1), 1, "$name, $secondary_name: [2]";
		comp_bool $cgi->csrf(),  1, "$name, $secondary_name: [3]";
		
		# get csrf value
		$csrf_value = $cgi->oc->{'csrf'}->{'values'}->{'v'};
		is_def '$csrf_value', $csrf_value, "$name: get csrf value";
		
		# csrf name
		comp $cgi->csrf_name, 'csrf', "$name: csrf name";
		
		# csrf form field
		comp
			$cgi->csrf_field,
			qq|<input type="hidden" name="csrf" value="$csrf_value">|,
			"$name: csrf form field";
		
		# csrf URL param
		comp $cgi->csrf_param, qq|csrf=$csrf_value|, "$name: csrf URL param";
		
		# csrf_check: should return false
		comp_bool $cgi->csrf_check(), 0, "$name: csrf_check: should return false";
	};
	#
	# csrf
	#------------------------------------------------------------------------------
	
	
	
	#------------------------------------------------------------------------------
	##- self_link
	#
	do {
		my ($url, $cgi, $secondary_name);
		$cgi = CGI::Plus->new();
		my $name = 'self_link';
		
		$secondary_name = 'get current url';
		$url = $cgi->self_link();
		ok ($url =~ m|x=2|s, "$name, $secondary_name: param x=2");
		ok ($url =~ m|y=1|s, "$name, $secondary_name: param y=1");
		ok ($url =~ m|y=2|s, "$name, $secondary_name: param y=2");
		
		$secondary_name = 'set new value for x';
		$url = $cgi->self_link(params=>{x=>3});
		ok ($url =~ m|x=3|s, "$name, $secondary_name: param x=3");
		ok ($url =~ m|y=1|s, "$name, $secondary_name: param y=1");
		ok ($url =~ m|y=2|s, "$name, $secondary_name: param y=2");
		
		$secondary_name = 'set new value for y';
		$url = $cgi->self_link(params=>{y=>3});
		ok ($url =~ m|x=2|s, "$name, $secondary_name: param x=2");
		ok ($url =~ m|y=3|s, "$name, $secondary_name: param y=3");
		
		$secondary_name = 'should only have one y param';
		$url =~ s|y=3||s;
		ok ($url !~ m|y=|s, "$name, $secondary_name");
		
		$secondary_name = 'set new valus for y';
		$url = $cgi->self_link(params=>{y=>[5,6]});
		ok ($url =~ m|x=2|s, "$name, $secondary_name: param x=2");
		ok ($url =~ m|y=5|s, "$name, $secondary_name: param y=5");
		ok ($url =~ m|y=6|s, "$name, $secondary_name: param y=6");
		
		# remove all params
		$url = $cgi->self_link(clear_params=>1);
		comp $url, '/cgi-plus/', "$name: remove all params";
		
		# clear params, add new param
		$url = $cgi->self_link(clear_params=>1, params=>{j=>7});
		comp $url, '/cgi-plus/?j=7', "$name: clear params, add new param";
	};
	#
	# self_link
	#------------------------------------------------------------------------------


	#------------------------------------------------------------------------------
	##- incoming cookies
	#
	do {
		my ($ic, $cookie, $cgi);
		my $name = 'incoming cookies';
		
		# get cgi object
		$cgi = CGI::Plus->new();
		
		# get incoming cookies
		$ic = $cgi->ic();
		is_def '$ic', $ic, "$name: get incoming cookies";
		
		# values
		# $ENV{'HTTP_COOKIE'} = 'cookie_single_val=pH3FdqRbvd; cookie_multiple_vals=v&xD5wnHLJNv';
		
		# single value cookie
		$cookie = $ic->{'cookie_single_val'};
		comp $cookie->{'value'}, 'pH3FdqRbvd', "$name: single value cookie";
		
		# multiple value cookie
		$cookie = $ic->{'cookie_multiple_vals'};
		comp $cookie->{'values'}->{'v'}, 'xD5wnHLJNv', "$name: multiple value cookie";
	};
	#
	# incoming cookies
	#------------------------------------------------------------------------------


	#------------------------------------------------------------------------------
	##- resend_cookie
	#
	do {
		my ($old_cookie, $new_cookie);
		my $cgi = CGI::Plus->new();
		my $name = 'resend_cookie';
		
		# get original cookie
		$old_cookie = $cgi->ic->{'cookie_multiple_vals'};
		is_def '$old_cookie', $old_cookie, "$name: get original cookie";
		
		# get resent cookie
		$new_cookie = $cgi->resend_cookie('cookie_multiple_vals');
		is_def '$new_cookie', $new_cookie, $old_cookie, "$name: get resent cookie";
		
		# should not be same object
		comp
			"$old_cookie",
			"$new_cookie",
			"$name: should not be same object",
			same => 0;
		
		# compare values
		comp
			$old_cookie->{'values'}->{'v'},
			$new_cookie->{'values'}->{'v'},
			"$name: compare values";
	};
	#
	# resend_cookie
	#------------------------------------------------------------------------------
	
	
	#------------------------------------------------------------------------------
	##- new_send_cookie
	#
	do {
		my ($cookie, %headers, $secondary_name);
		my $cgi = CGI::Plus->new();
		my $name = 'new_send_cookie';
		
		$secondary_name = 'new cookie with multiple values';
		$cookie = $cgi->new_send_cookie('new_cookie');
		is_def '$cookie', $cookie, "$name, $secondary_name: \$cookie";
		is_def "\$cookie->{'values'}", $cookie->{'values'}, "$name, $secondary_name: \$cookie->{'values'}";
		
		# set new value for x
		$cookie->{'values'}->{'x'} = 100;
		
		# get headers
		%headers = headers($cgi);
		
		$secondary_name = 'cookies should include new_cookie';
		FIND_COOKIE: {
			foreach my $cookie (@{$headers{'Set-Cookie'}}) {
				ok($cookie =~ m|^new_cookie=x&100;|s, "$name, $secondary_name: $cookie");
			}
		}
	};
	#
	# new_send_cookie
	#------------------------------------------------------------------------------
	
	
	#------------------------------------------------------------------------------
	##- set_header
	#
	do { ##i
		my (%headers);
		my $cgi = CGI::Plus->new();
		my $name = 'set_header';
		
		# set new header
		$cgi->set_header('myheader', 'whatever');
		
		# get headers
		%headers = headers($cgi);
		
		# chould have new header
		comp
			$headers{'Myheader'}->[0],
			'whatever',
			$name;
	};
	#
	# set_header
	#------------------------------------------------------------------------------


	#------------------------------------------------------------------------------
	##- set_content_type
	#
	do {
		my (%headers);
		my $cgi = CGI::Plus->new();
		my $name = 'set_header';
		
		# set new header
		$cgi->set_content_type('text/whatever');
		
		# get headers
		%headers = headers($cgi);
		
		# should have new header
		comp
			$headers{'Content-Type'}->[0],
			'text/whatever; charset=ISO-8859-1',
			$name;
	};
	#
	# set_content_type
	#------------------------------------------------------------------------------
	
};
#
# main body
#------------------------------------------------------------------------------



###############################################################################
# end of tests
###############################################################################



#------------------------------------------------------------------------------
# err
#
sub err {
	my ($function_name, $err, $test_name) = @_;
	
	# $test_name is require
	$test_name or croak '$test_name is require';
	
	print STDERR $function_name, ': ', $err, "\n";
	ok(0);
	exit;
}
#
# err
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# comp
#
sub comp {
	my ($is, $should, $test_name, %opts) = @_;
	my ($comp);
	
	# $test_name is required
	$test_name or croak ('$test_name is required');
	
	# default options
	%opts = (same=>1, %opts);
	
	# add got and should to test name
	$test_name .=
		' | is: ' . show_val($is) .
		' | got: ' . show_val($should);
	
	# compare
	$comp = $is eq $should;
	
	# reverse comparison if options indicate to do so
	if (! $opts{'same'})
		{ $comp = ! $comp }
	
	# set ok
	ok($comp, $test_name);
}
#
# comp
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# comp_bool
#
sub comp_bool {
	my ($is, $shouldbe, $test_name) = @_;
	
	# $test_name is require
	$test_name or croak '$test_name is require';
	
	if( $is && $shouldbe ) {
		ok(1, $test_name);
		return 1;
	}
	
	if( (! $is) && (! $shouldbe) ) {
		ok(1, $test_name);
		return 1;
	}
	
	# else not ok
	ok(0, $test_name);
}
#
# comp_bool
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# equndef
#
sub equndef {
	my ($str1, $str2) = @_;
	
	# if both defined
	if ( defined($str1) && defined($str2) )
		{return $str1 eq $str2}
	
	# if neither are defined 
	if ( (! defined($str1)) && (! defined($str2)) )
		{return 1}
	
	# only one is defined, so return false
	return 0;
}
#
# equndef
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# is_def
#
sub is_def {
	my ($name, $var, $test_name) = @_;
	
	# $test_name is require
	$test_name or croak '$test_name is require';
	
	# if not defined, throw error
	if (! defined $var) {
		ok(0);
		die qq|$name not defined|;
	}
	
	# else ok
	ok(1, $test_name);
}
#
# is_def
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# headers
#
sub headers {
	my ($cgi) = @_;
	my (%rv, $raw, @lines);
	
	# get raw headers
	$raw = $cgi->header_plus();
	
	# remove trailing space
	$raw =~ s|\s+$||s;
	
	# get lines
	@lines = split(m|[\n\r]|, $raw);
	@lines = grep {m|\S|s} @lines;
	
	# loop through lines
	LINE_LOOP:
	foreach my $line (@lines) {
		my ($n, $v);
		
		# parse into name and value
		($n, $v) = split(m|\s*:\s*|, $line, 2);
		
		# ensure existence of header element
		$rv{$n} ||= [];
		
		# add value
		push @{$rv{$n}}, $v;
	}
	
	# return
	return %rv;
}
#
# headers
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# show_val
#
sub show_val {
	my ($str) = @_;
	
	# not defined
	if (! defined $str) {
		return '[undef]';
	}
	
	# empty string
	if ($str eq '') {
		return '[empty string]';
	}
	
	# no content string
	if ($str !~ m|\S|s) {
		return '[no content string]';
	}
	
	# else return value
	return collapse($str);
}
#
# show_val
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# collapse
#
sub collapse {
	my ($val) = @_;
	
	if (defined $val) {
		$val =~ s|^\s+||s;
		$val =~ s|\s+$||s;
		$val =~ s|\s+| |sg;
	}
	
	return $val;
}
#
# collapse
#------------------------------------------------------------------------------
