#!/usr/bin/perl

# -------------------------------------------------------------------------------
# test harness for Data::Validate::URI::is_web_uri
#
# Author: Richard Sonnen (http://www.richardsonnen.com/)
# -------------------------------------------------------------------------------

use lib './t';
use ExtUtils::TBone;

use lib './blib';
use Data::Validate::URI qw(is_web_uri);

my $t = ExtUtils::TBone->typical();

$t->begin(26);
$t->msg("testing is_web_uri...");

# invalid
$t->ok(!defined(is_web_uri('')), "bad: ''");
$t->ok(!defined(is_web_uri('ftp://ftp.richardsonnen.com')), "bad: 'ftp://ftp.richardsonnen.com'");
$t->ok(!defined(is_web_uri('https:www.richardsonnen.com')), "bad: 'http:www.richardsonnen.com'");
$t->ok(!defined(is_web_uri('http:www.richardsonnen.com')), "bad: 'http:www.richardsonnen.com'");
$t->ok(!defined(is_web_uri('http://under_scored.richardsonnen.com/')), "bad: 'http://under_scored.richardsonnen.com/'");
$t->ok(!defined(is_web_uri('https://under_scored.richardsonnen.com/')), "bad: 'https://under_scored.richardsonnen.com/'");

# valid
$t->ok(defined(is_web_uri('https://www.richardsonnen.com/')), 'https://www.richardsonnen.com/');
$t->ok(defined(is_web_uri('https://www.richardsonnen.com')), 'https://www.richardsonnen.com');
$t->ok(defined(is_web_uri('https://www.richardsonnen.com/foo/bar/test.html')), 'https://www.richardsonnen.com/foo/bar/test.html');
$t->ok(defined(is_web_uri('https://www.richardsonnen.com/?foo=bar')), 'https://www.richardsonnen.com/?foo=bar');
$t->ok(defined(is_web_uri('https://www.richardsonnen.com:8080/test.html')), 'https://www.richardsonnen.com:8080/test.html');
$t->ok(defined(is_web_uri('http://www.richardsonnen.com/')), 'http://www.richardsonnen.com/');
$t->ok(defined(is_web_uri('http://www.richardsonnen.com')), 'http://www.richardsonnen.com');
$t->ok(defined(is_web_uri('http://www.richardsonnen.com/foo/bar/test.html')), 'http://www.richardsonnen.com/foo/bar/test.html');
$t->ok(defined(is_web_uri('http://www.richardsonnen.com/?foo=bar')), 'http://www.richardsonnen.com/?foo=bar');
$t->ok(defined(is_web_uri('http://www.richardsonnen.com:8080/test.html')), 'http://www.richardsonnen.com:8080/test.html');
$t->ok(defined(is_web_uri('http://example.w3.org/path%20with%20spaces.html')), 'http://example.w3.org/path%20with%20spaces.html');
$t->ok(defined(is_web_uri('http://192.168.0.1/')), 'http://192.168.0.1/');
$t->ok(defined(is_web_uri('http://under_scored.richardsonnen.com/', {domain_allow_underscore=>1})), 'http://under_scored.richardsonnen.com/');
$t->ok(defined(is_web_uri('https://under_scored.richardsonnen.com/', {domain_allow_underscore=>1})), 'https://under_scored.richardsonnen.com/');

# as an object
my $v = Data::Validate::URI->new();
$t->ok(defined($v->is_web_uri('http://www.richardsonnen.com/')), 'http://www.richardsonnen.com/ (object)');
$t->ok(!defined($v->is_web_uri('foo')), 'bad: foo (object)');
$t->ok(!defined($v->is_web_uri('http://under_scored.richardsonnen.com/')), "bad: 'http://under_scored.richardsonnen.com/' (object)");
$t->ok(!defined($v->is_web_uri('https://under_scored.richardsonnen.com/')), "bad: 'https://under_scored.richardsonnen.com/' (object)");
$v = Data::Validate::URI->new(domain_allow_underscore=>1);
$t->ok(defined($v->is_web_uri('http://under_scored.richardsonnen.com/')), 'http://under_scored.richardsonnen.com/ (object)');
$t->ok(defined($v->is_web_uri('https://under_scored.richardsonnen.com/')), 'https://under_scored.richardsonnen.com/ (object)');

# we're done
$t->end();

