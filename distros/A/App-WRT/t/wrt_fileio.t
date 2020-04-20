#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';

use Test::More tests => 2;
use App::WRT::FileIO;

my $io = App::WRT::FileIO->new();

my @dir_list = $io->dir_list('example/blog', 'alpha', '^wrt[.]json$');
ok(
  $dir_list[0] eq 'wrt.json',
  'got wrt.json from dir_list'
) or diag(@dir_list);

my $get_contents = $io->file_get_contents('example/blog/wrt.json');
ok(
  $get_contents =~ m/entry_dir/,
  'got an expected string - entry_dir - in wrt.json'
) or diag($get_contents);
