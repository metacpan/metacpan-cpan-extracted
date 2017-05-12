#! /usr/local/bin/perl -w

print "1..1\n";

$@ = '';
eval { require Crypt::DES_PP };
print $@ ? "not ok 1\n" : "ok 1\n";

