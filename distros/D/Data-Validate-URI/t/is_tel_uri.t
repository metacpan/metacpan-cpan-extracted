#!/usr/bin/perl

# -------------------------------------------------------------------------------
# test harness for Data::Validate::URI::is_tel_uri
#
# Author: David Dick
# -------------------------------------------------------------------------------

use lib './t';
use ExtUtils::TBone;

use lib './blib';
use Data::Validate::URI qw(is_tel_uri);

my $t = ExtUtils::TBone->typical();

$t->begin(23);
$t->msg("testing is_tel_uri...");

# valid examples taken from http://tools.ietf.org/html/rfc3966#section-6
$t->ok(defined(is_tel_uri('tel:+1-201-555-0123')), 'tel:+1-201-555-0123');
$t->ok(defined(is_tel_uri('tel:7042;phone-context=example.com')), 'tel:7042;phone-context=example.com');
$t->ok(defined(is_tel_uri('tel:863-1234;phone-context=+1-914-555')), 'tel:863-1234;phone-context=+1-914-555');

# valid examples taken from http://tools.ietf.org/html/rfc4715#section-5 
$t->ok(defined(is_tel_uri('tel:+17005554141;isub=12345;isub-encoding=nsap-ia5')), 'tel:+17005554141;isub=12345;isub-encoding=nsap-ia5');

# valid examples taken from http://tools.ietf.org/html/rfc4759#section-5
$t->ok(defined(is_tel_uri('tel:+441632960038;enumdi')), 'tel:+441632960038;enumdi');

# valid examples taken from http://tools.ietf.org/html/rfc4694#section-6
$t->ok(defined(is_tel_uri('tel:+1-800-123-4567;cic=+1-6789')), 'tel:+1-800-123-4567;cic=+1-6789');
$t->ok(defined(is_tel_uri('tel:+1-202-533-1234')), 'tel:+1-202-533-1234');
$t->ok(defined(is_tel_uri('tel:+1-202-533-1234;npdi;rn=+1-202-544-0000')), 'tel:+1-202-533-1234;npdi;rn=+1-202-544-0000');
$t->ok(defined(is_tel_uri('tel:+1-202-533-6789;npdi')), 'tel:+1-202-533-6789;npdi');

# valid examples taken from http://tools.ietf.org/html/rfc4904#section-5
$t->ok(defined(is_tel_uri('tel:5550100;phone-context=+1-630;tgrp=TG-1;trunk-context=example.com')), 'tel:5550100;phone-context=+1-630;tgrp=TG-1;trunk-context=example.com');
$t->ok(defined(is_tel_uri('tel:+16305550100;tgrp=TG-1;trunk-context=example.com')), 'tel:+16305550100;tgrp=TG-1;trunk-context=example.com');
$t->ok(defined(is_tel_uri('tel:+16305550100;tgrp=TG-1;trunk-context=+1-630')), 'tel:+16305550100;tgrp=TG-1;trunk-context=+1-630');

# valid examples taken from http://tools.ietf.org/html/rfc2806#section-2.6
$t->ok(defined(is_tel_uri('tel:+358-555-1234567')), 'tel:+358-555-1234567');

# invalid
$t->ok(!defined(is_tel_uri('')), "bad: ''");
$t->ok(!defined(is_tel_uri('ftp://ftp.richardsonnen.com')), "bad: 'ftp://ftp.richardsonnen.com'");
$t->ok(!defined(is_tel_uri('http://www.richardsonnen.com')), "bad: 'http://www.richardsonnen.com'");
$t->ok(!defined(is_tel_uri('tels:863-1234;phone-context=+1-914-555')), 'tels:863-1234;phone-context=+1-914-555');
$t->ok(!defined(is_tel_uri('tel:+441632960038;enumdi;enumdi')), 'tel:+441632960038;enumdi;enumdi');
$t->ok(!defined(is_tel_uri('tel:+441632960038;rn=+1-202-544-0000;rn=+1-202-544-0000')), 'tel:+441632960038;rn=+1-202-544-0000;rn=+1-202-544-0000');
$t->ok(!defined(is_tel_uri('tel:+441632960038;npdi;npdi')), 'tel:+441632960038;npdi;npdi');
$t->ok(!defined(is_tel_uri('tel:+1-800-123-4567;cic=+1-6789;cic=+1-6789')), 'tel:+1-800-123-4567;cic=+1-6789;cic=+1-6789');

# as an object
my $v = Data::Validate::URI->new();
$t->ok(defined($v->is_tel_uri('tel:+1-201-555-0111')), 'tel:+1-201-555-0111 (object)');
$t->ok(!defined($v->is_tel_uri('foo')), 'bad: foo (object)');

# we're done
$t->end();

