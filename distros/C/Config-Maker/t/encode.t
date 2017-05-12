#! /usr/bin/perl

use warnings;
use strict qw/subs refs/;
use utf8;

$::name = "encode"; # It's here twice on purpose.
$::name = "encode"; # It avoids the warning...

END { finalize(); }

use Test::More tests => 1 + ($skips = 3);#FILLME

# TEST 1
do 't/setup.i'; # The setup. It runs one test, loading of Config::Maker.

SKIP: {
    skip "PerlIO::encoding is not usable here", $skips unless $::ENCODING;
    skip "PerlIO::encoding is not usable here", $skips unless $::ENCODING;

    # TEST skips 1
    use_ok('Encode');

    skip "utf-8 encoding not supported here", $skips - 1
	unless Encode::find_encoding('utf-8');
    skip "iso-8859-2 encoding not supported here", $skips - 1
	unless Encode::find_encoding('iso-8859-2');

    Config::Maker::Encode->import();

    # TEST skips 2
    ok(1, "Imported Encode stuff");

    # TEST skips 3
    $conffile = puttemp(config => encode('utf-8', <<'EOF'));
# encoding: utf-8
bž ovec {
    fň bééé;
}
EOF
    $tmplfile = puttemp(template => encode('iso-8859-2', <<'EOF'));
[# encoding: iso-8859-2 #]
[$ map bž $]
[+value+] dělá [+value:fň+]
[/]
EOF
    $outfile = tf('output');
    $metafile = puttemp(metacfg => encode('iso-8859-2', <<"EOF"));
# encoding: iso-8859-2

schema {
    type bž {
	toplevel;
	named_group [ identifier ];
	contains one fň;
    }
    type fň {
	simple [ identifier ];
    }
}

search-path '.';
output-dir '.';

config '$conffile' {
    template {
	src '$tmplfile';
	out '$outfile';
	enc 'utf-8';
    }
}
EOF
    Config::Maker::Metaconfig->do($metafile);

    $real = gettemp('output');

    puttemp(desired => ($desired = encode('utf-8', <<"EOF")));

ovec dělá bééé
EOF

    ok($real eq $desired, "Recoding iso-8859-2, utf-8");

} # SKIP

# arch-tag: e43c460b-955c-43cd-8c2e-5e08c707cd03
# vim: set ft=perl:
