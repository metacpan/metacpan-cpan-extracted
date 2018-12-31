#-*-Perl-*-
#!perl -T
use 5.010;
use strict;
use warnings;
use File::Share ':all';
use FindBin qw($Bin);
use constant TEST_COUNT => 4;
use Data::Dumper;

use lib "$Bin/../lib", "$Bin/../blib/lib", "$Bin/../blib/arch";


BEGIN {
  # include Test.pm from 't' dir in case itis not installed
  eval { require Test::More; };
  if ($@) {
    use lib 't';
  }
  use Test::More tests => TEST_COUNT;
}

use Bio::RNA::RNAaliSplit::WrapRscape;

{
  my $aln1 = dist_file('Bio-RNA-RNAaliSplit','aln/all.SL.SPOVG.stk');
  my @arg1 = (ifile => $aln1, odir => ['t'], nofigures => 1);
  my @arg2 = (ifile => $aln1, odir => ['t'], statistic => "GTp" );
  my $ro1 = new_ok('Bio::RNA::RNAaliSplit::WrapRscape' => \@arg1);
  my $ro2 = new_ok('Bio::RNA::RNAaliSplit::WrapRscape' => \@arg2);
  #diag(Dumper($ro1));
  #diag(Dumper($ro2));

  subtest WrapRscape_Object1 => sub { # test ro1
    plan tests => 26;

    ok($ro1->has_statistic==1,"has_statistic");
    ok($ro1->has_cseq==1,"has_cseq");
    ok($ro1->has_nseq==1,"has_nseq");
    ok($ro1->has_alen==1,"has_alen");
    ok($ro1->has_nbpairs==1,"has_nbpairs");
    ok($ro1->has_evalue==1,"has_evalue");
    ok($ro1->has_FP==1,"has_FP");
    ok($ro1->has_TP==1,"has_TP"); #
    ok($ro1->has_T==1,"has_T");
    ok($ro1->has_F==1,"has_F");
    ok($ro1->has_Sen==1,"has_Sen");
    ok($ro1->has_PPV==1,"has_PPV");
    ok($ro1->has_Fmeasure==1,"has_Fmeasure");

    ok($ro1->statistic eq "RAFS", "statistic");
    ok($ro1->cseq=="9", "cseq");
    ok($ro1->nseq=="9", "nseq");
    ok($ro1->alen=="45", "alen");
    ok($ro1->nbpairs=="11", "nbpairs");
    ok($ro1->evalue=="0.05", "evalue");
    ok($ro1->FP=="0", "FP");
    ok($ro1->TP=="3", "TP");
    ok($ro1->T=="11", "T");
    ok($ro1->Sen=="27.27", "Sen");
    ok($ro1->PPV=="100.00", "PPV");
    ok($ro1->Fmeasure=="42.86", "Fmeasure");
    ok($ro1->nofigures=="1", "nofigures");
    #ok(${$ro1->sigBP}[0]{i}=="20", "ro1 sigBP[0][i]");
  };

  subtest WrapRscape_Object2 => sub { # test ro1
    plan tests => 25;

    ok($ro2->has_statistic==1,"has_statistic");
    ok($ro2->has_cseq==1,"has_cseq");
    ok($ro2->has_nseq==1,"has_nseq");
    ok($ro2->has_alen==1,"has_alen");
    ok($ro2->has_nbpairs==1,"has_nbpairs");
    ok($ro2->has_evalue==1,"has_evalue");
    ok($ro2->has_FP==1,"has_FP");
    ok($ro2->has_TP==1,"has_TP"); #
    ok($ro2->has_T==1,"has_T");
    ok($ro2->has_F==1,"has_F");
    ok($ro2->has_Sen==1,"has_Sen");
    ok($ro2->has_PPV==1,"has_PPV");
    ok($ro2->has_Fmeasure==1,"has_Fmeasure");

    ok($ro2->statistic eq "GTp", "statistic");
    ok($ro2->cseq=="9", "cseq");
    ok($ro2->nseq=="9", "nseq");
    ok($ro2->alen=="45", "alen");
    ok($ro2->nbpairs=="11", "nbpairs");
    ok($ro2->evalue=="0.05", "evalue");
    ok($ro2->FP=="0", "FP");
    ok($ro2->TP=="0", "FP");
    ok($ro2->T=="11", "T");
    ok($ro2->Sen=="0.00", "Sen");
    ok($ro2->PPV=="0.00", "PPV");
    ok($ro2->Fmeasure=="0.00", "Fmeasure");
  
  };
}

