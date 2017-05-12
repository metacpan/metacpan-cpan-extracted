# Apache::AppSamurai::Util - Utility functions for AppSamurai

# $Id: Util.pm,v 1.21 2008/04/30 21:40:06 pauldoom Exp $

##
# Copyright (c) 2008 Paul M. Hirsch (paul@voltagenoir.org).
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.
##

# NOTE - This file includes content directly from CGI::Util

# TODO - Move validation methods into this and provide methods exports

package Apache::AppSamurai::Util;
use strict;
use warnings;

use vars qw($VERSION @EXPORT_OK @ISA $IDLEN);
$VERSION = substr(q$Revision: 1.21 $, 10, -1);

use Digest::SHA qw(sha256_hex hmac_sha256_hex);
use Time::HiRes;

@ISA = qw(Exporter);
@EXPORT_OK = qw(expires CreateSessionAuthKey CheckSidFormat
		HashPass HashAny ComputeSessionId CheckUrlFormat CheckHostName
		CheckHostIP XHalf);

# $IDLEN defines the byte length for all IDs (Session IDs, Keys, etc).
# This should be the byte length of the main digest function used.
# (Provided in case something other than SHA256 is used.)
$IDLEN = 32;

# -- expires() shamelessly taken from CGI::Util
## -- And this expires shamelessly taken from Apache::AuthCookie::Util ;)
sub expires {
    my($time,$format) = @_;
    $format ||= 'http';

    my(@MON) = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
    my(@WDAY) = qw/Sun Mon Tue Wed Thu Fri Sat/;

    # pass through preformatted dates for the sake of expire_calc()
    $time = _expire_calc($time);
    return $time unless $time =~ /^\d+$/;

    # make HTTP/cookie date string from GMT'ed time
    # (cookies use '-' as date separator, HTTP uses ' ')
    my($sc) = ' ';
    $sc = '-' if $format eq "cookie";
    my($sec,$min,$hour,$mday,$mon,$year,$wday) = gmtime($time);
    $year += 1900;
    return sprintf("%s, %02d$sc%s$sc%04d %02d:%02d:%02d GMT",
                   $WDAY[$wday],$mday,$MON[$mon],$year,$hour,$min,$sec);
}

# -- expire_calc() shamelessly taken from CGI::Util
# This internal routine creates an expires time exactly some number of
# hours from the current time.  It incorporates modifications from 
# Mark Fisher.
sub _expire_calc {
    my($time) = @_;
    my(%mult) = ('s'=>1,
                 'm'=>60,
                 'h'=>60*60,
                 'd'=>60*60*24,
                 'M'=>60*60*24*30,
                 'y'=>60*60*24*365);
    # format for time can be in any of the forms...
    # "now" -- expire immediately
    # "+180s" -- in 180 seconds
    # "+2m" -- in 2 minutes
    # "+12h" -- in 12 hours
    # "+1d"  -- in 1 day
    # "+3M"  -- in 3 months
    # "+2y"  -- in 2 years
    # "-3m"  -- 3 minutes ago(!)
    # If you don't supply one of these forms, we assume you are
    # specifying the date yourself
    my($offset);
    if (!$time || (lc($time) eq 'now')) {
        $offset = 0;
    } elsif ($time=~/^\d+/) {
        return $time;
    } elsif ($time=~/^([+-]?(?:\d+|\d*\.\d*))([mhdMy]?)/) {
        $offset = ($mult{$2} || 1)*$1;
    } else {
        return $time;
    }
    return (time+$offset);
}


# Create a session authentication key to send back to the user's browser.
# This is the "session key", not the local "session ID".  It will be used
# with the server's ServerKey value to create the local session ID, and 
# to look up a user's session going forward.  This session key is also used
# to encrypt the user's session data.  Do not log the session authentication
# key!  All logging should reference the server side session key/ID.
#
# If no arguments are passed the key is chosen randomly, else it is a digest of
# the concatenated args
sub CreateSessionAuthKey {
    my $key = '';
    my $cycles = 5;
    my $text = '';

    # Pull in and concatenate custom key text
    if (scalar @_) {
	$text = join("", @_);
	($text =~ /^\s*$/) && ($text = '');
    }

    if ($text) {
	$key = sha256_hex($text);
    } else {
	# You only make a new session once in a while, so take the time to pick
	# something hard. (Though, Bruce Schneier might very well laugh at it.)
	for (my $i=0; $i < $cycles; $i++) {
	    $key = sha256_hex(sprintf("%0.6f", Time::HiRes::time()) . $key . $$);
	}
    }

    # One time I put a VERY stupid bug in this code.  End result: It returned
    # the SHA256 digest of '' for everything.  Stupid.  NEVER AGAIN!!!!
    # (FYI: Yes, this method is unit tested now, too, but still...)
    if ($key =~ /^e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855$/i) {
	die "OH MY GOD!!!! That is the SHA256 of nothing, bozo!";
    }

    return $key;
}

# Hash plaintext password/passphrase
sub HashPass {
    my $plain = shift;
 
    # Check for basic decency.  (This is checked when configuring.  This is just a failsafe.)
    ($plain =~ /^[[:print:]]+$/s) or die "HashPass(): Invalid characters in plaintext passphrase";

    return sha256_hex($plain);
}

# Just hash whatever is passed in, joining as needed
sub HashAny {
    my $plain = join('', @_);
    return sha256_hex($plain);
}
       
# Given session authentication key from browser and ServerKey from the config.
# use a HMAC to compute the real session ID.
sub ComputeSessionId {
    my ($authkey, $serverkey) = @_;

    # This is checked before this point.  This is just a failsafe
    (CheckSidFormat($authkey) && CheckSidFormat($serverkey)) or return undef;
    
    return hmac_sha256_hex($authkey, $serverkey);
}

# Check the composition of the Session ID.  This does not check if the ID 
# exists and that it is well formed
sub CheckSidFormat {
    my $sid = shift;
    (defined($sid)) || (return undef);
    
    my $tlen = $IDLEN * 2;

    # Check that the ID is a hex string of length $IDLEN bytes
    ($sid =~ /^([a-f0-9]{$tlen})$/i) ? (return $1) : (return undef);
}

# Check full URL (host + args).  Untaints as it cleans.  Returns undef if it
# ain't clean.  
sub CheckUrlFormat {
    my $url = shift;
    # Following check pulled out of OWASP FAQ, and converted for Perl
    ($url =~ /((((https?|ftps?|gopher|telnet|nntp):\/\/)|(mailto:|news:))(%[0-9A-Fa-f]{2}|[\-\(\)_\.!\~\*\';\/\?:\@\&=\+\$,A-Za-z0-9])+)([\)\.!\';\/\?:,][[:blank:]])?$/) ? (return $1) : (return undef);
}

# Check host address or DNS name.  NOT A STRICT TEST!  This will allow in
# IPv4 and v6 and most DNS names.  Use CheckHostIP for a strict IPv4 check.
sub CheckHostName {
    my $hostname = shift;
    ($hostname =~ /^\s*([\w\d\-\_\.\:]+)\s*$/) ? (return $1) : (return undef);
}

# Check IPv4 or IPv6 IP for valid format, using a nice little regex
# for the IPv4 check, and a hellaciously long but (as far as I can tell,
# good) regex from http://www.regexlib.com/REDetails.aspx?regexp_id=1000 by
# Jeff Johnston for IPv6 checks.  
sub CheckHostIP {
    my $ip = shift;
    my @t;

    if ($ip =~ /^\s*(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\s*$/) {
	# It is IPv4
	@t = ($1, $2, $3, $4);
	foreach (@t) {
	    # Strip leading 0s
	    s/^0{1,2}(\d)/$1/;
	    ($1 < 256) || (return undef); # One of the octets is too big
	}
	return join('.', @t);
    } #elsif ($ip =~ /^\s*((([0-9A-F]{1,4}:){7}[0-9A-F]{1,4})|(((0-9A-F]{1,4}:){6}:[0-9A-F]{1,4})|(([0-9A-F]{1,4}:){5}:([0-9A-F]{1,4}:)?[0-9A-F]{1,4})|(([0-9A-F]{1,4}:){4}:([0-9A-F]{1,4}:){0,2}[0-9A-F]{1,4})|(([0-9A-F]{1,4}:){3}:([0-9A-F]{1,4}:){0,3}[0-9A-F]{1,4})|(([0-9A-F]{1,4}:){2}:([0-9A-F]{1,4}:){0,4}[0-9A-F]{1,4})|(([0-9A-F]{1,4}:){6}((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|(([0-9A-F]{1,4}:){0,5}:((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|(::([0-9A-F]{1,4}:){0,5}((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|([0-9A-F]{1,4}::([0-9A-F]{1,4}:){0,5}[0-9A-F]{1,4})|(::([0-9A-F]{1,4}:){0,6}[0-9A-F]{1,4})|(([0-9A-F]{1,4}:){1,7}:))\s*$/i) {
	# Thanks to Jeff Johnston for the above.  Slightly shortened by
	# removing a-f set and adding /i to the end.  So, a programmatic
	# check may have been easier.  I'll stick with the regex-matic check.
	#return $ip;
    #}

    # Doesn't look IP-ish
    return undef;
}

# X out the second half of the string.  Used for debugging to reduce (BUT
# NOT ELIMINATE) the risk of sensitive information ending up in log files.
sub XHalf {
    my $text = shift;

    if ($text) {
	my $lb = int(length($text) / 2);
	if (($lb) && ($text =~ s/.{$lb}$/"X" x $lb/e)) {
	    return $text;
	}
    }

    # Better empty than sorry
    return "";
}

1; # End of Apache::AppSamurai::Tracker

__END__

=head1 NAME

Apache::AppSamurai::Util - Apache::AppSamurai utility methods

=head1 SYNOPSIS

 use Apache::AppSamurai::Util qw(expires CreateSessionAuthKey
	 			CheckSidFormat HashPass HashAny
		 		ComputeSessionId CheckUrlFormat
                                CheckHostName CheckHostIP XHalf);
 
 
 # Convert UNIX timestamp to a cookie expiration date
 $expirets = time() + 3600;
 $expire = expires($expire);

 # Get a random session authentication key.
 $newkey = CreateSessionAuthKey();

 # Compute a session authentication key from input.
 $junk = 'stuffySTUFFthing';
 $newkey = CreateSessionAuthKey($junk);

 # Untaint and check for valid session ID or session auth key format.
 if ($id = CheckSidFormat($id)) { print "ROCK ON!\n"; }

 # Check for a valid "passphrase" (must be all printables and normal
 # whitespace), then return a hash of input.
 $passphrase = "The quick brown cow jumped into the A&W root beer.";
 ($passkey = HashPass($passphrase)) or die "Bad passphrase";

 # Just hash the input, even if empty, and return hash.
 $hashstruff = HashAny('stuff');

 # Compute the real session ID by computing a HMAC of the user's session
 # authentication key and the server's key.
 $authkey = '628b49d96dcde97a430dd4f597705899e09a968f793491e4b704cae33a40dc02';
 $servkey = 'c44474038d459e40e4714afefa7bf8dae9f9834b22f5e8ec1dd434ecb62b512e';
 ($sessid = ComputeSessionId($authkey, $servkey)) or die "Bad input!";

 # Untaint and check for a valid session ID, session authentication key,
 # or server key value.  (All should be hex strings of a proper length.)
 ($authkey = CheckSidFormat($authkey)) or die "Bad authentication key!";

 # Untaint and check (loosely) for a properly formatted URL.
 $url = 'http://jerryonly.mil/TheApp?test=1';
 ($url = CheckUrlFormat($url)) or die "You call that an URL?";

 # Untaint and check for a decent looking hostname/DNS name
 $hn = 'jerryonly.mil';
 ($hn = CheckHostName($hn)) or die "Bad name, man.";

 # Untaint and check for a valid IP. IPv4 only supported at this time :(
 $ip = '10.11.12.13';
 ($ip = CheckHostIP($ip)) or die "That is no kind of dotted quad....";

 # Untaint and then X out the second half of the input.  This is used
 # for various debugging output to (hopefully) protect sensitive info from
 # ending up in logs.
 $msg = "Who stole my notebook?  Was it you Larry?";
 $msg = XHalf($msg);
 print $msg, "\n";
 # Prints out: Who stole my notebookXXXXXXXXXXXXXXXXXXXX

=head1 DESCRIPTION

This is a set of utility methods for L<Apache::AppSamurai|Apache::AppSamurai>
and related sub-modules to use.  All methods should be called with a full
module path, (Apache::AppSamurai::Util::CheckHostIp(), etc), or be imported
into the current namespace.

Almost all the methods return a clean, untainted value on success, or undef
on failure.

=head1 METHODS

=head2 expires()

Convert a UNIX timestamp to a valid cookie expire stamp.  (Copied from
L<CGI::Util|CGI::Util>).

=head2 CreateSessionAuthKey()

Takes one or more arguments and concatenates them.  If no arguments are given,
a random string is created instead.  Returns the SHA256 digest hex string 
of the input or random string.

=head2 HashPass()

Takes a scalar with printable text (normal chars and whitespace), and returns
the SHA256 digest hex string of the input.

=head2 HashAny()

Concatenates one or more arguments and returns the SHA256 digest hex string
of the input.  This method allows an input of ''.  Do not use for security
checks without first checking your input.

=head2 ComputeSessionId()

Takes a session authentication key, (generally the cookie value from the
client), as the first argument.  The second is the server key, (configured
with the ServerKey or ServerPass option in the Apache config.)  After checking
for valid input, a HMAC is calculated using the SHA256 digest algorithm.
The HMAC is returned as a hex string.

This method of looking up the real (local) session ID allows for keeping the
session authentication key a secret to the web server while it is not
being actively used.  This is important because the session authentication key
is used (in part) to encrypt the user's session data.  Without the session
authentication key, a hacker can not steal information from a stale session
file, remnant data on a hard drive, or from a hacked database.

=head2 CheckSidFormat()

Check input scalar for proper ID format.  (Characters and length.)  Returns
the untainted input, or undef on failure.

Apache::AppSamurai currently uses SHA256 for all digest and ID functions.
All are represented as hex strings with a length of 32 characters.  (256 bits
divided by 4 characters per nibble.)  This magic number is set in the C<$IDLEN>
global in the Util.pm file.  Future versions may be more flexible and allow
alternate digest algorithms.

=head2 CheckUrlFormat()

Check the scalar for proper URL formatting.  Returns the untainted URL or undef
on failure.

This is just a basic check, and allows through ftp:, gopher:, etc in addition
to http: and https:.  It is just a sanity check.  Apply more extensive
filtering using mod_rewrite or other means, as needed.

=head2 CheckHostName()

Check scalar for basic hostname/domain name syntax.  Returns an untainted
version of the input, or undef on failure.

=head2 CheckHostIP()

Check input scalar for proper text IP format. Returns the untainted input
on success, or undef on failure.

IPv4 dotted quads are only supported at this time.  IPv6 support will be
added, but considering the ungodly tangled mess that can represent an
IPv6 address, the motivation to tackle it is not currently present.

=head2 XHalf()

Check that input scalar is text, then convert the second half of the string
to a string of 'X's and return the new string.

This is used for debug logging of potentially sensitive information, where
some context text is required, but where a full disclosure would be dangerous.
Only use this method when the latter half of the text contains all or most
of the sensitive data.  It is a convenience function to avoid needing to
write custom data sanitization into each logging event.

For instance, for a session ID of
"628b49d96dcde97a430dd4f597705899e09a968f793491e4b704cae33a40dc02"
the output would be:
"628b49d96dcde97a430dd4f597705899XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
which would be fairly safe since only half the data would be revealed in the
log. This is still 128 bits of digest, and in most cases would be enough not
to seriously endanger the data.
 
On the other hand, if you allow long passwords and you log a basic
authentication "Authorization:" header of:
"cm9nZXJ0aGVtYW46VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wZWQgb3ZlciB0aGUgbGF6eSBkb2cu"
the output would be:
"cm9nZXJ0aGVtYW46VGhlIHF1aWNrIGJyb3duIGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX".
This is not very safe.  Here is what decoding produces:
"rogertheman:The quick brown e×]u×]u×]u×]u×]u×]u×]u×]u×]u×"
So, the user's name is "rogertheman".  More importantly, we can guess what
the rest of the password is, and we know the length of the password.

Apache::AppSamurai does log the Authorization: header using XHalf when
Debug is enabled.  Be very careful when running production servers!  Only
use Debug when absolutely needed, monitor the logs for sensitive information
leak, and remove debug log data when possible.

That said, leave Debug set to 0 and do not use XHalf in any modules you
code if you find it too risky.

=head1 SEE ALSO

L<Apache::AppSamurai>, L<Digest::SHA>

=head1 AUTHOR

Paul M. Hirsch, C<< <paul at voltagenoir.org> >>

=head1 BUGS

See L<Apache::AppSamurai> for information on bug submission and tracking.

=head1 SUPPORT

See L<Apache::AppSamurai> for support information.

=head1 ACKNOWLEDGEMENTS

This module includes date calculation code from
L<CGI::Util>.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Paul M. Hirsch, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
