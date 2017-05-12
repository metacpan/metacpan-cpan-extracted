#! /usr/bin/perl -T

use Test::More tests => 9;

use Bio::GeneDesign;
use Bio::Seq;

use strict;
use warnings;

my $GD = Bio::GeneDesign->new();
$GD->set_organism(-organism_name => "yeast",
                  -table_path => "codon_tables/Standard.ct",
                  -rscu_path => "codon_tables/Saccharomyces_cerevisiae.rscu");


my $orf = "ATGGACAGATCTTGGAAGCAGAAGCTGAACCGCGACACCGTGAAGCTGACCGAGGTGATGACCTGGA";
$orf .= "GAAGACCCGCCGCTAAATGGTTTTATACTTTAATTAATGCTAATTATTTGCCACCATGCCCACCCGACC";
$orf .= "ACCAAGATCACCGGCAGCAACAACTACCTGAGCCTGATCAGCCTGAACATCAACGGCCTGAACAGCCCC";
$orf .= "ATCAAGCGGCACCGCCTGACCGACTGGCTGCACAAGCAGGACCCCACCTTCTGTTGCCTCCAGGAGACC";
$orf .= "CACCTGCGCGAGAAGGACCGGCACTACCTGCGGGTGAAGGGCTGGAAGACCATCTTTCAGGCCAACGGC";
$orf .= "CTGAAGAAGCAGGCTGGCGTGGCCATCCTGATCAGCGACAAGATCGACTTCCAGCCCAAGGTGATCAAG";
$orf .= "AAGGACAAGGAGGGCCACTTCATCCTGATCAAGGGCAAGATCCTGCAGGAGGAGCTGAGCATTCTGAAC";
$orf .= "ATCTACGCCCCCAACGCCCGCGCCGCCACCTTCATCAAGGACACCCTCGTGAAGCTGAAGGCCCACATC";
$orf .= "GCTCCCCACACCATCATCGTCGGCGACCTGAACACCCCCCTGAGCAGTGA";
my $seqobj = Bio::Seq->new( -seq => $orf, -id => "torf");

my $busted = "ATGGAYMGNWSNTGGAARCARAARYTNAAYMGNGAYACNGTNAARYTNACNGARGTNATGACNT";
$busted .= "GGMGNMGNCCNGCNGCNAARTGGTTYTAYACNYTNATHAAYGCNAAYTAYYTNCCNCCNTGYCCNC";
$busted .= "CNGAYCAYCARGAYCAYMGNCARCARCARYTNCCNGARCCNGAYCARCCNGARCAYCARMGNCCNG";
$busted .= "ARCARCCNCAYCARGCNGCNCCNCCNGAYMGNYTNGCNGCNCARGCNGGNCCNCAYYTNYTNYTNC";
$busted .= "CNCCNGGNGAYCCNCCNGCNMGNGARGGNCCNGCNYTNCCNGCNGGNGARGGNYTNGARGAYCAYY";
$busted .= "TNWSNGGNCARMGNCCNGARGARGCNGGNTGGMGNGGNCAYCCNGAYCARMGNCARGAYMGNYTNC";
$busted .= "CNGCNCARGGNGAYCARGARGGNCARGGNGGNCCNYTNCAYCCNGAYCARGGNCARGAYCCNGCNG";
$busted .= "GNGGNGCNGARCAYWSNGARCAYYTNMGNCCNCARMGNCCNMGNMGNCAYYTNCAYCARGGNCAYC";
$busted .= "CNMGNGARGCNGARGGNCCNCAYMGNWSNCCNCAYCAYCAYMGNMGNMGNCCNGARCAYCCNCCNG";
$busted .= "ARCARTRR";
my $bustedobj = Bio::Seq->new( -seq => $busted, -id => "bustedorf");

my $shortamb = "ABGCDT";

# TESTING codon_table
{
  my $rCT = {TTT => "F", TTC => "F", TTA => "L", TTG => "L", CTT => "L",
          CTC => "L", CTA => "L", CTG => "L", ATT => "I", ATC => "I",
          ATA => "I", ATG => "M", GTT => "V", GTC => "V", GTA => "V",
          GTG => "V", TCT => "S", TCC => "S", TCA => "S", TCG => "S",
          CCT => "P", CCC => "P", CCA => "P", CCG => "P", ACT => "T",
          ACC => "T", ACA => "T", ACG => "T", GCT => "A", GCC => "A",
          GCA => "A", GCG => "A", TAT => "Y", TAC => "Y", TAA => "*",
          TAG => "*", CAT => "H", CAC => "H", CAA => "Q", CAG => "Q",
          AAT => "N", AAC => "N", AAA => "K", AAG => "K", GAT => "D",
          GAC => "D", GAA => "E", GAG => "E", TGT => "C", TGC => "C",
          TGA => "*", TGG => "W", CGT => "R", CGC => "R", CGA => "R",
          CGG => "R", AGT => "S", AGC => "S", AGA => "R", AGG => "R",
          GGT => "G", GGC => "G", GGA => "G", GGG => "G"};
  is_deeply( $GD->codontable, $rCT, "codon table" );
}

# TESTING reverse_codon_table
{
  my $rRCT = {A => [qw(GCA GCC GCG GCT)], C => [qw(TGC TGT)],
    D => [qw(GAC GAT)], E => [qw(GAA GAG)], F => [qw(TTC TTT)],
    G => [qw(GGA GGC GGG GGT)], H => [qw(CAC CAT)], I => [qw(ATA ATC ATT)],
    K => [qw(AAA AAG)], L => [qw(CTA CTC CTG CTT TTA TTG)], M => [qw(ATG)],
    N => [qw(AAC AAT)], P => [qw(CCA CCC CCG CCT)], Q => [qw(CAA CAG)],
    R => [qw(AGA AGG CGA CGC CGG CGT)], S => [qw(AGC AGT TCA TCC TCG TCT)],
    T => [qw(ACA ACC ACG ACT)], V => [qw(GTA GTC GTG GTT)], W => [qw(TGG)],
    Y => [qw(TAC TAT)], '*' => [qw(TAA TAG TGA)]};
  is_deeply( $GD->reversecodontable, $rRCT, "reverse codon table" );
}

# TESTING define_RSCU_values()
{
  my $rRSCU = {TTT => "0.19", TTC => "1.81", TTA => "0.49", TTG => "5.34",
    CTT => "0.02", CTC => "0.00", CTA => "0.15", CTG => "0.02", ATT => "1.26",
    ATC => "1.74", ATA => "0.00", ATG => "1.00", GTT => "2.07", GTC => "1.91",
    GTA => "0.00", GTG => "0.02", TCT => "3.26", TCC => "2.42", TCA => "0.08",
    TCG => "0.02", CCT => "0.21", CCC => "0.02", CCA => "3.77", CCG => "0.00",
    ACT => "1.83", ACC => "2.15", ACA => "0.00", ACG => "0.01", GCT => "3.09",
    GCC => "0.89", GCA => "0.03", GCG => "0.00", TAT => "0.06", TAC => "1.94",
    TAA => "1.00", TAG => "0.00", CAT => "0.32", CAC => "1.68", CAA => "1.98",
    CAG => "0.02", AAT => "0.06", AAC => "1.94", AAA => "0.16", AAG => "1.84",
    GAT => "0.70", GAC => "1.30", GAA => "1.98", GAG => "0.02", TGT => "1.80",
    TGC => "0.20", TGA => "0.00", TGG => "1.00", CGT => "0.63", CGC => "0.00",
    CGA => "0.00", CGG => "0.00", AGT => "0.06", AGC => "0.16", AGA => "5.37",
    AGG => "0.00", GGT => "3.92", GGC => "0.06", GGA => "0.00", GGG => "0.02"};
  is_deeply( $GD->rscutable, $rRSCU, "RSCU table" );
}

# TESTING translate
subtest "translation" => sub
{
  plan tests => 6;

  my $tpeptide = $GD->translate(-sequence => $seqobj, -frame => 1);
  my $rpeptide = "MDRSWKQKLNRDTVKLTEVMTWRRPAAKWFYTLINANYLPPCPPDHQDHRQQQLPEPDQP";
     $rpeptide .= "EHQRPEQPHQAAPPDRLAAQAGPHLLLPPGDPPAREGPALPAGEGLEDHLSGQRPEEAG";
     $rpeptide .= "WRGHPDQRQDRLPAQGDQEGQGGPLHPDQGQDPAGGAEHSEHLRPQRPRRHLHQGHPRE";
     $rpeptide .= "AEGPHRSPHHHRRRPEHPPEQ*";
  is ($tpeptide->seq, $rpeptide, "translate frame 1");

  my $teptide = $GD->translate(-sequence => $seqobj, -frame => 2);
  my $reptide = "WTDLGSRS*TATP*S*PR**PGEDPPLNGFIL*LMLIICHHAHPTTKITGSNNYLSLISLN";
     $reptide .= "INGLNSPIKRHRLTDWLHKQDPTFCCLQETHLREKDRHYLRVKGWKTIFQANGLKKQAGV";
     $reptide .= "AILISDKIDFQPKVIKKDKEGHFILIKGKILQEELSILNIYAPNARAATFIKDTLVKLKA";
     $reptide .= "HIAPHTIIVGDLNTPLSS";
  is ($teptide->seq, $reptide, "translate frame 2");

  my $tptide = $GD->translate(-sequence => $seqobj, -frame => 3);
  my $rptide = "GQILEAEAEPRHREADRGDDLEKTRR*MVLYFN*C*LFATMPTRPPRSPAATTT*A*SA*TS";
     $rptide .= "TA*TAPSSGTA*PTGCTSRTPPSVASRRPTCARRTGTTCG*RAGRPSFRPTA*RSRLAWPS";
     $rptide .= "*SATRSTSSPR*SRRTRRATSS*SRARSCRRS*AF*TSTPPTPAPPPSSRTPS*S*RPTSL";
     $rptide .= "PTPSSSAT*TPP*AV";
  is ($tptide->seq, $rptide, "translate frame 3");

  my $teditpep = $GD->translate(-sequence => $seqobj, -frame => -1);
  my $reditpep = "SLLRGVFRSPTMMVWGAMWAFSFTRVSLMKVAARALGA*MFRMLSSSCRILPLIRMKWPS";
     $reditpep .= "LSFLITLGWKSILSLIRMATPACFFRPLA*KMVFQPFTRR*CRSFSRRWVSWRQQKVGS";
     $reditpep .= "CLCSQSVRRCRLMGLFRPLMFRLIRLR*LLLPVILVVGWAWWQIISIN*SIKPFSGGSS";
     $reditpep .= "PGHHLGQLHGVAVQLLLPRSVH";
  is ($teditpep->seq, $reditpep, "translate frame -1");

  my $tditpep = $GD->translate(-sequence => $seqobj, -frame => -2);
  my $rditpep = "HCSGGCSGRRR*WCGERCGPSASRGCP**RWRRGRWGRRCSECSAPPAGSCP*SG*SGPPC";
     $rditpep .= "PS*SPWAGSRSCR*SGWPRQPASSGRWPERWSSSPSPAGSAGPSRAGGSPGGNRRWGPAC";
     $rditpep .= "AASRSGGAA*WGCSGR*CSG*SGSGSCCCR*SWWSGGHGGK*LALIKV*NHLAAGLLQVI";
     $rditpep .= "TSVSFTVSRFSFCFQDLS";
  is ($tditpep->seq, $rditpep, "translate frame -2");

  my $titpep = $GD->translate(-sequence => $seqobj, -frame => -3);
  my $ritpep = "TAQGGVQVADDDGVGSDVGLQLHEGVLDEGGGAGVGGVDVQNAQLLLQDLALDQDEVALLVL";
     $ritpep .= "LDHLGLEVDLVADQDGHASLLLQAVGLKDGLPALHPQVVPVLLAQVGLLEATEGGVLLVQP";
     $ritpep .= "VGQAVPLDGAVQAVDVQADQAQVVVAAGDLGGRVGMVANN*H*LKYKTI*RRVFSRSSPRSA";
     $ritpep .= "SRCRGSASASKICP";
  is ($titpep->seq, $ritpep, "translate frame -3");
};

#TESTING codon_count
subtest "codon count" => sub
{
  plan tests => 2;

  my $tcount = $GD->codon_count([$seqobj]);
  my $rcount = {TTT => 1, TTA => 1, TTG => 2, CTT => 5, CTA => 3, CTG => 5,
    ATT => 1, ATG => 2, GTG => 2, TCT => 2, TCC => 1, TCA => 1, CCT => 15,
    CCC => 6, CCA => 9, CCG => 3, ACT => 1, ACC => 3, GCT => 5, GCC => 2,
    GCA => 6, GCG => 3, TAT => 2, CAT => 11, CAC => 7, CAA => 15, CAG => 6,
    AAT => 2, AAC => 1, AAA => 1, AAG => 3, GAT => 7, GAC => 6, GAA => 12,
    GAG => 4, TGC => 1, TGA => 1, TGG => 4, CGT => 3, CGC => 6, CGA => 5,
    CGG => 4, AGA => 3, GGT => 2, GGC => 4, GGA => 8, GGG => 3, ACG => 0,
    TAG => 0, GTC => 0, AGT => 0, TGT => 0, ATC => 0, AGC => 0, TAC => 0,
    ACA => 0, TCG => 0, AGG => 0, GTT => 0, ATA => 0, TTC => 0, CTC => 0,
    TAA => 0, GTA => 0};
  is_deeply($tcount, $rcount, "codon count starting blank");

  my $tcount2 = $GD->codon_count([$seqobj], $rcount);
  my %rcount2 = map {$_ => $tcount->{$_}+$tcount->{$_}} keys %$tcount;
  is_deeply($tcount2, \%rcount2, "codon count starting from a count");

};

#TESTING generate_RSCU_values()
{
  my $tORSCU = $GD->generate_RSCU_table([$seqobj]);
  my $rORSCU = {TTT => "2.00", TTA => 0.38, TTG => 0.75, CTT => 1.88,
    CTA => 1.12, CTG => 1.88, ATT => "3.00", ATG => "1.00", GTG => "4.00",
    TCT => "3.00", TCC => "1.50", TCA => "1.50", CCT => 1.82, CCC => 0.73,
    CCA => 1.09, CCG => 0.36, ACT => "1.00", ACC => "3.00", GCT => 1.25,
    GCC => "0.50", GCA => "1.50", GCG => 0.75, TAT => "2.00", CAT => 1.22,
    CAC => 0.78, CAA => 1.43, CAG => 0.57, AAT => 1.33, AAC => 0.67,
    AAA => "0.50", AAG => "1.50", GAT => 1.08, GAC => 0.92, GAA => "1.50",
    GAG => "0.50", TGC => "2.00", TGA => "3.00", TGG => "1.00", CGT => 0.86,
    CGC => 1.71, CGA => 1.43, CGG => 1.14, AGA => 0.86, GGT => 0.47,
    GGC => 0.94, GGA => 1.88, GGG => 0.71, TAG => "0.00", GTC => "0.00",
    AGT => "0.00", TGT => "0.00", ATC => "0.00", AGC => "0.00", TAC => "0.00",
    TCG => "0.00", ACA => "0.00", GTT => "0.00", AGG => "0.00", ATA => "0.00",
    TTC => "0.00", CTC => "0.00", TAA => "0.00", ACG => "0.00", GTA => "0.00"};
  is_deeply($tORSCU, $rORSCU, "generate RSCU values");
}

#TESTING generate_codon_report
if (1)
{

}

# TESTING ambiguous_translation()
subtest "ambiguous translation" => sub
{
  plan tests => 4;

  my @tpospeps = $GD->ambiguous_translation(-sequence => $shortamb,
                                            -frame => "s");
  @tpospeps = sort @tpospeps;
  my $rpospeps = [qw(*A* *AC *AF *AL *AS *AW *AY *CF *CI *CL *CM *CV *GF *GI *GL
    *GM *GV *RF *RI *RL *RM *RV *SI *SL *SM *SV ACF ACI ACL ACM ACV AGF AGI AGL
    AGM AGV ARF ARI ARL ARM ARV ASI ASL ASM ASV DA* DAC DAF DAL DAS DAW DAY EA*
    EAC EAF EAL EAS EAW EAY ECF ECI ECL ECM ECV EGF EGI EGL EGM EGV ERF ERI ERL
    ERM ERV ESI ESL ESM ESV GCF GCI GCL GCM GCV GGF GGI GGL GGM GGV GRF GRI GRL
    GRM GRV GSI GSL GSM GSV HA* HAC HAF HAL HAS HAW HAY ICF ICI ICL ICM ICV IGF
    IGI IGL IGM IGV IRF IRI IRL IRM IRV ISI ISL ISM ISV KA* KAC KAF KAL KAS KAW
    KAY KCF KCI KCL KCM KCV KGF KGI KGL KGM KGV KH KP KR KRF KRI KRL KRM KRV KSI
    KSL KSM KSV LCF LCI LCL LCM LCV LGF LGI LGL LGM LGV LRF LRI LRL LRM LRV LSI
    LSL LSM LSV MH ML MP MR NA* NAC NAF NAL NAS NAW NAY PCF PCI PCL PCM PCV PGF
    PGI PGL PGM PGV PRF PRI PRL PRM PRV PSI PSL PSM PSV QA* QAC QAF QAL QAS QAW
    QAY QCF QCI QCL QCM QCV QGF QGI QGL QGM QGV QRF QRI QRL QRM QRV QSI QSL QSM
    QSV RCF RCI RCL RCM RCV RGF RGI RGL RGM RGV RH RL RR RRF RRI RRL RRM RRV RSI
    RSL RSM RSV SCF SCI SCL SCM SCV SGF SGI SGL SGM SGV SRF SRI SRL SRM SRV SSI
    SSL SSM SSV TCF TCI TCL TCM TCV TGF TGI TGL TGM TGV TH TL TP TR TRF TRI TRL
    TRM TRV TSI TSL TSM TSV VCF VCI VCL VCM VCV VGF VGI VGL VGM VGV VRF VRI VRL
    VRM VRV VSI VSL VSM VSV YA* YAC YAF YAL YAS YAW YAY)];
  is_deeply(\@tpospeps, $rpospeps, "ambiguous translation 6 frame");

  my @tpospepst = $GD->ambiguous_translation(-sequence => $shortamb,
                                            -frame => "t");
  @tpospepst = sort @tpospepst;
  my $rpospepst = [qw(*A* *AC *AF *AL *AS *AW *AY *CF *CI *CL *CM *CV *GF *GI
    *GL *GM *GV *RF *RI *RL *RM *RV ACF ACI ACL ACM ACV AGF AGI AGL AGM AGV ARF
    ARI ARL ARM ARV DA* DAC DAF DAL DAS DAW DAY EA* EAC EAF EAL EAS EAW EAY ECF
    ECI ECL ECM ECV EGF EGI EGL EGM EGV ERF ERI ERL ERM ERV GCF GCI GCL GCM GCV
    GGF GGI GGL GGM GGV GRF GRI GRL GRM GRV HA* HAC HAF HAL HAS HAW HAY ICF ICI
    ICL ICM ICV IGF IGI IGL IGM IGV IRF IRI IRL IRM IRV KA* KAC KAF KAL KAS KAW
    KAY KCF KCI KCL KCM KCV KGF KGI KGL KGM KGV KRF KRI KRL KRM KRV LCF LCI LCL
    LCM LCV LGF LGI LGL LGM LGV LRF LRI LRL LRM LRV MH ML MR NA* NAC NAF NAL NAS
    NAW NAY PCF PCI PCL PCM PCV PGF PGI PGL PGM PGV PRF PRI PRL PRM PRV QA* QAC
    QAF QAL QAS QAW QAY QCF QCI QCL QCM QCV QGF QGI QGL QGM QGV QRF QRI QRL QRM
    QRV RCF RCI RCL RCM RCV RGF RGI RGL RGM RGV RH RL RR RRF RRI RRL RRM RRV SCF
    SCI SCL SCM SCV SGF SGI SGL SGM SGV SRF SRI SRL SRM SRV TCF TCI TCL TCM TCV
    TGF TGI TGL TGM TGV TH TL TR TRF TRI TRL TRM TRV VCF VCI VCL VCM VCV VGF VGI
    VGL VGM VGV VRF VRI VRL VRM VRV YA* YAC YAF YAL YAS YAW YAY)];
  is_deeply(\@tpospepst, $rpospepst, "ambiguous translation 3 frame");

  my @tpospeps1 = $GD->ambiguous_translation(-sequence => $shortamb,
                                            -frame => 1);
  @tpospeps1 = sort @tpospeps1;
  my $rpospeps1 = [qw(MH ML MR RH RL RR TH TL TR)];
  is_deeply(\@tpospeps1, $rpospeps1, "ambiguous translation 1 frame");

  my @tpospeps3 = $GD->ambiguous_translation(-sequence => $shortamb,
                                            -frame => -3);
  @tpospeps3 = sort @tpospeps3;
  my $rpospeps3 = [qw(*CI *CL *CM *CV *RI *RL *RM *RV *SI *SL *SM *SV ACI ACL
    ACM ACV ARI ARL ARM ARV ASI ASL ASM ASV ECI ECL ECM ECV ERI ERL ERM ERV ESI
    ESL ESM ESV GCI GCL GCM GCV GRI GRL GRM GRV GSI GSL GSM GSV ICI ICL ICM ICV
    IRI IRL IRM IRV ISI ISL ISM ISV KCI KCL KCM KCV KRI KRL KRM KRV KSI KSL KSM
    KSV LCI LCL LCM LCV LRI LRL LRM LRV LSI LSL LSM LSV PCI PCL PCM PCV PRI PRL
    PRM PRV PSI PSL PSM PSV QCI QCL QCM QCV QRI QRL QRM QRV QSI QSL QSM QSV RCI
    RCL RCM RCV RRI RRL RRM RRV RSI RSL RSM RSV SCI SCL SCM SCV SRI SRL SRM SRV
    SSI SSL SSM SSV TCI TCL TCM TCV TRI TRL TRM TRV TSI TSL TSM TSV VCI VCL VCM
    VCV VRI VRL VRM VRV VSI VSL VSM VSV)];
  is_deeply(\@tpospeps3, $rpospeps3, "ambiguous translation -3 frame");
};


# TESTING pattern_aligner()
subtest "pattern alignment" => sub
{
  plan tests => 5;

	my ($tnewaligned2, $tnewoffset2) = $GD->pattern_aligner(
    -sequence => "GACAGATCT",
    -pattern => "GACCGGA",
    -offset => 1
  );
	my $rnewaligned2 = "GACCGGANN";
	is ($tnewaligned2, $rnewaligned2, "align in frame 1");
	is ($tnewoffset2, 0, "align in frame 1");
	
	my ($tnewaligned3, $tnewoffset3) = $GD->pattern_aligner(
    -sequence => "GACAGATCT",
    -pattern => "ACAGATC"
  );
	my $rnewaligned3 = "NACAGATCN";
	is ($tnewaligned3, $rnewaligned3, "align in frame 2");

  my ($tnewaligned, $tnewoffset1) = $GD->pattern_aligner(
    -sequence => "GACAGATCT",
    -pattern => "CCGGAGC",
    -offset => 1
  );
  my $rnewaligned = "NNCCGGAGC";
  is ($tnewaligned, $rnewaligned, "align in frame 3");
  is ($tnewoffset1, 2, "offset in frame 3");
};


# TESTING pattern_adder()
my $tpattadd = $GD->pattern_adder(
  -sequence =>"GACAGATCT",
  -pattern => "NNCCGGAGC"
);
my $rpattadd = "GACCGGAGC";
is($tpattadd, $rpattadd, "pattern adding");