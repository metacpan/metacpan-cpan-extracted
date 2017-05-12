#! /usr/bin/perl

use warnings;
use strict qw/subs refs/;
use utf8;

$::name = "cache"; # It's here twice on purpose.
$::name = "cache"; # It avoids the warning...

END { finalize(); }

use Test::More tests => 10;#FILLME

# TEST 1
do 't/setup.i'; # The setup. It runs one test, loading of Config::Maker.

# Prepare data...

$force = 0;

sub expands_to {
    my ($name, $tmpl, $req, $testname) = @_;
    
    my $tmplfile = puttemp("$name.tmpl", $tmpl);
    my $reqfile = puttemp("$name.req", $req) if defined $req;
    my $outfile = tf("$name.out");
    my $metafile = puttemp(metacfg => <<"EOF");
search-path '.';
output-dir '.';
cache-dir '.';

config '$conffile' {
    template {
	src '$tmplfile';
	out '$outfile';
	cache '$cachefile';
    }
}

EOF
    Config::Maker::Metaconfig->do($metafile, 0, $force);

    if(defined $req) {
	my $real = gettemp("$name.out");
	ok($real eq $req, "$name: $testname");
    } else {
	ok(!-e $outfile, "$name: $testname");
    }
}

$schemafile = puttemp(schema => <<'EOF');
schema {
    type foo {
	toplevel;
	simple [ identifier ];
    }
}
EOF

# TEST 2
isa_ok(Config::Maker::Config->new($schemafile), 'Config::Maker::Config');

$conffile = puttemp('config', <<'EOF');
foo A;
EOF

$cachefile = tf('cache');

############################################## REAL TESTS START HERE ##########

# TEST 3
expands_to('first-run', <<'IN', <<'OUT', "No file exists yet");
42
IN
42
OUT

# TEST 4
expands_to('re-run1', <<'IN', undef, "The same should do nothing");
42
IN

# TEST 5
expands_to('change', <<'IN', <<'OUT', "Output must be generated after change");
6 x 9 = ?
IN
6 x 9 = ?
OUT

# TEST 6
expands_to('re-run2', <<'IN', undef, "The same should do nothing again");
6 x 9 = ?
IN

# TEST 7
expands_to('output1', <<'IN', <<'OUT', "Add output-only text");
The question: 6 x 9 = ?
[$ output only-out $]
The answer: 42
[$ endoutput $]
IN
The question: 6 x 9 = ?
The answer: 42
OUT

# TEST 8
expands_to('output2', <<'IN', undef, "Changes to output-only must not matter");
The question: 6 x 9 = ?
[$ output only-out $]
The answer: 69 # What?!
[$ endoutput $]
IN

# TEST 9
expands_to('output3', <<'IN', undef, "Cache and output can differ");
[$ output only-cache $]
The question: 6 x 9 = ?
[$ endoutput $]
[$ output no-cache $]
The question: 6 x 7 = ? # What?!
The answer: 42
[$ endoutput $]
IN

# TEST 10
$force = 1;
expands_to('force', <<'IN', <<'OUT', "When forced, it is output");
[$ output only-cache $]
The question: 6 x 9 = ?
[$ endoutput $]
[$ output no-cache $]
The question: 6 x 7 = ? # What?!
The answer: 42
[$ endoutput $]
IN
The question: 6 x 7 = ? # What?!
The answer: 42
OUT

# arch-tag: 283c6d9d-011c-47a8-a5e5-ff9ef9bd993f
# vim: set ft=perl:
