#!/usr/bin/perl
# $Id: 40-stress.t 284 2006-12-01 07:51:49Z chronos $

use Test::More tests => 27;
use strict;
use warnings;
use lib 't';

BEGIN { require "common.ph"; }

BEGIN { use_ok 'BBCode::Parser'; }

our $p = BBCode::Parser->new;

bbtest	q([TEXT="[FOO]"]),
		q([[FOO]]),
		q([FOO]);

bbtest	q([TEXT="[Foo, Bar"]),
		q([[Foo, Bar),
		q([Foo, Bar);

bbtest	q([TEXT="&foo"]),
		q([ENT=amp]foo),
		q(&amp;foo);

bbtest	q([TEXT="<Url:foo"]),
		q([ENT=lt]Url:foo),
		q(&lt;Url:foo);

bbfail q(Bogus argument[BR=10]);
bbfail q([B STYLE="display: none"]Bogus parameter[/B]);
bbfail q([SIZE=foo]Bogus size[/SIZE]);
bbfail q([COLOR=salmon]Bogus color[/COLOR]);
bbfail q([CODE LANG='<foo/>']Breakout attempt[/CODE]);
bbfail q([CODE][B]Bogus nesting[/B][/CODE]);
bbfail q([URL=javascript:void(0)]Javascript link[/URL]);
bbfail q([IMG=javascript:void(0)]Javascript image);
bbfail q([QUOTE CITE=javascript:void(0)]Javascript cite[/QUOTE]);
bbfail q([UL BULLET=javascript:void(0)][LI]Javascript list bullet[/LI][/UL]);

bbtest	q([FONT=Verdana\'\"><foo/>]Breakout attempt[/FONT]),
		q(<span style="font-family: 'Verdana&apos;&quot;&gt;&lt;foo/&gt;'">Breakout attempt</span>);

bbtest	q([LIST][*]One[*]Two),
		q([LIST][LI]One[/LI][LI]Two[/LI][/LIST]),
		qq(<ul>\n\t<li>One</li>\n\t<li>Two</li>\n</ul>);

bbtest	<<'END_A',
[FONT
	SIZE = 10\ pt
	COLOR = "r"'ed'
	FACE="Times \
New \
Roman\
"
]Text[/FONT]
END_A

<<'END_B',
[FONT="Times New Roman", SIZE=10pt, COLOR=red]Text[/FONT]
END_B

<<'END_C';
<span style="font-family: 'Times New Roman'; font-size: 10pt; color: red">Text</span>
END_C

$p->set(follow_override => 1);

bbtest	<<'END_A',
[ URL = http://slashdot.org/ FOLLOW = yes ]slashdot.org[ / URL ]
END_A

<<'END_B',
[URL=http://slashdot.org/, FOLLOW=1]slashdot.org[/URL]
END_B

<<'END_C';
<a href="http://slashdot.org/">slashdot.org</a>
END_C

# vim:set ft=perl:
