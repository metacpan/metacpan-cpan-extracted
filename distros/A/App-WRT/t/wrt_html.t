#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib';

use Test::More tests => 2;
use App::WRT::HTML qw(:all);

my $a_tag = a('hi', {href => 'https://example.com/', title => 'example'});
# diag($a_tag);

is(
  $a_tag,
  '<a href="https://example.com/" title="example">hi</a>',
  'got a tag with attributes'
);

my $small_tag = small('text', {title => '<thing with angle brackets>'});
# diag($small_tag);

is(
  $small_tag,
  '<small title="&lt;thing with angle brackets&gt;">text</small>',
  'got a tag with escaped attributes'
);
