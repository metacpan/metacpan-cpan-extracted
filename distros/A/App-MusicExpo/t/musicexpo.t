#!/usr/bin/perl -w
use v5.14;
use warnings;

use Test::More tests => 2;

use Storable qw/thaw/;

BEGIN { use_ok('App::MusicExpo'); }

close STDOUT;
my $out;
open STDOUT, '>', \$out;

App::MusicExpo->run;

is $out, <<'OUT', 'output is correct';
<!DOCTYPE html>
<title>Music</title>
<meta charset="utf-8">
<link rel="stylesheet" href="musicexpo.css">
<script async defer type="application/javascript" src="player.js"></script>

<div id="player"></div>

<table border>
<thead>
<tr><th>Title<th>Artist<th>Album<th>Genre<th>Track<th>Year<th>Type
<tbody>
</table>
OUT
