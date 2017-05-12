#!/usr/bin/perl
use strict;
use warnings;

use Test::RequiresInternet 'www.imdb.com' => 80;
use Test::More tests => 2;
use App::IMDBtop;

App::IMDBtop::add_film 'tt0114814';

ok ((grep { $App::IMDBtop::cast_cache{$_} =~ /Kevin Spacey/i && $App::IMDBtop::cast_count{$_} > 0 } keys %App::IMDBtop::cast_count), 'Kevin Spacey starred in The Usual Suspects (using movie id)');

%App::IMDBtop::cast_count = %App::IMDBtop::cast_cache = ();

App::IMDBtop::add_film 'The Usual Suspects';

ok ((grep { $App::IMDBtop::cast_cache{$_} =~ /Kevin Spacey/i && $App::IMDBtop::cast_count{$_} > 0 } keys %App::IMDBtop::cast_count), 'Kevin Spacey starred in The Usual Suspects (using movie name)');
