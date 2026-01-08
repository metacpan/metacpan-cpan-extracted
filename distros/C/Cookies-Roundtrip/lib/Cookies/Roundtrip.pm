package Cookies::Roundtrip;

# NOTE: HTTP::Cookies and HTTP::CookieJar and
# Firefox::Marionette::Cookie
# have expires or expiry fields.
# some can be undef which has a special meaning:
# they are session cookies (which are deleted when session/browser/tab is closed).
# THEY ALL store expiry as unix epoch seconds.
# BUT SetCookie needs a "YYYY-MM-DD hh:mm:ssZ"-formatted string representing Universal Time.
# use this: HTTP::Date::time2isoz(epochsecs)

use strict;
use warnings;

our $VERSION = '0.01';

use HTTP::Cookies;
use HTTP::CookieJar;
use Firefox::Marionette::Cookie;
use HTTP::Date qw(str2time parse_date time2str);
use HTTP::Response;
use HTTP::Request;
use DateTime;
use HTTP::Headers::Util qw/join_header_words/;
use Data::Compare;
use Devel::StackTrace; # until the module is stable

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use Exporter; # you need to import 'import' if you don't define it further down
# the EXPORT_OK and EXPORT_TAGS is code by [kcott] @ Perlmongs.org, thanks!
# see https://perlmonks.org/?node_id=11115288
our (@EXPORT_OK, %EXPORT_TAGS);
# For all the EXPORT subs and tags see the BEGIN{} block at the end

sub	lwpuseragent_get_cookies {
	my ($ua, $verbosity) = @_;
	#$verbosity //= 0;
	#my $parent = ( caller(1) )[3] || "N/A";
	#my $whoami = ( caller(0) )[3];
	return $ua->cookie_jar
}

# Save cookies of LWP::UserAgent (they are HTTP::CookieJar)
# into a file. The file will be empty if no cookies.
# It returns 1 on failure, 0 on success.
sub	lwpuseragent_save_cookies_to_file {
	my ($ua, $filename, $skip_discard, $verbosity) = @_;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	# LWP::UserAgent supports both HTTP::Cookies and HTTP::CookieJar
	# cookie jars (depending on the 'cookie_jar_class' param to their constructor)
	# we need to find the class of the cookie jar of mech
	# this is probably unsupported but there is no other way:
	my $cookie_jar_class = $ua->{'cookie_jar_class'};

	if( $cookie_jar_class eq 'HTTP::Cookies' ){
		if( httpcookies2file(
			defined($ua->cookie_jar) ? $ua->cookie_jar : $cookie_jar_class->new(),
			$filename, $skip_discard, $verbosity
		) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies2file()'." has failed.\n"; return 1 }
	} elsif( ($cookie_jar_class eq 'HTTP::CookieJar') || ($cookie_jar_class eq 'HTTP::CookieJar::LWP') ){
		if( httpcookiejar2file(
			defined($ua->cookie_jar) ? $ua->cookie_jar : $cookie_jar_class->new(),
			$filename, $skip_discard, $verbosity
		) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies2file()'." has failed.\n"; return 1 }
	} else {
		print STDERR "${whoami}, line ".__LINE__." (via $parent): error, input cookies type '$cookie_jar_class' is not known. Known cookies types are 'HTTP::Cookies' and 'HTTP::CookieJar'.\n";
		return 0
	}

	return 0 # success
}

# Convenience method to load any kind of cookies
# or a cookies file, into the LWP::UserAgent
# it returns the $ua's cookie_jar on success or undef on failure
sub	lwpuseragent_load_cookies {
	my ($ua, $cookies_or_file_etc, $verbosity) = @_;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $r = ref($cookies_or_file_etc);
	if( $r eq 'HTTP::Cookies' ){
		my $ret = lwpuseragent_load_httpcookies($ua, $cookies_or_file_etc, $verbosity);
		if( ! defined $ret ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'lwpuseragent_load_httpcookies()'." has failed.\n"; return undef }
		return $ret;
	} elsif( ($r eq 'HTTP::CookieJar') || ($r eq 'HTTP::CookieJar::LWP') ){
		my $ret = lwpuseragent_load_httpcookiejar($ua, $cookies_or_file_etc, $verbosity);
		if( ! defined $ret ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'lwpuseragent_load_httpcookiejar()'." has failed.\n"; return undef }
		return $ret;
	} elsif( $r eq 'ARRAY' ){
		# an ARRAY_REF of cookie which can be strings as come from a server as Set-Cookie headers
		# or can be an ARRAY of Firefox::Marionette::Cookie
		my $ret;
		if( (scalar(@$cookies_or_file_etc) > 0)
		 && (ref($cookies_or_file_etc->[0])eq'Firefox::Marionette::Cookie')
		){
			$ret = lwpuseragent_load_firefoxmarionettecookies($ua, $cookies_or_file_etc, $verbosity);
			if( ! defined $ret ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'lwpuseragent_load_firefoxmarionettecookies()'." has failed.\n"; return undef }
		} else {
			$ret = lwpuseragent_load_setcookies($ua, $cookies_or_file_etc, $verbosity);
			if( ! defined $ret ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'lwpuseragent_load_setcookies()'." has failed.\n"; return undef }
		}
		return $ret;
	} elsif( $r eq '' ){
		# scalar means a filename
		my $ret = lwpuseragent_load_cookies_from_file($ua, $cookies_or_file_etc, $verbosity);
		if( ! defined $ret ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'lwpuseragent_load_cookies_from_file()'." has failed.\n"; return undef }
		return $ret;
	}
	# error!
	print STDERR "${whoami}, line ".__LINE__." (via $parent): error, input cookies type '$r' is not known. Known cookies types are 'HTTP::Cookies', 'HTTP::CookieJar', 'HTTP::CookieJar::LWP', array of SetCookie strings, array of 'Firefox::Marionette::Cookie' or you can specify a filename as a string.\n";
	return undef
}

# It loads cookies from specified file which needs
# to have this header:
#   #LWP-Cookies-ZZZ.ZZZ
# and then followed by 'Set-Cookie: blahblah' lines,
# into the specified LWP::UserAgent object, appending
# cookies to it if already some there.
# It takes in the $ua, $filename and, optionally $verbosity (integer),
# and returns back the $ua's cookie jar (as HTTP::CookieJar object)
# It returns undef on failure.
sub	lwpuseragent_load_cookies_from_file {
	my ($ua, $filename, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	# LWP::UserAgent supports both HTTP::Cookies and HTTP::CookieJar
	# cookie jars (depending on the 'cookie_jar_class' param to their constructor)
	# we need to find the class of the cookie jar of mech
	# this is probably unsupported but there is no other way:
	my $cookie_jar_class = $ua->{'cookie_jar_class'};

	my $old_num_cookies = 0;
	my $ua_cookies;
	if( ! defined($ua_cookies=$ua->cookie_jar) ){
		# there is no cookiejar in $ua, make one and insert it into mech
		if( ! defined($ua_cookies=$cookie_jar_class->new()) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to $cookie_jar_class".'->new()'." has failed.\n"; return undef }
		$ua->cookie_jar($ua_cookies);
	} else {
		$old_num_cookies = count_cookies($ua_cookies, $skip_discard, $verbosity);
		if( ! defined $old_num_cookies ){ print STDERR as_string_httpcookies($ua_cookies)."\n${whoami}, line ".__LINE__." (via $parent): error, call to ".'count_cookies()'." has failed for above cookies object/0.\n"; return undef }
	}

	my $read_num_cookies = 0;
	# by now $ua has a cookie_jar (fresh or already there)
	# and this is the cookie jar we supply to the sub below
	# to load the input cookies (which are of type HTTP::Cookies)
	if( $cookie_jar_class eq 'HTTP::Cookies' ){
		# this is the same as the format of the cookies file
		if( ! defined file2httpcookies($filename, $ua_cookies, $verbosity) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'file2httpcookies()'." has failed for cookies file '$filename'.\n"; return undef }
		$read_num_cookies = count_httpcookies($ua_cookies, $skip_discard, $verbosity);
		if( ! defined $read_num_cookies ){ print STDERR as_string_httpcookies($ua_cookies)."\n${whoami}, line ".__LINE__." (via $parent): error, call to ".'count_httpcookies()'." has failed for above cookies object/1.\n"; return undef }
	} elsif( ($cookie_jar_class eq 'HTTP::CookieJar') || ($cookie_jar_class eq 'HTTP::CookieJar::LWP') ){
		my $httpcookies = file2httpcookies($filename, undef, $verbosity);
		if( ! defined $httpcookies ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'file2httpcookies()'." has failed for cookies file '$filename'.\n"; return undef }
		# convert to cookiejar and insert straight into the mech
		if( ! defined httpcookies2httpcookiejar($httpcookies, $ua_cookies, $verbosity) ){ print STDERR "--begin HTTP::Cookies:\n".as_string_httpcookies($httpcookies)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies2httpcookiejar()'." has failed for above HTTP::Cookies object (which was read from cookie file '$filename').\n"; return undef }
		$read_num_cookies = count_httpcookiejar($ua_cookies);
		if( ! defined $read_num_cookies ){ print STDERR as_string_httpcookiejar($ua_cookies)."\n${whoami}, line ".__LINE__." (via $parent): error, call to ".'count_httpcookiejar()'." has failed for above cookies object/2.\n"; return undef }
	} else {
		print STDERR "${whoami}, line ".__LINE__." (via $parent): error, input cookies type '$cookie_jar_class' is not known. Known cookies types are 'HTTP::Cookies' and 'HTTP::CookieJar'.\n";
		return undef
	}

	if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): loaded ${read_num_cookies} cookies into the specified LWP::UserAgent object. It now has ".count_cookies($ua->cookie_jar, $skip_discard, $verbosity)." cookies.\n" }

	return $ua->cookie_jar;
}

# It loads the specified HTTP::Cookies object
# into the specified LWP::UserAgent object, appending
# cookies to it if already some there.
# It takes in the $ua, $httpcookies and, optionally $verbosity (integer),
# and returns back the $ua's cookie jar (as HTTP::CookieJar object)
# It returns undef on failure.
sub	lwpuseragent_load_setcookies {
	my ($ua, $setcookies, $verbosity) = @_;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $httpcookiejar;
	if( ! defined($httpcookiejar=$ua->cookie_jar) ){
		# there is no cookiejar in $ua, make one and insert it into ua
		if( ! defined($httpcookiejar=HTTP::CookieJar->new()) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::CookieJar->new()'." has failed.\n"; return undef }
		$ua->cookie_jar($httpcookiejar);
	}
	# by now $ua has a cookie_jar (fresh or already there)
	# and this is the cookie jar we supply to the sub below
	# to load the input cookies
	if( ! defined setcookies2httpcookiejar($setcookies, $httpcookiejar, $verbosity) ){ print STDERR "--begin Set-Cookies:\n".as_string_setcookies($setcookies)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'setcookies2httpcookiejar()'." has failed for above Set-Cookies array (which was supplied by the user as input parameter).\n"; return undef }
	if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): inserted ".count_setcookies($setcookies)." cookies in the input Set-Cookies and loaded them into the LWP::UserAgent. It now has ".count_httpcookiejar($ua->cookie_jar)." cookies.\n" }
	return $ua->cookie_jar;
}

# It loads the specified ARRAY of Firefox::Marionette::Cookie
# into the specified LWP::UserAgent object, appending
# cookies to it if already some there.
# It takes in the $ua, $httpcookies and, optionally $verbosity (integer),
# and returns back the $ua's cookie jar (as HTTP::CookieJar object)
# It returns undef on failure.
sub	lwpuseragent_load_firefoxmarionettecookies {
	my ($ua, $firefoxmarionettecookies, $verbosity) = @_;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $httpcookiejar;
	if( ! defined($httpcookiejar=$ua->cookie_jar) ){
		# there is no cookiejar in $ua, make one and insert it into ua
		if( ! defined($httpcookiejar=HTTP::CookieJar->new()) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::CookieJar->new()'." has failed.\n"; return undef }
		$ua->cookie_jar($httpcookiejar);
	}
	# by now $ua has a cookie_jar (fresh or already there)
	# and this is the cookie jar we supply to the sub below
	# to load the input cookies
	if( ! defined firefoxmarionettecookies2httpcookiejar($firefoxmarionettecookies, $httpcookiejar, $verbosity) ){ print STDERR "--begin Set-Cookies:\n".as_string_firefoxmarionettecookies($firefoxmarionettecookies)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'firefoxmarionettecookies2httpcookiejar()'." has failed for above Set-Cookies array (which was supplied by the user as input parameter).\n"; return undef }
	if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): inserted ".count_firefoxmarionettecookies($firefoxmarionettecookies)." cookies in the input Set-Cookies and loaded them into the LWP::UserAgent. It now has ".count_httpcookiejar($ua->cookie_jar)." cookies.\n" }
	return $ua->cookie_jar;
}

# It loads the specified HTTP::Cookies object
# into the specified LWP::UserAgent object, appending
# cookies to it if already some there.
# It takes in the $ua, $httpcookies and, optionally $verbosity (integer),
# and returns back the $ua's cookie jar (as HTTP::CookieJar object)
# It returns undef on failure.
sub	lwpuseragent_load_httpcookies {
	my ($ua, $httpcookies, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	# LWP::UserAgent supports both HTTP::Cookies and HTTP::CookieJar
	# cookie jars (depending on the 'cookie_jar_class' param to their constructor)
	# we need to find the class of the cookie jar of mech
	# this is probably unsupported but there is no other way:
	my $cookie_jar_class = $ua->{'cookie_jar_class'};

	my $ua_cookies;
	if( ! defined($ua_cookies=$ua->cookie_jar) ){
		# there is no cookiejar in $ua, make one and insert it into mech
		if( ! defined($ua_cookies=$cookie_jar_class->new()) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::Cookies->new()'." has failed.\n"; return undef }
		$ua->cookie_jar($ua_cookies);
	}

	# by now $ua has a cookie_jar (fresh or already there)
	# and this is the cookie jar we supply to the sub below
	# to load the input cookies
	if( $cookie_jar_class eq 'HTTP::Cookies' ){
		# we have the same class of cookiejar, we need to merge
		if( ! defined merge_httpcookies($httpcookies, $ua_cookies, $skip_discard, $verbosity) ){ print STDERR "--begin HTTP::Cookies:\n".as_string_httpcookies($httpcookies)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'merge_httpcookies()'." has failed for above HTTP::CookieJar object (which was supplied by the user as input parameter).\n"; return undef }
	} elsif( ($cookie_jar_class eq 'HTTP::CookieJar') || ($cookie_jar_class eq 'HTTP::CookieJar::LWP') ){
		# we have a cookies entering a cookiejar in mech, need to convert
		if( ! defined httpcookies2httpcookiejar($httpcookies, $ua_cookies, $skip_discard, $verbosity) ){ print STDERR "--begin HTTP::Cookies:\n".as_string_httpcookies($httpcookies)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies2httpcookiejar()'." has failed for above HTTP::CookieJar object (which was supplied by the user as input parameter).\n"; return undef }
	} else {
		print STDERR "${whoami}, line ".__LINE__." (via $parent): error, input cookies type '$cookie_jar_class' is not known. Known cookies types are 'HTTP::Cookies' and 'HTTP::CookieJar'.\n";
		return undef
	}

	if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): inserted ".count_httpcookies($httpcookies, $skip_discard, $verbosity)." cookies in the input HTTP::Cookies and loaded them into the LWP::UserAgent. It now has ".count_cookies($ua->cookie_jar, $skip_discard, $verbosity)." cookies.\n" }
	return $ua->cookie_jar;
}

# It loads the specified HTTP::CookieJar object
# into the specified LWP::UserAgent object, appending
# cookies to it if already some there.
# It takes in the $ua, $httpcookiejar and, optionally $verbosity (integer),
# and returns back the $ua's cookie jar (as HTTP::CookieJar object)
# If the $ua has no cookie jar then the supplied cookie jar will be
# first cloned and then set into $ua.
# So the input $httpcookiejar will be independent of the one in $ua.
# It returns undef on failure.
sub	lwpuseragent_load_httpcookiejar {
	my ($ua, $httpcookiejar, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	# LWP::UserAgent supports both HTTP::Cookies and HTTP::CookieJar
	# cookie jars (depending on the 'cookie_jar_class' param to their constructor)
	# we need to find the class of the cookie jar of mech
	# this is probably unsupported but there is no other way:
	my $cookie_jar_class = $ua->{'cookie_jar_class'};

	my $ua_cookies;
	if( ! defined($ua_cookies=$ua->cookie_jar) ){
		# there is no cookiejar in $ua, make one and insert it into mech
		if( ! defined($ua_cookies=$cookie_jar_class->new()) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::Cookies->new()'." has failed.\n"; return undef }
		$ua->cookie_jar($ua_cookies);
	}

	# by now $ua has a cookie_jar (fresh or already there)
	# and this is the cookie jar we supply to the sub below
	# to load the input cookies
	if( $cookie_jar_class eq 'HTTP::Cookies' ){
		# we have a cookiejar entering a cookies in mech, need to convert
		if( ! defined httpcookiejar2httpcookies($httpcookiejar, $ua_cookies, $skip_discard, $verbosity) ){ print STDERR "--begin HTTP::Cookies:\n".as_string_httpcookies($httpcookiejar)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookiejar2httpcookies()'." has failed for above HTTP::CookieJar object (which was supplied by the user as input parameter).\n"; return undef }
	} elsif( ($cookie_jar_class eq 'HTTP::CookieJar') || ($cookie_jar_class eq 'HTTP::CookieJar::LWP') ){
		# we have the same class of cookiejar, we need to merge
		if( ! defined merge_httpcookiejar($httpcookiejar, $ua_cookies, $skip_discard, $verbosity) ){ print STDERR "--begin HTTP::Cookies:\n".as_string_httpcookies($httpcookiejar)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'merge_httpcookiejar()'." has failed for above HTTP::CookieJar object (which was supplied by the user as input parameter).\n"; return undef }
	} else {
		print STDERR "${whoami}, line ".__LINE__." (via $parent): error, input cookies type '$cookie_jar_class' is not known. Known cookies types are 'HTTP::Cookies' and 'HTTP::CookieJar'.\n";
		return undef
	}

	if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): inserted ".count_cookies($httpcookiejar, $skip_discard, $verbosity)." cookies in the input HTTP::Cookies and loaded them into the LWP::UserAgent. It now has ".count_cookies($ua->cookie_jar, $skip_discard, $verbosity)." cookies.\n" }

	return $ua->cookie_jar;
}

## Firefox::Marionette browser related subs
sub	firefoxmarionette_get_cookies {
	my ($ffmar, $verbosity) = @_;
	#$verbosity //= 0;
	#my $parent = ( caller(1) )[3] || "N/A";
	#my $whoami = ( caller(0) )[3];
	return [ $ffmar->cookies() ]
}

# Save cookies of LWP::UserAgent (they are HTTP::CookieJar)
# into a file. The file will be empty if no cookies.
# It returns 1 on failure, 0 on success.
sub	firefoxmarionette_save_cookies_to_file {
	my ($ffmar, $filename, $skip_discard, $verbosity) = @_;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $cookies = firefoxmarionette_get_cookies($ffmar);
	if( ! defined $cookies ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'firefoxmarionette_get_cookies()'." has failed.\n"; return 1 }
	if( firefoxmarionettecookies2file($cookies, $filename, $skip_discard, $verbosity) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies2file()'." has failed.\n"; return 1 }

	return 0 # success
}

# Convenience method to load any kind of cookies
# or a cookies file, into the LWP::UserAgent
# it returns the $ffmar's cookies on success or undef on failure
# NOTE: firefox marionette will not load cookies unless we visit the site
# of the cookie domain. However, some sites redirect you if you
# do not ask for a full-path endpoint URL (e.g. www.abc.com/a/b/c
# instead of cookie domain www.abc.com. If you visit www.abc.com
# it may take you to cy.abc.com)
# So, parameter $visit_cookie_domain_first controls this
# if it is undef, then no visit is made,
# if '' (empty string) then it goes to the domain https://www.abc.com above
# if non-empty string it visits that URL instead, this is the most safe.
sub	firefoxmarionette_load_cookies {
	my ($ffmar, $cookies_or_file_etc, $visit_cookie_domain_first, $skip_discard, $verbosity) = @_;
	$verbosity //= 0;
	$skip_discard //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $r = ref($cookies_or_file_etc);
	if( $r eq 'HTTP::Cookies' ){
		my $ret = firefoxmarionette_load_httpcookies($ffmar, $cookies_or_file_etc, $visit_cookie_domain_first, $skip_discard, $verbosity);
		if( ! defined $ret ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'firefoxmarionette_load_httpcookies()'." has failed.\n"; return undef }
		return $ret;
	} elsif( ($r eq 'HTTP::CookieJar') || ($r eq 'HTTP::CookieJar::LWP') ){
		my $ret = firefoxmarionette_load_httpcookiejar($ffmar, $cookies_or_file_etc, $visit_cookie_domain_first, $skip_discard, $verbosity);
		if( ! defined $ret ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'firefoxmarionette_load_httpcookiejar()'." has failed.\n"; return undef }
		return $ret;
	} elsif( $r eq 'ARRAY' ){
		# an ARRAY_REF of cookie which can be strings as come from a server as Set-Cookie headers
		# or can be an ARRAY of Firefox::Marionette::Cookie
		my $ret;
		if( (scalar(@$cookies_or_file_etc) > 0)
		 && (ref($cookies_or_file_etc->[0])eq'Firefox::Marionette::Cookie')
		){
			$ret = firefoxmarionette_load_firefoxmarionettecookies(
				$ffmar,
				$cookies_or_file_etc,
				$visit_cookie_domain_first,
				$skip_discard, $verbosity
			);
			if( ! defined $ret ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'firefoxmarionette_load_firefoxmarionettecookies()'." has failed.\n"; return undef }
		} else {
			$ret = firefoxmarionette_load_setcookies($ffmar, $cookies_or_file_etc, $visit_cookie_domain_first, $skip_discard, $verbosity);
			if( ! defined $ret ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'firefoxmarionette_load_setcookies()'." has failed.\n"; return undef }
		}
		return $ret;
	} elsif( $r eq '' ){
		# scalar means a filename
		my $ret = firefoxmarionette_load_cookies_from_file($ffmar, $cookies_or_file_etc, $visit_cookie_domain_first, $skip_discard, $verbosity);
		if( ! defined $ret ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'firefoxmarionette_load_cookies_from_file()'." has failed.\n"; return undef }
		return $ret;
	}
	# error!
	print STDERR "${whoami}, line ".__LINE__." (via $parent): error, input cookies type '$r' is not known. Known cookies types are 'HTTP::Cookies' and 'HTTP::CookieJar'.\n";
	return undef
}

# It loads cookies from specified file which needs
# to have this header:
#   #LWP-Cookies-ZZZ.ZZZ
# and then followed by 'Set-Cookie: blahblah' lines,
# into the specified LWP::UserAgent object, appending
# cookies to it if already some there.
# It takes in the $ffmar, $filename and, optionally $verbosity (integer),
# and returns back the $ffmar's cookie jar (as HTTP::CookieJar object)
# It returns undef on failure.
# NOTE: firefox marionette will not load cookies unless we visit the site
# of the cookie domain. However, some sites redirect you if you
# do not ask for a full-path endpoint URL (e.g. www.abc.com/a/b/c
# instead of cookie domain www.abc.com. If you visit www.abc.com
# it may take you to cy.abc.com)
# So, parameter $visit_cookie_domain_first controls this
# if it is undef, then no visit is made,
# if '' (empty string) then it goes to the domain https://www.abc.com above
# if non-empty string it visits that URL instead, this is the most safe.
sub	firefoxmarionette_load_cookies_from_file {
	my ($ffmar, $filename, $visit_cookie_domain_first, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $httpcookies = file2httpcookies($filename, undef, $verbosity);
	if( ! defined $httpcookies ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'file2httpcookies()'." has failed for cookies file '$filename'.\n"; return undef }
	my $read_num_cookies = count_cookies($httpcookies, $skip_discard, $verbosity);
	my $new_ffmar_cookies = httpcookies2firefoxmarionettecookies($httpcookies, undef, $skip_discard, $verbosity);
	if( ! defined $new_ffmar_cookies ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies2firefoxmarionettecookies()'." has failed for cookies file '$filename'.\n"; return undef }

	if( ! defined firefoxmarionette_load_firefoxmarionettecookies(
		$ffmar,
		$new_ffmar_cookies,
		$visit_cookie_domain_first,
		$skip_discard,
		$verbosity
	) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'firefoxmarionette_load_firefoxmarionettecookies()'." has failed.\n"; return undef }

	my $now_ffmar_cookies = firefoxmarionette_get_cookies($ffmar, $verbosity);
	if( ! defined $now_ffmar_cookies ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'firefoxmarionette_get_cookies()'." has failed.\n"; return undef }
	if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): loaded ${read_num_cookies} cookies into the specified Firefox::Marionette object. It now has ".count_cookies($now_ffmar_cookies, $skip_discard, $verbosity)." cookies.\n" }

	return $now_ffmar_cookies;
}

# It loads the specified HTTP::Cookies object
# into the specified LWP::UserAgent object, appending
# cookies to it if already some there.
# It takes in the $ffmar, $httpcookies and, optionally $verbosity (integer),
# and returns back the $ffmar's cookie jar (as HTTP::CookieJar object)
# It returns undef on failure.
# NOTE: firefox marionette will not load cookies unless we visit the site
# of the cookie domain. However, some sites redirect you if you
# do not ask for a full-path endpoint URL (e.g. www.abc.com/a/b/c
# instead of cookie domain www.abc.com. If you visit www.abc.com
# it may take you to cy.abc.com)
# So, parameter $visit_cookie_domain_first controls this
# if it is undef, then no visit is made,
# if '' (empty string) then it goes to the domain https://www.abc.com above
# if non-empty string it visits that URL instead, this is the most safe.
sub	firefoxmarionette_load_setcookies {
	my ($ffmar, $setcookies, $visit_cookie_domain_first, $skip_discard, $verbosity) = @_;
	$verbosity //= 0;
	$skip_discard //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $firefoxmarionettecookies = setcookies2firefoxmarionettecookies($setcookies, undef, $verbosity);
	if( ! defined $firefoxmarionettecookies ){ print STDERR "--begin cookies:\n".as_string_cookies($setcookies)."\n--end cookies.\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'setcookies2firefoxmarionettecookies()'." has failed for above SetCookies.\n"; return undef }
	if( ! defined firefoxmarionette_load_firefoxmarionettecookies(
		$ffmar,
		$firefoxmarionettecookies,
		$visit_cookie_domain_first,
		$skip_discard,
		$verbosity
	) ){ print STDERR "--begin cookies:\n".as_string_cookies($setcookies)."\n--end cookies.\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'firefoxmarionette_load_firefoxmarionettecookies()'." has failed for above array of Firefox::Marionette::Cookie objects.\n"; return undef }

	my $now_ffmar_cookies = firefoxmarionette_get_cookies($ffmar, $verbosity);
	if( ! defined $now_ffmar_cookies ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'firefoxmarionette_get_cookies()'." has failed.\n"; return undef }
	if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): loaded ".count_cookies($setcookies, $skip_discard, $verbosity)." cookies into the specified Firefox::Marionette object. It now has ".count_cookies($now_ffmar_cookies, $skip_discard, $verbosity)." cookies.\n" }

	return $now_ffmar_cookies;
}

# It loads the specified ARRAY of Firefox::Marionette::Cookie
# OR JUST A SINGLE Firefox::Marionette::Cookie object
# into the specified Firefox::Marionette browser object, appending
# cookies to it if already some there.
# It takes in the $ffmar, $firefoxmarionettecookies and, optionally $verbosity (integer),
# and returns back the $ffmar's cookie jar (as array of Firefox::Marionette::Cookie objects)
# It returns undef on failure.
# NOTE: if you have not visited a url then you can not add cookies!!!! (for firefox-marionette/firefox)
# if you have visited a url then you can add only cookies whose domain is the same as the
# current url!!! Otherwise you get error about cookie-averse document etc.
# see
#   https://stackoverflow.com/questions/48352380/org-openqa-selenium-invalidcookiedomainexception-document-is-cookie-averse-usin
# So, we have an extra flag to visit the page of each cookie domain before loading it
# set $visit_cookie_domain_first to false in order not to visit (that means you are sure
# you are there already, otherwise this call will fail).
# Default is to visit first.
# NOTE: firefox marionette will not load cookies unless we visit the site
# of the cookie domain. However, some sites redirect you if you
# do not ask for a full-path endpoint URL (e.g. www.abc.com/a/b/c
# instead of cookie domain www.abc.com. If you visit www.abc.com
# it may take you to cy.abc.com)
# So, parameter $visit_cookie_domain_first controls this
# if it is undef, then no visit is made,
# if '' (empty string) then it goes to the domain https://www.abc.com above
# if non-empty string (and starts with https?://) it visits that URL instead, this is the most safe.
# BUT if you have a lot of cookies you need to load each with its own calculated url
# This is so stupid and will probably fail.
# Perhaps we can skip cookies which are failing to load and not dump core...
sub	firefoxmarionette_load_firefoxmarionettecookies {
	my ($ffmar, $firefoxmarionettecookies, $visit_cookie_domain_first, $skip_discard, $verbosity) = @_;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	for my $acookie (
		(ref($firefoxmarionettecookies) eq 'Firefox::Marionette::Cookie')
		? [ $firefoxmarionettecookies ]
		: @$firefoxmarionettecookies
	){
		my $domain = $acookie->domain;
		if( ! defined($domain) || ($domain=~/^\s*$/) ){ print STDERR "--begin cookie:\n".as_string_cookies($acookie)."\n--end cookie.\n"."${whoami}, line ".__LINE__." (via $parent): error, above cookie has no domain!\n"; return undef }
		my $rr;
		if( defined $visit_cookie_domain_first ){
			my $url;
			if( $visit_cookie_domain_first eq '' ){
			  # visit the domain site as it is
			  $url = eval {
				my $uri = URI->new();
				$uri->scheme('https'); # i guess ... this can be a huge bug
				# there may be a path else use some imaginary path
				# hoping it will not redirect us OUTSIDE the domain, inside the domain is ok, cookie will be set.
				$uri->path(defined($acookie->path)?$acookie->path:'a/b/c');
				$uri->host($domain);
				$uri->as_string;
			  };
			  if( $@ || ! $url ){ print STDERR "--begin cookie:\n".as_string_cookies($acookie)."\n--end cookie.\n"."${whoami}, line ".__LINE__." (via $parent): error, failed to create a URL from above cookie's domain".($@?": $@":".")."\n"; return undef }
			  if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): visiting cookie's domain ($domain) to url ($url) before loading above cookie...\n" }
			} elsif( $visit_cookie_domain_first =~ m!^https?\://!i ){
			  # we have a user-specified full url, hopefully, check it is valid
			  # and go there instead of the domain, this is much preferred
			  $url = eval {
				my $uri = URI->new($visit_cookie_domain_first);
				$uri->as_string;
			  };
			  if( $@ || ! $url ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, failed to create a URL from specified url parameter '${visit_cookie_domain_first}'".($@?": $@":".")."\n"; return undef }
			  if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): visiting cookie's domain ($domain) to url ($url) before loading above cookie...\n" }
			} else { print STDERR "${whoami}, line ".__LINE__." (via $parent): error, parameter 'visit_cookie_domain_first' was not understood ($visit_cookie_domain_first).\n"; return undef }
			$rr = eval { $ffmar->go($url) };
			if( $@ || ! $rr ){ print STDERR "--begin cookie:\n".as_string_cookies($acookie)."\n--end cookie.\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'Firefox::Marionette::go()'." has failed for above cookie and url ($url). Warning: this error can be because we failed to visit the url, is the network connected?".($@?": $@":".")."\n"; return undef }
		}
		$rr = eval { $ffmar->add_cookie($acookie) };
		if( $@ || ! $rr ){
			print STDERR "--begin cookie:\n".as_string_cookies($acookie)."\n--end cookie.\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'Firefox::Marionette::add_cookie()'." has failed for above cookie but will continue with the others".($@?": $@":".")."\n";
			# ignoring errors!
			#return undef
		}
	}
	my $now_ffmar_cookies = firefoxmarionette_get_cookies($ffmar, $verbosity);
	if( ! defined $now_ffmar_cookies ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'firefoxmarionette_get_cookies()'." has failed.\n"; return undef }
	if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): loaded ".count_cookies($firefoxmarionettecookies, $skip_discard, $verbosity)." cookies into the specified Firefox::Marionette object. It now has ".count_cookies($now_ffmar_cookies, $skip_discard, $verbosity)." cookies.\n" }

	return $now_ffmar_cookies;
}

# It loads the specified HTTP::Cookies object
# into the specified LWP::UserAgent object, appending
# cookies to it if already some there.
# It takes in the $ffmar, $httpcookies and, optionally $verbosity (integer),
# and returns back the $ffmar's cookie jar (as array of Firefox::Marionette::Cookie object)
# It returns undef on failure.
# NOTE: firefox marionette will not load cookies unless we visit the site
# of the cookie domain. However, some sites redirect you if you
# do not ask for a full-path endpoint URL (e.g. www.abc.com/a/b/c
# instead of cookie domain www.abc.com. If you visit www.abc.com
# it may take you to cy.abc.com)
# So, parameter $visit_cookie_domain_first controls this
# if it is undef, then no visit is made,
# if '' (empty string) then it goes to the domain https://www.abc.com above
# if non-empty string it visits that URL instead, this is the most safe.
sub	firefoxmarionette_load_httpcookies {
	my ($ffmar, $httpcookies, $visit_cookie_domain_first, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $firefoxmarionettecookies = httpcookies2firefoxmarionettecookies($httpcookies, undef, $verbosity);
	if( ! defined $firefoxmarionettecookies ){ print STDERR "--begin cookies:\n".as_string_cookies($httpcookies)."\n--end cookies.\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies2firefoxmarionettecookies()'." has failed for above HTTP::Cookies.\n"; return undef }
	if( ! defined firefoxmarionette_load_firefoxmarionettecookies(
		$ffmar,
		$firefoxmarionettecookies,
		$visit_cookie_domain_first,
		$skip_discard,
		$verbosity
	) ){ print STDERR "--begin cookies:\n".as_string_cookies($httpcookies)."\n--end cookies.\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'firefoxmarionette_load_firefoxmarionettecookies()'." has failed for above array of Firefox::Marionette::Cookie objects.\n"; return undef }

	my $now_ffmar_cookies = firefoxmarionette_get_cookies($ffmar, $verbosity);
	if( ! defined $now_ffmar_cookies ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'firefoxmarionette_get_cookies()'." has failed.\n"; return undef }
	if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): loaded ".count_cookies($httpcookies, $skip_discard, $verbosity)." cookies into the specified Firefox::Marionette object. It now has ".count_cookies($now_ffmar_cookies, $skip_discard, $verbosity)." cookies.\n" }

	return $now_ffmar_cookies;
}

# It loads the specified HTTP::CookieJar object
# into the specified LWP::UserAgent object, appending
# cookies to it if already some there.
# It takes in the $ffmar, $httpcookiejar and, optionally $verbosity (integer),
# and returns back the $ffmar's cookie jar (as HTTP::CookieJar object)
# If the $ffmar has no cookie jar then the supplied cookie jar will be
# first cloned and then into $ffmar.
# So the input $httpcookiejar will be independent of the one in $ffmar.
# It returns undef on failure.
# NOTE: firefox marionette will not load cookies unless we visit the site
# of the cookie domain. However, some sites redirect you if you
# do not ask for a full-path endpoint URL (e.g. www.abc.com/a/b/c
# instead of cookie domain www.abc.com. If you visit www.abc.com
# it may take you to cy.abc.com)
# So, parameter $visit_cookie_domain_first controls this
# if it is undef, then no visit is made,
# if '' (empty string) then it goes to the domain https://www.abc.com above
# if non-empty string it visits that URL instead, this is the most safe.
sub	firefoxmarionette_load_httpcookiejar {
	my ($ffmar, $httpcookiejar, $visit_cookie_domain_first, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $firefoxmarionettecookies = httpcookiejar2firefoxmarionettecookies($httpcookiejar, undef, $verbosity);
	if( ! defined $firefoxmarionettecookies ){ print STDERR "--begin cookies:\n".as_string_cookies($httpcookiejar)."\n--end cookies.\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookiejar2firefoxmarionettecookies()'." has failed for above HTTP::Cookies.\n"; return undef }
	if( ! defined firefoxmarionette_load_firefoxmarionettecookies(
		$ffmar,
		$firefoxmarionettecookies,
		$visit_cookie_domain_first,
		$skip_discard,
		$verbosity
	) ){ print STDERR "--begin cookies:\n".as_string_cookies($httpcookiejar)."\n--end cookies.\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'firefoxmarionette_load_firefoxmarionettecookies()'." has failed for above array of Firefox::Marionette::Cookie objects.\n"; return undef }

	my $now_ffmar_cookies = firefoxmarionette_get_cookies($ffmar, $verbosity);
	if( ! defined $now_ffmar_cookies ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'firefoxmarionette_get_cookies()'." has failed.\n"; return undef }
	if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): loaded ".count_cookies($httpcookiejar)." cookies into the specified Firefox::Marionette object. It now has ".count_cookies($now_ffmar_cookies)." cookies.\n" }

	return $now_ffmar_cookies;
}

## WWW::Mechanize browser related subs

sub	wwwmechanize_get_cookies {
	my ($mech, $verbosity) = @_;
	#$verbosity //= 0;
	#my $parent = ( caller(1) )[3] || "N/A";
	#my $whoami = ( caller(0) )[3];
	return $mech->cookie_jar
}

# Save cookies of WWW::Mechanize::ANY (they are HTTP::Cookies)
# into a file. The file will be empty if no cookies.
# It returns 1 on failure, 0 on success.
sub	wwwmechanize_save_cookies_to_file {
	my ($mech, $filename, $skip_discard, $verbosity) = @_;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	# WWW::Mechanize::* supports both HTTP::Cookies and HTTP::CookieJar
	# cookie jars (depending on the 'cookie_jar_class' param to their constructor)
	# we need to find the class of the cookie jar of mech
	# this is probably unsupported but there is no other way:
	my $cookie_jar_class = $mech->{'cookie_jar_class'};

	if( $cookie_jar_class eq 'HTTP::Cookies' ){
		if( httpcookies2file(
			defined($mech->cookie_jar) ? $mech->cookie_jar : $cookie_jar_class->new(),
			$filename, $skip_discard, $verbosity
		) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies2file()'." has failed.\n"; return 1 }
	} elsif( ($cookie_jar_class eq 'HTTP::CookieJar') || ($cookie_jar_class eq 'HTTP::CookieJar::LWP') ){
		if( httpcookiejar2file(
			defined($mech->cookie_jar) ? $mech->cookie_jar : $cookie_jar_class->new(),
			$filename, $skip_discard, $verbosity
		) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies2file()'." has failed.\n"; return 1 }
	} else {
		print STDERR "${whoami}, line ".__LINE__." (via $parent): error, input cookies type '$cookie_jar_class' is not known. Known cookies types are 'HTTP::Cookies' and 'HTTP::CookieJar'.\n";
		return 0
	}

	return 0 # success
}

# Convenience method to load any kind of cookies
# or a cookies file, into the WWW::Mechanize::ANY
# it returns the $mech's cookie_jar on success or undef on failure
sub	wwwmechanize_load_cookies {
	my ($mech, $cookies_or_file_etc, $verbosity) = @_;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $r = ref($cookies_or_file_etc);
	if( $r eq 'HTTP::Cookies' ){
		my $ret = wwwmechanize_load_httpcookies($mech, $cookies_or_file_etc, $verbosity);
		if( ! defined $ret ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'wwwmechanize_load_httpcookies()'." has failed.\n"; return undef }
		return $ret;
	} elsif( ($r eq 'HTTP::CookieJar') || ($r eq 'HTTP::CookieJar::LWP') ){
		my $ret = wwwmechanize_load_httpcookiejar($mech, $cookies_or_file_etc, $verbosity);
		if( ! defined $ret ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'wwwmechanize_load_httpcookiejar()'." has failed.\n"; return undef }
		return $ret;
	} elsif( $r eq 'ARRAY' ){
		# an ARRAY_REF of cookie which can be strings as come from a server as Set-Cookie headers
		# or can be an ARRAY of Firefox::Marionette::Cookie
		my $ret;
		if( (scalar(@$cookies_or_file_etc) > 0)
		 && (ref($cookies_or_file_etc->[0])eq'Firefox::Marionette::Cookie')
		){
			$ret = wwwmechanize_load_firefoxmarionettecookies($mech, $cookies_or_file_etc, $verbosity);
			if( ! defined $ret ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'wwwmechanize_load_firefoxmarionettecookies()'." has failed.\n"; return undef }
		} else {
			$ret = wwwmechanize_load_setcookies($mech, $cookies_or_file_etc, $verbosity);
			if( ! defined $ret ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'wwwmechanize_load_setcookies()'." has failed.\n"; return undef }
		}
		return $ret;
	} elsif( $r eq '' ){
		# scalar means a filename
		my $ret = wwwmechanize_load_cookies_from_file($mech, $cookies_or_file_etc, $verbosity);
		if( ! defined $ret ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'wwwmechanize_load_cookies_from_file()'." has failed.\n"; return undef }
		return $ret;
	}
	# error!
	print STDERR "${whoami}, line ".__LINE__." (via $parent): error, input cookies type '$r' is not known. Known cookies types are 'HTTP::Cookies', 'HTTP::CookieJar', 'HTTP::CookieJar::LWP', array of SetCookie strings, array of 'Firefox::Marionette::Cookie' or you can specify a filename as a string.\n";
	return undef
}

# It loads cookies from specified file which needs
# to have this header:
#   #LWP-Cookies-ZZZ.ZZZ
# and then followed by 'Set-Cookie: blahblah' lines,
# into the specified WWW::Mechanize::ANY object, appending
# cookies to it if already some there.
# It takes in the $mech, $filename and, optionally $verbosity (integer),
# and returns back the $mech's cookie jar (as HTTP::Cookies object)
# It returns undef on failure.
sub	wwwmechanize_load_cookies_from_file {
	my ($mech, $filename, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	# WWW::Mechanize::* supports both HTTP::Cookies and HTTP::CookieJar
	# cookie jars (depending on the 'cookie_jar_class' param to their constructor)
	# we need to find the class of the cookie jar of mech
	# this is probably unsupported but there is no other way:
	my $cookie_jar_class = $mech->{'cookie_jar_class'};

	my $old_num_cookies = 0;
	my $mech_cookies;
	if( ! defined($mech_cookies=$mech->cookie_jar) ){
		# there is no cookiejar in $mech, make one and insert it into mech
		if( ! defined($mech_cookies=$cookie_jar_class->new()) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to $cookie_jar_class".'->new()'." has failed.\n"; return undef }
		$mech->cookie_jar($mech_cookies);
	} else {
		$old_num_cookies = count_cookies($mech_cookies);
		if( ! defined $old_num_cookies ){ print STDERR as_string_httpcookies($mech_cookies)."\n${whoami}, line ".__LINE__." (via $parent): error, call to ".'count_cookies()'." has failed for above cookies object/0.\n"; return undef }
	}

	my $read_num_cookies = 0;
	# by now $mech has a cookie_jar (fresh or already there)
	# and this is the cookie jar we supply to the sub below
	# to load the input cookies (which are of type HTTP::Cookies)
	if( $cookie_jar_class eq 'HTTP::Cookies' ){
		# this is the same as the format of the cookies file
		if( ! defined file2httpcookies($filename, $mech_cookies, $verbosity) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'file2httpcookies()'." has failed for cookies file '$filename'.\n"; return undef }
		$read_num_cookies = count_httpcookies($mech_cookies, $skip_discard, $verbosity);
		if( ! defined $read_num_cookies ){ print STDERR as_string_httpcookies($mech_cookies)."\n${whoami}, line ".__LINE__." (via $parent): error, call to ".'count_httpcookies()'." has failed for above cookies object/1.\n"; return undef }
	} elsif( ($cookie_jar_class eq 'HTTP::CookieJar') || ($cookie_jar_class eq 'HTTP::CookieJar::LWP') ){
		my $httpcookies = file2httpcookies($filename, undef, $verbosity);
		if( ! defined $httpcookies ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'file2httpcookies()'." has failed for cookies file '$filename'.\n"; return undef }
		# convert to cookiejar and insert straight into the mech
		if( ! defined httpcookies2httpcookiejar($httpcookies, $mech_cookies, $verbosity) ){ print STDERR "--begin HTTP::Cookies:\n".as_string_httpcookies($httpcookies)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies2httpcookiejar()'." has failed for above HTTP::Cookies object (which was read from cookie file '$filename').\n"; return undef }
		$read_num_cookies = count_httpcookiejar($mech_cookies);
		if( ! defined $read_num_cookies ){ print STDERR as_string_httpcookiejar($mech_cookies)."\n${whoami}, line ".__LINE__." (via $parent): error, call to ".'count_httpcookiejar()'." has failed for above cookies object/2.\n"; return undef }
	} else {
		print STDERR "${whoami}, line ".__LINE__." (via $parent): error, input cookies type '$cookie_jar_class' is not known. Known cookies types are 'HTTP::Cookies' and 'HTTP::CookieJar'.\n";
		return undef
	}

	if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): loaded ${read_num_cookies} cookies into the specified WWW::Mechanize::ANY object. It now has ".count_cookies($mech->cookie_jar)." cookies.\n" }

	return $mech->cookie_jar;
}

# It loads the specified HTTP::Cookies object
# into the specified WWW::Mechanize::ANY object, appending
# cookies to it if already some there.
# It takes in the $mech, $httpcookies and, optionally $verbosity (integer),
# and returns back the $mech's cookie jar (as HTTP::Cookies object)
# It returns undef on failure.
sub	wwwmechanize_load_setcookies {
	my ($mech, $setcookies, $verbosity) = @_;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $httpcookies;
	if( ! defined($httpcookies=$mech->cookie_jar) ){
		# there is no cookiejar in $mech, make one and insert it into mech
		if( ! defined($httpcookies=HTTP::Cookies->new()) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::Cookies->new()'." has failed.\n"; return undef }
		$mech->cookie_jar($httpcookies);
	}

	# by now $mech has a cookie_jar (fresh or already there)
	# and this is the cookie jar we supply to the sub below
	# to load the input cookies
	if( ! defined setcookies2httpcookies($setcookies, $httpcookies, $verbosity) ){ print STDERR "--begin Set-Cookies:\n".as_string_setcookies($setcookies)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'setcookies2httpcookies()'." has failed for above Set-Cookies array (which was supplied by the user as input parameter).\n"; return undef }
	if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): inserted ".count_setcookies($setcookies)." cookies in the input Set-Cookies and loaded them into the WWW::Mechanize::ANY. It now has ".count_httpcookies($mech->cookie_jar, undef, $verbosity)." cookies.\n" }
	return $mech->cookie_jar;
}

# It loads the specified ARRAY of Firefox::Marionette::Cookie
# into the specified LWP::UserAgent object, appending
# cookies to it if already some there.
# It takes in the $mech, $httpcookies and, optionally $verbosity (integer),
# and returns back the $mech's cookie jar (as HTTP::CookieJar object)
# It returns undef on failure.
sub	wwwmechanize_load_firefoxmarionettecookies {
	my ($mech, $firefoxmarionettecookies, $verbosity) = @_;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $httpcookies;
	if( ! defined($httpcookies=$mech->cookie_jar) ){
		# there is no cookiejar in $mech, make one and insert it into mech
		if( ! defined($httpcookies=HTTP::Cookies->new()) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::Cookies->new()'." has failed.\n"; return undef }
		$mech->cookie_jar($httpcookies);
	}

	# by now $mech has a cookie_jar (fresh or already there)
	# and this is the cookie jar we supply to the sub below
	# to load the input cookies
	if( ! defined firefoxmarionettecookies2httpcookies($firefoxmarionettecookies, $httpcookies, $verbosity) ){ print STDERR "--begin Set-Cookies:\n".as_string_firefoxmarionettecookies($firefoxmarionettecookies)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'firefoxmarionettecookies2httpcookies()'." has failed for above Set-Cookies array (which was supplied by the user as input parameter).\n"; return undef }
	if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): inserted ".count_firefoxmarionettecookies($firefoxmarionettecookies)." cookies in the input Set-Cookies and loaded them into the WWW::Mechanize::ANY. It now has ".count_httpcookies($mech->cookie_jar, undef, $verbosity)." cookies.\n" }
	return $mech->cookie_jar;
}

# It loads the specified HTTP::Cookies object
# into the specified WWW::Mechanize::ANY object, appending
# cookies to it if already some there.
# It takes in the $mech, $httpcookies and, optionally $verbosity (integer),
# and returns back the $mech's cookie jar (as HTTP::Cookies object)
# It returns undef on failure.
sub	wwwmechanize_load_httpcookies {
	my ($mech, $httpcookies, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	# WWW::Mechanize::* supports both HTTP::Cookies and HTTP::CookieJar
	# cookie jars (depending on the 'cookie_jar_class' param to their constructor)
	# we need to find the class of the cookie jar of mech
	# this is probably unsupported but there is no other way:
	my $cookie_jar_class = $mech->{'cookie_jar_class'};

	my $mech_cookies;
	if( ! defined($mech_cookies=$mech->cookie_jar) ){
		# there is no cookiejar in $mech, make one and insert it into mech
		if( ! defined($mech_cookies=$cookie_jar_class->new()) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::Cookies->new()'." has failed.\n"; return undef }
		$mech->cookie_jar($mech_cookies);
	}

	# by now $mech has a cookie_jar (fresh or already there)
	# and this is the cookie jar we supply to the sub below
	# to load the input cookies
	if( $cookie_jar_class eq 'HTTP::Cookies' ){
		# we have the same class of cookiejar, we need to merge
		if( ! defined merge_httpcookies($httpcookies, $mech_cookies, $skip_discard, $verbosity) ){ print STDERR "--begin HTTP::Cookies:\n".as_string_httpcookies($httpcookies)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'merge_httpcookies()'." has failed for above HTTP::CookieJar object (which was supplied by the user as input parameter).\n"; return undef }
	} elsif( ($cookie_jar_class eq 'HTTP::CookieJar') || ($cookie_jar_class eq 'HTTP::CookieJar::LWP') ){
		# we have a cookies entering a cookiejar in mech, need to convert
		if( ! defined httpcookies2httpcookiejar($httpcookies, $mech_cookies, $skip_discard, $verbosity) ){ print STDERR "--begin HTTP::Cookies:\n".as_string_httpcookies($httpcookies)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies2httpcookiejar()'." has failed for above HTTP::CookieJar object (which was supplied by the user as input parameter).\n"; return undef }
	} else {
		print STDERR "${whoami}, line ".__LINE__." (via $parent): error, input cookies type '$cookie_jar_class' is not known. Known cookies types are 'HTTP::Cookies' and 'HTTP::CookieJar'.\n";
		return undef
	}

	if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): inserted ".count_httpcookies($httpcookies, $skip_discard, $verbosity)." cookies in the input HTTP::Cookies and loaded them into the WWW::Mechanize::ANY. It now has ".count_cookies($mech->cookie_jar)." cookies.\n" }
	return $mech->cookie_jar;
}

# It loads the specified HTTP::CookieJar object
# into the specified WWW::Mechanize::ANY object, appending
# cookies to it if already some there.
# It takes in the $mech, $httpcookiejar and, optionally $verbosity (integer),
# and returns back the $mech's cookie jar (as HTTP::CookieJar object)
# If the $mech has no cookie jar then the supplied cookie jar will be
# first cloned and then set into $mech.
# So the input $httpcookiejar will be independent of the one in $mech.
# It returns undef on failure.
sub	wwwmechanize_load_httpcookiejar {
	my ($mech, $httpcookiejar, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	# WWW::Mechanize::* supports both HTTP::Cookies and HTTP::CookieJar
	# cookie jars (depending on the 'cookie_jar_class' param to their constructor)
	# we need to find the class of the cookie jar of mech
	# this is probably unsupported but there is no other way:
	my $cookie_jar_class = $mech->{'cookie_jar_class'};

	my $mech_cookies;
	if( ! defined($mech_cookies=$mech->cookie_jar) ){
		# there is no cookiejar in $mech, make one and insert it into mech
		if( ! defined($mech_cookies=$cookie_jar_class->new()) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::Cookies->new()'." has failed.\n"; return undef }
		$mech->cookie_jar($mech_cookies);
	}

	# by now $mech has a cookie_jar (fresh or already there)
	# and this is the cookie jar we supply to the sub below
	# to load the input cookies
	if( $cookie_jar_class eq 'HTTP::Cookies' ){
		# we have a cookiejar entering a cookies in mech, need to convert
		if( ! defined httpcookiejar2httpcookies($httpcookiejar, $mech_cookies, $skip_discard, $verbosity) ){ print STDERR "--begin HTTP::Cookies:\n".as_string_httpcookies($httpcookiejar)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookiejar2httpcookies()'." has failed for above HTTP::CookieJar object (which was supplied by the user as input parameter).\n"; return undef }
	} elsif( ($cookie_jar_class eq 'HTTP::CookieJar') || ($cookie_jar_class eq 'HTTP::CookieJar::LWP') ){
		# we have the same class of cookiejar, we need to merge
		if( ! defined merge_httpcookiejar($httpcookiejar, $mech_cookies, $skip_discard, $verbosity) ){ print STDERR "--begin HTTP::Cookies:\n".as_string_httpcookies($httpcookiejar)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'merge_httpcookiejar()'." has failed for above HTTP::CookieJar object (which was supplied by the user as input parameter).\n"; return undef }
	} else {
		print STDERR "${whoami}, line ".__LINE__." (via $parent): error, input cookies type '$cookie_jar_class' is not known. Known cookies types are 'HTTP::Cookies' and 'HTTP::CookieJar'.\n";
		return undef
	}

	if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): inserted ".count_cookies($httpcookiejar)." cookies in the input HTTP::Cookies and loaded them into the WWW::Mechanize::ANY. It now has ".count_cookies($mech->cookie_jar)." cookies.\n" }

	return $mech->cookie_jar;
}

# It creates a new firefoxmarionettecookie (Firefox::Marionette::Cookie) (not ARRAY of them)
# and returns it given a hash of constructor parameters
sub	new_firefoxmarionettecookie {
	my ($params, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	# make sure about some details
	# 1. value must be stringified, e.g. value => 123 will cause problems that it is not a string
	$params->{'value'} = "".$params->{'value'};
	# 2. expiry must be a number and positive integer
	if( exists($params->{'expiry'}) && defined($params->{'expiry'}) ){
		$params->{'expiry'} = 1 + $params->{'expiry'} - 1;
		if( $params->{'expiry'} <= 0 ){ $params->{'expiry'} = 1 } # because FF::Mar does not like 0
	}
	# 3. domain can start with a dot, remove it
	$params->{'domain'} =~ s/^\.//;
	my $ret = Firefox::Marionette::Cookie->new(%$params);
	if( ! defined $ret ){ print STDERR perl2dump($params)."${whoami}, line ".__LINE__." (via $parent): error, call to ".'Firefox::Marionette::Cookie->new()'." has failed for above parameters.\n"; return undef }
	return $ret;
}
# It creates a new firefoxmarionettecookies (ARRAY of Firefox::Marionette::Cookie)
# and returns it given an array with constructor parameters for each cookie, as a hash
sub	new_firefoxmarionettecookies {
	my ($params, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my @ret;
	for my $aparam (@$params){
		my $rr = new_firefoxmarionettecookie($aparam, $skip_discard, $verbosity);
		if( ! defined $rr ){ print STDERR perl2dump($aparam)."${whoami}, line ".__LINE__." (via $parent): error, call to ".'new_firefoxmarionettecookie()'." has failed for above parameters.\n"; return undef }
		push @ret, $rr;
	}
	return \@ret;
}
# convenience method for saving any cookie type to a file.
# It takes in the $cookies, $filename and, optionally $verbosity (integer),
# optionally $skip_discard (default=0),
# and returns 0 on success or 1 on failure.
# NOTE: Firefox::Marionette::Cookie(s) will be saved as Set Cookies
# NOTE: We also support a single Firefox::Marionette::Cookie (as well as an ARRAY of them)
sub	cookies2file {
	my ($cookies, $filename, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $r = ref($cookies);

	if( $r eq 'ARRAY' ){
		return setcookies2file($cookies, $filename, $skip_discard, $verbosity)
			if scalar(@$cookies) == 0
		;
		if( ref($cookies->[0]) eq 'Firefox::Marionette::Cookie' ){ return firefoxmarionettecookies2file($cookies, $filename, $skip_discard, $verbosity) }
		else {
			return setcookies2file($cookies, $filename, $skip_discard, $verbosity);
		}
	} elsif( $r eq 'Firefox::Marionette::Cookie' ){ return firefoxmarionettecookies2file([$cookies], $filename, $skip_discard, $verbosity) }
	elsif( $r eq 'HTTP::Cookies' ){ return httpcookies2file($cookies, $filename, $skip_discard, $verbosity) }
	elsif( ($r eq 'HTTP::CookieJar') || ($r eq 'HTTP::CookieJar::LWP') ){ return httpcookiejar2file($cookies, $filename, $skip_discard, $verbosity) }
	print STDERR "${whoami}, line ".__LINE__." (via $parent): error, don't know how to handle type '$r'.\n";
	return 1 # failed
}
# It saves HTTP::CookieJar into a file.
# NOTE: all our 2file methods save to HTTP::Cookies format. So this one too!
# It takes in the $filename and, optionally $verbosity (integer),
# optionally $skip_discard (default=0),
# and returns 0 on success or 1 on failure.
sub	httpcookiejar2file {
	my ($httpcookiejar, $filename, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	# first convert to httpcookies, and save that into its own format
	my $httpcookies = httpcookiejar2httpcookies($httpcookiejar, undef, $skip_discard, $verbosity);
	if( ! defined $httpcookies ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookiejar2httpcookies()'." has failed.\n"; return 1 }
	# now save HTTP::Cookies to file
	if( httpcookies2file($httpcookies, $filename, $skip_discard, $verbosity) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies2file()'." has failed for file '$filename'.\n"; return 1 }
	return 0 # success
}

# It reads HTTP::CookieJar cookies from a file.
# NOTE: all our 2file methods save to this format.
# It takes in the $filename, optionally a HTTP::CookieJar object to append to,
# or a fresh one will be created, and, optionally $verbosity (integer),
# and returns back the cookies read as HTTP::Cookies on succes.
# It returns undef on failure.
sub	file2httpcookiejar {
	my ($filename, $httpcookiejar, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	if( ! defined $httpcookiejar ){
		if( ! defined($httpcookiejar = HTTP::CookieJar->new()) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::CookieJar->new()'." has failed.\n"; return undef }
	}

	# read the file as HTTP::Cookies
	my $httpcookies = file2httpcookies($filename, undef, $verbosity);
	if( ! defined $httpcookies ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'file2httpcookies()'." has failed.\n"; return undef }
	if( ! defined httpcookies2httpcookiejar($httpcookies, $httpcookiejar, $skip_discard, $verbosity) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies2httpcookiejar()'." has failed.\n"; return undef }
	# print only the fresh loaded cookies, so httpcookies:
	if( $verbosity > 0 ){ print STDOUT "--begin cookies:\n".as_string_httpcookies($httpcookies)."\n--end cookies\n\n"."${whoami}, line ".__LINE__." (via $parent): above cookies have successfully been read from file '$filename'.\n" }
	return $httpcookiejar;
}

# It reads HTTP::Cookies from a file.
# It takes in the $filename and, optionally a HTTP::Cookies
# object to append to (or a fresh one will be created),
# and optionally verbosity (integer),
# and returns back the cookies read as HTTP::Cookies on succes.
# It returns undef on failure.
sub	file2httpcookies {
	my ($filename, $httpcookies, $verbosity) = @_;
	$verbosity //= 0;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	if( ! defined $httpcookies ){
		if( ! defined($httpcookies = HTTP::Cookies->new()) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::Cookies->new()'." has failed.\n"; return undef }
	}
	my $ret = eval { $httpcookies->load($filename) };
	if( $@ || ! defined($ret) || ($ret!=1) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, failed to load cookies from file '$filename'".(defined($@)?" with this exception: $@":".").")\n"; return undef }
	# if we are appending then the following is wrong because it lists ALL cookies already in store
	if( $verbosity > 0 ){ print STDOUT "--begin cookies:\n".as_string_httpcookies($httpcookies)."\n--end cookies\n\n"."${whoami}, line ".__LINE__." (via $parent): cookies have successfully been read from file '$filename' and ALL cookies in store are now as above.\n"; }
	return $httpcookies;
}

# It saves HTTP::Cookies into a file.
# It takes in the $filename and, optionally $verbosity (integer),
# optionally $skip_discard (default=0),
# and returns 0 on success or 1 on failure.
sub	httpcookies2file {
	my ($httpcookies, $filename, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	# ignore_discard : from what i understood, means to ignore the discard flag, i.e. print even discarded
	my $ret = eval { $httpcookies->save(file=>$filename, ignore_discard=>!$skip_discard) };
	if( ! defined($ret) || ($ret!=1) || $@ ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::Cookies::save()'." has failed".(defined($@)?" with this exception: $@":".").")\n"; return 1 }
	return 0 # success
}

# It saves File::Marionette::Cookie into a file AS HTTP::Cookies
# NOTE: all our 2file methods save to HTTP::Cookies format. So this one too!
# It takes in the $filename and, optionally $verbosity (integer),
# optionally $skip_discard (default=0),
# and returns 0 on success or 1 on failure.
sub	firefoxmarionettecookies2file {
	my ($firefoxmarionettecookies, $filename, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	# first convert to httpcookies, and save that into its own format
	my $httpcookies = firefoxmarionettecookies2httpcookies($firefoxmarionettecookies, undef, $skip_discard, $verbosity);
	if( ! defined $httpcookies ){ print STDERR "--begin array of File::Marionette::Cookie:\n".as_string_firefoxmarionettecookies($firefoxmarionettecookies)."\n--end cookies.\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'firefoxmarionettecookies2httpcookies()'." has failed for above array of File::Marionette::Cookie.\n"; return 1 }
	# now save HTTP::Cookies to file
	if( httpcookies2file($httpcookies, $filename, $skip_discard, $verbosity) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies2file()'." has failed for file '$filename'.\n"; return 1 }
	return 0 # success
}

# It reads array of Firefox::Marionette::Cookie cookies from file,
# which are actually saved in HTTP::Cookies format.
# NOTE: all our 2file methods save to this format.
# It takes in the $filename, optionally a HTTP::CookieJar object to append to,
# or a fresh one will be created, and, optionally $verbosity (integer),
# and returns back the cookies read as array of Firefox::Marionette::Cookie on succes.
# It returns undef on failure.
sub	file2firefoxmarionettecookies {
	my ($filename, $firefoxmarionettecookies, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	if( ! defined $firefoxmarionettecookies ){ $firefoxmarionettecookies = [] }

	# read the file which is in HTTP::Cookies format
	my $httpcookies = file2httpcookies($filename, undef, $verbosity);
	if( ! defined $httpcookies ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'file2httpcookies()'." has failed.\n"; return undef }
	if( ! defined httpcookies2firefoxmarionettecookies($httpcookies, $firefoxmarionettecookies, $skip_discard, $verbosity) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies2firefoxmarionettecookies()'." has failed.\n"; return undef }
	# print only the fresh loaded cookies, so httpcookies:
	if( $verbosity > 0 ){ print STDOUT "--begin cookies:\n".as_string_firefoxmarionettecookies($firefoxmarionettecookies)."\n--end cookies\n\n"."${whoami}, line ".__LINE__." (via $parent): above cookies have successfully been read from file '$filename'.\n" }
	return $firefoxmarionettecookies;
}

# It saves File::Marionette::Cookie into a file AS HTTP::Cookies
# NOTE: all our 2file methods save to HTTP::Cookies format. So this one too!
# It takes in the $filename and, optionally $verbosity (integer),
# optionally $skip_discard (default=0),
# and returns 0 on success or 1 on failure.
sub	setcookies2file {
	my ($setcookies, $filename, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	# first convert to httpcookies, and save that into its own format
	my $httpcookies = setcookies2httpcookies($setcookies, undef, $skip_discard, $verbosity);
	if( ! defined $httpcookies ){ print STDERR "--begin array of File::Marionette::Cookie:\n".as_string_setcookies($setcookies)."\n--end cookies.\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'setcookies2httpcookies()'." has failed for above array of File::Marionette::Cookie.\n"; return 1 }
	# now save HTTP::Cookies to file
	if( httpcookies2file($httpcookies, $filename, $skip_discard, $verbosity) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies2file()'." has failed for file '$filename'.\n"; return 1 }
	return 0 # success
}

# It reads array of Set Cookie cookies from file,
# which are actually saved in HTTP::Cookies format.
# NOTE: all our 2file methods save to this format.
# It takes in the $filename, optionally a HTTP::CookieJar object to append to,
# or a fresh one will be created, and, optionally $verbosity (integer),
# and returns back the cookies read as array of Firefox::Marionette::Cookie on succes.
# It returns undef on failure.
sub	file2setcookies {
	my ($filename, $setcookies, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	if( ! defined $setcookies ){ $setcookies = [] }

	# read the file which is in HTTP::Cookies format
	my $httpcookies = file2httpcookies($filename, undef, $verbosity);
	if( ! defined $httpcookies ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'file2httpcookies()'." has failed.\n"; return undef }
	if( ! defined httpcookies2setcookies($httpcookies, $setcookies, $skip_discard, $verbosity) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies2setcookies()'." has failed.\n"; return undef }
	# print only the fresh loaded cookies, so httpcookies:
	if( $verbosity > 0 ){ print STDOUT "--begin cookies:\n".as_string_setcookies($setcookies)."\n--end cookies\n\n"."${whoami}, line ".__LINE__." (via $parent): above cookies have successfully been read from file '$filename'.\n" }
	return $setcookies;
}

# It converts HTTP::Cookies object to HTTP::CookieJar object.
# It takes in the $httpcookies object and, optionally
# $httpcookiejar (as a HTTP::CookieJar object) to append cookies in,
# and returns back a fresh HTTP::CookieJar object or the
# user-supplied HTTP::CookieJar object, with all the cookies loaded.
# It returns undef on failure.
# WARNING: httpcookies allows for domains to start with a dot (.)
#          httpcookiejar strips the leading dot in _parse_cookies()
#          WE WILL RISK AND REINSTATE THE LEADING DOT in httpcookiejar's domain
sub	httpcookies2httpcookiejar {
	my ($httpcookies, $httpcookiejar, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	if( ! defined $httpcookiejar ){
		if( ! defined($httpcookiejar = HTTP::CookieJar->new()) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::CookieJar->new()'." has failed.\n"; return undef }
	}

	# for better control we will loop through the cookies, pre-process,
	# convert to string and load into the HTTP::CookieJar.
	# The alternative is to convert to string (with httpcookies2setcookies())
	# and load into HTTP::CookieJar but we will not be able to preprocess which is essential

	# below code shamelessly borrowed from HTTP::Cookies::as_string() :
	#  https://metacpan.org/dist/HTTP-Cookies/source/lib/HTTP/Cookies.pm#L568
	# NOTE: It adds extra quotes, e.g. in path="/" or expires="xyz"
	# we have code to remove these but ...
	$httpcookies->scan(sub {
		my($version,$key,$val,$_path,$domain,$port,
		   $path_spec,$secure,$_expires,$discard,$rest) = @_;
		return if $discard && $skip_discard;
		my @h = ($key, $val);

		my $path = $_path; if( defined $path ){ $path =~ s/^"//; $path =~ s/"$// } else { $path = '' }
		# this can be undef, what do we do? set it to 10 years from now
		# it needs a "YYYY-MM-DD hh:mm:ssZ"-formatted string representing Universal Time.
		my $expires = $_expires;
		if( defined $_expires ){
			$expires = $_expires;
			$expires =~ s/^"//;
			$expires =~ s/"$//;
		} else {
			# No, leave undef expires as it is, it means session cookies
#			#$expires = HTTP::Date::time2isoz(time()+365*24*60*60*10);
#			# no, make it a bit more random!
#			#$expires = time() + 315334161 + int(rand(6000)); #315360000;
#			$expires = 0;
#			print STDERR "${whoami}, line ".__LINE__." (via $parent): warning, HTTP::Cookies cookie field 'expires' is undefined and setting it to something large ($expires) ...\n";
		}
		push(@h, "path", $path);
		push(@h, "domain" => $domain);
		push(@h, "port" => $port) if defined $port;
		push(@h, "path_spec" => undef) if $path_spec;
		# if this is present then it is secure, there is no value
		if( $secure ){ push @h, "secure" }
		#push(@h, "secure" => undef) if $secure;
		# NOTE: this can be undef and we set it to +10 years but it is optional, i don't think so
		push(@h, "expires" => HTTP::Date::time2isoz($expires)) if $expires;
		#push(@h, "expires" => $expires);
		push(@h, "discard" => undef) if $discard;
		my $k;
		for $k (sort keys %$rest) {
		    push(@h, $k, $rest->{$k});
		}
		push(@h, "version" => $version);
		my $cookstr = HTTP::Headers::Util::join_header_words(\@h);

		# and yet again we suffer from the quotes, perhaps HTTP::CookieJar::load_cookies()
		# assumes no quotes?!
		# this is for the key and value
		$cookstr =~ s/^(.+?)=\\"(.+?)\\";/$1=$2;/g;
		if( $cookstr =~ s/^(.+?)="(.+?)";/<%%___123_keyval_7851__%%>/ ){
			my $kk = $1; my $vv = $2;
			$kk =~ s/\\"/"/g;
			$vv =~ s/\\"/"/g;
			$cookstr =~ s/<%%___123_keyval_7851__%%>/${kk}=${vv};/;
		}
		$cookstr =~ s/\bpath="([^"]*)";/path=$1;/;
		$cookstr =~ s/\bpath="([^"]*)";/path=$1;/;
		$cookstr =~ s/\bexpires="([^"]*)";/expires=$1;/;

		# now load it, BUT!:
		# create a new jar because we need to process the cookie added
		# if appending, it will be lost in that madness
		my $htc = HTTP::CookieJar->new();
		if( ! defined $htc ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::CookieJar->new()'." has failed.\n"; return undef }
		if( ! defined $htc->load_cookies($cookstr) ){ print STDERR "--begin cookie:\n".$cookstr."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::CookieJar->load_cookies()'." has failed for above cookie (which was produced by the HTTP::Cookies object supplied by the user as input parameter).\n"; return undef }
		# delete httponly. Note: there is only 1 cookie in here now, this is guaranteed, so [0] is OK!
		my $v = $htc->{store};
		for (1..3){ # go does 3 levels from 'store'->domain->path->key
			$v = $v->{ (keys %$v)[0] }
		}
		delete $v->{'httponly'};
		# leading dot in domain? the HTTP::CookieJar will have removed it.
		# Reinstate it. No leave it, we can't do this everywhere
		#if( $domain =~ /^\./ ){ $v->{domain} = '.' . $v->{domain} }
		# and append the result to the $httpcookiejar, which is returned
		if( ! defined merge_httpcookiejar($htc, $httpcookiejar, $verbosity) ){ print STDERR "$0 : error, call to ".'merge_httpcookiejar()'." has failed.\n"; return undef }
	});

	return $httpcookiejar;
}

# It converts HTTP::Cookies object to an ARRAY of Firefox::Marionette::Cookie
# It takes in the $httpcookies object and, optionally
# $firefoxmarionettecookies (as an ARRAY) to append cookies in,
# and returns back a fresh ARRAY of Firefox::Marionette::Cookie or the
# user-supplied ARRAY of Firefox::Marionette::Cookie, with all the cookies loaded.
# It returns undef on failure.
# WARNING: httpcookies allows for domains to start with a dot (.)
sub	httpcookies2firefoxmarionettecookies {
	my ($httpcookies, $firefoxmarionettecookies, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	if( ! defined $firefoxmarionettecookies ){ $firefoxmarionettecookies = [] }

	# for better control we will loop through the cookies, pre-process,
	# convert to string and load into the HTTP::CookieJar.
	# The alternative is to convert to string (with httpcookies2setcookies())
	# and load into the ARRAY of Firefox::Marionette::Cookie
	# but we will not be able to preprocess which is essential

	# below code shamelessly borrowed from HTTP::Cookies::as_string() :
	#  https://metacpan.org/dist/HTTP-Cookies/source/lib/HTTP/Cookies.pm#L568
	# NOTE: It adds extra quotes, e.g. in path="/" or expires="xyz"
	# we have code to remove these but ...
	$httpcookies->scan(sub {
		my($version,$key,$val,$_path,$domain,$port,
		   $path_spec,$secure,$_expires,$discard,$rest) = @_;
		return if $discard && $skip_discard;
		my @h = ($key, $val);

		my $path = $_path; if( defined $path ){ $path =~ s/^"//; $path =~ s/"$// } else { $path = '' }
		# this can be undef, what do we do? set it to 10 years from now
		# it needs a "YYYY-MM-DD hh:mm:ssZ"-formatted string representing Universal Time.
		my $expires = $_expires;
		if( defined $_expires ){
			$expires = $_expires;
			$expires =~ s/^"//;
			$expires =~ s/"$//
		} else {
			# No, leave undef expires as it is, it means session cookies
#			#$expires = HTTP::Date::time2isoz(time()+365*24*60*60*10);
#			# no, make it a bit more random!
#			#$expires = time() + 315334161 + int(rand(6000)); #315360000;
#			$expires = 0;
#			print STDERR "${whoami}, line ".__LINE__." (via $parent): warning, HTTP::Cookies cookie field 'expires' is undefined and setting it to something large ($expires) ...\n";
		}

		# quotes?
		$key =~ s/"//g;

		my %ffparams = (
			"name" => $key,
			"value" => $val,
			"path" => $path,
			"domain" => $domain,
			"secure" => (defined($secure) && ($secure==1)) ? 1 : 0,
			"expiry" => $expires,
			"same_site" => 'None', # None, Lax, Strict
			"http_only" => 0,
		);
		my $ff = new_firefoxmarionettecookie(\%ffparams, $skip_discard, $verbosity);
		if( ! defined $ff ){ print STDERR "--begin input HTTP::Cookies:\n".$httpcookies."\n--end cookies.\n--begin ".'Firefox::Marionette::Cookie->new()'." parameters:\n".perl2dump(\%ffparams)."--end parameters.\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'Firefox::Marionette::Cookie->new()'." has failed for above parameters produced by one item in the input HTTP::Cookies object.\n"; return undef }
		if( ! defined merge_firefoxmarionettecookies($ff, $firefoxmarionettecookies, $verbosity) ){ print STDERR "$0 : error, call to ".'merge_firefoxmarionettecookies()'." has failed.\n"; return undef }
	});
	return $firefoxmarionettecookies;
}

# we also support a single Firefox::Marionette::Cookie object as well as an array of them
sub	clone_cookies {
	my ($w, $verbosity) = @_;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	
	my $r = ref($w);
	if( $r eq 'ARRAY' ){
		return [] if scalar(@$w) == 0;
		if( ref($w->[0]) eq 'Firefox::Marionette::Cookie' ){ return clone_firefoxmarionettecookies($w, $verbosity) }
		else {
			return clone_setcookies($w, $verbosity)
		}
	} elsif( $r eq 'Firefox::Marionette::Cookie' ){ return clone_firefoxmarionettecookie($w, $verbosity) }
	elsif( $r eq 'HTTP::Cookies' ){ return clone_httpcookies($w, $verbosity) }
	elsif( ($r eq 'HTTP::CookieJar') || ($r eq 'HTTP::CookieJar::LWP') ){ return clone_httpcookiejar($w, $verbosity) }
	print STDERR "${whoami}, line ".__LINE__." (via $parent): error, don't know how to handle type '$r'.\n";
	return undef # failed
}
sub	clone_httpcookiejar {
	my ($httpcookiejar, $verbosity) = @_;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $ret = HTTP::CookieJar->new();
	if( ! defined $ret ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::CookieJar->new()'." has failed.\n"; return undef }

	# this is not necessary as the code in HTTP::CookieJar::dump_cookies currently stands
	# but you never know when someone throws a die in there!
	my @cooks = eval { $httpcookiejar->dump_cookies() };
	if( $@ ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::CookieJar->dump_cookies()'." has failed".(defined($@)?" with this exception: $@":".").").\n"; return undef }
	if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): found ".scalar(@cooks)." cookies in the input cookiejar and loading them ...\n" }
	$ret->load_cookies(@cooks);
	return $ret;
}
# just a single Firefox::Marionette::Cookie object
sub	clone_firefoxmarionettecookie {
	my ($firefoxmarionettecookie, $verbosity) = @_;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my %cparams = ( map { $_ => $firefoxmarionettecookie->$_->() }
		('path', 'domain', 'secure', 'name', 'value', 'http_only', 'same_site', 'expiry')
	);
	my $ret = new_firefoxmarionettecookie(\%cparams, undef, $verbosity);
	if( ! defined $ret ){ print STDERR perl2dump(\%cparams)."${whoami}, line ".__LINE__." (via $parent): error, call to ".'new_firefoxmarionettecookie()'." has failed for above parameters.\n"; return undef }
	if( $verbosity > 0 ){ print STDOUT "--begin cookie:\n".as_string_cookies($ret)."--end cookie.\n"."${whoami}, line ".__LINE__." (via $parent): cloned Firefox::Marionette::Cookie as above.\n" }
	return $ret;
}
# an ARRAY of Firefox::Marionette::Cookie objects
sub	clone_firefoxmarionettecookies {
	my ($firefoxmarionettecookies, $verbosity) = @_;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my @ret;
	for my $acookie (@$firefoxmarionettecookies){
		my $a_cloned_cookie = clone_firefoxmarionettecookie($acookie, $verbosity);
		if( ! defined $a_cloned_cookie ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'clone_firefoxmarionettecookie()'." has failed.\n"; return undef }
		push @ret, $a_cloned_cookie;
	}
	if( $verbosity > 0 ){ print STDOUT "--begin cookies:\n".as_string_cookies(\@ret)."\n--end cookies.\n"."${whoami}, line ".__LINE__." (via $parent): cloned an ARRAY of Firefox::Marionette::Cookie objects as above.\n" }
	return \@ret;
}

sub	clone_httpcookies {
	my ($httpcookies, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $ret = HTTP::Cookies->new();
	if( ! defined $ret ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::Cookies->new()'." has failed.\n"; return undef }

	my $rrr = eval {
	$httpcookies->scan(
	  sub {
		my($version,
		   $key,$val,$path,$domain,$port,
		   $path_spec,$secure,$expires,$discard,$rest
		) = @_;
		return if $discard && $skip_discard;
		# HTTP::Cookies::scan() provides $expires, but HTTP::Cookies::set_cookie()
		# requires $maxage! ouch!
		my $maxage = $expires - time();
		my $rr = eval { $ret->set_cookie(
			$version,$key,$val,$path,$domain,
			$port,$path_spec,$secure,$maxage,$discard,
			$rest # << a hashref
		) };
		if( ! defined($rr) || $@ ){ die 'scan()'." callback : error, call to ".'HTTP::Cookies->set_cookie()'." has failed for these values: $version,$key,$val,$path,$domain,$port,$path_spec,$secure,$maxage,$discard,$rest".(defined($@)?" with this exception: $@":".").").\n"; }
	  }
	); 1
	};
	if( ! defined($rrr) || ($rrr!=1) || $@ ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::Cookies::scan()'." has failed with this exception: $@\n"; return undef }
	return $ret;
}
sub	clone_setcookies { return [ @{ $_[0] } ] }

# Convenience method to merge two cookiejars (of the same type atm)
# It returns the merged cookiejar of the two input cookies on succes,
# It returns undef on failure
# $skip_discard may not apply to all cookiejar types
sub	merge_cookies {
	my ($obj1, $obj2, $skip_discard, $verbosity) = @_;
	$verbosity //= 0;
	$skip_discard //=0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $r = ref($obj1);
	if( $r ne ref($obj2) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, the two input cookies must be of the same type/class. The first one is '$r' but the second is '".ref($obj2)."'.\n"; return undef }

	if( $r eq 'ARRAY' ){
		return [ @$obj1 ] if scalar(@$obj2) == 0;
		return [ @$obj2 ] if scalar(@$obj1) == 0;
		if( ref($obj1->[0]) eq 'Firefox::Marionette::Cookie' ){ return merge_firefoxmarionettecookies($obj1, $obj2, $skip_discard, $verbosity) }
		else {
			return merge_setcookies($obj1, $obj2, $skip_discard, $verbosity);
		}
	} elsif( $r eq 'HTTP::Cookies' ){ return merge_httpcookies($obj1, $obj2, $skip_discard, $verbosity) }
	elsif( ($r eq 'HTTP::CookieJar') || ($r eq 'HTTP::CookieJar::LWP') ){ return merge_httpcookiejar($obj1, $obj2, $skip_discard, $verbosity) }
	print STDERR 'merge_cookies()'.", line ".__LINE__." : error, don't know how to handle type '$r'.\n";
	return undef # failed
}
# It appends httpcookies_src into httpcookies_dst
# and returns httpcookies_dst.
sub	merge_httpcookies {
	my ($httpcookies_src, $httpcookies_dst, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $rrr = eval {
	$httpcookies_src->scan(
	  sub {
		my($version,
		   $key,$val,$path,$domain,$port,
		   $path_spec,$secure,$expires,$discard,$rest
		) = @_;
		return if $discard && $skip_discard;
		my $rr = eval { $httpcookies_dst->set_cookie(
			$version,$key,$val,$path,$domain,$port,
			$path_spec,$secure,$expires,$discard,
			$rest # <<< hashref
		) };
		if( ! defined($rr) || $@ ){ die 'scan()'." callback : error, call to ".'HTTP::Cookies->set_cookie()'." has failed for these values: $version,$key,$val,$path,$domain,$port,$path_spec,$secure,$expires,$discard,$rest\n"; }
	  }
	); 1
	};
	if( ! defined($rrr) || ($rrr!=1) || $@ ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::Cookies::scan()'." has failed".(defined($@)?" with this exception: $@":".").").\n"; return undef }
	return $httpcookies_dst;
}

# It appends httpcookies_src into httpcookies_dst
# and returns httpcookies_dst.
sub	merge_httpcookiejar {
	my ($httpcookiejar_src, $httpcookiejar_dst, $skip_discard, $verbosity) = @_;
	$verbosity //= 0;
	$skip_discard //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	if( $verbosity > 0 ){ print STDOUT "--begin 1st cookies:\n".as_string_cookies($httpcookiejar_src)."\n--end cookies.\n\n--begin 2nd cookies:\n".as_string_cookies($httpcookiejar_dst)."\n--end cookies.\n"."${whoami}, line ".__LINE__." (via $parent): called with above data ...\n" }

	my @cooks = eval { $httpcookiejar_src->dump_cookies() };
	if( $@ ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::CookieJar->dump_cookies()'." has failed".(defined($@)?"".(defined($@)?" with this exception: $@":".").").\n":".").")\n"; return undef }
	my $ret = eval { $httpcookiejar_dst->load_cookies(@cooks) };
	if( ! defined($ret) || $@ ){ print STDERR "--begin cookies:\n@cooks\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::CookieJar::load_cookies()'." has failed for above cookies: $@\n"; print Devel::StackTrace->new->as_string; return undef }
	return $httpcookiejar_dst;
} 

# makes them unique!
# it removes duplicate cookie strings
sub	merge_setcookies {
	return [ keys %{ { map { $_ => 1 } @{ $_[0] }, @{ $_[1] } } } ]
}

# we are appending $src into @$dst
# only uniqune cookie names+path+domain will be there.
# the ones in src will overwrite same in @$dst
# we can have $src to be a single Firefox::Marionette::Cookie
# BUT $dst must be an ARRAY (to store Firefox::Marionette::Cookie)
sub	merge_firefoxmarionettecookies {
	my ($src, $dst) = @_;

	my @src = (ref($src) eq 'ARRAY') ? @$src : ($src);

	my $shrimp = [ values %{ { map { join('!!!', $_->name(), $_->path(), $_->domain()) => $_ } @$dst, @src } } ];

	# we need to keep the arrayref, so empty the array and push the shrimps in
	$#$dst = -1;
	push @$dst, @$shrimp;
	return $dst; # return but also in @$dst
}

# Insert an array of Set-Cookie strings into an
# optionally, user-supplied or fresh HTTP::CookieJar
# and return it. Optionally specifying $verbosity (as integer).
# $httpcookiejar is optional, if given, then cookies
# will be appended in it and return it. Else
# a fresh HTTP::CookieJar will be created, loaded and returned.
# It returns undef on failure.
sub	setcookies2httpcookiejar {
	my ($setcookies, $httpcookiejar, $verbosity) = @_;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	if( ! defined $httpcookiejar ){
		if( ! defined($httpcookiejar = HTTP::CookieJar->new()) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::CookieJar->new()'." has failed.\n"; return undef }
	}
	$httpcookiejar->load_cookies(@$setcookies);
	if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): inserted ".count_setcookies($setcookies)." Set-Cookies into HTTP::CookieJar which now has ".count_httpcookiejar($httpcookiejar)." cookies.\n" }
	return $httpcookiejar;
}

# Insert an array of Set-Cookie strings into an
# optionally, user-supplied (appending)
# or fresh Firefox::Marionette::Cookies
# and return it. Optionally specifying $verbosity (as integer).
# $httpcookiejar is optional, if given, then cookies
# will be appended in it and return it. Else
# a fresh HTTP::CookieJar will be created, loaded and returned.
# It returns undef on failure.
sub	setcookies2firefoxmarionettecookies {
	my ($setcookies, $firefoxmarionettecookies, $verbosity) = @_;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	if( ! defined $firefoxmarionettecookies ){ $firefoxmarionettecookies = [] }

	# this creates a lot of failed tests and discards cookies for strange reasons,
	# DO NOT USE
	# make sure your setcookies have their Domain starting with a dot!
#	my $httpcookies = setcookies2httpcookies($setcookies, undef, $verbosity);
#	if( ! defined $httpcookies ){ print STDERR "--begin Set-Cookies:\n".as_string_setcookies($setcookies)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'setcookies2httpcookies()'." has failed for above Set-Cookies array (which was supplied by the user as input parameter).\n"; return undef }
#	# and now convert to ff
#	if( ! defined httpcookies2firefoxmarionettecookies($httpcookies, $firefoxmarionettecookies, undef, $verbosity) ){ print STDERR "--begin Set-Cookies:\n".as_string_setcookies($setcookies)."\n--end cookies.\n\n--begin HTTP::Cookies :\n".as_string_httpcookies($httpcookies)."\n--end cookies.\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies2firefoxmarionettecookies()'." has failed for above intermediate cookie. The input cookie is also above.\n"; return undef }

	# USE THIS:
	my $httpcookiejar = setcookies2httpcookiejar($setcookies, undef, $verbosity);
	if( ! defined $httpcookiejar ){ print STDERR "--begin Set-Cookies:\n".as_string_setcookies($setcookies)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'setcookies2httpcookiejar()'." has failed for above Set-Cookies array (which was supplied by the user as input parameter).\n"; return undef }
	# and now convert to ff
	if( ! defined httpcookiejar2firefoxmarionettecookies($httpcookiejar, $firefoxmarionettecookies, undef, $verbosity) ){ print STDERR "--begin Set-Cookies:\n".as_string_setcookies($setcookies)."\n--end cookies.\n\n--begin HTTP::Cookies :\n".as_string_httpcookiejar($httpcookiejar)."\n--end cookies.\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookiejar2firefoxmarionettecookies()'." has failed for above intermediate cookie. The input cookie is also above.\n"; return undef }

	if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): inserted ".count_setcookies($setcookies)." Set-Cookies into an array of Firefox::Marionette::Cookie which now has ".count_firefoxmarionettecookies($firefoxmarionettecookies)." cookies.\n" }
	return $firefoxmarionettecookies;
}

# Single Set Cookie to Firefox::Marionette::Cookie
# into a fresh or user-supplied (overwrite its contents)
# Firefox::Marionette::Cookie.
sub	setcookie2firefoxmarionettecookie {
	my ($setcookie, $firefoxmarionettecookie, $verbosity) = @_;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	die "fix me it is not a string but ".ref($setcookie) unless ref($setcookie)eq'';

	my $parsed_setcookie_hash = setcookie2hash($setcookie, $verbosity);
	if( ! defined $parsed_setcookie_hash ){ print STDERR "--begin SetCookie:\n${setcookie}\n--end cookie.\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'setcookie2hash()'." has failed for above SetCookie string.\n"; return undef }

	my %ffcookpar = (%$parsed_setcookie_hash);
	if( ! exists($ffcookpar{'http_only'}) ){ $ffcookpar{'http_only'} = 0 }
	if( ! exists($ffcookpar{'same_site'}) ){ $ffcookpar{'same_site'} = 'None' }

	if( ! defined $firefoxmarionettecookie ){
		if( ! defined($firefoxmarionettecookie=new_firefoxmarionettecookie(\%ffcookpar, undef, $verbosity)) ){ print STDERR perl2dump(\%ffcookpar)."${whoami}, line ".__LINE__." (via $parent): error, call to ".'new_firefoxmarionettecookie()'." has failed for above Set Cookie data (1 cookie).\n"; return undef }
	} else {
		for (keys %ffcookpar){
			# don't like this but ...
			if( exists $firefoxmarionettecookie->{$_} ){
				$firefoxmarionettecookie->{$_} = $ffcookpar{$_}
			}
		}
	}
	if( $verbosity > 0 ){ print STDOUT "--begin Set Cookie:\n".perl2dump($setcookie)."\n--end Set Cookie.\n--begin Firefox::Marionette::Cookie:\n".perl2dump($firefoxmarionettecookie)."\n--end cookies.\n"."${whoami}, line ".__LINE__." (via $parent): done converted Set Cookies to Firefox::Marionette::Cookies.\n" }
	return $firefoxmarionettecookie;
}

# not all input parameters will be passed on to the calling subs
# The return will be undef on failure or an integer (>=0) on success
sub	count_cookies {
	my ($w, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $r = ref($w);
	if( $r eq 'ARRAY' ){
		# actually here we can just do return scalar(@$w)
		return 0 if scalar(@$w) == 0;
		if( ref($w->[0]) eq 'Firefox::Marionette::Cookie' ){ return count_firefoxmarionettecookies($w, $skip_discard, $verbosity) }
		else {
			return count_setcookies($w, $skip_discard, $verbosity)
		}
	} elsif( $r eq 'Firefox::Marionette::Cookie' ){ return 1 }
	elsif( $r eq 'HTTP::Cookies' ){ return count_httpcookies($w, $skip_discard, $verbosity) }
	elsif( ($r eq 'HTTP::CookieJar') || ($r eq 'HTTP::CookieJar::LWP') ){ return count_httpcookiejar($w, $skip_discard, $verbosity) }
	print STDERR "${whoami}, line ".__LINE__." (via $parent): error, input cookies type '$r' is not known. Known cookies types are 'HTTP::Cookies', 'HTTP::CookieJar', 'HTTP::CookieJar::LWP', array of SetCookie strings, array of 'Firefox::Marionette::Cookie'.\n";
	print Devel::StackTrace->new->as_string;
	return undef # failure
}
sub	count_httpcookies {
	my ($httpcookies, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	return 0 unless defined $httpcookies;

	my $count = 0;
	my $ret = eval {
	  $httpcookies->scan(
	    sub {
		my($version,$key,$val,$path,$domain,$port,
		   $path_spec,$secure,$expires,$discard,$rest
		) = @_;
		return if $discard && $skip_discard;
		$count++;
	    }
	  ); 1
	}; # eval
	if( ! defined($ret) || ($ret!=1) || $@ ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::Cookies->scan()'." has failed".(defined($@)?"".(defined($@)?" with this exception: $@":".").").\n":".").")\n"; return undef }
	return $count;
}

sub	count_httpcookiejar { return scalar $_[0]->_all_cookies }

sub	count_setcookies { return scalar @{ $_[0] } }

sub	count_firefoxmarionettecookies { 
	return 0 unless defined $_[0];
	return scalar @{ $_[0] }
}

# a SetCookie string converted to an array which can then
# be passed into HTTP::Cookies::set_cookie
sub	setcookie2httpcookies_set_cookie_array {
	my ($setcookie, $verbosity) = @_;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $parsed_setcookie = setcookie2hash($setcookie, $verbosity);
	if( ! defined $parsed_setcookie ){ print STDERR "--begin SetCookie:\n${setcookie}\n--end cookie.\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'setcookie2hash()'." has failed for above SetCookie string.\n"; return undef }

	my @parsed_setcookie = map {
		exists($parsed_setcookie->{$_}) ? $parsed_setcookie->{$_} : undef
	} (
		'version',
		'name', 'value', 'path', 'domain', 'port',
		'path_spec', 'secure', 'max-age', 'discard', 'rest'
	);

	return \@parsed_setcookie;
}

# a SetCookie string converted to a hash, keyed on the attributes
sub	setcookie2hash {
	my ($setcookie, $verbosity) = @_;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $new_setcookie = $setcookie;
	if( $new_setcookie !~ /;\s*Domain=(\..*?)\s*;/i ){
		if( $verbosity > 0 ){ print STDERR "--begin SetCookie:\n${setcookie}\n--end cookie.\n"."${whoami}, line ".__LINE__." (via $parent): error, above SetCookie does not contain a Domain field or Domain does not start with a dot (.). I AM FIXING IT.\n" }
		$new_setcookie =~ s/(;\s*)Domain=(.+?)(\s*;)/${1}Domain=.${2}${3}/;
	}
	$new_setcookie =~ /;\s*Domain=(.*?)\s*;/i;

	my $parsed_setcookie = HTTP::CookieJar::_parse_cookie($new_setcookie);

	# from HTTP/Cookies.pm, set_cookie signature:
	#    my($version,
	#       $key, $val, $path, $domain, $port,
	#       $path_spec, $secure, $maxage, $discard, $rest) = @_;

	# it expects a max-age but we could have expires
	# and expires can be an epoch or a string date
	if( exists $parsed_setcookie->{'expires'} ){
		if( ! defined $parsed_setcookie->{'expires'} ){ $parsed_setcookie->{'max-age'} = undef }
		elsif( $parsed_setcookie->{'expires'}=~ /^\d+$/ ){
			$parsed_setcookie->{'max-age'} = $parsed_setcookie->{'expires'} - DateTime->now()->epoch();
		} else {
			$parsed_setcookie->{'max-age'} = HTTP::Date::str2time($parsed_setcookie->{'expires'}) - DateTime->now()->epoch();
		}
		delete $parsed_setcookie->{'expires'}; # does not care if you do
	}
	if( ! exists($parsed_setcookie->{'secure'}) || ! defined($parsed_setcookie->{'secure'}) ){
		$parsed_setcookie->{'secure'} = 0;
	}

	return $parsed_setcookie;
}


# Convert an array of Set-Cookie strings into a fresh
# or user-supplied (this is appending) HTTP::Cookies object
# and return it. Optionally specifying $verbosity (as integer).
# $httpcookiejar is optional, if given, then cookies
# will be appended in it and return it. Else
# a fresh HTTP::Cookies will be created, loaded and returned.
# It returns undef on failure.
sub	setcookies2httpcookies {
	my ($setcookies, $httpcookies, $verbosity) = @_;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	if( ! defined $httpcookies ){
		if( ! defined($httpcookies = HTTP::Cookies->new()) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::Cookies->new()'." has failed.\n"; return undef }
	}
	for my $asc (@$setcookies){
		if( $verbosity > 1 ){
			my $parsed_setcookie_hash = setcookie2hash($asc, $verbosity);
			if( ! defined $parsed_setcookie_hash ){ print STDERR "--begin SetCookie:\n${asc}\n--end cookie.\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'setcookie2hash()'." has failed for above SetCookie string.\n"; return undef }
			print STDOUT perl2dump($parsed_setcookie_hash)."${whoami}, line ".__LINE__." (via $parent): parse this SetCookie into the above hash: ${asc}\n";
		}

		my $parsed_setcookie_array = setcookie2httpcookies_set_cookie_array($asc, $verbosity);
		if( ! defined $parsed_setcookie_array ){ print STDERR "--begin SetCookie:\n${asc}\n--end cookie.\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'setcookie2httpcookies_set_cookie_array()'." has failed for above SetCookie string.\n"; return undef }

		# from HTTP/Cookies.pm, set_cookie signature:
		#    my($version,
		#       $key, $val, $path, $domain, $port,
		#       $path_spec, $secure, $maxage, $discard, $rest) = @_;

		$httpcookies->set_cookie(@$parsed_setcookie_array);
		if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): inserting 1 Set-Cookies into HTTP::Cookies which now has ".count_httpcookies($httpcookies, undef, $verbosity)." cookies.\n" }

# this way is bogus, what with response and request and url and all
#		my $response = HTTP::Response->new(200);
#		my $request = HTTP::Request->new(GET => $url);
#		$response->request($request);
#		$response->header('Set-Cookie2', $newasc); # TODO: does it push multiple Cookie headers or overrides?
#		if( ! defined $httpcookies->extract_cookies($response) ){ print STDERR "--begin cookies:\n".as_string_setcookies($setcookies)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies->extract_cookies()'." has failed for above Set-Cookies.\n"; return undef }
#		if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): inserting 1 Set-Cookies into HTTP::Cookies which now has ".count_httpcookies($httpcookies, undef, $verbosity)." cookies.\n" }
	}
	if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): done all, inserted ".count_setcookies($setcookies)." Set-Cookies into HTTP::Cookies which now has ".count_httpcookies($httpcookies, undef, $verbosity)." cookies.\n" }
	return $httpcookies;
}

# Array of Firefox::Marionette::Cookie to array of cookies.
# Each of the output cookie resembles a Set-Cookie header and,
# logically, it can be loaded by any cookies container.
# It converts the specified Array of Firefox::Marionette::Cookie object into
# an array of cookies which can then be loaded into other exotic
# cookie containers.
# It returns the cookies as ARRAY_REF.
# for Set-Cookie format see:
#   https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Set-Cookie
sub     firefoxmarionettecookies2setcookies {
        my ($firefoxmarionettecookies, $setcookies, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	if( ! defined $setcookies ){ $setcookies = [] }

	for my $afc (@$firefoxmarionettecookies){
		my @h = ($afc->name, $afc->value);
		push @h, 'path', $afc->path;
		push @h, 'domain', $afc->domain;
		# no port in F:M:C
		# boolean, it can be present or not present, it has no value like secure=...
		push(@h, 'secure') if $afc->secure;
		if( defined $afc->expiry ){
			# we can have expires as Date or max-age as epoch
			push @h, 'expires', HTTP::Date::time2isoz($afc->expiry)
		}
		# SameSite can be one of: Lax, None, Strict
		if( $afc->same_site !~ /^(None|Lax|Strict)$/ ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, field 'same_site' (".$afc->same_site.") is not one of: 'Lax', 'None', 'Strict'.\n"; return undef }
		push @h, 'SameSite', $afc->same_site;
		# boolean, it can be present or not present, it has no value like secure=...
		push(@h, 'HttpOnly') if $afc->http_only;

		my $cookstr = HTTP::Headers::Util::join_header_words(\@h);

		# and yet again we suffer from the quotes, perhaps HTTP::CookieJar::load_cookies()
		# assumes no quotes?!
		$cookstr =~ s/\bpath="([^"]*)";/path=$1;/;
		$cookstr =~ s/\bexpires="([^"]*)";/expires=$1;/;
		#push(@$setcookies, "Set-Cookie3: " . $cookstr); # this is for a header?
		push(@$setcookies, $cookstr);
	}
	return $setcookies;
}

# Convert an array of Firefox::Marionette::Cookie objects into
# a fresh or user-supplied (this is appending)
# HTTP::CookieJar and return it. Optionally specifying $verbosity (as integer).
# $httpcookiejar is optional, if given, then cookies
# will be appended in it and return it. Else
# a fresh HTTP::CookieJar will be created, loaded and returned.
# It returns undef on failure.
sub	firefoxmarionettecookies2httpcookiejar {
	my ($firefoxmarionettecookies, $httpcookiejar, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	if( ! defined $httpcookiejar ){
		if( ! defined($httpcookiejar = HTTP::CookieJar->new()) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::CookieJar->new()'." has failed.\n"; return undef }
	}
#	my $httpcookies = firefoxmarionettecookies2httpcookies($firefoxmarionettecookies, undef, $skip_discard, $verbosity);
#	if( ! defined $httpcookies ){ print STDERR "--begin Firefox::Marionette::Cookie:\n".as_string_firefoxmarionettecookies($firefoxmarionettecookies)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'firefoxmarionettecookies2httpcookies()'." has failed for above Firefox::Marionette::Cookie data.\n"; return undef }
#	if( ! defined httpcookies2httpcookiejar($httpcookies, $httpcookiejar, $verbosity) ){ print STDERR "--begin Set-Cookies:\n".as_string_httpcookies($httpcookies)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies2httpcookiejar()'." has failed for above Set-Cookies array (which was supplied by the user as input parameter).\n"; return undef }
#	if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): inserted ".count_firefoxmarionettecookies($firefoxmarionettecookies)." Firefox::Marionette::Cookie(s) into HTTP::CookieJar which now has ".count_httpcookiejar($httpcookiejar, undef, $verbosity)." cookies.\n" }

	for my $c (
		ref($firefoxmarionettecookies)eq'ARRAY'
		? @$firefoxmarionettecookies
		: ($firefoxmarionettecookies) # it can be a single cookie not an ARRAY of Firefox::Marionette::Cookie
	){
		my $path = $c->path; if( defined $path ){ $path =~ s/^"//; $path =~ s/"$// } else { $path = '' }
		my $value = $c->value; if( defined $value ){ $value =~ s/^"//; $value =~ s/"$// } else { $value = '' }
		my $expires = $c->expiry;
		if( defined $expires ){
			$expires =~ s/^"//;
			$expires =~ s/"$//
		} else {
			# No, leave undef expires as it is, it means session cookies
#			# no, make it a bit more random!
#			#$expires = time() + 315334161 + int(rand(6000)); #315360000;
#			$expires  = 0;
#			print STDERR "${whoami}, line ".__LINE__." (via $parent): warning, HTTP::Cookies cookie field 'expires' is undefined and setting it to something large ($expires) ...\n";
		}
		my @h = ($c->name, $value);
		push(@h, "path", $path);
		push(@h, "domain" => $c->domain);
		push(@h, "expires" => $expires); # derived from $c->expiry
		push(@h, "secure" => $c->secure) if $c->secure;
		#push(@h, "port" => $c->port) if $c->port;
		#push(@h, "path_spec" => undef) if $c->path_spec;
		#push(@h, "discard" => undef) if $discard;
		#push(@h, "version" => $version);
		my $cookstr = HTTP::Headers::Util::join_header_words(\@h);

		# and yet again we suffer from the quotes, perhaps HTTP::CookieJar::load_cookies()
		# assumes no quotes?!
		$cookstr =~ s/\bpath="([^"]*)";/path=$1;/;
		$cookstr =~ s/\bexpires="([^"]*)";/expires=$1;/;

		# now load it, BUT!:
		# create a new jar because we need to process the cookie added
		# if appending, it will be lost in that madness
		my $htc = HTTP::CookieJar->new();
		if( ! defined $htc ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::CookieJar->new()'." has failed.\n"; return undef }
		if( ! defined $htc->load_cookies($cookstr) ){ print STDERR "--begin cookie:\n".$cookstr."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::CookieJar->load_cookies()'." has failed for above cookie (which was produced by the HTTP::Cookies object supplied by the user as input parameter).\n"; return undef }
		# delete httponly. Note: there is only 1 cookie in here now, this is guaranteed, so [0] is OK!
		my $v = $htc->{store};
		for (1..3){ # go does 3 levels from 'store'->domain->path->key
			$v = $v->{ (keys %$v)[0] }
		}
		delete $v->{'httponly'};
		# leading dot in domain? the HTTP::CookieJar will have removed it.
		# Reinstate it. No leave it, we can't do this everywhere
		#if( $domain =~ /^\./ ){ $v->{domain} = '.' . $v->{domain} }
		# and append the result to the $httpcookiejar, which is returned
		if( ! defined merge_httpcookiejar($htc, $httpcookiejar, $verbosity) ){ print STDERR "$0 : error, call to ".'merge_httpcookiejar()'." has failed.\n"; return undef }
	}
	return $httpcookiejar;
}

# convert a HTTP::CookieJar into a fresh
# or user-supplied (this means appending) HTTP::Cookies
# optionally, user-supplied or fresh HTTP::CookieJar
# and return it. Optionally specifying $verbosity (as integer).
# $httpcookiejar is optional, if given, then cookies
# will be appended in it and return it. Else
# a fresh HTTP::CookieJar will be created, loaded and returned.
# It returns undef on failure.
# NOTE: if expiry is <0 then the cookie will not show!!!!!
sub	httpcookiejar2httpcookies {
	my ($httpcookiejar, $httpcookies, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0; # not used atm
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	if( ! defined $httpcookies ){
		if( ! defined($httpcookies = HTTP::Cookies->new()) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::Cookies->new()'." has failed.\n"; return undef }
	}

	for my $c ($httpcookiejar->_all_cookies){
		# signature of httpcookies->set_cookie() is this:
		#my($version,
		#	$key, $val, $path, $domain, $port,
		#	$path_spec, $secure, $maxage, $discard, $rest) = @_;
		# requires $maxage! ouch!
		# HTTP::Cookies::scan() provides $expires, but HTTP::Cookies::set_cookie()
		# requires $maxage! ouch!
		my $maxage = (exists($c->{'expires'}) && defined($c->{'expires'}) && ($c->{'expires'}>0) )
			? ($c->{'expires'} - time())
			: undef
		;
		if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): max-age calculated from 'expires' : ".(defined($maxage)?$maxage:"<NA>").".\n" }

		my $path = $c->{'path'}; if( defined $path ){ $path =~ s/^"//; $path =~ s/"$// } else { $path = '' }
		my $value = $c->{'value'}; if( defined $value ){ $value =~ s/^"//; $value =~ s/"$// } else { $value = '' }
		my @params = (
			undef, # $version?
			$c->{'name'}, # corresponds to $key
			$value,# $value without quotes
			$path, # $path without quotes
			$c->{'domain'}, # $domain
			undef, # no port
			# path_spec is boolean, 1 if path exists (I think!)
			defined($path) && ($path ne '') ? 1 : 0,
			# $secure
			exists($c->{'secure'}) ? $c->{'secure'} : undef,
			# HTTP::Cookies::scan() provides $expires, but HTTP::Cookies::set_cookie()
			# requires $maxage! ouch!
			$maxage, # derived from Expires
			exists($c->{'discard'}) ? $c->{'discard'} : undef,
			# rest is added below
		);
		my %rest;
		# the $rest as a HASH_REF
		for ('httponly','hostonly','creation_time','last_access_time'){
			next unless exists($c->{$_}) && defined($c->{$_});
			$rest{$_} = $c->{$_};
		}
		push @params, \%rest;
		my $ret = eval { $httpcookies->set_cookie(@params) };
		if( ! defined($ret) || $@ ){ print STDERR "--begin cookies:\n".as_string_httpcookiejar($httpcookiejar)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies->set_cookie()'." has failed for above HTTP::CookieJar object".(defined($@)?" with this exception: $@":".").").\n"; print Devel::StackTrace->new->as_string; return undef }
	}

	# NOTE: if expires is <0 then the cookie will not show!!!!!

	return $httpcookies;

if( 0 ){
	# special case when _all_cookies returns nothing but {store}
	my $c = $httpcookiejar->{'store'};
	my @k = keys %$c;
	for my $dK (@k){
	  $c = $c->{$dK}; # ->{'store'}{domain}
	  @k = keys %$c;
	  if( 0 == scalar @k ){
		# special case, we have empty cookie content but we do have a domain and path
		# just set it empty except domain
		my @params = (undef) x 10; $params[4] = $dK;
		if( ! defined $httpcookies->set_cookie(@params) ){ print STDERR "--begin cookies:\n".as_string_httpcookiejar($httpcookiejar)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies->set_cookie()'." has failed for above HTTP::CookieJar object.\n"; return undef }
		# the result is nothing in its 'COOKIES' anyway
		next
	  }
	  for my $pK (@k){
	    $c = $c->{$pK}; # ->{'store'}{domain}->{path}
	    @k = keys %$c;
	    if( 0 == scalar @k ){
		# special case, we have empty cookie content but we do have a domain and path
		# just set it empty except domain and path
		my @params = (undef) x 10; $params[4] = $dK; $params[3] = $pK;
		if( ! defined $httpcookies->set_cookie(@params) ){ print STDERR "--begin cookies:\n".as_string_httpcookiejar($httpcookiejar)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies->set_cookie()'." has failed for above HTTP::CookieJar object.\n"; return undef }
		# the result is nothing in its 'COOKIES' anyway
		next
	    }
	    for my $nK (@k){
		$c = $c->{$nK}; # ->{'store'}{domain}->{path}->{name}
		my @k = keys %$c;
		if( 0 == scalar @k ){
			# special case, we have empty cookie content but we do have a domain and path
			# just set it empty except domain and path and name
			my @params = (undef) x 10; $params[4] = $dK; $params[3] = $pK; $params[1] = $nK;
			if( ! defined $httpcookies->set_cookie(@params) ){ print STDERR "--begin cookies:\n".as_string_httpcookiejar($httpcookiejar)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies->set_cookie()'." has failed for above HTTP::CookieJar object.\n"; return undef }
			# the result is nothing in its 'COOKIES' anyway
			next
		}
		# cookie has some values
		#for my $c ($httpcookiejar->_all_cookies){
		# signature of httpcookies->set_cookie() is this:
		#my($version,
		#	$key, $val, $path, $domain, $port,
		#	$path_spec, $secure, $maxage, $discard, $rest) = @_;
		# requires $maxage! ouch!
		# HTTP::Cookies::scan() provides $expires, but HTTP::Cookies::set_cookie()
		# requires $maxage! ouch!
		my $maxage = (exists($c->{'expires'}) && defined($c->{'expires'}) && ($c->{'expires'}>0) )
			? ($c->{'expires'} - time())
			: undef
		;
		if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): max-age calculated from expiry : ".(defined($maxage)?$maxage:"<NA>").".\n" }
		my @params = (
			undef, # $version?
			$c->{'name'}, # corresponds to $key
			$c->{'value'},# $value
			$c->{'path'}, # $path
			$c->{'domain'}, # $domain
			undef, # no port
			# path_spec is boolean, 1 if path exists (I think!)
			exists($c->{'path'}) && defined($c->{'path'}) && ($c->{'path'}ne'') ? 1 : 0,
			exists($c->{'secure'}) ? $c->{'secure'} : undef, # $secure
			# HTTP::Cookies::scan() provides $expires, but HTTP::Cookies::set_cookie()
			# requires $maxage! ouch!
			$maxage, # derived from Expires
			exists($c->{'discard'}) ? $c->{'discard'} : undef,
		);
		my %rest;
		# the $rest as a HASH_REF
		for ('httponly','hostonly','creation_time','last_access_time'){
			next unless exists($c->{$_}) && defined($c->{$_});
			$rest{$_} = $c->{$_};
		}
		push @params, \%rest;
		if( ! defined $httpcookies->set_cookie(@params) ){ print STDERR "--begin cookies:\n".as_string_httpcookiejar($httpcookiejar)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies->set_cookie()'." has failed for above HTTP::CookieJar object.\n"; return undef }
	    } # for name
	  } # for path
	} # for domain
}

}

# convert an array or a single Firefox::Marionette::Cookie into a fresh
# or user-supplied (this means appending) HTTP::Cookies
# optionally, user-supplied or fresh HTTP::Cookies
# and return it. Optionally specifying $verbosity (as integer).
# $httpcookiejar is optional, if given, then cookies
# will be appended in it and return it. Else
# a fresh HTTP::Cookies will be created, loaded and returned.
# It returns undef on failure.
sub	firefoxmarionettecookies2httpcookies {
	my ($firefoxmarionettecookies, $httpcookies, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	if( ! defined $httpcookies ){
		if( ! defined($httpcookies = HTTP::Cookies->new()) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::Cookies->new()'." has failed.\n"; return undef }
	}

	for my $c (
		ref($firefoxmarionettecookies)eq'ARRAY'
		? @$firefoxmarionettecookies
		: ($firefoxmarionettecookies) # it can be a single cookie not an ARRAY of Firefox::Marionette::Cookie
	){
		# signature of httpcookies->set_cookie() is this:
		#my($version,
		#	$key, $val, $path, $domain, $port,
		#	$path_spec, $secure, $maxage, $discard, $rest) = @_;
		# requires $maxage! ouch!
		# HTTP::Cookies::scan() provides $expires, but HTTP::Cookies::set_cookie()
		# requires $maxage! ouch!
		my $maxage = (exists($c->{'expiry'}) && defined($c->{'expiry'}) && ($c->{'expiry'}>0) )
			? ($c->{'expiry'} - time())
			: undef
		;
		if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): max-age calculated from expiry : ".(defined($maxage)?$maxage:"<NA>").".\n" }
		next if $skip_discard && (!defined($maxage) || ($maxage < 0));
		my $path = $c->{'path'}; if( defined $path ){ $path =~ s/^"//; $path =~ s/"$// } else { $path = '' }
		my $value = $c->{'value'}; if( defined $value ){ $value =~ s/^"//; $value =~ s/"$// } else { $value = '' }
		my @params = (
			undef, # $version?
			$c->{'name'}, # corresponds to $key
			$value,# $value without quotes
			$path, # $path without quotes
			$c->{'domain'}, # $domain
			undef, # no port
			# path_spec is boolean, 1 if path exists (I think!)
			defined($path) && ($path ne '') ? 1 : 0,
			# $secure
			exists($c->{'secure'}) ? $c->{'secure'} : undef,
			# HTTP::Cookies::scan() provides $expires, but HTTP::Cookies::set_cookie()
			# requires $maxage! ouch!
			$maxage, # derived from Expires
			exists($c->{'discard'}) ? $c->{'discard'} : undef,
			# rest is added below
		);
		my %rest;
		# the $rest as a HASH_REF
		for ('http_only','same_site'){
			next unless exists($c->{$_}) && defined($c->{$_});
			$rest{$_} = $c->{$_};
		}
		push @params, \%rest;
		my $ret = eval { $httpcookies->set_cookie(@params) };
		if( ! defined($ret) || $@ ){ print STDERR "--begin cookies:\n".as_string_httpcookies($httpcookies)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies->set_cookie()'." has failed for above HTTP::Cookies object".(defined($@)?" with this exception: $@":".").").\n"; print Devel::StackTrace->new->as_string; return undef }
	}
	return $httpcookies;
}

# HTTP::Cookies to array of cookies.
# Each of the output cookie resembles a Set-Cookie header and,
# logically, it can be loaded by any cookies container.
# It converts the specified HTTP::Cookies object into
# an array of cookies which can then be loaded into other exotic
# cookie containers.
# It returns the cookies as ARRAY_REF.
sub	httpcookies2setcookies {
	my ($httpcookies, $setcookies, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;

	if( ! defined $setcookies ){ $setcookies = [] }

	# below code shamelessly borrowed from HTTP::Cookies::as_string() :
	#  https://metacpan.org/dist/HTTP-Cookies/source/lib/HTTP/Cookies.pm#L568
	# NOTE: It adds extra quotes, e.g. in path="/" or expires="xyz"
	# we have code to remove these but ...
	$httpcookies->scan(sub {
		my($version,$key,$val,$path,$domain,$port,
		   $path_spec,$secure,$expires,$discard,$rest) = @_;
		return if $discard && $skip_discard;
		my @h = ($key, $val);
		push(@h, "path", $path);
		push(@h, "domain" => $domain);
		push(@h, "port" => $port) if defined $port;
		push(@h, "path_spec" => undef) if $path_spec;
		push(@h, "secure" => undef) if $secure;
		# Set Cookie requires actual date as a "YYYY-MM-DD hh:mm:ssZ"-formatted string representing Universal Time.
		push(@h, "expires" => HTTP::Date::time2isoz($expires)) if $expires;
		push(@h, "discard" => undef) if $discard;
		my $k;
		for $k (sort keys %$rest) {
		    push(@h, $k, $rest->{$k});
		}
		push(@h, "version" => $version);
		#push(@$setcookies, "Set-Cookie3: " . HTTP::Headers::Util::join_header_words(\@h));
		push(@$setcookies, HTTP::Headers::Util::join_header_words(\@h));
	});
	return $setcookies
}

# HTTP::CookieJar to array of cookies.
# Each of the output cookie resembles a Set-Cookie header and,
# logically, it can be loaded by any cookies container.
# It converts the specified HTTP::CookieJar object into
# an array of cookies which can then be loaded into other exotic
# cookie containers.
# It returns the cookies as ARRAY_REF.
sub	httpcookiejar2setcookies {
	my ($httpcookiejar, $setcookies, $verbosity) = @_;
	$verbosity //= 0;
	#my $parent = ( caller(1) )[3] || "N/A";
	#my $whoami = ( caller(0) )[3];
	my @ret = $httpcookiejar->dump_cookies;
	if( ! defined $setcookies ){ return \@ret }
	push @$setcookies, @ret;
	return $setcookies;
}

# Insert all cookies from a HTTP::CookieJar into an
# optionally, user-supplied (appending)
# or fresh Array of Firefox::Marionette::Cookie
# and return it. Optionally specifying $verbosity (as integer).
# $firefoxmarionettecookies is optional, if given, then cookies
# will be appended in it and return it. Else
# a fresh array of Firefox::Marionette::Cookie
# will be created, loaded and returned.
# It returns undef on failure.
sub	httpcookiejar2firefoxmarionettecookies {
	my ($httpcookiejar, $firefoxmarionettecookies, $verbosity) = @_;
	$verbosity //= 0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	if( ! defined $firefoxmarionettecookies ){ $firefoxmarionettecookies = [] }

	my $httpcookies = httpcookiejar2httpcookies($httpcookiejar, undef, $verbosity);
	if( ! defined $httpcookies ){ print STDERR "--begin HTTP::CookieJar:\n".as_string_httpcookiejar($httpcookiejar)."\n--end cookies.\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookiejar2httpcookies()'." has failed.\n"; return undef }

	if( ! defined httpcookies2firefoxmarionettecookies($httpcookies,  $firefoxmarionettecookies, $verbosity) ){ print STDERR "--begin HTTP::Cookies:\n".as_string_httpcookies($httpcookies)."\n--end cookies.\n"."${whoami}, line ".__LINE__." (via $parent): error, call to ".'httpcookies2firefoxmarionettecookies()'." has failed.\n"; return undef }

	if( $verbosity > 0 ){ print STDOUT "${whoami}, line ".__LINE__." (via $parent): inserted ".count_httpcookiejar($httpcookiejar, undef, $verbosity)." HTTP::CookieJar into an array of Firefox::Marionette::Cookie which now has ".count_firefoxmarionettecookies($firefoxmarionettecookies)." cookies.\n" }
	return $firefoxmarionettecookies;
}

sub	as_string_cookies {
	my ($w, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;

	my $r = ref($w);
	if( $r eq 'ARRAY' ){
		return 'Empty array of some kind of cookies' if scalar(@$w) == 0;
		if( ref($w->[0]) eq 'Firefox::Marionette::Cookie' ){ return as_string_firefoxmarionettecookies($w, $skip_discard, $verbosity) }
		else {
			return as_string_setcookies($w, $skip_discard, $verbosity)
		}
	} elsif( $r eq 'Firefox::Marionette::Cookie' ){ return as_string_firefoxmarionettecookie($w, $skip_discard, $verbosity) }
	elsif( $r eq 'HTTP::Cookies' ){ return as_string_httpcookies($w, $skip_discard, $verbosity) }
	elsif( ($r eq 'HTTP::CookieJar') || ($r eq 'HTTP::CookieJar::LWP') ){ return as_string_httpcookiejar($w, $skip_discard, $verbosity) }
	print STDERR 'as_string_cookies()'.", line ".__LINE__." : error, don't know how to handle type '$r'.\n";
	return undef # failed
}
sub	as_string_firefoxmarionettecookies {
	my ($w, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;
	my $ret = "";
	for my $aw (@$w){
		$ret .= as_string_firefoxmarionettecookie($aw, $skip_discard, $verbosity);
	}
	return $ret;
}
sub	as_string_firefoxmarionettecookie {
	my ($w, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;

	return ref($w).":\n"
	 . "====begin cookie====\n"
	 . " name='".$w->name."'\n"
	 . " value='".$w->value."'\n"
	 . " path='".$w->path."'\n"
	 . " secure='".(defined($w->secure)?($w->secure?"1":"0"):"<undef>")."'\n"
	 . " domain='".$w->domain."'\n"
	 . " expiry='".(defined($w->expiry)?$w->expiry:"<undef>")."'\n"
	 # must be one of None|Lax|Strict
	 . " same_site='".(defined($w->same_site)?$w->same_site:"<undef>")."'\n"
	 . " http_only='".(defined($w->http_only)?($w->http_only?"1":"0"):"<undef>")."'\n"
	;
}
sub	as_string_setcookies { return ref($_[0]).":\n".join("\n", @{ $_[0] }) }
sub	as_string_httpcookiejar { return ref($_[0]).":\n".join("\n", $_[0]->dump_cookies) }
sub	as_string_httpcookies {
	my ($httpcookies, $skip_discard, $verbosity) = @_;
	$skip_discard //= 0;
	$verbosity //= 0;
	my $ret = ref($httpcookies).":\n";
	my $rrr = eval { $httpcookies->scan(sub {
		my($version,$key,$val,$path,$domain,$port,
		   $path_spec,$secure,$expires,$discard,$rest) = @_;
		return if $discard && $skip_discard;
		$ret .= "====begin cookie====\n";
		$ret .= " key='$key', value='$val'\n";
		$ret .= " path='$path'\n";
		$ret .= " domain='$domain'\n";
		$ret .= " version='$version'\n";
		$ret .= " path_spec='".(defined($path_spec)?$path_spec:"<undef>")."'\n";
		$ret .= " port='".(defined($port)?$port:"<undef>")."'\n";
		# $secure ? "1":"0" has been tested for secure being a string '1'/'0'
		# an int 1/0 or a bool (1==1/1!=1) and works ok
		$ret .= " secure='".(defined($secure)?($secure?"1":"0"):"<undef>")."'\n";
		$ret .= " expires='".(defined($expires)?$expires:"<undef>")."'\n";
		$ret .= " discard='".(defined($discard)?($discard?"1":"0"):"<undef>")."'\n";
		$ret .= " rest=(".perl2dump($rest,{terse=>1}).")\n";
		$ret .= "====end cookie====\n";
	}); 1 };
	if( ! defined($rrr) || ($rrr!=1) || $@ ){ print STDERR 'as_string_httpcookies()'.", line ".__LINE__." : error, call to ".'HTTP::Cookies::scan()'." has failed".(defined($@)?" with this exception: $@":".").").\n"; return undef }
	return $ret;
}

# It returns 1 if the two input objects (which must be of the same type)
# are equal. It returns 0 if they are different.
# It returns undef on failure.
sub	cookies_are_equal {
	my ($obj1, $obj2, $skip_discard, $verbosity) = @_;
	$verbosity //= 0;
	$skip_discard //=0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $r = ref($obj1);
	if( $r ne ref($obj2) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, the two input cookies must be of the same type/class. The first one is '$r' but the second is '".ref($obj2)."'.\n"; return undef }

	if( $r eq 'ARRAY' ){
		my $N = scalar(@$obj1);
		return 0 unless $N == scalar(@$obj2);
		return 1 if $N == 0;
		if( ref($obj1->[0]) eq 'Firefox::Marionette::Cookie' ){
			# this returns undef on failure, so ok with what we return here
			return cookies_are_equal_firefoxmarionettecookies($obj1, $obj2, $skip_discard, $verbosity);
		} else {
			return cookies_are_equal_setcookies($obj1, $obj2, $skip_discard, $verbosity);
		}
	} elsif( $r eq 'Firefox::Marionette::Cookie' ){ return cookies_are_equal_firefoxmarionettecookie($obj1, $obj2, $skip_discard, $verbosity) }
	elsif( $r eq 'HTTP::Cookies' ){ return cookies_are_equal_httpcookies($obj1, $obj2, $skip_discard, $verbosity) }
	elsif( ($r eq 'HTTP::CookieJar') || ($r eq 'HTTP::CookieJar::LWP') ){ return cookies_are_equal_httpcookiejar($obj1, $obj2, $skip_discard, $verbosity) }
	print STDERR "${whoami}, line ".__LINE__." (via $parent): error, don't know how to handle type '$r'.\n";
	return undef
}

# TODO: cookies_diff?

# It returns 1 if the two input objects (which must be of the same type)
# are equal. It returns 0 if they are different.
# It returns undef on failure.
sub	cookies_are_equal_setcookies {
	my ($obj1, $obj2, $skip_discard, $verbosity) = @_;
	$verbosity //= 0;
	$skip_discard //=0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $r = ref($obj1);

	if( $verbosity > 0 ){ print STDOUT "--begin 1st cookies:\n".as_string_cookies($obj1)."\n--end cookies.\n\n--begin 2nd cookies:\n".as_string_cookies($obj2)."\n--end cookies.\n"."${whoami}, line ".__LINE__." (via $parent): called with above data ...\n" }

	if( $r ne 'ARRAY' ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, the two input cookies must be ARRAY_REF but the first one is '$r'.\n"; return undef }
	if( $r ne ref($obj2) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, the two input cookies must be of the same type/class. The first one is '$r' but the second is '".ref($obj2)."'.\n"; return undef }

	die "not implemented"
}

# It returns 1 if the two input objects (which must be of the same type)
# are equal. It returns 0 if they are different.
# It returns undef on failure.
sub	cookies_are_equal_firefoxmarionettecookie {
	my ($obj1, $obj2, $skip_discard, $verbosity) = @_;
	$verbosity //= 0;
	$skip_discard //=0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $r = ref($obj1);

	if( $verbosity > 0 ){ print STDOUT "--begin 1st cookies:\n".as_string_cookies($obj1)."\n--end cookies.\n\n--begin 2nd cookies:\n".as_string_cookies($obj2)."\n--end cookies.\n"."${whoami}, line ".__LINE__." (via $parent): called with above data ...\n" }

	my $same = 1;
	{
	  no strict 'refs';
	  for my $k ('path', 'domain', 'secure', 'name', 'value', 'http_only', 'same_site', 'expiry'){
		my $v1 = $obj1->$k(); my $v2 = $obj2->$k();
		if( (! defined($v1)) && (! defined($v2)) ){ return 1 } # same but both undef
		if( defined($v1) ^ defined($v2) ){ return 0 } # not same, one is undef
		if( $v1 ne $v2 ){ return 0 } # not same
	  }
	}
	return 1 # same
}
# It returns 1 if the two input objects (which must be of the same type)
# are equal. It returns 0 if they are different.
# It returns undef on failure.
# NOTE: the container of the cookies is an ARRAY
# so order of cookies is important, so we need
# to discard order by using a hash.
sub	cookies_are_equal_firefoxmarionettecookies {
	my ($obj1, $obj2, $skip_discard, $verbosity) = @_;
	$verbosity //= 0;
	$skip_discard //=0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $r = ref($obj1);

	if( $verbosity > 0 ){ print STDOUT "--begin 1st cookies:\n".as_string_cookies($obj1)."\n--end cookies.\n\n--begin 2nd cookies:\n".as_string_cookies($obj2)."\n--end cookies.\n"."${whoami}, line ".__LINE__." (via $parent): called with above data ...\n" }

	return 1 if $obj1 == $obj2; # both refer to the same array object
	my $N = scalar(@$obj1);
	return 0 if $N != scalar(@$obj2); # different number of items

	# in need to discard order. It think the best way is to convert
	# to httpcookies and compare that.
	my $httpcookies1 = firefoxmarionettecookies2httpcookies($obj1, undef, $skip_discard, $verbosity);
	if( ! defined $httpcookies1 ){ print STDERR "--begin 1st cookies:\n".as_string_cookies($obj1)."\n--end cookies.\n\n${whoami}, line ".__LINE__." (via $parent): error, failed to convert 1st cookies to httpcookies, see above.\n"; return undef }
	my $httpcookies2 = firefoxmarionettecookies2httpcookies($obj2, undef, $skip_discard, $verbosity);
	if( ! defined $httpcookies2 ){ print STDERR "--begin 2nd cookies:\n".as_string_cookies($obj2)."\n--end cookies.\n\n${whoami}, line ".__LINE__." (via $parent): error, failed to convert 2nd cookies to httpcookies, see above.\n"; return undef }

	my $ret = cookies_are_equal_httpcookies($httpcookies1, $httpcookies2, $skip_discard, $verbosity);
	if( ! defined $ret ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, call to ".'cookies_are_equal_httpcookies()'." has failed.\n"; return undef }
	return $ret;
}
# It returns 1 if the two input objects (which must be of the same type)
# are equal. It returns 0 if they are different.
# It returns undef on failure.
sub	cookies_are_equal_httpcookies {
	my ($obj1, $obj2, $skip_discard, $verbosity) = @_;
	$verbosity //= 0;
	$skip_discard //=0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $r = ref($obj1);

	if( $verbosity > 0 ){ print STDOUT "--begin 1st cookies:\n".as_string_cookies($obj1)."\n--end cookies.\n\n--begin 2nd cookies:\n".as_string_cookies($obj2)."\n--end cookies.\n".__PACKAGE__."::${whoami}, line ".__LINE__." (via $parent): called with above data ...\n" }

	if( $r ne 'HTTP::Cookies' ){ print STDERR __PACKAGE__."::${whoami}, line ".__LINE__." (via $parent): error, the two input cookies must be of class 'HTTP::Cookies' but the first one is '$r'.\n"; return undef }
	if( $r ne ref($obj2) ){ print STDERR __PACKAGE__."::${whoami}, line ".__LINE__." (via $parent): error, the two input cookies must be of the same type/class. The first one is '$r' but the second is '".ref($obj2)."'.\n"; return undef }

	# loop over all cookies in $obj1 and check if each is present+equal in $obj2, unless $discard'ed
	# loop over all cookies in $obj2 and check if each is present+equal in $obj1, unless $discard'ed
	# return 1 if all conditions met, 0 if not. The latter means not equal.
	my $rrr = _cookies_are_equal_httpcookies_comparator($obj1, $obj2, $skip_discard, $verbosity);
	if( ! defined($rrr) || $@ ){ print STDERR __PACKAGE__."::${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::Cookies::scan()'." has failed".(defined($@)?" with this exception: $@":".").").\n"; return undef }
	if( $rrr == 0 ){ return 0 } # not equal

	$rrr = _cookies_are_equal_httpcookies_comparator($obj2, $obj1, $skip_discard, $verbosity);
	if( ! defined($rrr) || $@ ){ print STDERR __PACKAGE__."::${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::Cookies::scan()'." has failed".(defined($@)?" with this exception: $@":".").").\n"; return undef }

	return $rrr; # 1 if equals
}

sub	_cookies_are_equal_httpcookies_comparator {
	my ($obj1, $obj2, $skip_discard, $verbosity) = @_;
	$verbosity //= 0;
	$skip_discard //=0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $rrr = eval { 
	  my $eqs = 1;
	  $obj1->scan(
	    sub {
		no autovivification; # hopefully locally
		# if one not equal, then we are done, so shortcircuit this here:
		return unless $eqs;
		my($version,
		   $key,$val,$path,$domain,$port,
		   $path_spec,$secure,$expires,$discard,$rest) = @_;

		return if $discard && $skip_discard; # it is discarded, it is as if a match is found;

		# hopefully no autovivify will work locally
		my $p;
		my @fixdomains = ($domain, '.'.$domain, $domain);
		$fixdomains[2] =~ s/^\.//;
		# check the stupid domain having a dot in front or not!
		FIX:
		for my $fixdomain (@fixdomains){
			if( defined $obj2->{COOKIES}{$fixdomain}{$path}{$key} ){
				$p = $obj2->{COOKIES}{$fixdomain}{$path}{$key};
				last FIX;
			}
		}
		if( ! defined $p ){
			# failed !
			if( $verbosity > 1 ){ print STDOUT "obj1: ".join("|", map { defined($_)?$_:"<undef>" } @_)."\nobj2:".perl2dump($obj2->{COOKIES}).__PACKAGE__."::${whoami}, line ".__LINE__." (via $parent): not equal because item '{COOKIES}{$domain}{$path}{$key}' does not exist in second object (see above).\n" }
			$eqs = 0; return;
		}

		if( $verbosity > 1 ){ print STDOUT "obj1: ".join("|", map { defined($_)?$_:"<undef>" } @_)."\nobj2:".perl2dump($obj2->{COOKIES}).__PACKAGE__."::${whoami}, line ".__LINE__." (via $parent): comparing above cookies ...\n" }

		# ->{COOKIES}{$domain}{$path}{$key} holds an array as:
		#     ($version, $val, $port, $path_spec, $secure, $expires, $discard);
		# how do the contents compare?

		my $i = 0;
		#if( (defined($version) xor defined($p->[$i]))
		# || (defined($version) and ($version ne $p->[$i]))
		#){
		#	if( $verbosity > 1 ){ print STDOUT "differ on version:\nobj1: ".join("|", map { defined($_)?$_:"<undef>" } @_)."\nobj2:".perl2dump($p).__PACKAGE__."::${whoami}, line ".__LINE__." (via $parent): not equal because key 'version' in obj1 is '".(defined($version)?$version:"<undef>")."' and in obj2 is '".(defined($p->[$i])?$p->[$i]:"<undef>")."'. See above obj2.\n" }
		#	$eqs = 0; return
		#}

		$i++;
		if( (defined($val) xor defined($p->[$i]))
		 || (defined($val) and ($val ne $p->[$i]))
		){
			if( $verbosity > 1 ){ print STDOUT "differ on value:\nobj1: ".join("|", map { defined($_)?$_:"<undef>" } @_)."\nobj2:".perl2dump($p).__PACKAGE__."::${whoami}, line ".__LINE__." (via $parent): not equal because key 'val' (i=$i) in obj1 is '".(defined($val)?$val:"<undef>")."' and in obj2 is '".(defined($p->[$i])?$p->[$i]:"<undef>")."'. See above obj2.\n" }
			$eqs = 0; return
		}

		$i++;
		if( (defined($port) xor defined($p->[$i]))
		 || (defined($port) and ($port ne $p->[$i]))
		){
			if( $verbosity > 1 ){ print STDOUT "differ on port:\nobj1: ".join("|", map { defined($_)?$_:"<undef>" } @_)."\nobj2:".perl2dump($p).__PACKAGE__."::${whoami}, line ".__LINE__." (via $parent): not equal because key 'port' (i=$i) in obj1 is '".(defined($port)?$port:"<undef>")."' and in obj2 is '".(defined($p->[$i])?$p->[$i]:"<undef>")."'. See above obj2.\n" }
			$eqs = 0; return
		}

		$i++;
		#if( (defined($path_spec) xor defined($p->[$i]))
		# || (defined($path_spec) and ($path_spec ne $p->[$i]))
		#){
		#	if( $verbosity > 1 ){ print STDOUT "differ on path_spec:\nobj1: ".join("|", map { defined($_)?$_:"<undef>" } @_)."\nobj2:".perl2dump($p).__PACKAGE__."::${whoami}, line ".__LINE__." (via $parent): not equal because key 'path_spec' (i=$i) in obj1 is '".(defined($path_spec)?$path_spec:"<undef>")."' and in obj2 is '".(defined($p->[$i])?$p->[$i]:"<undef>")."'. See above obj2.\n" }
		#	$eqs = 0; return
		#}

		# this sometimes is undef or ''
		$i++;
		if( (defined($secure) xor defined($p->[$i]))
		 || (defined($secure) and ( ($secure?"1":"0") ne ($p->[$i]?"1":"0") ))
		){
			if( defined($secure) ){
				if( (defined($p->[$i]) && ($secure ne $p->[$i]))
				 || (defined($p->[$i]) && ('' ne $p->[$i]))
				){
					if( $verbosity > 1 ){ print STDOUT "differ on secure ('$secure' and '".$p->[$i]."'):\nobj1: ".join("|", map { defined($_)?$_:"<undef>" } @_)."\nobj2:".perl2dump($p).__PACKAGE__."::${whoami}, line ".__LINE__." (via $parent): not equal because key 'secure' (i=$i) in obj1 is '".(defined($secure)?$secure:"<undef>")."' and in obj2 is '".(defined($p->[$i])?$p->[$i]:"<undef>")."'. See above obj2.\n" }
					$eqs = 0; return
				}
			} else {
				if( defined($p->[$i]) && ($p->[$i] ne '') ){
					if( $verbosity > 1 ){ print STDOUT "differ on secure:\nobj1: ".join("|", map { defined($_)?$_:"<undef>" } @_)."\nobj2:".perl2dump($p).__PACKAGE__."::${whoami}, line ".__LINE__." (via $parent): not equal because key 'secure' (i=$i) in obj1 is '".(defined($secure)?$secure:"<undef>")."' and in obj2 is '".(defined($p->[$i])?$p->[$i]:"<undef>")."'. See above obj2.\n" }
					$eqs = 0; return
				}
			}
		}

		$i++;
		if( (defined($expires) xor defined($p->[$i]))
		 || (defined($expires) and ($expires ne $p->[$i]))
		){
			if( $verbosity > 1 ){ print STDOUT "obj1: ".join("|", map { defined($_)?$_:"<undef>" } @_)."\nobj2:".perl2dump($p).__PACKAGE__."::${whoami}, line ".__LINE__." (via $parent): not equal because key 'expires' (i=$i) in obj1 is '".(defined($expires)?$expires:"<undef>")."' and in obj2 is '".(defined($p->[$i])?$p->[$i]:"<undef>")."'. See above obj2.\n" }
			$eqs = 0; return
		}

		# discard is checked above and forget it.
		$i++;
		#if( (defined($discard) xor defined($p->[$i]))
		# || (defined($discard) and ( ($discard?"1":"0") ne ($p->[$i]?"1":"0") ))
		#){
		#	if( $verbosity > 1 ){ print STDOUT "obj1: ".join("|", map { defined($_)?$_:"<undef>" } @_)."\nobj2:".perl2dump($p).__PACKAGE__."::${whoami}, line ".__LINE__." (via $parent): not equal because key 'discard' (i=$i) in obj1 is '".(defined($discard)?$discard:"<undef>")."' and in obj2 is '".(defined($p->[$i])?$p->[$i]:"<undef>")."'. See above obj2.\n" }
		#	$eqs = 0; return
		#}

		# we don't care about the $rest

		if( $verbosity > 1 ){ print STDOUT "obj1: ".join("|", map { defined($_)?$_:"<undef>" } @_)."\nobj2:".perl2dump($obj2->{COOKIES}).__PACKAGE__."::${whoami}, line ".__LINE__." (via $parent): above (single) cookies are equal ...\n" }

		# still the same!
	    }
	  ); $eqs;
	};
	if( ! defined($rrr) || $@ ){ print STDERR __PACKAGE__."::${whoami}, line ".__LINE__." (via $parent): error, call to ".'HTTP::Cookies::scan()'." has failed".(defined($@)?" with this exception: $@":".").").\n"; return undef }
	return $rrr # 1 if equals
}

# It returns 1 if the two input objects (which must be of the same type)
# are equal. It returns 0 if they are different.
# It returns undef on failure.
sub	cookies_are_equal_httpcookies_bad {
	my ($obj1, $obj2, $skip_discard, $verbosity) = @_;
	$verbosity //= 0;
	$skip_discard //=0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $r = ref($obj1);

	if( $verbosity > 0 ){ print STDOUT "--begin 1st cookies:\n".as_string_cookies($obj1)."\n--end cookies.\n\n--begin 2nd cookies:\n".as_string_cookies($obj2)."\n--end cookies.\n"."${whoami}, line ".__LINE__." (via $parent): called with above data ...\n" }

	if( $r ne 'HTTP::Cookies' ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, the two input cookies must be of class 'HTTP::Cookies' but the first one is '$r'.\n"; return undef }
	if( $r ne ref($obj2) ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, the two input cookies must be of the same type/class. The first one is '$r' but the second is '".ref($obj2)."'.\n"; return undef }

	# convert them to strings but because we don't know the order, hash them.
	my $s1 = $obj1->as_string($skip_discard); $s1 =~ s/\R+$//;
	my $s2 = $obj2->as_string($skip_discard); $s2 =~ s/\R+$//;
	# this stupid adds the rest... we need to remove them
	my %s1 = ( map { s/(?:^|\n)Set-Cookie3:\s*//; $_ => 1 } map {
		s/\s*creation_time=.+?(?:;|$)//;
		s/\s*last_access_time=.+?(?:;|$)//;
		s/\s*discard(?:;|$)//;
		s/\s*version=.+?(?:;|$)//;
		$_
	} split /\n/, $s1 );
	my %s2 = ( map { s/(?:^|\n)Set-Cookie3:\s*//; $_ => 1 } map {
		s/\s*creation_time=.+?(?:;|$)//;
		s/\s*last_access_time=.+?(?:;|$)//;
		s/\s*discard(?:;|$)//;
		s/\s*version=.+?(?:;|$)//;
		$_
	} split /\n/, $s2 );
	if( $verbosity > 0 ){ print STDOUT "--begin 1st cookies HASH:\n".perl2dump(\%s1)."\n--end cookies.\n\n--begin 2nd cookies HASH:\n".perl2dump(\%s2)."\n--end cookies.\n"."${whoami}, line ".__LINE__." (via $parent): comparing above hashes ...\n" }

	for my $k (keys %s1){
		if( ! exists($s2{$k}) ){
			if( $verbosity > 0 ){ print STDOUT "--begin cookies:\n".join("\n", keys %s2)."\n--end cookies.\n${whoami}, line ".__LINE__." (via $parent): the following cookie from 1st cookies object does not exist in the 2nd cookies object which is above: $k\n" }
			return 0
		}
		delete $s2{$k};
	}
	# now do it the other way
	for my $k (keys %s2){
		if( ! exists($s1{$k}) ){
			if( $verbosity > 0 ){ print STDOUT "--begin cookies:\n".join("\n", keys %s1)."\n--end cookies.\n${whoami}, line ".__LINE__." (via $parent): cookie from 2nd cookies object does not exist in the 1st cookies object, see above: $k\n" }
			return 0
		}
	}

	return 1; # they are equal
}

# It returns 1 if the two input objects (which must be of the same type)
# are equal. It returns 0 if they are different.
# It returns undef on failure.
sub	cookies_are_equal_httpcookiejar {
	my ($obj1, $obj2, $skip_discard, $verbosity) = @_;
	$verbosity //= 0;
	$skip_discard //=0;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $r1 = ref($obj1);
	my $r2 = ref($obj2);
	if( ($r1 ne 'HTTP::CookieJar') && ($r1 ne 'HTTP::CookieJar::LWP') ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, the two input cookies must be of class 'HTTP::CookieJar' or 'HTTP::CookieJar::LWP' but the first one is '$r1' (and the second is is '$r2').\n"; return undef }
	if( ($r2 ne 'HTTP::CookieJar') && ($r2 ne 'HTTP::CookieJar::LWP') ){ print STDERR "${whoami}, line ".__LINE__." (via $parent): error, the two input cookies must be of class 'HTTP::CookieJar' or ' but the second one is '$r2'.\n"; return undef }
	# ok, we do not need to compare them r1/r2 because they can be
	# one 'HTTP::CookieJar' and the other 'HTTP::CookieJar::LWP'
	# but that's hopefully OK
	if( $verbosity > 0 ){ print STDOUT "--begin 1st cookies:\n".as_string_cookies($obj1)."\n--end cookies.\n\n--begin 2nd cookies:\n".as_string_cookies($obj2)."\n--end cookies.\n"."${whoami}, line ".__LINE__." (via $parent): comparing above two 'HTTP::CookieJar' objects.\n" }

	#print "ALL COOKIES1 ".perl2dump([$obj1->_all_cookies])."ALL COOKIES2 ".perl2dump([$obj2->_all_cookies]);
	#print "STORE1 ".perl2dump($obj1->{store})."STORE2 ".perl2dump($obj2->{store});

	# _all_cookies flattens 'store' hash and returns an array
	# whose items are in random order (values of hash)
	# and sometimes the comparison fails, so key it on domain/path/name/value
	return Data::Compare::Compare(
		{ map { join('|', map { defined $_ ? $_ : '<undef>' } @{$_}{qw/domain path name value/}) => $_ } $obj1->_all_cookies },
		{ map { join('|', map { defined $_ ? $_ : '<undef>' } @{$_}{qw/domain path name value/}) => $_ } $obj2->_all_cookies },
	) ? 1 : 0;
	#return Compare([$obj1->_all_cookies], [$obj2->_all_cookies]) ? 1 : 0;
	#return Compare([$obj1->{'store'}], [$obj2->{'store'}]) ? 1 : 0;
}

######################################################
# exporter private things
######################################################
sub import {
	# what comes here is (package, param1, param2...) = @_
	# for something like
	# use Cookies::Roundtrip qw/param1 params2 .../;
	# we are looking for a param, eq to 'xyz'
	# the rest we must pass to the Exporter::import() but in a tricky way
	# so as it injects all these subs in the proper namespace.
	# that call is at the end, but with our parameter removed from the list
	for(my $i=@_;$i-->1;){
		#if( $_[$i] eq 'xyz' ){
		#	splice @_, $i, 1; # remove it from the list
		#	do whatever this requires
		#} elsif( ...
	}
	# now let Exporter handle the rest of the params if any
	# from ikegami at https://www.perlmonks.org/?node_id=1214104
	goto &Exporter::import;
}
BEGIN {
	# group various subs for importing them with tags
	my @_lwpuseragent = qw/lwpuseragent_save_cookies_to_file lwpuseragent_load_cookies lwpuseragent_load_cookies_from_file lwpuseragent_load_setcookies lwpuseragent_load_httpcookies lwpuseragent_load_httpcookiejar lwpuseragent_get_cookies/;
	my @_wwwmechanize = qw/wwwmechanize_save_cookies_to_file wwwmechanize_load_cookies wwwmechanize_load_cookies_from_file wwwmechanize_load_setcookies wwwmechanize_load_httpcookies wwwmechanize_load_httpcookiejar wwwmechanize_get_cookies/;
	my @_firefoxmarionette = qw/firefoxmarionette_save_cookies_to_file firefoxmarionette_load_cookies firefoxmarionette_load_cookies_from_file firefoxmarionette_load_setcookies firefoxmarionette_load_httpcookies firefoxmarionette_load_httpcookiejar firefoxmarionette_get_cookies/;
	my @_clone = qw/clone_httpcookiejar clone_httpcookies clone_setcookies clone_cookies/;
	my @_merge = qw/merge_httpcookies merge_httpcookiejar merge_setcookies merge_firefoxmarionettecookies merge_cookies/;
	my @_count = qw/count_httpcookies count_httpcookiejar count_setcookies count_firefoxmarionettecookies count_cookies/;
	my @_equal = qw/cookies_are_equal cookies_are_equal_httpcookies cookies_are_equal_httpcookiejar cookies_are_equal_setcookies cookies_are_equal_firefoxmarionettecookie cookies_are_equal_firefoxmarionettecookies/;
	my @_setcookies2 = qw/setcookies2httpcookiejar setcookies2httpcookies/;
	my @_httpcookies2 = qw/httpcookies2setcookies httpcookies2file httpcookies2httpcookiejar httpcookies2firefoxmarionettecookies/;
	my @_httpcookiejar2 = qw/httpcookiejar2file httpcookiejar2httpcookies httpcookiejar2setcookies httpcookiejar2firefoxmarionettecookies/;
	my @_firefoxmarionettecookies2 = qw/firefoxmarionettecookies2file firefoxmarionettecookies2httpcookies firefoxmarionettecookies2httpcookiejar firefoxmarionettecookies2setcookies/;
	my @_new = qw/new_firefoxmarionettecookie new_firefoxmarionettecookies/;
	my @_file = qw/file2httpcookiejar httpcookiejar2file file2httpcookies httpcookies2file firefoxmarionettecookies2file file2firefoxmarionettecookies setcookies2file file2setcookies lwpuseragent_save_cookies_to_file lwpuseragent_load_cookies_from_file wwwmechanize_save_cookies_to_file wwwmechanize_load_cookies_from_file cookies2file/;
	my @_as_string = qw/as_string_httpcookiejar as_string_httpcookies as_string_setcookies as_string_cookies as_string_firefoxmarionettecookies/;
	@EXPORT_OK = qw/
as_string_httpcookiejar as_string_httpcookies as_string_setcookies as_string_firefoxmarionettecookies as_string_cookies
cookies_are_equal cookies_are_equal_httpcookies cookies_are_equal_httpcookiejar cookies_are_equal_setcookies cookies_are_equal_firefoxmarionettecookie cookies_are_equal_firefoxmarionettecookies
file2httpcookiejar httpcookiejar2file file2httpcookies httpcookies2file lwpuseragent_save_cookies_to_file lwpuseragent_load_cookies_from_file wwwmechanize_save_cookies_to_file wwwmechanize_load_cookies_from_file firefoxmarionettecookies2file file2firefoxmarionettecookies firefoxmarionettecookies2file setcookies2file file2setcookies cookies2file
firefoxmarionettecookies2setcookies
firefoxmarionettecookies2httpcookiejar
firefoxmarionettecookies2httpcookie
httpcookies2httpcookiejar 
lwpuseragent_get_cookies
lwpuseragent_load_cookies
lwpuseragent_load_setcookies
lwpuseragent_load_httpcookies
lwpuseragent_load_httpcookiejar
new_firefoxmarionettecookie new_firefoxmarionettecookies
wwwmechanize_get_cookies
wwwmechanize_load_cookies
wwwmechanize_load_setcookies
wwwmechanize_load_httpcookies
wwwmechanize_load_httpcookiejar
firefoxmarionette_save_cookies_to_file
firefoxmarionette_load_cookies
firefoxmarionette_load_cookies_from_file
firefoxmarionette_load_setcookies
firefoxmarionette_load_httpcookies
firefoxmarionette_load_httpcookiejar
firefoxmarionette_get_cookies
clone_httpcookiejar clone_httpcookies clone_setcookies clone_firefoxmarionettecookie clone_firefoxmarionettecookies clone_cookies
merge_httpcookies merge_httpcookiejar merge_setcookies merge_firefoxmarionettecookies merge_cookies
count_httpcookies count_httpcookiejar count_setcookies count_firefoxmarionettecookies count_cookies
setcookies2httpcookiejar
setcookies2httpcookies
setcookies2firefoxmarionettecookies
httpcookiejar2httpcookies
httpcookies2setcookies
httpcookiejar2setcookies
httpcookies2firefoxmarionettecookies
httpcookiejar2firefoxmarionettecookies
firefoxmarionettecookies2httpcookies
firefoxmarionettecookies2httpcookiejar
firefoxmarionettecookies2setcookies
	/;
	%EXPORT_TAGS = (
		lwpuseragent => [@_lwpuseragent],
		wwwmechanize => [@_wwwmechanize],
		firefoxmarionette => [@_firefoxmarionette],
		clone => [@_clone],
		merge => [@_merge],
		count => [@_count],
		equal => [@_equal],
		new => [@_new],
		setcookies2 => [@_setcookies2],
		httpcookies2 => [@_httpcookies2],
		httpcookiejar2 => [@_httpcookiejar2],
		firefoxmarionettecookies2 => [@_firefoxmarionettecookies2],
		file => [@_file],
		as_string => [@_as_string],
		all  => [@EXPORT_OK],
	);
} # end BEGIN

########## only pod below
=pod

=head1 NAME

Cookies::Roundtrip - Convert between different HTTP Cookie formats, well, at least we tried!

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

This module provides functionality for converting between some of the
various HTTP Cookie formats. I<Roundtrip> is a bit of a wish really
as there can be unsupported fields in the various Cookie formats.

Anyway! Here we try to convert between L<HTTP::Cookies>, L<HTTP::CookieJar>,
single L<Firefox::Marionette::Cookie> or an ARRAY of L<Firefox::Marionette::Cookie>,
an ARRAY of C<Set-Cookie> header strings,
which cover L<WWW::Mechanize> (and subclasses), L<LWP::UserAgent> (and subclasses)
and L<Firefox::Marionette>. Note that L<WWW::Mechanize> (and subclasses)
and L<LWP::UserAgent> (and subclasses) support both
L<HTTP::Cookies>, L<HTTP::CookieJar> and this is controlled during construction.

Example usage:

    use Cookies::Roundtrip qw/:all/;
    use HTTP::Cookies;
    use HTTP::CookieJar;

    # Skip discarded (expired etc.) cookies?
    my $skip_discard = 1; # or 0
    # Verbosity level
    my $VERBOSITY = 1; # 0 to ...

    # from this HTTP::CookieJar cookie ...
    my $hcj = HTTP::CookieJar->new;
    $hc->add(...);
    # ... convert to HTTP::Cookies
    my $hc = httpcookiejar2httpcookies($hcj, undef, $skip_discard, $VERBOSITY);
    # ... or supply the HTTP::Cookies object ($hc) to append to as sub parameter
    httpcookiejar2httpcookies($hcj, $hc, $skip_discard, $VERBOSITY) or die;

    # and back ...
    my $hcj2 = httpcookies2httpcookiejar($hc, undef, $skip_discard, $VERBOSITY);

    # From LWP::UserAgent
    my $ua = LWP::UserAgent->new(cookie_jar_class=>'HTTP::CookieJar');
    ...
    # extract them from LWP::UserAgent object
    $hcj = lwpuseragent_get_cookies($ua, $VERBOSITY);
    print "got ".count_cookies($hcj)." cookies\n";
    # ... or load them into the LWP::UserAgent object
    # note that the 2nd param ($hcj) can be a filename to load from file
    # or any other Cookie object whose class we support
    lwpuseragent_load_cookies($ua, $hcj, $VERBOSITY);

    # write to files
    wwwmechanize_save_cookies_to_file($mech, 'out.cookies', $skip_discard, $VERBOSITY);
    lwpuseragent_save_cookies_to_file($ua, 'out.cookies', $skip_discard, $VERBOSITY);
    firefoxmarionette_save_cookies_to_file($ffm, 'out.cookies', $skip_discard, $VERBOSITY);
    # or load from files
    wwwmechanize_load_cookies_from_file($mech, 'my.cookies', $skip_discard, $VERBOSITY);
    wwwmechanize_load_cookies_from_file($ua, 'my.cookies', $skip_discard, $VERBOSITY);
    wwwmechanize_load_cookies_from_file($ffm, 'my.cookies', $skip_discard, $VERBOSITY);
    # write cookie to file
    httpcookies2file($hc, 'out.cookies', $skip_discard, $VERBOSITY);
    httpcookiejar2file($hcj, 'out.cookies', $skip_discard, $VERBOSITY);
    # read cookies from file
    $hc = file2httpcookies('my.cookies', undef, $VERBOSITY);
    # or append them to existing cookies object
    file2httpcookies('my.cookies', $hc, $VERBOSITY);

    # count cookies of any Cookies object whose class we support
    count_cookies($cookies_obj, $skip_discard, $VERBOSITY);
    # clone cookies of any Cookies object whose class we support
    my $newcook = clone_cookies($cookies_obj, $VERBOSITY);
    # merge Cookie objects OF THE SAME class
    $newcook = merge_cookies($cook1, $cook2, $skip_discard, $VERBOSITY);

    # compare Cookie objects OF THE SAME class (we support) for equality
    my $yes = cookies_are_equal($cook1, $cook2, $skip_discard, $VERBOSITY); # 1 or 0 or undef

    # stringify any Cookies object whose class we support
    print as_string_cookies($cook, $skip_discard, $VERBOSITY);


=head1 EXPORT

By default no symbols are exported. You need to manually import any
symbol you wish to use.
However, for your convenience the following export tags are available
for importing symbols in groups.

Note that the C<:all> tag will import all the exportable symbols.

=over 4

=item * C<:all> : everything

=item * C<:lwpuseragent> : C<lwpuseragent_save_cookies_to_file>, C<lwpuseragent_load_cookies>, C<lwpuseragent_load_cookies_from_file>, C<lwpuseragent_load_setcookies>, C<lwpuseragent_load_httpcookies>, C<lwpuseragent_load_httpcookiejar>, C<lwpuseragent_get_cookies>

=item * C<:wwwmechanize> : C<wwwmechanize_save_cookies_to_file>, C<wwwmechanize_load_cookies>, C<wwwmechanize_load_cookies_from_file>, C<wwwmechanize_load_setcookies>, C<wwwmechanize_load_httpcookies>, C<wwwmechanize_load_httpcookiejar>, C<wwwmechanize_get_cookies>

=item * C<:firefoxmarionette> : C<firefoxmarionettecookies2file>, C<firefoxmarionettecookies2httpcookies>, C<firefoxmarionettecookies2httpcookiejar>, C<firefoxmarionettecookies2setcookies>,

=item * C<:clone> : C<clone_httpcookiejar>, C<clone_httpcookies>, C<clone_setcookies>, C<clone_cookies>

=item * C<:merge> : C<merge_httpcookies>, C<merge_httpcookiejar>, C<merge_setcookies>, C<merge_firefoxmarionettecookies>, C<merge_cookies>

=item * C<:count> : C<count_httpcookies>, C<count_httpcookiejar>, C<count_setcookies>, C<count_firefoxmarionettecookies>, C<count_cookies>

=item * C<:equal> : C<cookies_are_equal>, C<cookies_are_equal_httpcookies>, C<cookies_are_equal_httpcookiejar>, C<cookies_are_equal_setcookies>, C<cookies_are_equal_firefoxmarionettecookie>, C<cookies_are_equal_firefoxmarionettecookies>

=item * C<:setcookies2> : C<setcookies2httpcookiejar>, C<setcookies2httpcookies>

=item * C<:httpcookies2> : C<httpcookies2setcookies>, C<httpcookies2file>, C<httpcookies2httpcookiejar>, C<httpcookies2firefoxmarionettecookies>

=item * C<:httpcookiejar2> : C<httpcookies2setcookies>, C<httpcookies2file>, C<httpcookies2httpcookiejar>, C<httpcookies2firefoxmarionettecookies>

=item * C<:firefoxmarionettecookies2> : C<firefoxmarionettecookies2file>, C<firefoxmarionettecookies2httpcookies>, C<firefoxmarionettecookies2httpcookiejar>, C<firefoxmarionettecookies2setcookies>

=item * C<:new> : C<new_firefoxmarionettecookie>, C<new_firefoxmarionettecookies>

=item * C<:file> : C<file2httpcookiejar>, C<httpcookiejar2file>, C<file2httpcookies>, C<httpcookies2file>, C<firefoxmarionettecookies2file>, C<file2firefoxmarionettecookies>, C<setcookies2file>, C<file2setcookies>, C<lwpuseragent_save_cookies_to_file>, C<lwpuseragent_load_cookies_from_file>, C<wwwmechanize_save_cookies_to_file>, C<wwwmechanize_load_cookies_from_file>, C<cookies2file>

=item * C<:as_string> : C<as_string_httpcookiejar>, C<as_string_httpcookies>, C<as_string_setcookies>, C<as_string_cookies>, C<as_string_firefoxmarionettecookies>

=back

=head1 SUBROUTINES

Below, C<$skip_discard> is a flag
dictating whether
to skip discarded cookies during the operation (value
of C<1>) or not (value of C<0>).

C<$verbosity> denotes the verbosity level
as an integer. C<0> being mute.


=head2 C<lwpuseragent_get_cookies>

  my $ret = lwpuseragent_get_cookies($ua, $verbosity);

Arguments:

=over 4

=item * C<$ua>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

It returns the cookies of the specified L<LWP::UserAgent> object.

=head2 C<lwpuseragent_save_cookies_to_file>

  my $ret = lwpuseragent_save_cookies_to_file($ua, $filename, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$ua>

=item * C<$filename>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

It saves the cookies held in specified L<LWP::UserAgent> object to
specified file. It returns (C<$ret>) C<1> on failure or C<0> on success.


=head2 C<lwpuseragent_load_cookies>

  my $ret = lwpuseragent_load_cookies($ua, $cookies_or_file_etc, $verbosity);

Arguments:

=over 4

=item * C<$ua>

=item * C<$cookies_or_file_etc>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

This is a generic function to load any type of cookies
into the specifed L<LWP::UserAgent> object. Cookies
can be in a file (C<$cookies_or_file_etc> is a scalar holding the filename),
or a Cookies object we support or an ARRAY_REF of C<SetCookie> strings
or an ARRAY_REF of L<Firefox::Marionette::Cookie> objects.

=head2 C<lwpuseragent_load_cookies_from_file>

  my $ret = lwpuseragent_load_cookies_from_file($ua, $filename, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$ua>

=item * C<$filename>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

It loads cookies from file into the specifed L<LWP::UserAgent> object.
L<lwpuseragent_load_cookies> will do the same job when specified
with a filename.

It returns C<undef> on failure or
the cookies read from file as a Cookies object on success.
Note that L<LWP::UserAgent> supports both L<HTTP::Cookies> and
L<HTTP::CookieJar>, the class of the returned object will
be one of these, depending what the specified L<LWP::UserAgent>
object was instructed to hold, by using

    my $ua = LWP::UserAgent->new(cookie_jar_class=>'HTTP::CookieJar');


=head2 C<lwpuseragent_load_setcookies>

  my $ret = lwpuseragent_load_setcookies($ua, $setcookies, $verbosity);

Arguments:

=over 4

=item * C<$ua>

=item * C<$setcookies>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<lwpuseragent_load_firefoxmarionettecookies>

  my $ret = lwpuseragent_load_firefoxmarionettecookies($ua, $firefoxmarionettecookies, $verbosity);

Arguments:

=over 4

=item * C<$ua>

=item * C<$firefoxmarionettecookies>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<lwpuseragent_load_httpcookies>

  my $ret = lwpuseragent_load_httpcookies($ua, $httpcookies, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$ua>

=item * C<$httpcookies>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<lwpuseragent_load_httpcookiejar>

  my $ret = lwpuseragent_load_httpcookiejar($ua, $httpcookiejar, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$ua>

=item * C<$httpcookiejar>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<firefoxmarionette_get_cookies>

  my $ret = firefoxmarionette_get_cookies($ffmar, $verbosity);

Arguments:

=over 4

=item * C<$ffmar>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<firefoxmarionette_save_cookies_to_file>

  my $ret = firefoxmarionette_save_cookies_to_file($ffmar, $filename, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$ffmar>

=item * C<$filename>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<firefoxmarionette_load_cookies>

  my $ret = firefoxmarionette_load_cookies($ffmar, $cookies_or_file_etc, $visit_cookie_domain_first, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$ffmar>

=item * C<$cookies_or_file_etc>

=item * C<$visit_cookie_domain_first>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<firefoxmarionette_load_cookies_from_file>

  my $ret = firefoxmarionette_load_cookies_from_file($ffmar, $filename, $visit_cookie_domain_first, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$ffmar>

=item * C<$filename>

=item * C<$visit_cookie_domain_first>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<firefoxmarionette_load_setcookies>

  my $ret = firefoxmarionette_load_setcookies($ffmar, $setcookies, $visit_cookie_domain_first, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$ffmar>

=item * C<$setcookies>

=item * C<$visit_cookie_domain_first>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<firefoxmarionette_load_firefoxmarionettecookies>

  my $ret = firefoxmarionette_load_firefoxmarionettecookies($ffmar, $firefoxmarionettecookies, $visit_cookie_domain_first, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$ffmar>

=item * C<$firefoxmarionettecookies>

=item * C<$visit_cookie_domain_first>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<firefoxmarionette_load_httpcookies>

  my $ret = firefoxmarionette_load_httpcookies($ffmar, $httpcookies, $visit_cookie_domain_first, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$ffmar>

=item * C<$httpcookies>

=item * C<$visit_cookie_domain_first>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<firefoxmarionette_load_httpcookiejar>

  my $ret = firefoxmarionette_load_httpcookiejar($ffmar, $httpcookiejar, $visit_cookie_domain_first, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$ffmar>

=item * C<$httpcookiejar>

=item * C<$visit_cookie_domain_first>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<wwwmechanize_get_cookies>

  my $ret = wwwmechanize_get_cookies($mech, $verbosity);

Arguments:

=over 4

=item * C<$mech>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<wwwmechanize_save_cookies_to_file>

  my $ret = wwwmechanize_save_cookies_to_file($mech, $filename, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$mech>

=item * C<$filename>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<wwwmechanize_load_cookies>

  my $ret = wwwmechanize_load_cookies($mech, $cookies_or_file_etc, $verbosity);

Arguments:

=over 4

=item * C<$mech>

=item * C<$cookies_or_file_etc>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<wwwmechanize_load_cookies_from_file>

  my $ret = wwwmechanize_load_cookies_from_file($mech, $filename, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$mech>

=item * C<$filename>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<wwwmechanize_load_setcookies>

  my $ret = wwwmechanize_load_setcookies($mech, $setcookies, $verbosity);

Arguments:

=over 4

=item * C<$mech>

=item * C<$setcookies>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<wwwmechanize_load_firefoxmarionettecookies>

  my $ret = wwwmechanize_load_firefoxmarionettecookies($mech, $firefoxmarionettecookies, $verbosity);

Arguments:

=over 4

=item * C<$mech>

=item * C<$firefoxmarionettecookies>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<wwwmechanize_load_httpcookies>

  my $ret = wwwmechanize_load_httpcookies($mech, $httpcookies, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$mech>

=item * C<$httpcookies>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<wwwmechanize_load_httpcookiejar>

  my $ret = wwwmechanize_load_httpcookiejar($mech, $httpcookiejar, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$mech>

=item * C<$httpcookiejar>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<new_firefoxmarionettecookie>

  my $ret = new_firefoxmarionettecookie($params, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$params>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<new_firefoxmarionettecookies>

  my $ret = new_firefoxmarionettecookies($params, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$params>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<cookies2file>

  my $ret = cookies2file($cookies, $filename, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$cookies>

=item * C<$filename>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<httpcookiejar2file>

  my $ret = httpcookiejar2file($httpcookiejar, $filename, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$httpcookiejar>

=item * C<$filename>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<file2httpcookiejar>

  my $ret = file2httpcookiejar($filename, $httpcookiejar, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$filename>

=item * C<$httpcookiejar>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<file2httpcookies>

  my $ret = file2httpcookies($filename, $httpcookies, $verbosity);

Arguments:

=over 4

=item * C<$filename>

=item * C<$httpcookies>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<httpcookies2file>

  my $ret = httpcookies2file($httpcookies, $filename, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$httpcookies>

=item * C<$filename>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<firefoxmarionettecookies2file>

  my $ret = firefoxmarionettecookies2file($firefoxmarionettecookies, $filename, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$firefoxmarionettecookies>

=item * C<$filename>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<file2firefoxmarionettecookies>

  my $ret = file2firefoxmarionettecookies($filename, $firefoxmarionettecookies, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$filename>

=item * C<$firefoxmarionettecookies>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<setcookies2file>

  my $ret = setcookies2file($setcookies, $filename, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$setcookies>

=item * C<$filename>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<file2setcookies>

  my $ret = file2setcookies($filename, $setcookies, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$filename>

=item * C<$setcookies>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<httpcookies2httpcookiejar>

  my $ret = httpcookies2httpcookiejar($httpcookies, $httpcookiejar, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$httpcookies>

=item * C<$httpcookiejar>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<httpcookies2firefoxmarionettecookies>

  my $ret = httpcookies2firefoxmarionettecookies($httpcookies, $firefoxmarionettecookies, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$httpcookies>

=item * C<$firefoxmarionettecookies>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<clone_cookies>

  my $ret = clone_cookies($w, $verbosity);

Arguments:

=over 4

=item * C<$w>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<clone_httpcookiejar>

  my $ret = clone_httpcookiejar($httpcookiejar, $verbosity);

Arguments:

=over 4

=item * C<$httpcookiejar>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<clone_firefoxmarionettecookie>

  my $ret = clone_firefoxmarionettecookie($firefoxmarionettecookie, $verbosity);

Arguments:

=over 4

=item * C<$firefoxmarionettecookie>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<clone_firefoxmarionettecookies>

  my $ret = clone_firefoxmarionettecookies($firefoxmarionettecookies, $verbosity);

Arguments:

=over 4

=item * C<$firefoxmarionettecookies>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<clone_httpcookies>

  my $ret = clone_httpcookies($httpcookies, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$httpcookies>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<merge_cookies>

  my $ret = merge_cookies($obj1, $obj2, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$obj1>

=item * C<$obj2>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<merge_httpcookies>

  my $ret = merge_httpcookies($httpcookies_src, $httpcookies_dst, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$httpcookies_src>

=item * C<$httpcookies_dst>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<merge_httpcookiejar>

  my $ret = merge_httpcookiejar($httpcookiejar_src, $httpcookiejar_dst, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$httpcookiejar_src>

=item * C<$httpcookiejar_dst>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<merge_firefoxmarionettecookies>

  my $ret = merge_firefoxmarionettecookies($src, $dst);

Arguments:

=over 4

=item * C<$src>

=item * C<$dst>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<setcookies2httpcookiejar>

  my $ret = setcookies2httpcookiejar($setcookies, $httpcookiejar, $verbosity);

Arguments:

=over 4

=item * C<$setcookies>

=item * C<$httpcookiejar>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<setcookies2firefoxmarionettecookies>

  my $ret = setcookies2firefoxmarionettecookies($setcookies, $firefoxmarionettecookies, $verbosity);

Arguments:

=over 4

=item * C<$setcookies>

=item * C<$firefoxmarionettecookies>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<setcookie2firefoxmarionettecookie>

  my $ret = setcookie2firefoxmarionettecookie($setcookie, $firefoxmarionettecookie, $verbosity);

Arguments:

=over 4

=item * C<$setcookie>

=item * C<$firefoxmarionettecookie>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<count_cookies>

  my $ret = count_cookies($w, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$w>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<count_httpcookies>

  my $ret = count_httpcookies($httpcookies, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$httpcookies>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<setcookie2httpcookies_set_cookie_array>

  my $ret = setcookie2httpcookies_set_cookie_array($setcookie, $verbosity);

Arguments:

=over 4

=item * C<$setcookie>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<setcookie2hash>

  my $ret = setcookie2hash($setcookie, $verbosity);

Arguments:

=over 4

=item * C<$setcookie>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<setcookies2httpcookies>

  my $ret = setcookies2httpcookies($setcookies, $httpcookies, $verbosity);

Arguments:

=over 4

=item * C<$setcookies>

=item * C<$httpcookies>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<firefoxmarionettecookies2setcookies>

  my $ret = firefoxmarionettecookies2setcookies($firefoxmarionettecookies, $setcookies, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$firefoxmarionettecookies>

=item * C<$setcookies>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<firefoxmarionettecookies2httpcookiejar>

  my $ret = firefoxmarionettecookies2httpcookiejar($firefoxmarionettecookies, $httpcookiejar, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$firefoxmarionettecookies>

=item * C<$httpcookiejar>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<httpcookiejar2httpcookies>

  my $ret = httpcookiejar2httpcookies($httpcookiejar, $httpcookies, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$httpcookiejar>

=item * C<$httpcookies>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<firefoxmarionettecookies2httpcookies>

  my $ret = firefoxmarionettecookies2httpcookies($firefoxmarionettecookies, $httpcookies, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$firefoxmarionettecookies>

=item * C<$httpcookies>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<httpcookies2setcookies>

  my $ret = httpcookies2setcookies($httpcookies, $setcookies, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$httpcookies>

=item * C<$setcookies>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<httpcookiejar2setcookies>

  my $ret = httpcookiejar2setcookies($httpcookiejar, $setcookies, $verbosity);

Arguments:

=over 4

=item * C<$httpcookiejar>

=item * C<$setcookies>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<httpcookiejar2firefoxmarionettecookies>

  my $ret = httpcookiejar2firefoxmarionettecookies($httpcookiejar, $firefoxmarionettecookies, $verbosity);

Arguments:

=over 4

=item * C<$httpcookiejar>

=item * C<$firefoxmarionettecookies>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<as_string_cookies>

  my $ret = as_string_cookies($w, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$w>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<as_string_firefoxmarionettecookies>

  my $ret = as_string_firefoxmarionettecookies($w, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$w>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<as_string_firefoxmarionettecookie>

  my $ret = as_string_firefoxmarionettecookie($w, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$w>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<as_string_httpcookies>

  my $ret = as_string_httpcookies($httpcookies, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$httpcookies>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<cookies_are_equal>

  my $ret = cookies_are_equal($obj1, $obj2, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$obj1>

=item * C<$obj2>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<cookies_are_equal_setcookies>

  my $ret = cookies_are_equal_setcookies($obj1, $obj2, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$obj1>

=item * C<$obj2>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<cookies_are_equal_firefoxmarionettecookie>

  my $ret = cookies_are_equal_firefoxmarionettecookie($obj1, $obj2, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$obj1>

=item * C<$obj2>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<cookies_are_equal_firefoxmarionettecookies>

  my $ret = cookies_are_equal_firefoxmarionettecookies($obj1, $obj2, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$obj1>

=item * C<$obj2>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<cookies_are_equal_httpcookies>

  my $ret = cookies_are_equal_httpcookies($obj1, $obj2, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$obj1>

=item * C<$obj2>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<cookies_are_equal_httpcookies_bad>

  my $ret = cookies_are_equal_httpcookies_bad($obj1, $obj2, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$obj1>

=item * C<$obj2>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description

=head2 C<cookies_are_equal_httpcookiejar>

  my $ret = cookies_are_equal_httpcookiejar($obj1, $obj2, $skip_discard, $verbosity);

Arguments:

=over 4

=item * C<$obj1>

=item * C<$obj2>

=item * C<$skip_discard>

=item * C<$verbosity>

=back

Return value:

=over 4

=item * C<$ret> : a cookie object on success or C<undef> on failure.

=back

=for comment
add here description


=head1 CAVEATS

Converting between Perl Cookie classes is a futile task.
Those who implemented a second Perl Cookie class are
doing a dis-service to the community.

This module can fail at any time. If it does, please
provide the details AND the remedy.


=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cookies-roundtrip at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cookies-Roundtrip>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cookies::Roundtrip


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Cookies-Roundtrip>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Cookies-Roundtrip>

=item * Search CPAN

L<https://metacpan.org/release/Cookies-Roundtrip>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Andreas Hadjiprocopis.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Cookies::Roundtrip

