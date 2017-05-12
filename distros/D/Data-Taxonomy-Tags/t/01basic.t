#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 4;
use Data::Taxonomy::Tags;

my $tagset = Data::Taxonomy::Tags->new('foo bar baz bat');
isa_ok($tagset, 'Data::Taxonomy::Tags');

is("$tagset", "foo bar baz bat");

my $t;

$t = Data::Taxonomy::Tags->new('foo meta:bar baz system:bat');
is("$t", "foo meta:bar baz system:bat");

$t = Data::Taxonomy::Tags->new('foo|meta bar|baz|system bat',{separator=>'|',category=>' '});
is("$t", "foo|meta bar|baz|system bat");

