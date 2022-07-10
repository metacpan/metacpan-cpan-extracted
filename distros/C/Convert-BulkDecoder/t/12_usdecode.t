#!/usr/bin/perl -w

@ARGV = qw(U S);		# uudecode, single-part
-d "t" && chdir "t";
require "./decode.pl";
