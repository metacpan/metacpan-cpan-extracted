#!/usr/bin/perl

use t::Utils qw/:ALL/;

@Filter = [site => qw/foo bar/];

filt +(<<DATA) x 2,             "site leaves non-% lines alone";
+foo.com:1.2.3.4:::lo
=bar.org:2.3.4.5
DATA

filt <<DATA, "",                "site removes unused % lines";
%qu:1.2.3:quux
DATA

filt <<DATA, <<WANT,            "site edits wanted % lines";
%fo:1.2.3:foo
%ba:4.5:bar
DATA
%fo:1.2.3
%ba:4.5
WANT

done_testing;
