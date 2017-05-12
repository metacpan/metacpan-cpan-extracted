package CGI::Plus;
use strict;
use Carp;
use CGI::Safe 'taint';
use base 'CGI::Safe';
use String::Util ':all';
use CGI::Cookie;

# version
our $VERSION = '0.15';

# Debug::ShowStuff
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;

# enable file uploads
$CGI::DISABLE_UPLOADS = 0;

# maximum upload: 5 mb
$CGI::POST_MAX = 5 * 1024 * 1024;

# set path to empty string
$ENV{'PATH'} = '';

=head1 NAME

CGI::Plus -- Extra utilities for CGI

=head1 Description

This module adds a few enhancements to
L<CGI::Safe|http://search.cpan.org/~ovid/CGI-Safe/lib/CGI/Safe.pm>,
which itself adds a few security-based enancements to
L<CGI.pm|http://perldoc.perl.org/CGI.html>.  The enhancement are almost
entirely additions -  the only method that is overridden is new(), and
the changes there are only addition.  The enhancements in this module entirely
use the object-oriented interface.

=head1 SYNOPSIS

 use CGI::Plus;
 my ($cgi, $cookie, $url, $param);

 # new CGI::Plus object
 $cgi = CGI::Plus->new();

 # turn on checks for cross-site request forgeries (CSRF)
 $cgi->csrf(1);

 # get a cookie and look at its values
 $cookie = $cgi->incoming_cookies->{'mycookie'};
 print $cookie->{'values'}->{'x'}, "\n";
 print $cookie->{'values'}->{'y'}, "\n";

 # more concise way to get an incoming cookie
 $cookie = $cgi->ic->{'mycookie'};

 # resend a cookie, but change one of its values
 $cookie = $cgi->resend_cookie('mycookie');
 $cookie->{'values'}->{'x'} = 2;

 # add an outgoing cookie, set some values
 $cookie = $cgi->new_send_cookie('newcookie');
 $cookie->{'values'}->{'val1'} = '1';
 $cookie->{'values'}->{'val2'} = '2';

 # output HTTP header with outgoing cookies, including CSRF
 # check cookie, automatically added
 print $cgi->header_plus;
 
 # output header again if it hasn't already been sent, but if it
 # has then output an empty string
 print $cgi->header_plus;

 # output the URL of the current page but set a new value
 # for the "t" param and remove the "j" param
 $url = $cgi->self_link(params=>{t=>2, j=>undef});

 # check if the submitted form includes the value of the CSRF
 # cookie that was sent
 if (! $cgi->csrf_check)
     { die 'security error' }

 # output the randomly generated value of the CSRF cookie,
 # output: KTFnGgpkZ4
 print $cgi->csrf_value, "\n";

 # output the hidden input form field that uses the same
 # value as the CSRF cookie
 # output: <input type="hidden" name="csrf" value="KTFnGgpkZ4">
 print $cgi->csrf_field, "\n";

 # get the CSRF check param for use in a URL
 # output: csrf=KTFnGgpkZ4
 print $cgi->csrf_param;

 # set a custom header
 $cgi->set_header('myheader', 'whatever');

 # change content type
 $cgi->set_content_type('text/json');

 # output HTTP headers, including added cookies, the CSRF cookie,
 # and the new header
 print $cgi->header_plus;

 # outputs something like this:
 # Set-Cookie: newcookie=val2&2&val1&1; path=/
 # Set-Cookie: mycookie=y&2&x&2; path=/
 # Set-Cookie: csrf=v&KTFnGgpkZ4; path=/
 # Date: Sun, 29 Jul 2012 04:08:06 GMT
 # Myheader: whatever
 # Content-Type: text/json; charset=ISO-8859-1

=head1 INSTALLATION

CGI::Plus can be installed with the usual routine:

 perl Makefile.PL
 make
 make test
 make install

=head1 METHODS

=cut


#------------------------------------------------------------------------------
## new
#

=head2 CGI::Plus->new()

Creates and returns a CGI::Plus object.  New calls the super-class' new()
method, so all params sent to this method will be passed through to CGI
and CGI::Safe.

=cut

sub new {
	my $class = shift;
	my $cgi = $class->SUPER::new(@_);
	
	# set cookies
	$cgi->initialize_cookies();
	
	# call super method
	return $cgi;
}
#
# new
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# ic, oc
# quick accesors to incoming and outgoing cookies
#

=head2 $cgi->ic, $cgi->oc


=cut

sub incoming_cookies { return $_[0]->{'cookies'}->{'incoming'} }
sub ic { return shift->incoming_cookies(@_) }

sub outgoing_cookies { return $_[0]->{'cookies'}->{'outgoing'} }
sub oc { return shift->outgoing_cookies(@_) }

#
# ic, oc
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# initialize_cookies
# private method
#
sub initialize_cookies {
	my ($cgi) = @_;
	my ($got, %cookies);
	
	# cookie hashes
	$cgi->{'cookies'} = {};
	$got = $cgi->{'cookies'}->{'incoming'} = {};
	$cgi->{'cookies'}->{'outgoing'} = {};
	
	# get hash of cookies that were sent
	%cookies = CGI::Cookie->fetch();
	# showhash \%cookies, title=>'%cookies';
	
	# populate cookie values
	foreach my $name (keys %cookies) {
		my ($cookie, $element, @value);
		$cookie = $cookies{$name};
		$element = {};
		
		# name of cookie
		$element->{'name'} = $name;
		
		# original cookie object
		$element->{'org'} = $cookie;
		
		# expires
		if (defined $cookie->expires())
			{ $element->{'expires'} = $cookie->expires() }
		
		# get parsed values
		@value = $cookie->value();
		
		# if more than one element in @value, assume it's a hash
		if (@value > 1)
			{ $element->{'values'} = {@value} }
		
		# else it's a single string value
		else
			{ $element->{'value'} = $cookie->value() }
		
		# hold on to cookie element
		$got->{$name} = $element;
	}
}
#
# initialize_cookies
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# cookie_resend
#
sub resend_cookie {
	my $cgi = shift;
	return $cgi->cookie_resend(@_);
}

sub cookie_resend {
	my ($cgi, $name, %opts) = @_;
	my ($got, $send);
	
	# default %opts
	%opts = (ensure=>1, %opts);
	
	# if not ensuring existence of cookie, and cookie doesn't
	# exist, return  undef
	unless ( $cgi->ic->{$name} || $opts{'ensure'}) {
		return undef;
	}
	
	# get sent cookie
	$got = $cgi->ic->{$name} || {'name'=>$name};
	
	# create cookie that gets sent back out
	$send = {};
	
	# clone $got cookie
	foreach my $key (keys %$got) {
		my $value = $got->{$key};
		
		# original cookie
		if (UNIVERSAL::isa $value, 'CGI::Cookie') {
			$send->{$key} = $value;
		}
		
		# hashref
		elsif (UNIVERSAL::isa $value, 'HASH') {
			$send->{$key} = {%$value};
		}
		
		# else just copy
		else {
			$send->{$key} = $value;
		}
	}
	
	# set cookie
	$cgi->oc->{$name} = $send;
	
	# return new cookie
	return $send;
}
#
# cookie_resend
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# new_send_cookie
#
sub new_send_cookie {
	my ($cgi, $name) = @_;
	my ($cookie);
	
	# create oject
	$cookie = {};
	$cookie->{'name'} = $name;
	$cookie->{'values'} = {};
	
	# add to hash of outgoing cookies
	$cgi->oc->{$name} = $cookie;
	
	# return new cookie
	return $cookie;
}
#
# new_send_cookie
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# self_link
#

=head2 $cgi->self_link(%options)

Returns a url that is a relative link to the current page.  The local path of
the URL is sent, but not the protocol or host.  So, for example, if the URL
of the current page is

 http://www.example.com/cgi-plus/?y=1&x=2&t=2&y=2

then $cgi->self_link() would return something like as follows.  Note that the
order of the URL params mght be changed.

 /cgi-plus/?y=1&y=2&x=2&t=2

NOTE: If all you want is to do is get the URL of the current page, then
L<$cgi-E<gt>url()|http://perldoc.perl.org/CGI.html#OBTAINING-THE-SCRIPT%27S-URL>
is a better choice because it preserves the order of URL params.

B<option:> params

The C<params> option allows you to change the values of some of the URL params
while leaving others as-is.  C<params> is a hashref of URL params and
their new values. For example, consider this URL:

 http://www.example.com/cgi-plus/?y=1&x=2&t=2&y=2

Suppose you want to change just that C<t> param from 2 to 3.  You would do that
like this:

 $cgi->self_link(params=>{t=>3})

which gives us this relative URL with the C<x> and C<y> values as they were before, but
with the new C<t> value:

 /cgi-plus/?y=1&y=2&x=2&t=3

If the value of the param is an array ref, then the param is output once
for each value in the array ref.  So, for example, you could set that C<t>
to have the values 4 and 5 like this:

 $cgi->self_link(params=>{t=>[4,5]})

which gives us

 /cgi-plus/?y=1&y=2&x=2&t=4&t=5

You can remove params by setting their values to undef:

 $cgi->self_link(params=>{t=>undef})

which gives us

 /cgi-plus/?y=1&y=2&x=2

B<option:> clear_params

C<clear_params> removes all params from the URL.  For example, using our
example URL from above:

 http://www.example.com/cgi-plus/?y=1&x=2&t=2&y=2

this:

 $cgi->self_link(clear_params=>1)

returns this URL;

 /cgi-plus/

You can use C<clear_params> in conjunction with C<params> to wipe the slate clean
and send only specific params. So, for example, this call

 $cgi->self_link(clear_params=>1, params=>{j=>10})

gives us this URL:

 /cgi-plus/?j=10

B<option:> html

The C<html> option returns the URL HTML-escaped.  So, for example, this
call:

 $cgi->self_link(params=>{t=>[4,5]}, html=>1)

returns this:

 /cgi-plus/?y=1&amp;y=2&amp;x=2&amp;t=4&amp;t=5

=cut

sub self_link {
	my ($cgi, %opts) = @_;
	my (%params, $rv, $query, $changes, %added);
	
	# get params for adding to url
	$changes = $opts{'params'} || $opts{'param'} || {};
	
	# start with uri path
	unless ($rv = $ENV{'PATH_INFO'}) {
		$rv = $ENV{'REQUEST_URI'};
		$rv =~ s|\?.*||s;
	}
	
	# get parameter names from cgi
	unless ($opts{'clear_params'})
		{ @params{$cgi->param()} = () }
	
	# get parameter names from changes
	@params{keys %$changes} = ();
	
	# loop through params
	foreach my $key (keys %params) {
		my (@vals);
		
		# get values from adds
		if (exists $changes->{$key}) {
			if (ref $changes->{$key})
				{ @vals = @{$changes->{$key}} }
			else
				{ @vals = $changes->{$key} }
		}
		else {
			@vals = $cgi->param($key);
		}
		
		# remove values that are undef
		@vals = grep {defined $_} @vals;
		
		# output values
		foreach my $val (@vals) {
			# add delimiter or query marker
			if ($query)
				{ $query .= '&' }
			else
				{ $query = '?' }
			
			# url escape
			$val = $cgi->escape($val);
			
			# add value
			$query .= $key . '=' . $val;
		}
	}
	
	# add query
	if ($query)
		{ $rv .= $query }
	
	# html escape
	if ($opts{'html'})
		{ $rv = htmlesc($rv) }
	
	# return
	return $rv;
}
#
# self_link
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# set_header
#
sub set_header {
	my ($cgi, $name, $value) = @_;
	
	# initialize header hash
	$cgi->{'headers'} ||= {};
	
	# set header
	$cgi->{'headers'}->{$name} = $value;
	
	# return
	return 1;
}
#
# set_header
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# set_content_type
#
sub set_content_type {
	my ($cgi, $type) = @_;
	
	# set type
	$cgi->{'content_type'} = $type;
	
	# return
	return 1;
}
#
# set_content_type
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# header_plus
#
sub header_plus {
	my ($cgi, %opts) = @_;
	my (@cookies);
	
	# if header has already been sent, don't send it again, just
	# return empty string
	if ($cgi->{'header_sent'})
		{ return '' }
	
	# set content type
	if ( (! $opts{'-type'}) && $cgi->{'content_type'} ) {
		$opts{'-type'} = $cgi->{'content_type'};
	}
	
	# add headers
	if ($cgi->{'headers'}) {
		while ( my($name, $value) = each(%{$cgi->{'headers'}}) ) {
			$name =~ s|^\-*|-|s;
			$opts{$name} ||= $value;
		}
	}
	
	# add cookies
	foreach my $name ( keys %{$cgi->oc} ) {
		my (%element, %params, $cookie);
		%element = %{$cgi->oc->{$name}};
		
		# 'values' takes precedence over 'value'
		if ($element{'values'})
			{ delete $element{'value'} }
		
		# else if no 'value' either, set it to empty string
		elsif (! defined $element{'value'})
			{ $element{'value'} = '' }
		
		# loop through values
		foreach my $key (keys %element) {
			# special case: values
			if ($key eq 'values') {
				$params{'-value'} = $element{$key};
			}
			
			# else just copy value
			else {
				my $send_key = $key;
				$send_key =~ s|^\-*|-|;
				
				$params{$send_key} = $element{$key};
			}
		}
		
		# set domain
		if ($element{'domain'})
			{ $params{'-domain'} = $element{'domain'} }
		
		# set expires: default to one year
		if (exists $element{'expires'}) {
			if (defined $element{'expires'})
				{ $params{'-expires'} = $element{'expires'} }
		}
		else {
			$params{'-expires'} = '+1y';
		}
		
		# create cookie object
		$cookie = CGI::Cookie->new(%params);
		
		if (! defined $cookie) {
			# showhash \%params, title=>'error generating cookie';
			die 'cookie error';
		}
		
		# add to cookie array
		push @cookies, $cookie;
	}
	
	# add cookies to header options
	if (@cookies)
		{ $opts{'-cookie'} = \@cookies }
	
	# note that header has been sent
	$cgi->{'header_sent'} = 1;
	
	# call super method
	return $cgi->SUPER::header(%opts);
}
#
# header_plus
#------------------------------------------------------------------------------




#------------------------------------------------------------------------------
# CSRF info
#

=head1 Cross-site request forgery (CSRF) defenses

A L<Cross-site request forgery|http://en.wikipedia.org/wiki/Cross-site_request_forgery>
(CSRF) is a technique for breaching a web site's security.  CSRF is one of the
most common web-site vulnerabilities.  CGI::Plus provides a technique for
protecting

=cut

#
# CSRF info
#------------------------------------------------------------------------------




#------------------------------------------------------------------------------
# csrf
#
sub csrf {
	my $cgi = shift;
	
	# set csrf value if sent
	if (@_) {
		$cgi->{'csrf'} = $_[0];
		
		# set csrf cookie
		if ($cgi->{'csrf'}) {
			my ($cookie);
			$cookie = $cgi->cookie_resend($cgi->csrf_name);
			$cookie->{'values'} ||= {v=>randword(10)};
		}
	}
	
	# return
	return $cgi->{'csrf'};
}
#
# csrf
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# csrf_name
#
sub csrf_name {
	return 'csrf';
}
#
# csrf_name
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# csrf_value
#

=head2 $cgi->csrf_value()

Returns the string used in CSRF checks.  This value must be included in an HTML
form (see L</$cgi-E<gt>csrf_value()>) 

=cut

sub csrf_value {
	my ($cgi) = @_;
	my ($name, $cookie, $rv);
	
	# must be in csrf mode
	if (! $cgi->csrf)
		{ croak 'cannot set CSRF field when not in CSRF mode' }
	
	# get name of csrf cookie
	$name = $cgi->csrf_name;
	
	# get csrf cookie
	$cookie = $cgi->oc->{$name};
	$cookie or die 'do not have csrf cookie';
	
	# return
	return $cookie->{'values'}->{'v'};
}
#
# csrf_value
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# csrf_field
#

=head2 $cgi->csrf_field()

Returns a hidden HTML field with the CSRF check value in it.  This field must
be included in HTML forms if you do a CSRF check.  The string will look
something like this:

 <input type="hidden" name="csrf" value="8hFnVjSr25">

=cut

sub csrf_field {
	my ($cgi) = @_;
	my ($name, $cookie, $rv);
	
	# must be in csrf mode
	if (! $cgi->csrf)
		{ croak 'cannot set CSRF field when not in CSRF mode' }
	
	# get name of csrf cookie
	$name = $cgi->csrf_name;
	
	# get csrf cookie
	$cookie = $cgi->oc->{$name};
	$cookie or die 'do not have csrf cookie';
	
	# showhash $cookie;
	# showhash $cookie->{'values'}->{'v'};
	
	# build return value
	$rv =
		'<input type="hidden" ' .
		'name="' . htmlesc($name) . '" ' .
		'value="' . htmlesc($cookie->{'values'}->{'v'}) . '">';
	
	# return
	return $rv;
}
#
# csrf_field
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# csrf_param
#

=head2 $cgi->csrf_param()

Returns the URL parameter to use in a URL.  The return value will look
something like this:

 csrf=8hFnVjSr25

The string will never contain HTML or URL meta characters, so it does not need
to be HTML or URL escaped.

=cut

sub csrf_param {
	my ($cgi) = @_;
	my ($name, $cookie, $rv);
	
	# must be in csrf mode
	if (! $cgi->csrf)
		{ croak 'cannot set CSRF field when not in CSRF mode' }
	
	# get name of csrf cookie
	$name = $cgi->csrf_name;
	
	# get csrf cookie
	$cookie = $cgi->oc->{$name};
	$cookie or die 'do not have csrf cookie';
	
	# build return value
	$rv = $name . '=' . $cookie->{'values'}->{'v'};
	
	# return
	return $rv;
}
#
# csrf_param
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# csrf_check
#

=head2 $cgi->csrf_check()

Checks if a CSRF check value was sent and that it matches the CSRF check
cookie.  CSRF checks must be turned on or this method will croak.  The
following code is a typical usage of csrf checking:

 $cgi->csrf(1);

 if (! $cgi->csrf_check) {
    die 'security error';
 }

=cut

sub csrf_check {
	my ($cgi) = @_;
	my ($name, $cookie, $cookie_value, $form_value);
	
	# must be in csrf mode
	if (! $cgi->csrf)
		{ croak 'cannot check CSRF when not in CSRF mode' }
	
	# get name of csrf cookie
	$name = $cgi->csrf_name;
	
	# get csrf cookie
	$cookie = $cgi->oc->{$name};
	$cookie or return 0;
	
	# get cookie value
	$cookie_value = $cookie->{'values'}->{'v'};
	$cookie_value or return 0;
	
	# get form value
	$form_value = $cgi->param($name);
	$form_value or return 0;
	
	# return true if same
	if ($cookie_value eq $form_value)
		{ return 1 }
	
	# else return false
	return 0;
}
#
# csrf_check
#------------------------------------------------------------------------------




# return true
1;

__END__

=head1 TERMS AND CONDITIONS

Copyright (c) 2012 by Miko O'Sullivan.  All rights reserved.  This program is 
free software; you can redistribute it and/or modify it under the same terms 
as Perl itself. This software comes with B<NO WARRANTY> of any kind.

=head1 AUTHOR

Miko O'Sullivan
F<miko@idocs.com>


=head1 VERSION

=over

=item Version 0.10    November 22, 2012

Initial release

=item Version 0.12    November 28, 2012

Fixing prerequisite lists in CPAN upload.

=item Version 0.13    April 25, 2014

Fixed error in META.yml.

=item Version 0.14    May 23, 2014

Fixed bugs in test script.

=item Version 0.15 January 4, 2015

Gave tests names.

=back


=cut
