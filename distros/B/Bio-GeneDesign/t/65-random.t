#! /usr/bin/perl -T

use Test::More tests => 3;
use Test::Deep;

use Bio::GeneDesign;
use Bio::Seq;

use strict;
use warnings;

my $GD = Bio::GeneDesign->new();

my $reps = 10000;

# TESTING random bases
if (1)
{
  my $rhshref =
  {
    A => num(0.25, 0.021), C => num(0.25, 0.021),
    G => num(0.25, 0.021), T => num(0.25, 0.021)
  };
  my $thshref = {};
  for my $x (1..$reps)
  {
    my $tbase = $GD->random_dna(-length => 1);
    $thshref->{$tbase}++;
  }
  foreach my $key (keys %$thshref)
  {
    my $ratio = $thshref->{$key} / $reps || 0;
    $thshref->{$key} = sprintf("%.2f", $ratio);
  }
  cmp_deeply($thshref, $rhshref, "random, single base");
}

# TESTING random weighted bases
subtest "random, weighted base" => sub
{
  plan tests => 2;

  my $rhshref =
  {
    A => num(0.20, 0.021), C => num(0.30, 0.021),
    G => num(0.30, 0.021), T => num(0.20, 0.021)
  };
  my $thshref = {};
  for my $x (1..$reps)
  {
    my $tbase = $GD->random_dna(-length => 1, -gc_percentage => 60);
    $thshref->{$tbase}++;
  }
  foreach my $key (keys %$thshref)
  {
    my $ratio = $thshref->{$key} / $reps || 0;
    $thshref->{$key} = sprintf("%.2f", $ratio);
  }
  cmp_deeply($thshref, $rhshref, "random, weighted base 1");

  $rhshref =
  {
    C => num(0.50, 0.021), G => num(0.50, 0.021),
  };
  $thshref = {};
  for my $x (1..$reps)
  {
    my $tbase = $GD->random_dna(-length => 1, -gc_percentage => 100);
    $thshref->{$tbase}++;
  }
  foreach my $key (keys %$thshref)
  {
    my $ratio = $thshref->{$key} / $reps || 0;
    $thshref->{$key} = sprintf("%.2f", $ratio);
  }
  cmp_deeply($thshref, $rhshref, "random, weighted base 2");
};

# TESTING replace ambiguous bases
subtest "replace ambiguous bases" => sub
{
  plan tests => 6;

  my $ieasy = "GTYRAC";
  my $reasy = $GD->regex_nt($ieasy);
  my $teasy = $GD->replace_ambiguous_bases($ieasy);
  my $aeasy = $GD->sequence_is_ambiguous($teasy);
  like($teasy, qr /$reasy/, "simple replace");
  is($aeasy, 0, "simple replace no ambig left");

  my $ideep = "VCTCGAGB";
  my $rdeep = $GD->regex_nt($ideep);
  my $tdeep = $GD->replace_ambiguous_bases($ideep);
  my $adeep = $GD->sequence_is_ambiguous($tdeep);
  like($tdeep, qr /$rdeep/, "complex replace");
  is($adeep, 0, "complex replace no ambig left");

  my $ilong = "GACNNNNNNGTC";
  my $rlong = $GD->regex_nt($ilong);
  my $tlong = $GD->replace_ambiguous_bases($ilong);
  my $along = $GD->sequence_is_ambiguous($tlong);
  like($tlong, qr /$rlong/, "long N replace match");
  is($along, 0, "long N replace no ambig left");
};