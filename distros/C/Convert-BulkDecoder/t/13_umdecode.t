#!/usr/bin/perl -w

@ARGV = qw(U M);		# uudecode, multi-part
-d "t" && chdir "t";
require "./decode.pl";
