#!perl -T

use strict;
use Test::More tests => 1;

use Acme::PlayCode;

my $from = <<'FROM';
my $a = "a";
my $b = "'b'";
my $c = 'c';
my $d = qq~'d'~;
if ( $a eq "a" ) {
    print "a " . "print 'a' . 'b'" . "c\n";
} elsif ( $b eq 'b') {
    print "2";
} elsif ( $c ne qq~c~) {
    print "3";
} elsif ( $c eq q~d~) {
    print '4';
} else {
    print '5';
}
FROM

my $to = <<'TO';
my $a = 'a';
my $b = q~'b'~;
my $c = 'c';
my $d = qq~'d'~;
if ( 'a' eq $a ) {
    print 'a ', q~print 'a' . 'b'~, "c\n";
} elsif ( 'b' eq $b) {
    print '2';
} elsif ( $c ne 'c') {
    print '3';
} elsif ( q~d~ eq $c) {
    print '4';
} else {
    print '5';
}
TO

my $app = Acme::PlayCode->new();
$app->load_plugin('Averything');
my $ret = $app->play($from);

is($ret, $to, '1 ok');
