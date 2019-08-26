#-*-Perl-*-
use Test2::V0;

BEGIN {
  use Data::Dumper;
  use File::Share ':all';
  use FindBin qw($Bin);
  use lib "$Bin/../lib", "$Bin/../blib/lib", "$Bin/../blib/arch";
  use ok ('Bio::RNA::RNAaliSplit::WrapRscape');
  diag( "Testing Bio::RNA::RNAaliSplit::WrapRscape $Bio::RNA::RNAaliSplit::WrapRscape::VERSION, Perl $], $^X" );
}

{
  my ($ro1,$ro2,$ro3);
  my $aln1 = dist_file('Bio-RNA-RNAaliSplit','aln/all.SL.SPOVG.stk');
  my $aln2 = dist_file('Bio-RNA-RNAaliSplit','aln/RF00050.part.stk');
  my %arg1 = (ifile => $aln1, odir => ['t'], nofigures => 1);
  my %arg2 = (ifile => $aln1, odir => ['t'], statistic => "GTp" );
  my %arg3 = (ifile => $aln2, odir => ['t'], nofigures => 1, statistic => "GTp" );

  $ro1 = Bio::RNA::RNAaliSplit::WrapRscape->new(\%arg1);
  note (Dumper($ro1));
  ok($ro1->has_statistic==1,"has_statistic");
  ok($ro1->has_cseq==1,"has_cseq");
  ok($ro1->has_nseq==1,"has_nseq");
  ok($ro1->has_alen==1,"has_alen");
  ok($ro1->has_nbpairs==1,"has_nbpairs");
  ok($ro1->statistic eq "RAFS", "statistic");
  ok($ro1->cseq=="9", "cseq");
  ok($ro1->nseq=="9", "nseq");
  ok($ro1->alen=="45", "alen");
  ok($ro1->nbpairs=="11", "nbpairs");
  ok($ro1->nofigures=="1", "nofigures");
  ok($ro1->status=="2", "status 2");

  $ro2 = Bio::RNA::RNAaliSplit::WrapRscape->new(\%arg2);
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
  ok($ro2->status=="1", "status 1");

  $ro3 = Bio::RNA::RNAaliSplit::WrapRscape->new(\%arg3);
  ok($ro3->has_statistic==1,"has_statistic");
  ok($ro3->has_cseq==1,"has_cseq");
  ok($ro3->has_nseq==1,"has_nseq");
  ok($ro3->has_alen==1,"has_alen");
  ok($ro3->has_nbpairs==1,"has_nbpairs");
  ok($ro3->has_evalue==1,"has_evalue");
  ok($ro3->has_FP==1,"has_FP");
  ok($ro3->has_TP==1,"has_TP"); #
  ok($ro3->has_T==1,"has_T");
  ok($ro3->has_F==1,"has_F");
  ok($ro3->has_Sen==1,"has_Sen");
  ok($ro3->has_PPV==1,"has_PPV");
  ok($ro3->has_Fmeasure==1,"has_Fmeasure");

  ok($ro3->statistic eq "GTp", "statistic");
  ok($ro3->cseq=="99", "cseq");
  ok($ro3->nseq=="98", "nseq");
  ok($ro3->alen=="139", "alen");
  ok($ro3->nbpairs=="23", "nbpairs");
  ok($ro3->evalue=="0.05", "evalue");
  ok($ro3->FP=="2", "FP");
  ok($ro3->TP=="8", "FP");
  ok($ro3->T=="23", "T");
  ok($ro3->Sen=="34.78", "Sen");
  ok($ro3->PPV=="80.00", "PPV");
  ok($ro3->Fmeasure=="48.48", "Fmeasure");
  ok($ro3->status=="0", "status 0");
  done_testing;
}
