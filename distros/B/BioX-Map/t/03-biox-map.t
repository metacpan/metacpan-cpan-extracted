#!/usr/bin/env perl
use Modern::Perl;
use IO::All;
use Data::Dumper;
use Test::More;
use FindBin qw($Bin);
use Test::File::ShareDir
  -share => {
    -dist => { 'BioX-Map' => 'share' }
  };

my $module;
BEGIN {
  $module = 'BioX::Map';
  use_ok($module);
}

my @attrs = qw(
  infile        indir         outfile
  mismatch      genome        tool
  bwa           soap          soap_index
  process_tool  process_sample
);

my @methods = qw(exist_index create_index _map_one map statis_result);

for my $attr(@attrs) {
  can_ok($module, $attr);
}

for my $method(@methods) {
  can_ok($module, $method);
}

my $tmpdir = io->tmpdir;
say $Bin;
my $ref = io->file("$Bin/../share/data/ref.fa");
my $fq = io->file("$Bin/../share/data/test.fq");
my $outfile = io->catfile($tmpdir, 'test.sam');

SKIP : {
  skip "$ref or $fq is not exist", 1  unless $ref->exists and $fq->exists;
  say "ref:$ref\nfq:$fq\nout:$outfile\n";
  $ref->copy("$tmpdir");
  my $bm = new_ok($module => [
      infile  => "$fq",
      genome  => "$tmpdir/ref.fa",
      outfile => "$outfile",
      tool    => 'bwa',
    ]
  );
  #is($bm->exist_index, 0, "exist_index");
  #is($bm->create_index, 1, "create_index");
  $bm->exist_index;
  $bm->create_index;
  $bm->map;
  say Dumper $bm->statis_result;
}

done_testing;
