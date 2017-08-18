#!/usr/bin/perl
use Crypt::PW44 qw(generate_password);
printf "Content-type: text/html\n\n";
printf "%s\n", generate_password(pack("Ll", int(rand(2**32)), int(rand(2**16))), 3);
