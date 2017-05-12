#!perl -T

use strict;
use Test::More tests => 1;

use Acme::PlayCode;

my $from = <<'FROM';
my $a = "a";
my $b = "'b'";
my $c = 'c';
my $d = qq~d~;
if ( $a eq "a" ) {
    print "1";
} elsif ( $b eq 'b') {
    print "2";
} elsif ( $c ne qq~c~) {
    print "3";
} elsif ( $c eq q~d~) {
    print '4';
} else {
    print '5';
}
if ( $a eq $b ) {
    print '6';
}
if ( $c eq '$d' ) {
    print 7;
}
if ( $a =~ /$b/ ) {
    print 8;
}
if ( $a == '$b' or $c == '$d' ) {
    print 9;
}
FROM

my $to = <<'TO';
my $a = "a";
my $b = "'b'";
my $c = 'c';
my $d = qq~d~;
if ( "a" eq $a ) {
    print "1";
} elsif ( 'b' eq $b) {
    print "2";
} elsif ( $c ne qq~c~) {
    print "3";
} elsif ( q~d~ eq $c) {
    print '4';
} else {
    print '5';
}
if ( $a eq $b ) {
    print '6';
}
if ( '$d' eq $c ) {
    print 7;
}
if ( $a =~ /$b/ ) {
    print 8;
}
if ( '$b' == $a or '$d' == $c ) {
    print 9;
}
TO

my $app = Acme::PlayCode->new();
$app->load_plugin('ExchangeCondition');
my $ret = $app->play($from);

is($ret, $to, '1 ok');
