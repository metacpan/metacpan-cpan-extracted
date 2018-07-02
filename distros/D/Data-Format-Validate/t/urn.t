#!/usr/bin/perl
use 5.008;
use strict;
use warnings;

use Test::Simple tests => 13;
use Data::Format::Validate::URN 'looks_like_urn';

ok(looks_like_urn 'urn:oid:2.16.840');
ok(looks_like_urn 'urn:ietf:rfc:2648');
ok(looks_like_urn 'urn:issn:0167-6423');
ok(looks_like_urn 'urn:isbn:0451450523');
ok(looks_like_urn 'urn:mpeg:mpeg7:schema:2001');
ok(looks_like_urn 'urn:uci:I001+SBSi-B10000083052');
ok(looks_like_urn 'urn:lex:br:federal:lei:2008-06-19;11705');
ok(looks_like_urn 'urn:isan:0000-0000-9E59-0000-O-0000-0000-2');
ok(looks_like_urn 'urn:uuid:6e8bc430-9c3a-11d9-9669-0800200c9a66');

ok(not looks_like_urn 'oid:2.16.840');
ok(not looks_like_urn 'This is not a valid URN');
ok(not looks_like_urn 'urn:-768hgf-0000-0000-0000');
ok(not looks_like_urn 'urn:this-is-a-realy-big-URN-maybe-the-bigest');
