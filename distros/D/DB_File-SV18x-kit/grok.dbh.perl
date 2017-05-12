#!/usr/bin/perl -w

=comment

All we have to do is insert an include for the survival macros. So if
you want to edit your db.h file for some reason, it should be no
problem.

=cut

use File::Basename;
use ExtUtils::MakeMaker;

my %arg = @ARGV;
my $out = $arg{DB_H};
my $in;
if (-e $out) {
  $in = $out;
} else {
  $in = MM->catfile(dirname($out), "..", "..", "include", "db.h");
  unless (-e $in) {
    $in = MM->catfile(dirname($in), "..", "..", "include", "db.h");
  }
  unless (-e $in) {
    die "No db.h found. Cannot proceed";
  }
}

open IN, $in or die "Couldn't open $in: $!";
local $/;
my $db_h = <IN>;
close IN;
unlink $in if $in eq $out; # permission problem?
my $ins = qq{
\#ifdef DB_SURVIVAL_KIT
\#include <db-survive-$arg{DB_VERSION_SYM}.h>
\#endif
};
unless ($db_h =~ /\Q$ins\E/s) {
  $db_h =~ s/(\#ifndef\s+_DB_H_\s+\#define\s+_DB_H_\s+)/$1$ins/s;
}
open OUT, ">$out" or die "Couldn't open $out: $!";
print OUT $db_h;
close OUT;

