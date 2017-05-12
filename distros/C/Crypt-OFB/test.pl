#!/usr/bin/perl -w

use Crypt::OFB;

my ($path, $ok, @modules);

my $crypt = Crypt::OFB->new;

print "Checking your perl installation for cipher modules:\n";

foreach $path (@INC) {
    while (<$path/Crypt/*.pm>) {
	s|^.*Crypt/||;
	s|\.pm$||;
	print " Found $_.\n" if $crypt->cipher($_) and ++$ok;
    }
}

unless ($ok) {
    print "There are no crypt modules installed that I know of."
	. " Attention: Crypt::OFB will not be of any use to you"
	. " unless you install some cipher module(s).\n";
}
