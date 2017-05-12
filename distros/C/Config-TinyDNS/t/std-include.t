#!/usr/bin/perl

use t::Utils qw/:ALL/;

chdir "t";

@Filter = "include";
$Data = $Want = <<DATA;
+foo.org:2.3.4.5
DATA

filt "", "", "include with no includes does nothing";

filt    "Ione\n",
        "+bar.com:1.2.3.4\n",
    "include reads in a file";

filt    "Itwo\n",
        "+bar.com:1.2.3.4\n",
    "include recurses";

@Filter = qw/include vars/;

filt    "\$foo:octopus\nIvar\n",
        "+octopus\n",
    "include with vars";

done_testing;
