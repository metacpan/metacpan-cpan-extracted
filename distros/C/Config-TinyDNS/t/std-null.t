#!/usr/bin/perl

use t::Utils qw/:ALL/;

@Filter = "null";
$Data = $Want = <<DATA;
=foo.com:1.2.3.4:::lo
+bar.org:2.3.4.5:::ex
Zsome.soa:a.ns.some.soa:hostmaster.some.soa::8192::::ex
DATA


filt "", "",                        "null doesn't change ordinary records";
filt "\n\n", "",                    "null removes blank lines";
filt "+foo.com:1.2.3.4", "+foo.com:1.2.3.4\n",
                                    "null adds terminal newline";
filt "+foo.com:1.2.3.4::\n", "+foo.com:1.2.3.4\n",
                                    "null strips trailing commas";
filt "# some:comm:ent\n",           "null leaves comments";
filt "!some:unknown:record\n",      "null leaves unknown records";
filt "\u{0x150}foo:bar\n",          "null leaves UTF8 records";
filt "'foo.com:\u{100}xx\u{101}yy\n",   "null leaves UTF8 data alone";

done_testing;
