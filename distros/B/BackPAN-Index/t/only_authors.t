#!perl

use strict;
use warnings;

use lib 't/lib';
use TestUtils;

use Test::More tests => 1;

my $p = new_backpan();

my $files = $p->files->search({ path => { 'not like' => "%authors/%" } });
is_deeply [map { $_->path } $files->all], [], "only_authors only sees authors/";
