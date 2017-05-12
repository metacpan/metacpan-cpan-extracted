#!/usr/bin/perl
# $Id: 20-block.t 284 2006-12-01 07:51:49Z chronos $

use Test::More tests => 19;
use strict;
use warnings;
use lib 't';

BEGIN { require "common.ph"; }

BEGIN { use_ok 'BBCode::Parser'; }

our $p = BBCode::Parser->new(follow_links => 1);

# 1:1 mappings
bbtest	qq([HR]),
		qq(<hr/>);

bbtest	<<'END_A',
[QUOTE]
Foo
Bar
[/QUOTE]
END_A

<<'END_C';
<div class="bbcode-quote">
<div class="bbcode-quote-head">Quote:</div>
<blockquote class="bbcode-quote-body">
<div>
Foo<br/>
Bar
</div>
</blockquote>
</div>
END_C

bbtest <<'END_A',
[CODE, LANG=sh]
#!/bin/sh
exit 0
[/CODE]
END_A

<<'END_C';
<div class="bbcode-code">
<div class="bbcode-code-head">Sh Code:</div>
<pre class="bbcode-code-body">
#!/bin/sh
exit 0
</pre>
</div>
END_C

bbtest <<'END_A',
[LIST]
[LI]One[/LI]
	[LI]Two[/LI]
[/LIST]
END_A

<<'END_C';
<ul>
	<li>One</li>
	<li>Two</li>
</ul>
END_C

bbtest <<'END_A',
[LIST]
[LI][LIST]
[LI]One A[/LI]
[LI]One B[/LI]
[/LIST][/LI]
[LI][LIST]
[LI]Two A[/LI]
[LI]Two B[/LI]
[/LIST][/LI]
[/LIST]
END_A

<<'END_C';
<ul>
	<li>
		<ul>
			<li>One A</li>
			<li>One B</li>
		</ul>
	</li>
	<li>
		<ul>
			<li>Two A</li>
			<li>Two B</li>
		</ul>
	</li>
</ul>
END_C

bbtest <<'END_A',
[OL]
	[LI]One[/LI]
	[LI]Two[/LI]
[/OL]
END_A

<<'END_C';
<ol>
	<li>One</li>
	<li>Two</li>
</ol>
END_C

bbtest <<'END_A',
[UL]
	[LI]One[/LI]
	[LI]Two[/LI]
[/UL]
END_A

<<'END_C';
<ul>
	<li>One</li>
	<li>Two</li>
</ul>
END_C

# Block canonizations
bbtest	q([LIST][LI]One[/LI][LI]Two[/LI][/LIST]),
		q([LIST][LI]One[/LI][LI]Two[/LI][/LIST]),
		<<'END_C';
<ul>
	<li>One</li>
	<li>Two</li>
</ul>
END_C

# Attribute canonizations
bbtest <<'END_A',
[quote cite="http://www.chronos-tachyon.net/","Chronos"]
Foo!
[/quote]
END_A

<<'END_B',
[QUOTE=Chronos, CITE=http://www.chronos-tachyon.net/]
Foo!
[/QUOTE]
END_B

<<'END_C';
<div class="bbcode-quote">
<div class="bbcode-quote-head"><a href="http://www.chronos-tachyon.net/">Chronos wrote</a>:</div>
<blockquote class="bbcode-quote-body" cite="http://www.chronos-tachyon.net/">
<div>
Foo!
</div>
</blockquote>
</div>
END_C

# vim:set ft=perl:
