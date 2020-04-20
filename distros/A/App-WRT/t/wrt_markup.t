#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib';

use Test::More tests => 2;
use App::WRT;

chdir 'example/blog';

ok (my $w = App::WRT::new_from_file('wrt.json'), "Got WRT object.");

my $testlines = <<'LINES';
<textile>h1. Hello

Some stuff.
</textile>

<markdown>
La la la!
</markdown>
<freeverse>
Dogs
frolic in

moonlight.
</freeverse>

<list>
one

two
</list>

<include>files/include_me</include>
<include>files/include_me</include>
LINES

my $expectedlines = <<'LINES';
<h1>Hello</h1>

<p>Some stuff.</p>

<p>La la la!</p>

<p>Dogs<br />
frolic in</p>

<p>moonlight.</p>

<ul>
<li>one</li>

<li>two</li>
</ul>

<p>This content included from elsewhere.</p>

<p>This content included from elsewhere.</p>

LINES

my $result = $w->line_parse($testlines, undef);

ok(
  $result eq $expectedlines,
  'line_parse works'
);

if ($result ne $expectedlines) {
  diag($result);
}

1;
