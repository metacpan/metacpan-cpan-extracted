#!/usr/bin/perl
use 5.008;
use strict;
use warnings;

use Test::Simple tests => 11;
use Data::Format::Validate::URL 'looks_like_any_url';

ok(looks_like_any_url 'duckduckgo.com');
ok(looks_like_any_url 'www.duckduckgo.com');
ok(looks_like_any_url 'ftp.duckduckgo.com');
ok(looks_like_any_url 'http://duckduckgo.com');
ok(looks_like_any_url 'ftp://www.duckduckgo.com');
ok(looks_like_any_url 'https://www.duckduckgo.com');
ok(looks_like_any_url 'https://www.youtube.com/watch?v=tqgBN44orKs');

ok(not looks_like_any_url '.com');
ok(not looks_like_any_url 'www. duckduckgo');
ok(not looks_like_any_url 'this is not an url');
ok(not looks_like_any_url 'perl.com is the best website');
