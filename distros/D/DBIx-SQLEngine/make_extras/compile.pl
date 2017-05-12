#!perl

system("perl -Iblib/lib -wc $_") foreach ( @ARGV )