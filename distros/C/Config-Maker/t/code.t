#! /usr/bin/perl

use warnings;
use strict qw/subs refs/;
use utf8;

$::name = "code"; # It's here twice on purpose.
$::name = "code"; # It avoids the warning...

END { finalize(); }

use Test::More tests => 11;#FILLME

# TEST 1
do 't/setup.i'; # The setup. It runs one test, loading of Config::Maker.

sub expand {
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

#    use Data::Dumper;
#    print STDERR Data::Dumper::Dumper ($real eq $req, "$name: $testname");
    return ($real eq $req, "$name: $testname");
}

$schemafile = puttemp(schema => <<'EOF');
schema {
    type foo {
	toplevel;
	simple [ identifier ];
    }
    type bar {
	toplevel;
	named_group [ identifier ];
	contains any foo;
	contains any bar;
    }
}
EOF

# TEST 2
isa_ok(Config::Maker::Config->new($schemafile), 'Config::Maker::Config');

$conffile = puttemp('config', <<'EOF');
foo one;
bar two {
    foo three;
}
bar four {
    foo five;
    bar six {
	foo seven;
    }
}
EOF

############################################## REAL TESTS START HERE ##########

# TEST 3
&ok(expand('config', <<'IN', <<'OUT', 'No strict, $config available'));
[{ $config->{root} eq $_; }]
IN
1
OUT

# TEST 4
&ok(expand('Get-1', <<'IN', <<'OUT', 'Get function'));
[{ Get('/foo'); }]
[{ Get('/foo:none') }]
[{ Get('/foo:none', 'not-there') }]
[{ join '+', Get('/**/foo') }]
IN
one

not-there
one+three+five+seven
OUT

# TEST 5
&ok(expand('Get1-1', <<'IN', <<'OUT', 'Get1 function in correct cases'));
[{ Get1('/foo'); }]
[{ Get1('/foo:none', 'not-there') }]
IN
one
not-there
OUT

# TEST 6
eval {
    expand('Get1-2', <<'IN', <<'OUT', '');
[{ Get1('/foo:none') }]
IN
OUT
};
like($@, qr{^/foo:none should}, "Get1-2: Get1 functions no match");

# TEST 7
eval {
    expand('Get1-3', <<'IN', <<'OUT', '');
[{ Get1('/**/foo') }]
IN
OUT
};
like($@, qr{^/\*\*/foo should}, "Get1-3: Get1 functions multiple matches");

# TEST 8
&ok(expand('ValueType', <<'IN', <<'OUT', "Value and Type access"));
[{ Value('/foo') }]
[{ Type('/:one') }]
[{ Value(Get1('/foo')) }]
[{ Type(Get1('/:one')) }]
IN
one
foo
one
foo
OUT

# TEST 9
&ok(expand('CondPath-1', <<'IN', <<'OUT', "Exists in path condition"));
[$ map **/bar(Exists "bar") $]
Bar with bar: [+value+]
[/]
IN
Bar with bar: four
OUT

# TEST 10
&ok(expand('CondPath-2', <<'IN', <<'OUT', "Unique and parens in path cond"));
[$ map **/bar(Unique("foo")) $]
Bar with unique foo: [+value+]
[/]
IN
Bar with unique foo: two
Bar with unique foo: four
Bar with unique foo: six
OUT

# TEST 11
&ok(expand('CondPath-3', <<'IN', <<'OUT', "One in path codition"));
[$ map **/bar(One("**/foo")) $]
Bar with one foo: [+value+]
[/]
IN
Bar with one foo: two
Bar with one foo: six
OUT

# arch-tag: b0435376-f5e3-4375-9756-4ff1d3025614
# vim: set ft=perl:
