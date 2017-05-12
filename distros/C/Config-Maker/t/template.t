#! /usr/bin/perl

use warnings;
use strict qw/subs refs/;
use utf8;

$::name = "template"; # It's here twice on purpose.
$::name = "template"; # It avoids the warning...

END { finalize(); }

use Test::More tests => 15;#FILLME

# TEST 1
do 't/setup.i'; # The setup. It runs one test, loading of Config::Maker.

# Prepare data...

sub expands_to {
    my ($name, $tmpl, $req, $testname) = @_;
    
    my $tmplfile = puttemp("$name.tmpl", $tmpl);
    my $reqfile = puttemp("$name.req", $req);
    my $outfile = tf("$name.out");
    my $metafile = puttemp(metacfg => <<"EOF");
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

    my $real = gettemp("$name.out");

    ok($real eq $req, "$name: $testname");
}

$schemafile = puttemp(schema => <<'EOF');
schema {
    type foo {
	toplevel;
	simple [ identifier ];
    }
    type foobar {
	toplevel;
	named_group [ identifier ];
	type any bar {
	    simple [ identifier ];
	}
    }
    type foobaz {
	toplevel;
	named_group [ identifier ];
	type any baz {
	    simple [ identifier ];
	}
    }
}
EOF

# TEST 2
isa_ok(Config::Maker::Config->new($schemafile), 'Config::Maker::Config');

$conffile = puttemp('config', <<'EOF');
foo one;
foobar two {
    bar aaa;
    bar aab;
    bar abb;
    bar bbb;
}

foobar three {
}

foobaz four {
    baz xxx;
}

foobaz five {
    baz yyy;
    baz zzz;
}

foo six;

foobar seven {
    bar b0;
}
EOF

############################################## REAL TESTS START HERE ##########

# TEST 3
expands_to('if0', <<'IN', <<'OUT', "If no path");
[$ map * $][$if none bar|baz $]
[+value+]
[/][/]
IN
one
three
six
OUT

# TEST 4
expands_to('if1', <<'IN', <<'OUT', "If expression");
[$if (1)$]
one
[/]
[$if (0)$]
zero
[/]
IN
one
OUT

# TEST 5
expands_to('map0', <<'IN', <<'OUT', "Map path-by-value");
[$ map */bar:a*b $]
[+type+]:[+value+]
[/]
IN
bar:aab
bar:abb
OUT

# TEST 6
expands_to('map1', <<'IN', <<'OUT', "Map path-by-value 2");
[$ map */:a?b $]
[+type+]:[+value+]
[/]
IN
bar:aab
bar:abb
OUT

# TEST 7
expands_to('map2', <<'IN', <<'OUT', "Map over perl list");
[$ map (1, 2, 3) $]
[{ $_; }]
[$ endmap $]
IN
1
2
3
OUT

# TEST 8
expands_to('map3', <<'IN', <<'OUT', "Map path-with-simple-condition");
[$ map foo(1) $]
[+value+]
[/]
IN
one
six
OUT

# TEST 9
expands_to('map4', <<'IN', <<'OUT', "Map path-with-condition");
[$ map foobar/*( /(.)\1\1/ ) $]
[+value+]
[/]
IN
aaa
bbb
OUT

# TEST 10
expands_to('map5', <<'IN', <<'OUT', "Map path-with-condition 2");
[$ map foobar( grep /(.)\1\1/, $_->get('bar') ) $]
[+value+]
[/]
IN
two
OUT

# TEST 11
expands_to('map6', <<'IN', <<'OUT', "Map path-with-character-group");
[$ map foobar/:a[ab][ab] $]
[+value+]
[/]
IN
aaa
aab
abb
OUT

# TEST 12
expands_to('map7', <<'IN', <<'OUT', "Map path-with-alternative");
[$ map foobaz/:{xxx|zzz} $]
[+value:..+]
[/]
IN
four
five
OUT

# TEST 13
expands_to('if2', <<'IN', <<'OUT', "If-elsif-else path");
[$ map *$][$if exists bar $]
[+value+] has bar
[$elsif exists baz $]
[+value+] has baz
[$else$]
[+value+] is dummy
[$endif$][$endmap$]
IN
one is dummy
two has bar
three is dummy
four has baz
five has baz
six is dummy
seven has bar
OUT

# TEST 14
expands_to('if3', <<'IN', <<'OUT', "If-elsif-else mixed");
[$ map *$][$if one bar$]
[+value+] has one bar
[$elsif (1)$]
ELSE
[/][/]
IN
ELSE
ELSE
ELSE
ELSE
ELSE
ELSE
seven has one bar
OUT

# TEST 15
$include = puttemp('incl1.tinc', <<EOF);
Type = [+type+], Value = [+value+]
EOF

expands_to('incl1', <<IN, <<OUT, "Include directive");
[\$ map */bar|baz \$]
[<$include>]
[/]
IN
Type = bar, Value = aaa
Type = bar, Value = aab
Type = bar, Value = abb
Type = bar, Value = bbb
Type = baz, Value = xxx
Type = baz, Value = yyy
Type = baz, Value = zzz
Type = bar, Value = b0
OUT

# arch-tag: d06f6f44-31c4-4ba3-8b26-0b32e3829c0a
# vim: set ft=perl:
