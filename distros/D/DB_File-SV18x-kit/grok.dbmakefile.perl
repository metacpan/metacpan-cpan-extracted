#!/usr/bin/perl -w

use File::Basename;
use ExtUtils::MakeMaker;

my %arg = @ARGV;
my $out = $arg{MAKEFILE_DB};
my $in = MM->catfile(dirname($out), "Makefile");

my $db_lib = basename($arg{DB_LIB});

open MAKE, $in or die "Couldn't open $in: $!";
open OUT, ">$out" or die "Couldn't open $out: $!";
while (<MAKE>) {
  s/^\s*(LIBDB\s*=\s*).*/$1$db_lib/;
  s/^\s*(CL\s*=\s*.+?\-D\w+)\s+(.+)/$1 -DDB_SURVIVAL_KIT $2/;
  print OUT $_;
}
