#!/usr/bin/perl -w
use v5.14;
use warnings;

use Test::More tests => 3;

use File::Temp qw/tempfile/;

my $file;

BEGIN {
  $file = (tempfile UNLINK => 1)[1];
  @ARGV = (-cache => $file, sort <empty*>);
}
BEGIN { use_ok('App::MusicExpo'); }

close STDOUT;
my $out;
open STDOUT, '>', \$out;

my %handled = map { $_ => 1 } App::MusicExpo::extensions_handled;

my $prefix = '<tr><td class="title"><a href="#silence-cellule" data-hash="#silence-cellule">Cellule</a><td class="artist">Silence<td class="album">L&#39;autre endroit<td class="genre">Electro<td class="track">01/09<td class="year">2005<td class="formats">';

my @lines;
if ($handled{'.flac'} && $handled{'.ogg'}) {
	push @lines, $prefix . '<a href="/music/empty.flac">FLAC</a> <a href="/music/empty.ogg">Vorbis</a> '
} elsif ($handled{'.flac'}) {
	push @lines, $prefix . '<a href="/music/empty.flac">FLAC</a> '
} elsif ($handled{'.ogg'}) {
	push @lines, $prefix . '<a href="/music/empty.ogg">Vorbis</a> '
}

push @lines, $prefix . '<a href="/music/empty2.opus">Opus</a> ' if $handled{'.opus'};
push @lines, $prefix . '<a href="/music/empty3.mp3">MP3</a> ' if $handled{'.mp3'};
push @lines, '<tr><td class="title"><a href="#silence-cellule" data-hash="#silence-cellule">Cellule</a><td class="artist">Silence<td class="album">L&#39;autre endroit<td class="genre">Electro<td class="track">1/9<td class="year">2005<td class="formats"><a href="/music/empty4.aac">AAC</a> ' if $handled{'.aac'};

my $contents = join '', map { "\n$_" } @lines;

App::MusicExpo->run;

is $out, <<"OUT", 'output is correct';
<!DOCTYPE html>
<title>Music</title>
<meta charset="utf-8">
<link rel="stylesheet" href="musicexpo.css">
<script async defer type="application/javascript" src="player.js"></script>

<div id="player"></div>

<table border>
<thead>
<tr><th>Title<th>Artist<th>Album<th>Genre<th>Track<th>Year<th>Type
<tbody>$contents
</table>
OUT

ok -e $file, 'cache exists';
