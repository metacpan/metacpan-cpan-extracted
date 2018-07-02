#!/usr/bin/perl
use 5.008;
use strict;
use warnings;

use Test::Simple tests => 8;
use Data::Format::Validate::URL 'looks_like_full_url';

ok(looks_like_full_url 'ftp://www.duckduckgo.com');
ok(looks_like_full_url 'http://www.duckduckgo.com');
ok(looks_like_full_url 'https://www.duckduckgo.com');
ok(looks_like_full_url 'http://www.duckduckgo.com/search?q=perl');

ok(not looks_like_full_url 'duckduckgo.com');
ok(not looks_like_full_url 'www.duckduckgo.com');
ok(not looks_like_full_url 'ftp.duckduckgo.com');
ok(not looks_like_full_url 'http://duckduckgo.com');
