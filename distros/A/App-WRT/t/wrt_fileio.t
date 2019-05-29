#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use Test::More tests => 2;
use App::WRT::FileIO;

my $io = App::WRT::FileIO->new();

my @dir_list = $io->dir_list('example', 'alpha', '^wrt[.]json$');
diag(@dir_list);
ok(
  $dir_list[0] eq 'wrt.json',
  'got wrt.json from dir_list'
);

my $get_contents = $io->file_get_contents('example/wrt.json');
ok(
  $get_contents =~ m/entry_dir/,
  'got an expected string in wrt.json'
);
