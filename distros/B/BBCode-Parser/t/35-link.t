#!/usr/bin/perl
# $Id: 30-raw.t 56 2005-05-09 18:53:00Z chronos $

use Test::More tests => 2;
use strict;
use warnings;
use lib 't';

BEGIN { require "common.ph"; }

BEGIN { use_ok 'BBCode::Parser'; }

our $p = BBCode::Parser->new(follow_override => 1);

my $t = $p->parse(<<'END_A');
[url=http://a.com/]A.com[/url]
[img=http://b.com/, alt=B.com]
[list=i]
[li][url=c.com, follow=1]C.com[/url][/li]
[li][img=d.com, alt=D.com][/li]
[li][url="data:text/plain,Hello%20World"]Inline[/url][/li]
[/list]
[quote="Gaius Julius Caesar", cite=http://e.com/]
Veni, Vidi, Vici.
[/quote]
[url]F.com[/url]
END_A

my $result = "";
foreach($t->toLinkList()) {
	my @x = @$_;
	$result .= '['.join('|', map { defined $_ ? $_ : '' } @x)."]\n";
}

is($result, <<'EOF',
[0|URL|http://a.com/|A.com]
[1|IMG|http://b.com/|B.com]
[1|URL|http://c.com/|C.com]
[1|IMG|http://d.com/|D.com]
[0|URL|data:text/plain,Hello%20World|Inline]
[0|QUOTE|http://e.com/|Gaius Julius Caesar]
[0|URL|http://f.com/|F.com]
EOF
"toLinkList test");

# vim:set ft=perl:
