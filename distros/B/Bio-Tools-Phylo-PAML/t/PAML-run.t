#!/usr/bin/env perl

use utf8;
use strict;
use warnings;

use Test::More;

use File::Spec;

use Bio::AlignIO;
use Bio::TreeIO;

use Bio::Tools::Phylo::PAML;
use Bio::Tools::Run::Phylo::PAML::Codeml;
use Bio::Tools::Run::Phylo::PAML::Yn00;

sub test_input_file {
  return File::Spec->catfile('t', 'data', @_);
}

my $verbose = 0;

my $inpaml = Bio::Tools::Phylo::PAML->new(-file =>
                     test_input_file('codeml.mlc'));

ok($inpaml);

my $codeml = Bio::Tools::Run::Phylo::PAML::Codeml->new
  (-params => {'runmode' => -2,
               'seqtype' => 1,
               'model'   => 0,
               'alpha'   => '0',
               'omega'   => 0.4,
               'kappa'    => 2,
               'CodonFreq'=> 2,
               'NSsites'   => 0,
               'model'    => 0,
              },
   -verbose => $verbose);

my $in = Bio::AlignIO->new(-format => 'phylip',
                           -file   => test_input_file('gf-s85.phylip'));
my $aln = $in->next_aln;
$codeml->alignment($aln);
my ($rc,$results) = $codeml->run();

is($rc,1);

ok(defined $results, "got results");
my $result = $results->next_result;
ok(defined $result, "got a result");

my $MLmatrix = $result->get_MLmatrix;

my ($vnum) = ($result->version =~ /(\d+(\.\d+)?)/);
SKIP: {
  if( $vnum == 3.12 ) {
    # PAML 2.12 results
    is($MLmatrix->[0]->[1]->{'dN'}, 0.0693);
    is($MLmatrix->[0]->[1]->{'dS'},1.1459);
    is($MLmatrix->[0]->[1]->{'omega'}, 0.0605);
    is($MLmatrix->[0]->[1]->{'S'}, 273.5);
    is($MLmatrix->[0]->[1]->{'N'}, 728.5);
    is($MLmatrix->[0]->[1]->{'t'}, 1.0895);
    skip($MLmatrix->[0]->[1]->{'lnL'},
         "I don't know what this should be, if you run this part, email the list so we can update the value",
         1);

  } elsif( $vnum >= 3.13  && $vnum < 4) {
    # PAML 2.13 results
    is($MLmatrix->[0]->[1]->{'dN'}, 0.0713);
    is($MLmatrix->[0]->[1]->{'dS'},1.2462);
    is(sprintf("%.4f",$MLmatrix->[0]->[1]->{'omega'}), 0.0572);
    is($MLmatrix->[0]->[1]->{'S'}, 278.8);
    is($MLmatrix->[0]->[1]->{'N'}, 723.2);
    is(sprintf("%.4f",$MLmatrix->[0]->[1]->{'t'}), 1.1946);
    skip($MLmatrix->[0]->[1]->{'lnL'},
         "I don't know what this should be, if you run this part, email the list so we can update the value",
         1);

  } elsif( $vnum >= 4 ) {
    ## PAML 4, 4.8, and 4.9h results
    is($MLmatrix->[0]->[1]->{'dN'}, 0.0713);
    is($MLmatrix->[0]->[1]->{'dS'},1.2462);
    is(sprintf("%.4f",$MLmatrix->[0]->[1]->{'omega'}), 0.0572);
    is($MLmatrix->[0]->[1]->{'S'}, 278.8);
    is($MLmatrix->[0]->[1]->{'N'}, 723.2);
    is(sprintf("%.4f",$MLmatrix->[0]->[1]->{'t'}), 1.1946);
    is($MLmatrix->[0]->[1]->{'lnL'}, -1929.935243);
  } else {
    skip("Can't test the result output, don't know about PAML version ".$result->version,
         7);
  }
}

unlike($codeml->error_string, qr/Error/); # we don't expect any errors;

my $yn00 = Bio::Tools::Run::Phylo::PAML::Yn00->new();
$yn00->alignment($aln);
($rc,$results) = $yn00->run();
is($rc,1);
ok(defined $results, "got results");
$result = $results->next_result;
ok(defined $result, "got a result");
$MLmatrix = $result->get_MLmatrix;

is($MLmatrix->[0]->[1]->{'dN'}, 0.0846);
is($MLmatrix->[0]->[1]->{'dS'}, 1.0926);
is($MLmatrix->[0]->[1]->{'omega'}, 0.0774);
is($MLmatrix->[0]->[1]->{'S'}, 278.4);
is($MLmatrix->[0]->[1]->{'N'}, 723.6);
is($MLmatrix->[0]->[1]->{'t'}, 1.0941);

unlike($yn00->error_string, qr/Error/); # we don't expect any errors;

$codeml = Bio::Tools::Run::Phylo::PAML::Codeml->new
  (-params => { 'alpha' => 1.53 },
   -verbose => $verbose);

ok($codeml);


# AAML
my $cysaln = Bio::AlignIO->new(-format => 'msf',
                               -file => test_input_file('cysprot.msf'))->next_aln;

my $cystre = Bio::TreeIO->new(-format => 'newick',
                              -file  => test_input_file('cysprot.raxml.tre'))->next_tree;
ok($cysaln);
ok($cystre);

$codeml = Bio::Tools::Run::Phylo::PAML::Codeml->new
  (
   -verbose => 0,
   -tree   => $cystre,
   -params => { 'runmode' => 0, # provide a usertree
                'seqtype' => 2, # AMINO ACIDS,
                'model'   => 0, # one dN/dS rate
                'NSsites' => 0, # one -- swap this with 1, 2, 3 etc
                'clock'   => 0, # 0 = no clock
                'getSE'   => 1, # get Standard Error
                'fix_blength' => 0, # use initial BLengths
                'ncatG' => 1, #increase approrpriately for NSsites,
              },
   -alignment => $cysaln,
   -save_tempfiles => 1,
  );
ok($codeml);

($rc,$results) = $codeml->run();
is($rc,1);
ok(defined $results, "got results");
$result = $results->next_result;

($vnum) = ($result->version =~ /(\d+(\.\d+)?)/);
for my $tree ( $result->get_trees ) {
  my $node = $tree->find_node(-id => 'CATL_HUMAN');
  if( $vnum == 4 ) {
    is($node->branch_length, '0.216223');
  } else {
    is($node->branch_length, '0.216223');
  }
}

done_testing ();
