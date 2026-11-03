#!perl

use 5.006;
use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs { 'Test::Spelling::Comment' => '0.002' };

Test::Spelling::Comment->import();
Test::Spelling::Comment->new()->add_stopwords(<DATA>)->all_files_ok();

__DATA__
TODO
aa
bb
Brotli
CHI
compat
ETag
ETags
Etag
eTag
etag
htm
html
img
lingua
lru
memGzip
preformatted
Satisfiable
src
UNzipped
unterminated
validator
