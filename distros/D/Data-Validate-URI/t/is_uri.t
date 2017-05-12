#!/usr/bin/perl

# -------------------------------------------------------------------------------
# test harness for Data::Validate::URI::is_uri
#
# Author: Richard Sonnen (http://www.richardsonnen.com/)
# -------------------------------------------------------------------------------

use lib './t';
use ExtUtils::TBone;

use lib './blib';
use Data::Validate::URI qw(is_uri);

my $t = ExtUtils::TBone->typical();

$t->begin(25);
$t->msg("testing is_uri...");

# valid -  from RFC 3986 for the most part
$t->ok(defined(is_uri('http://localhost/')), 'http://localhost/');
$t->ok(defined(is_uri('http://example.w3.org/path%20with%20spaces.html')), 'http://example.w3.org/path%20with%20spaces.html');
$t->ok(defined(is_uri('http://example.w3.org/%20')), 'http://example.w3.org/%20');
$t->ok(defined(is_uri('ftp://ftp.is.co.za/rfc/rfc1808.txt')), 'ftp://ftp.is.co.za/rfc/rfc1808.txt');
$t->ok(defined(is_uri('ftp://ftp.is.co.za/../../../rfc/rfc1808.txt')), 'ftp://ftp.is.co.za/../../../rfc/rfc1808.txt');
$t->ok(defined(is_uri('http://www.ietf.org/rfc/rfc2396.txt')), 'http://www.ietf.org/rfc/rfc2396.txt');
$t->ok(defined(is_uri('ldap://[2001:db8::7]/c=GB?objectClass?one')), 'ldap://[2001:db8::7]/c=GB?objectClass?one');
$t->ok(defined(is_uri('mailto:John.Doe@example.com')), 'mailto:John.Doe@example.com');
$t->ok(defined(is_uri('news:comp.infosystems.www.servers.unix')), 'news:comp.infosystems.www.servers.unix');
$t->ok(defined(is_uri('tel:+1-816-555-1212')), 'tel:+1-816-555-1212');
$t->ok(defined(is_uri('telnet://192.0.2.16:80/')), 'telnet://192.0.2.16:80/');
$t->ok(defined(is_uri('urn:oasis:names:specification:docbook:dtd:xml:4.1.2')), 'urn:oasis:names:specification:docbook:dtd:xml:4.1.2');


# invalid
$t->ok(!defined(is_uri('')), "bad: ''");
$t->ok(!defined(is_uri('foo')), 'bad: foo');
$t->ok(!defined(is_uri('foo@bar')), 'bad: foo@bar');
$t->ok(!defined(is_uri('http://<foo>')), 'bad: http://<foo>'); # illegal characters
$t->ok(!defined(is_uri('://bob/')), 'bad: ://bob/'); # empty schema
$t->ok(!defined(is_uri('1http://bob')), 'bad: 1http://bob/'); # bad schema
$t->ok(!defined(is_uri('1http:////foo.html')), 'bad: 1http://bob/'); # bad path
$t->ok(!defined(is_uri('http://example.w3.org/%illegal.html')), 'http://example.w3.org/%illegal.html');
$t->ok(!defined(is_uri('http://example.w3.org/%a')), 'http://example.w3.org/%a'); # partial escape
$t->ok(!defined(is_uri('http://example.w3.org/%a/foo')), 'http://example.w3.org/%a/foo'); # partial escape
$t->ok(!defined(is_uri('http://example.w3.org/%at')), 'http://example.w3.org/%at'); # partial escape


# as an object
my $v = Data::Validate::URI->new();
$t->ok(defined($v->is_uri('http://www.richardsonnen.com/')), 'http://www.richardsonnen.com/ (object)');
$t->ok(!defined($v->is_uri('foo')), 'bad: foo (object)');

# we're done
$t->end();

