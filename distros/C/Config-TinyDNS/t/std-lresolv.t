#!/usr/bin/perl

use t::Utils qw/:ALL/;

@Filter = "lresolv";

filt <<DATA, <<WANT,             "lresolve leaves IPs alone";
+foo.com:1.2.3.4::lo
=bar.org:2.3.4.5
DATA
+foo.com:1.2.3.4::lo
=bar.org:2.3.4.5
WANT

my @Defns = (
    ["+foo.com:1.2.3.4",                "",         "+"             ],
    ["=foo.com:1.2.3.4",                "",         "="             ],
    [".foo.com:1.2.3.4:nsa.foo.com",    "nsa.",     "explicit ."    ],
    [".foo.com:1.2.3.4:a",              "a.ns.",    "implicit ."    ],
    ["&foo.com:1.2.3.4:nsa.foo.com",    "nsa.",     "explicit &"    ],
    ["&foo.com:1.2.3.4:a",              "a.ns.",    "implicit &"    ],
    ["\@foo.com:1.2.3.4:mxa.foo.com",   "mxa.",     "explicit @"    ],
    ["\@foo.com:1.2.3.4:a",             "a.mx.",    "implicit @"    ],
);

my %Locs = qw/ + 4 = 4 . 5 & 5 @ 6 /;

for my $defn (@Defns) {
    my ($line, $dom, $name) = @$defn;
    while (my ($use, $loc) = each %Locs) {
        filt <<DATA, <<WANT,        "$name line IP shows up in $use line";
$line
${use}bar.org:${dom}foo.com
DATA
$line
${use}bar.org:1.2.3.4
WANT

        my ($linec) = $line =~ /(.)/;
        my $lcolons = ":" x ($Locs{$linec} - ($line =~ tr/://));
        my $ucolons = ":" x ($loc - 1);

        filt <<DATA, <<WANT,        "$name -> $use with equal locs";
${line}${lcolons}lo
${use}bar.org:${dom}foo.com${ucolons}lo
DATA
${line}${lcolons}lo
${use}bar.org:1.2.3.4${ucolons}lo
WANT

        filt +(<<DATA) x 2,         "$name -> $use with unequal locs";
${line}${lcolons}lo
${use}bar.org:${dom}foo.com${ucolons}ex
DATA

        filt <<DATA, <<WANT,        "$name -> $use with loc";
${line}
${use}bar.org:${dom}foo.com${ucolons}lo
DATA
${line}
${use}bar.org:1.2.3.4${ucolons}lo
WANT

        filt +(<<DATA) x 2,         "$name with loc -> $use";
${line}${lcolons}lo
${use}bar.org:${dom}foo.com
DATA
    }
}

done_testing;
