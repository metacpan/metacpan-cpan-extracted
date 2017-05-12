#!/usr/bin/perl
# 15_Buffy.t

use strict;
use Acme::EyeDrops qw(ascii_to_sightly sightly_to_ascii
                      get_eye_string make_siertri make_triangle
                      pour_sightly);

$|=1;

print "1..6\n";

my $last_bit = <<'LAST_CAMEL';
                                      ############
           ######                   ###############
        ##########                ##################
 ##########  ######              ###################
LAST_CAMEL

my $camelstr = get_eye_string('camel');
my $t1 = join("", map(chr, 0..255));
my $f1 = ascii_to_sightly($t1);
my $shape = pour_sightly($camelstr, $f1, 0, "", 0, sub {});
my $t1a = sightly_to_ascii($shape);
$t1 eq $t1a or print "not ";
print "ok 1\n";

$shape =~ tr/!-~/#/;
$shape eq $camelstr x 4 . $last_bit or print "not ";
print "ok 2\n";

my $siertristr = make_siertri(5);
$t1 = 'ABCDEFGHIJKLMNOPQ';
$f1 = ascii_to_sightly($t1);
$shape = pour_sightly($siertristr, $f1, 0, '#', 0, sub {});
$t1a = sightly_to_ascii($shape);
$t1 eq $t1a or print "not ";
print "ok 3\n";

$shape =~ tr/!-~/#/;
$shape eq $siertristr or print "not ";
print "ok 4\n";

my $trianglestr = make_triangle(42);
$t1 = 'abcdefghijklmnopqrstuvwxyz0123456789';
$f1 = ascii_to_sightly($t1);
$shape = pour_sightly($trianglestr, $f1, 0, '#', 0, sub {});
$t1a = sightly_to_ascii($shape);
$t1 eq $t1a or print "not ";
print "ok 5\n";

$shape =~ tr/!-~/#/;
$shape eq $trianglestr or print "not ";
print "ok 6\n";
