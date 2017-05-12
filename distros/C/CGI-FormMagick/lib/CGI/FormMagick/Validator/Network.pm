#!/usr/bin/perl -w

#
# FormMagick (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# Copyright (c) 2000-2002 Mitel Networks Corporation
# This software is distributed under the same licenses as Perl itself;
# see the file COPYING for details.
#
# $Id: Network.pm,v 1.12 2003/02/05 17:18:41 anoncvs_gtkglext Exp $
#

package    CGI::FormMagick::Validator;
use strict;
use Mail::RFC822::Address;

=pod

=head1 NAME

CGI::FormMagick::Validator::Network - network-related validation routines

=head1 SYNOPSIS

use CGI::FormMagick;

=head1 DESCRIPTION

See CGI::FormMagick::Validator for a general description.

=head2 Validation routines provided:

=over 4

=item url

The data looks like a (normalish) URL: C<$data =~ m!(http|ftp)://(\w/.-/+)!>

=begin testing
BEGIN: {
    use_ok("CGI::FormMagick::Validator");
}

isnt( url(undef, 'http://'), "OK" , "http:// is not a complete URL");
isnt( url(undef, 'ftp://'), "OK" , "ftp:// is not a complete URL");
isnt( url(undef, 'abc'), "OK" , "abc is not a valid URL");
isnt( url(), "OK" , "undef is not a valid URL");
isnt( url(undef, ''), "OK" , "empty string is not a valid URL");
is( url(undef, 'http://a.bc'), "OK" , "http://a.bc is a valid URL");
is( url(undef, 'ftp://a.bc:21/'), "OK" , "ftp://a.bc:21 is a valid URL");
isnt( url(undef, 'http:///a.bc'), "OK" , "http:///a.bc has too many slashes");
isnt( url(undef, 'http://a_a.bc'), "OK" , "Underscores are not allowed in URLs");

=end testing 

=cut

sub url {
    my ($fm, $data) = @_;
    if ($data && $data =~ m!(http|ftp)://[a-zA-Z0-9][a-zA-Z0-9/.-/]!) {
        return "OK";
    } else {
        return "This field must contain a URL starting with http:// or ftp://";
    }
}

=pod

=item email_simple

The data looks more or less like an internet email address:
C<$data =~ /.+\@.+\..+/> 

Note: not fully compliant with the entire gamut of RFC 822 addressing ;)

=for testing
is( email_simple(undef, 'a@b.c'), "OK" , 'a@b.c is a valid email address');
is( email_simple(undef, 'a+b@c.d'), "OK" , 'a+b@c.d is a valid email address');
is( email_simple(undef, 'a-b=c@d.e'), "OK" , 'a-b=c@d.e is a valid email address');
isnt( email_simple(undef, 'abc'), "OK" , 'abc is not a valid email address');
isnt( email_simple(undef, 'a@b'), "OK" , 'a@b is not a valid email address');
isnt( email_simple(undef, '@b.c'), "OK" , '@b.c is not a valid email address');
isnt( email_simple(), "OK" , 'undef is not a valid email address');
isnt( email_simple(undef, ""), "OK" , 'empty string is not a valid email address');

=cut

sub email_simple {
    my ($fm, $data) = @_;
    if (not defined $data ) {
        return "You must enter an email address.";
	} elsif (Mail::RFC822::Address::valid($data)) {
        return "OK";
    } else {
        return "This field doesn't look like an RFC822-compliant email address";
    }
}

=pod

=item domain_name

The data looks like an internet domain name or hostname.

=for testing
is( domain_name(undef, "abc.com"), "OK" , "abc.com is a valid domain name");
isnt( domain_name(undef, "abc"), "OK" , "abc is not a valid domain name");
isnt( domain_name(), "OK" , "undef is not a valid domain name");
isnt( domain_name(undef, ""), "OK" , "empty string is not a valid domain name");

=cut

sub domain_name {
    my ($fm, $data) = @_;
    if ($data && $data =~ /^([a-z\d\-]+\.)+[a-z]{1,3}\.?$/o ) {
        return "OK";
    } else {
        return "This field doesn't look like a valid Internet domain name or hostname.";
    }
}

=pod

=item ip_number

The data looks like a valid IP number.

=for testing
is(ip_number(undef, '1.2.3.4'), 'OK', "ip_number('1.2.3.4') should be valid.");
is(ip_number(undef, '0.0.0.0'), 'OK', "ip_number('0.0.0.0') should be valid.");
is(ip_number(undef, '255.255.255.255'), 'OK', "ip_number('255.255.255.255') should be valid.");
isnt(ip_number(undef, '1.2.3'), 'OK', "ip_number('1.2.3') shouldn't be valid.");
isnt(ip_number(undef, '1000.2.3.4'), 'OK', "ip_number('1000.2.3.4') shouldn't be valid.");
isnt(ip_number(undef, '256.2.3.4'), 'OK', "ip_number('256.2.3.4') shouldn't be valid.");
isnt(ip_number(undef, 'a.2.3.4'), 'OK', "ip_number('a.2.3.4') shouldn't be valid.");
isnt(ip_number(undef, '1,2,3,4'), 'OK', "ip_number('1,2,3,4') shouldn't be valid.");
isnt(ip_number(undef, '1.2.3'), 'OK', "ip_number('1.2.3') shouldn't be valid.");
isnt(ip_number(undef, ''), 'OK', "ip_number('') shouldn't be valid.");
isnt(ip_number(), 'OK', "ip_number(undef) shouldn't be valid.");

=cut

sub ip_number {
    my ($fm, $data) = @_;

    return undef unless defined $data;

    return 'Doesn\'t look like an IP' unless $data =~ /^[\d.]+$/;

    my @octets = split /\./, $data;

    return 'Not enough octets (expected X.X.X.X)' unless scalar @octets == 4;

    foreach my $octet (@octets) {
        return "$octet is more than 255" if $octet > 255;
    }

    return 'OK';
}

=pod

=item username

The data looks like a good, valid username

=for testing
is( username(undef, "abc"), "OK" , "abc is a valid username");
isnt( username(undef, "123"), "OK" , "123 is not a valid username");
isnt( username(), "OK" , "undef is not a valid username");
isnt( username(undef, ""), "OK" , "empty string is not a valid username");
isnt( username(undef, "  "), "OK" , "spaces is not a valid username");

=cut

sub username {
    my ($fm, $data) = @_;

    if ($data && $data =~ /[a-zA-Z]{3,8}/ ) {
        return "OK";
    } else {
        return "This field must look like a valid username (3 to 8 letters and numbers)";
    }
}

=pod

=item password

The data looks like a good password

=for testing
isnt( password(undef, "abc"), "OK" , "abc is not a good password");
isnt( password(), "OK" , "undef is not a good password");
isnt( password(undef, ""), "OK" , "empty string is not a good password");
is( password(undef, "ab1C23FouR!"), "OK" , "ab1C23FouR! is a good password");

=cut

sub password {
    my ($fm, $data) = @_;
    $_ = $data;
    if (not defined $_) {
        return "You must provide a password.";
    } elsif (/\d/ and /[A-Z]/ and /[a-z]/ and /\W/ and length($_) > 6) {
        return "OK";
    } else {
        return "The password you provided was not a good password.  A good password should have a mixture of upper and lower case letters, numbers, and non-alphanumeric characters.";
    }
}

=pod

=item mac_address

The data looks like a good MAC address

=for testing
isnt( mac_address(undef, "string"), "OK" , "string is not a good MAC address");
isnt( mac_address(), "OK" , "undef is not a good MAC address");
isnt( mac_address(undef, ""), "OK" , "empty string is not a good MAC address");
isnt( mac_address(undef, "01:23:45"), "OK" , "01:23:45 is too short for a MAC address");
isnt( mac_address(undef, "01:23:45:67:89:AB:CD"), "OK" , "01:23:45:67:89:AB:CD is too long for a MAC address");
is( mac_address(undef, "08:00:cf:2b:12:34"), "OK" , "08:00:cf:2b:12:34 is a good MAC address");
is( mac_address(undef, "08:00:CF:2B:12:34"), "OK" , "08:00:CF:2B:12:34 is a good MAC address");

=cut

sub mac_address {
    my ($fm, $data) = @_;
    $_ = lc $data;  # easier to match on $_
    if (not defined $_) {
        return "You must provide a MAC address.";
    } elsif (/^([0-9a-f][0-9a-f](:[0-9a-f][0-9a-f]){5})$/) {
        return "OK";
    } else {
        return "The MAC address you provided was not valid.";
    }
}

return "FALSE";
