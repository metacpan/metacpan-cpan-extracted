#-*-Perl-*-
use Test2::V0;

BEGIN {
  use Data::Dumper;
  use File::Share ':all';
  use FindBin qw($Bin);
  use lib "$Bin/../lib", "$Bin/../blib/lib", "$Bin/../blib/arch";
  use ok ('Bio::RNA::RNAaliSplit::WrapRNAalifold');
  diag( "Testing Bio::RNA::RNAaliSplit::WrapRNAalifold $Bio::RNA::RNAaliSplit::WrapRNAalifold::VERSION, Perl $], $^X" );
}

my $aln1 = dist_file('Bio-RNA-RNAaliSplit','aln/all.SL.SPOVG.aln');
my %arg1 = (ifile => $aln1, odir => ['t']);
my $ro1 = Bio::RNA::RNAaliSplit::WrapRNAalifold->new(\%arg1);
note (Dumper($ro1));

isa_ok ($ro1, ['Bio::RNA::RNAaliSplit::WrapRNAalifold'], 'self is a Bio::RNA::RNAaliSplit::WrapRNAalifold');
ok ($ro1->has_ifile==1 , "has input file");
isa_ok ($ro1->ifile, ['Path::Class::File'], 'ifile is a Path::Class::File');
ok ($ro1->has_odir==1, "has output directory");
isa_ok ($ro1->odir, ['Path::Class::Dir'], 'odir is a Path::Class::Dir');
ok ($ro1->has_stk==1, "has stockholm output");
isa_ok ($ro1->alignment_stk, ['Path::Class::File'], 'alignment_stk is a Path::Class::File');


ok ($ro1->has_format==1 , "has format");
ok ($ro1->format eq "C", "alignment format");
ok ($ro1->has_consensus_struc==1 , "has consesnus structure ");
ok ($ro1->consensus_struc eq "(((((............((((((.........))))))..)))))", "consesnus structure");
ok ($ro1->has_consensus_covar_terms==1, "has consensus covariance terms");
ok ($ro1->consensus_covar_terms=="-1.02", "consensus covariance terms");
ok ($ro1->has_consensus_energy==1, "has consensus energy");
ok ($ro1->consensus_energy=="-11.21", "consensus covariance terms");
ok ($ro1->has_consensus_mfe==1, "has consensus mfe");
ok ($ro1->consensus_mfe=="-12.23", "consensus covariance terms");
ok ($ro1->sci=="0.8205", "structure conservation index");

todo "These are todo" => sub {
    ok(0, "oops");
};

done_testing;
