#!/usr/bin/perl
# mamgal - a program for creating static image galleries
# Copyright 2007-2010 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
use strict;
use warnings;
use Carp 'verbose';
use Test::More tests => 4;
use Test::Files;
use Test::HTML::Content;
use lib 'testlib';
use App::MaMGal::TestHelper;

prepare_test_data;

dir_only_contains_ok('td/one_film', ['m.mov'],
						"index does not exist initially");
use_ok('App::MaMGal');
my $m = App::MaMGal->new;
ok($m->make_without_roots('td/one_film'),	"maker returns success on an dir with one film");
dir_only_contains_ok('td/one_film', [qw(index.html .mamgal-index.png .mamgal-thumbnails .mamgal-slides
					m.mov
					.mamgal-thumbnails/m.mov.png
					.mamgal-slides/m.mov.html)],
						"maker created index.html, .mamgal-thumbnails and .mamgal-slides");
