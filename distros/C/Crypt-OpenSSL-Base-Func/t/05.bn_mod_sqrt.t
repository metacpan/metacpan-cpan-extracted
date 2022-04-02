#!/usr/bin/perl
use utf8;
use Test::More;
use Crypt::OpenSSL::Base::Func qw/bn_mod_sqrt/;

my $p = '05';
my $a = '04';
my $s = bn_mod_sqrt($a, $p);
print "find ($s)^2 = $a mod $p\n";
ok($s eq '03');


$a = '02';
$s = bn_mod_sqrt($a, $p);
print "find ($s)^2 = $a mod $p\n";
ok($s eq '');

done_testing();
