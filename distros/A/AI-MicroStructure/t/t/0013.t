#!/usr/bin/perl -w



use Data::Dumper;
use strict;
use Test::More 'no_plan';#tests =>12;


use strict;

my $list = << 'EOT';
* foo
* bar
  * baz
    * A
    * B
  * dus
  * Ja
* Foo
EOT
$list =~ s/\*/\x{2022}/g;

my $html = << 'EOT';
<p>
<ul>
<li>foo</li>
<li>bar</li>
<ul>
<li>baz</li>
<ul>
<li>A</li>
<li>B</li>
</ul>
<li>dus</li>
<li>Ja</li>
</ul>
<li>Foo</li>
</ul>

</p>
EOT

ok(sprintf($html));
__DATA__
