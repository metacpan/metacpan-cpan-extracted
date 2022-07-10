#!/usr/bin/perl -w

@ARGV = qw(Y S);		# ydecode, single-part
-d "t" && chdir "t";
require "./decode.pl";
