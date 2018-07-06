#!./perl

print "1..20\n";

$x = 'x';

print "#1	:$x: eq :x:\n";
if ($x eq 'x') {print "ok 1\n";} else {print "not ok 1\n";}

$x = $#[0];

if ($x eq '') {print "ok 2\n";} else {print "not ok 2\n";}

$x = $#x;

if ($x eq '-1') {print "ok 3\n";} else {print "not ok 3\n";}

$x = '\\'; # ';

if (length($x) == 1) {print "ok 4\n";} else {print "not ok 4\n";}

eval 'while (0) {
    print "foo\n";
}
/^/ && (print "ok 5\n");
';

eval '$foo{1} / 1;';
if (!$@) {print "ok 6\n";} else {print "not ok 6 $@\n";}

eval '$foo = 123+123.4+123e4+123.4E5+123.4e+5+.12;';

$foo = int($foo * 100 + .5);
if ($foo eq 2591024652) {print "ok 7\n";} else {print "not ok 7 :$foo:\n";}

print <<'EOF';
ok 8
EOF

$foo = 'ok 9';
print <<EOF;
$foo
EOF

eval <<\EOE, print $@;
print <<'EOF';
ok 10
EOF

$foo = 'ok 11';
print <<EOF;
$foo
EOF
EOE

print <<'EOS' . <<\EOF;
ok 12 - make sure single quotes are honored \nnot ok
EOS
ok 13
EOF

print qq/ok 14\n/;
print qq(ok 15\n);

print qq
[ok 16\n]
;

print q<ok 17
>;

print "ok 18 - was the test for the deprecated use of bare << to mean <<\"\"\n";
#print <<;   # Yow!
#ok 18
#
## previous line intentionally left blank.

print <<E1 eq "foo\n\n" ? "ok 19\n" : "not ok 19\n";
@{[ <<E2 ]}
foo
E2
E1

print <<E1 eq "foo\n\n" ? "ok 20\n" : "not ok 20\n";
@{[
  <<E2
foo
E2
]}
E1

$foo = FOO;
$bar = BAR;
$foo{$bar} = BAZ;
$ary[0] = ABC;
