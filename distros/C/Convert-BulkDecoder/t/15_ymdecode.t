#!/usr/bin/perl -w

@ARGV = qw(Y M);		# ydecode, multi-part
-d "t" && chdir "t";
require "./decode.pl";
