#! /usr/bin/perl

use warnings;
use strict qw/subs refs/;
use utf8;

$::name = "config"; # It's here twice on purpose.
$::name = "config"; # It avoids the warning...

END { finalize(); }

use Test::More tests => 7;#FILLME

# TEST 1
do 't/setup.i'; # The setup. It runs one test, loading of Config::Maker.

# Prepare data...

sub proper_config {
    my ($name, $conf, $testname) = @_;

    my $conffile = puttemp("$name.conf", $conf);
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

$tmplfile = puttemp('template', <<'EOF');
Foos:
[$ map foo $]
- [+value+]
[/]
[$ map foobar $]
Foobar [+value+]'s bars:
[$ map bar $]
- [+value+]
[/]
[/]
[$ map foobaz $]
Foobaz [+value+]'s bazs:
[$ map baz $]
- [+value+]
[/]
[/]
EOF

our $reqfile;
$reqfile = puttemp('required', $req = <<'EOF');
Foos:
- a
- b
Foobar baz's bars:
- a
- b
Foobaz bar's bazs:
- a
- b
EOF

############################################## REAL TESTS START HERE ##########

# TEST 3

proper_config("plain", <<EOF, "Simple syntax");
foo a;
foobar baz {
    bar a;
    bar b;
}
foobaz bar {
    baz a;
    baz b;
}
foo b;
EOF

# TEST 4
proper_config("block1", <<EOF, "Extra curly brackets");
foo a;
{
    foobar baz {
	bar a;
	{
	    bar b;
	}
    }
}
{
    foobaz bar {
	baz a;
	baz b;
    }
    foo b;
}
EOF

# TEST 5
$include = puttemp('incl1.inc', <<EOF);
foobar baz {
    bar a;
    bar b;
}
foobaz bar {
    baz a;
    baz b;
}
EOF

proper_config("incl1", <<EOF, "Top-level include");
foo a;
foo b;
<$include>
EOF

# TEST 6
$include = puttemp('incl2.inc', <<EOF);
bar a;
bar b;
EOF

proper_config("incl2", <<EOF, "Inlude instead of a block");
foo a;
foobar baz <$include>
foo b;
foobaz bar { baz a; baz b; }
EOF

# TEST 7
$include = puttemp('all1.inc', <<EOF);
{
    bar a;
    bar b;
}
EOF

$include2 = puttemp('all1.inc2', <<EOF);
{
    foobaz bar {
	baz a;
	baz b;
    }
}
EOF

proper_config('all1', <<EOF, "All syntax together");
{
    {
	foo a;
    }
    foobar baz <$include>
}
<$include2>
foo b;
EOF

# arch-tag: 7b85bb14-bbab-48da-b1b0-2b966a3531f4
# vim: set ft=perl:
