#!/usr/bin/perl
# $Id: 10-inline.t 284 2006-12-01 07:51:49Z chronos $

use Test::More tests => 61;
use strict;
use warnings;
use lib 't';

BEGIN { require "common.ph"; }

BEGIN { use_ok 'BBCode::Parser'; }

our $p = BBCode::Parser->new;

bbtest	q(Simple example),
		q(Simple example);

bbtest	q([TEXT="Internal "]example),
		q(Internal example),
		q(Internal example);

bbtest	q(Multi[BR]Line),
		qq(Multi<br/>Line);

bbtest	qq(Multi\nLine),
		qq(Multi<br/>\nLine);

bbtest	q([ENT=amp]),
		q(&amp;);

bbtest	q([B]Bold[/B] text),
		q(<b>Bold</b> text);

bbtest	q([I]Italic[/I] text),
		q(<i>Italic</i> text);

bbtest	q([U]Underlined[/U] text),
		q(<span class="bbcode-u">Underlined</span> text);

bbtest	q([S]Strike-through[/S] text),
		q(<span class="bbcode-s">Strike-through</span> text);

bbtest	q([Q]Quoted[/Q] text),
		q(<q>Quoted</q> text);

bbtest	q([TT]Teletype[/TT] text),
		q(<tt>Teletype</tt> text);

bbtest	q(S[SUP]uper[/SUP]script text),
		q(S<sup>uper</sup>script text);

bbtest	q(S[SUB]ub[/SUB]script text),
		q(S<sub>ub</sub>script text);

bbtest	q([FONT=Verdana]Named-font[/FONT] text),
		q(<span style="font-family: 'Verdana'">Named-font</span> text);

bbtest	q([FONT="Times New Roman"]Named-font[/FONT] text),
		q(<span style="font-family: 'Times New Roman'">Named-font</span> text);

bbtest	q([FONT, SIZE=10pt]Named-size[/FONT] text),
		q(<span style="font-size: 10pt">Named-size</span> text);

bbtest	q([SIZE=6pt]Tiny[/SIZE] text),
		q([FONT, SIZE=8pt]Tiny[/FONT] text),
		q(<span style="font-size: 8pt">Tiny</span> text);

bbtest	q([FONT, COLOR=blue]Named-color[/FONT] text),
		q(<span style="color: blue">Named-color</span> text);

bbtest	q([FONT, COLOR=#cf]Hex color[/FONT] text),
		q([FONT, COLOR=#cfcfcf]Hex color[/FONT] text),
		q(<span style="color: #cfcfcf">Hex color</span> text);

bbtest	q([FONT, COLOR="rgba(0%,0%,100%,75%)"]RGBA color[/FONT] text),
		q(<span style="color: rgba(0%,0%,100%,75%)">RGBA color</span> text);

bbtest	q([COLOR=red]COLOR auto-replace[/COLOR]),
		q([FONT, COLOR=red]COLOR auto-replace[/FONT]),
		q(<span style="color: red">COLOR auto-replace</span>);

bbtest	q([FONT=Verdana, SIZE=10pt, COLOR=blue]Multi-attribute FONT[/FONT]),
		q(<span style="font-family: 'Verdana'; font-size: 10pt; color: blue">Multi-attribute FONT</span>);

bbtest	q([URL=http://slashdot.org/]Linked[/URL] text),
		q(<a href="http://slashdot.org/" rel="nofollow">Linked</a> text);

bbtest	q(More [EMAIL=mailto:chronos@chronos-tachyon.net]linked[/EMAIL] text),
		q(More <a href="mailto:chronos@chronos-tachyon.net" rel="nofollow">linked</a> text);

bbtest	q(Image: [IMG=http://chronos-tachyon.net/images/me/20040419-closeup.jpg, ALT="[My Face]", W=818, H=958, TITLE="A picture of Chronos Tachyon"]),
		q(Image: <img src="http://chronos-tachyon.net/images/me/20040419-closeup.jpg" alt="[My Face]" width="818" height="958" title="A picture of Chronos Tachyon" />);

bbtest	q([URL=http://slashdot.org/, FOLLOW=1]Linked[/URL] text),
		q(<a href="http://slashdot.org/" rel="nofollow">Linked</a> text);

$p->set(follow_override => 1);

bbtest	q([URL=http://slashdot.org/, FOLLOW=1]Linked[/URL] text),
		q(<a href="http://slashdot.org/">Linked</a> text);

bbtest	q([URL=http://www.example.org/?test=foo]Linked[/URL] text),
		q([URL=http://www.example.org/?test\=foo]Linked[/URL] text),
		q(<a href="http://www.example.org/?test=foo" rel="nofollow">Linked</a> text);

$p->set(follow_links => 1);

bbtest	q([URL=slashdot.org]Linked[/URL] text),
		q([URL=http://slashdot.org/]Linked[/URL] text),
		q(<a href="http://slashdot.org/">Linked</a> text);

bbtest	q(More [EMAIL=chronos@chronos-tachyon.net]linked[/EMAIL] text),
		q(More [EMAIL=mailto:chronos@chronos-tachyon.net]linked[/EMAIL] text),
		q(More <a href="mailto:chronos@chronos-tachyon.net">linked</a> text);

# vim:set ft=perl:
