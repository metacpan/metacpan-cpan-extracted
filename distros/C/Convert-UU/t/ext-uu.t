#!/usr/bin/perl -w -- -*- mode: cperl -*-

use strict;

use File::Spec;

my @PATH = File::Spec->path;
my $uudecode;
for my $p (@PATH) {
  my $u = File::Spec->catfile($p,"uudecode");
  if (-x $u) {
    $uudecode = $u;
    last;
  }
}

if ($uudecode) {
  print "1..3\n";
} else {
  print "1..0\n";
  exit;
}

require Convert::UU;

my $string = q{From andreas.koenig@xxxxxxxx Thu Feb  6 14:08:31 2003
Date: Thu, 06 Feb 2003 14:03:09 +0100
From: Andreas J. Koenig <andreas.koenig@xxxxxxxx>
To: Pierre Vanhove <pierre.vanhove@xxxxxxx>
Cc: andreas.koenig@xxxxxxxx
Subject: Re: Convert::UU

>>>>> On Thu, 6 Feb 2003 13:54:16 +0100 (CET), Pierre Vanhove <pierre.vanhove@xxxxxxx> said:

  > Dear Ms Koenig,
  > i'm trying to use your perl routine UU.pm but i always get the "Short
  > file" error message when decode the uufile which a linux or unix uudecode
  > script.

  > I want to uuencode some web uploaded file and have it send by email. The
  > file has to be uudecoded by the people who receive the file, and therefore
  > are not always using the uudecode of your routine.

  > How can i avoid this error message.

I do not know. Please try an external uudecode program instead of mine
and see if that works better.

- If it does, please send me the problematic file, describe what
  exactly you do with it and how external uudecode and my module
  differ.

- If it doesn't, then I suppose the problem is outside of my domain.

-- 
andreas
};

my $encoded = Convert::UU::uuencode($string,"t1.puu.txt");
open F, ">t1.puu" or die;
print F $encoded;
close F;
unlink "t1.puu.txt"; # may fail
system $uudecode, "t1.puu";
if ($?) {
  print "not ok 1 # system $uudecode returned false\n";
} else {
  print "ok 1\n";
}
if (-f "t1.puu.txt") {
  print "ok 2\n";
} else {
  print "not ok 2 # no output file t1.puu.txt written\n";
}
open F, "t1.puu.txt" or die $!;
local $/;
my $decoded = <F>;
close F;
if ($decoded eq $string) {
  print "ok 3\n";
} else {
  print "not ok 3\n";
}
