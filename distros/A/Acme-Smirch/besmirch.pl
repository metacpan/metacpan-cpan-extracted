#! /usr/bin/perl

use Acme::Smirch;

$#ARGV == 0 or print "Give me a program to make dirty!\n" and exit;
Acme::Smirch::smear($ARGV[0])

