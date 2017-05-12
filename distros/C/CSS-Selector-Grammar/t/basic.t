use strict;
use warnings;
use CSS::Selector::Grammar;
use Test::More;

my @good = lines(<<'END');
*
E
E[foo]
E[foo="bar"]
E[foo~="bar"]
E[foo^="bar"]
E[foo$="bar"]
E[foo*="bar"]
E[foo|="en"]
E:root
E:nth-child(n)
E:nth-last-child(n)
E:nth-of-type(n)
E:nth-last-of-type(n)
E:first-child
E:last-child
E:first-of-type
E:last-of-type
E:only-child
E:only-of-type
E:empty
E:link
E:visited
E:active
E:hover
E:focus
E:target
E:l
E:enabled
E:disabled
E:checked
E::first-line
E::first-letter
E::before
E::after
E.warning
E#myid
E:not(s)
E F
E > F
E + F
E ~ F
h1, h2, h3
span[hello="Cleveland"][goodbye="Columbus"]
DIALOGUE[character=romeo]
[foo|att=val]
[*|att]
[|att]
[att]
p.pastoral.marine
#chapter1
*#z98y
a.external:visited
a:focus:hover
*:target
*:target::before
html:lang(fr-be)
html:lang(de)
:lang(fr-be) > q
:lang(de) > q
p:nth-child(4n+1)
:nth-child(10n-1)
:nth-child( 3n + 1 )
:nth-child(3 n)
html|tr:nth-child(-n+6)
foo:nth-last-child(odd)
body > h2:not(:first-of-type):not(:last-of-type)
html|*:not(:link):not(:visited)
*|*:not(:hover)
END

my @bad = lines(<<'END');
1div
$div
E[]
E ++ F
E:::enabled
h1, h2..foo, h3
END

plan tests => @good + @bad;

ok( defined( parse_selector($_) ),  "could parse $_" )     for @good;
ok( !defined( parse_selector($_) ), "could not parse $_" ) for @bad;

done_testing();

sub lines {
    my @lines = shift =~ /^(\s*\S(?<!#).*)$/mg;
    return @lines;
}
