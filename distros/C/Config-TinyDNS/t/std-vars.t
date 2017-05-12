#!/usr/bin/perl

use t::Utils qw/:ALL/;

@Filter = "vars";
$Want = $Data = <<DATA;
+foo.com:1.2.3.4::lo
=bar.org:2.3.4.5
# comment
DATA

filt "", "",                    "no vars does nothing";

$Data = <<'DATA' . $Data;
$foo:onetwothree
$colon:four:five
$!*&":six
DATA

filt "", "",                    "defns are removed from output";

filt    "+\$foo.com\n", 
        "+onetwothree.com\n",       
    "simple variable";
filt    "+\$foo.\$foo\n",
        "+onetwothree.onetwothree\n",
    "variable twice";
filt    "+\$colon\n",
        "+four\n",
    "colon terminates value";
filt    "+\$bar\n",
        "+\n",
    "non-existent variable blanked";
filt    "+\$!*&\"\n",
        "+\$!*&\"\n",
    "bad variable name ignored";
filt    "+foo\$:1.2.3.4\n",
        "+foo\$:1.2.3.4\n",
    "empty variable name ignored";

filt    "+\$\$colon\n",
        "+\$colon\n",
    "double-\$ escapes";

filt    <<'DATA',
$$:octopus
+$$colon
DATA
        "+\$colon\n",
    "\$\$ cannot be set";

filt    <<'DATA',
$bar:three$colon
+$bar
DATA
        "+threefour\n",
    "values expand variables";

filt    <<'DATA',
$$colon:five
+$four
DATA
        "+five\n",
    "stupid symref tricks";

filt    <<'DATA',
$dollar:$$
$$dollar:octopus
+$$colon
DATA
        "+\$colon\n",
    "symrefs can't set \$\$";

done_testing;
