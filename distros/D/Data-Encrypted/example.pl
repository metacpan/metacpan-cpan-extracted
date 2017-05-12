#!/usr/bin/perl -w

use lib "blib/lib";
use strict;

use Data::Encrypted;

my $enc = new Data::Encrypted file => "./.secret";
my $password = $enc->encrypted("password");

print "Password entered: $password\n";
