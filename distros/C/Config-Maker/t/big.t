#! /usr/bin/perl

use warnings;
use strict qw/subs refs/;

$::name = "big";
$::name = "big";

END { finalize(); }

use Test::More tests => 2;#FILLME

# TEST 1
do 't/setup.i'; # The setup. It runs one test, loading of Config::Maker.

# TEST 2
# This is the big test. It tries to run it all and compares the results...
$conffile = puttemp(config => <<'EOF');
class bulb {
    net 192.168.1.0/24;
    port {
	from 212.71.168.94:3333;
	to 192.168.1.2:22;
    }
}

class hera {
    net 192.168.132.0/24;
    ip 192.168.255.237;
}

class dan {
    net 192.168.0.136/29;
    host martin {
	ip 192.168.0.195;
    }
    host dada {
	ip 192.168.0.200;
	public 212.71.168.91;
    }
    host scheibnb {
	ip 192.168.0.210;
    }
}

class jaros {
    host petr {
	ip 192.168.0.194;
    }
    host katy {
	ip 192.168.0.212;
    }
}
EOF

$tmplfile = puttemp(template => <<'EOF');
[# Komentar #]
[{ print "Cau.\n" }]
[$ map class $]
Trida: [+ value +]
[$ map net|ip $]
    Sit: [+ value +]
[/]
[$ map host $]
    Stanice: [+value+]
[$ map * $]
	[+type+] => [+value+]
[/]
[$ endmap $]
[$ map port $]
    Port: [+value:from+] -> [+value:to+]
[/]
[$ endmap $]
EOF

$outfile = tf('output');

$metafile = puttemp(metacfg => <<"EOF");
schema {
    type class {
	toplevel;
	named_group [ identifier ];
	contains any ip;
	type any host {
	    named_group [ dns_name ];
	    contains one ip;
	    type opt mac {
		simple [ ipv4 ];
	    }
	    type opt public {
		simple [ ipv4 ];
	    }
	}
	type any net {
	    simple [ ipv4_mask ];
	}
	type any port {
	    anon_group;
	    type one from {
		simple [ ipv4_port ];
	    }
	    type one to {
		simple [ ipv4_port ];
	    }
	}
    }

    type ip {
	simple [ ipv4 ];
    }
}

search-path '.';
output-dir '.';

config '$conffile' {
    template {
	src '$tmplfile';
	out '$outfile';
    }
}
EOF

Config::Maker::Metaconfig->do($metafile);

$real = gettemp('output');

puttemp(desired => $desired = <<"EOF");

Cau.
1
Trida: bulb
    Sit: 192.168.1.0/24
    Port: 212.71.168.94:3333 -> 192.168.1.2:22
Trida: hera
    Sit: 192.168.132.0/24
    Sit: 192.168.255.237
Trida: dan
    Sit: 192.168.0.136/29
    Stanice: martin
	ip => 192.168.0.195
    Stanice: dada
	ip => 192.168.0.200
	public => 212.71.168.91
    Stanice: scheibnb
	ip => 192.168.0.210
Trida: jaros
    Stanice: petr
	ip => 192.168.0.194
    Stanice: katy
	ip => 192.168.0.212
EOF

ok($real eq $desired, "Process big example");

# arch-tag: 2f394330-b095-4094-96c6-7d55e00ee2f1
# vim: set ft=perl:
