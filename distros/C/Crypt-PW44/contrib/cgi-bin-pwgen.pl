#!/usr/bin/perl
use Crypt::PW44 qw(generate);
printf "Content-type: text/html\n\n";
printf "%s\n", generate(pack(Ll, int(rand(2**32)), int(rand(2**16))), 3);
