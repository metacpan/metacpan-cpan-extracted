#! /usr/bin/perl -T

use Test::More tests => 8;

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

#TESTING sequence_is_ambiguous
subtest "sequence is ambiguous" => sub
{
  plan tests => 2;

  my $tnotambig = $GD->sequence_is_ambiguous($seqobj);
  my $tisambig = $GD->sequence_is_ambiguous($bustedobj);
  is($tnotambig, 0, "sequence is not ambiguous");
  is($tisambig, 1, "sequence is ambiguous");
};

#TESTING regres()
subtest "regular expression generation" => sub
{
  plan tests => 4;

  my $shortnt = "ABCDGHKMNRSTVWY";
  my $tbreg = $GD->regex_nt(-sequence => $shortnt);
  my $rbstr = "A[BCGKSTY]C[ADGKRTW]G[ACHMTWY][GKT][ACM][ABCDGHKMNRSTVWY][AGR]";
  $rbstr .= "[CGS]T[ACGMRSV][ATW][CTY]";
  my $rbreg = qr/$rbstr/ix;
  is ($tbreg, $rbreg, "nucleotide regexg");

  my $shorter = "TCCRAC";
  my $tareg = $GD->regex_nt(-sequence => $shorter, -reverse_complement => 1);
  my $rareg = [qr/TCC[AGR]AC/ix, qr/GT[CTY]GGA/ix];
  is_deeply ($tareg, $rareg, "nucleotide regexg rev comp 1");

  my $shortest = "AGCT";
  $tareg = $GD->regex_nt(-sequence => $shortest, -reverse_complement => 1);
  $rareg = [qr/AGCT/ix];
  is_deeply ($tareg, $rareg, "nucleotide regexg rev comp 2");

  my $shortpep = "MDRSWKQKLNRDTVKLTEVMTWR*";
  my $tpreg = $GD->regex_aa($shortpep);
  my $bpreg = qr/MDRSWKQKLNRDTVKLTEVMTWR[*]/ix;
  is ($tpreg, $bpreg, "protein regexg");
};

#TESTING complement()
subtest "complementing" => sub
{
  plan tests => 4;

  my $tfro = $GD->complement($orf, 1);
  my $rfro = "TCACTGCTCAGGGGGGTGTTCAGGTCGCCGACGATGATGGTGTGGGGAGCGATGTGGGCCTTCA";
     $rfro .= "GCTTCACGAGGGTGTCCTTGATGAAGGTGGCGGCGCGGGCGTTGGGGGCGTAGATGTTCAGAA";
     $rfro .= "TGCTCAGCTCCTCCTGCAGGATCTTGCCCTTGATCAGGATGAAGTGGCCCTCCTTGTCCTTCT";
     $rfro .= "TGATCACCTTGGGCTGGAAGTCGATCTTGTCGCTGATCAGGATGGCCACGCCAGCCTGCTTCT";
     $rfro .= "TCAGGCCGTTGGCCTGAAAGATGGTCTTCCAGCCCTTCACCCGCAGGTAGTGCCGGTCCTTCT";
     $rfro .= "CGCGCAGGTGGGTCTCCTGGAGGCAACAGAAGGTGGGGTCCTGCTTGTGCAGCCAGTCGGTCA";
     $rfro .= "GGCGGTGCCGCTTGATGGGGCTGTTCAGGCCGTTGATGTTCAGGCTGATCAGGCTCAGGTAGT";
     $rfro .= "TGTTGCTGCCGGTGATCTTGGTGGTCGGGTGGGCATGGTGGCAAATAATTAGCATTAATTAAA";
     $rfro .= "GTATAAAACCATTTAGCGGCGGGTCTTCTCCAGGTCATCACCTCGGTCAGCTTCACGGTGTCG";
     $rfro .= "CGGTTCAGCTTCTGCTTCCAAGATCTGTCCAT";
  is ($tfro, $rfro, "reverse complement");

  my $tfro2 = $GD->complement($orf);
  my $rfro2 = "TACCTGTCTAGAACCTTCGTCTTCGACTTGGCGCTGTGGCACTTCGACTGGCTCCACTACTGG";
     $rfro2 .= "ACCTCTTCTGGGCGGCGATTTACCAAAATATGAAATTAATTACGATTAATAAACGGTGGTAC";
     $rfro2 .= "GGGTGGGCTGGTGGTTCTAGTGGCCGTCGTTGTTGATGGACTCGGACTAGTCGGACTTGTAG";
     $rfro2 .= "TTGCCGGACTTGTCGGGGTAGTTCGCCGTGGCGGACTGGCTGACCGACGTGTTCGTCCTGGG";
     $rfro2 .= "GTGGAAGACAACGGAGGTCCTCTGGGTGGACGCGCTCTTCCTGGCCGTGATGGACGCCCACT";
     $rfro2 .= "TCCCGACCTTCTGGTAGAAAGTCCGGTTGCCGGACTTCTTCGTCCGACCGCACCGGTAGGAC";
     $rfro2 .= "TAGTCGCTGTTCTAGCTGAAGGTCGGGTTCCACTAGTTCTTCCTGTTCCTCCCGGTGAAGTA";
     $rfro2 .= "GGACTAGTTCCCGTTCTAGGACGTCCTCCTCGACTCGTAAGACTTGTAGATGCGGGGGTTGC";
     $rfro2 .= "GGGCGCGGCGGTGGAAGTAGTTCCTGTGGGAGCACTTCGACTTCCGGGTGTAGCGAGGGGTG";
     $rfro2 .= "TGGTAGTAGCAGCCGCTGGACTTGTGGGGGGACTCGTCACT";
  is ($tfro2, $rfro2, "complement");

  my $tdets = $GD->complement($busted, 1);
  my $rdets = "YYAYTGYTCNGGNGGRTGYTCNGGNCKNCKNCKRTGRTGRTGNGGNSWNCKRTGNGGNCCYTC";
     $rdets .= "NGCYTCNCKNGGRTGNCCYTGRTGNARRTGNCKNCKNGGNCKYTGNGGNCKNARRTGYTCNS";
     $rdets .= "WRTGYTCNGCNCCNCCNGCNGGRTCYTGNCCYTGRTCNGGRTGNARNGGNCCNCCYTGNCCY";
     $rdets .= "TCYTGRTCNCCYTGNGCNGGNARNCKRTCYTGNCKYTGRTCNGGRTGNCCNCKCCANCCNGC";
     $rdets .= "YTCYTCNGGNCKYTGNCCNSWNARRTGRTCYTCNARNCCYTCNCCNGCNGGNARNGCNGGNC";
     $rdets .= "CYTCNCKNGCNGGNGGRTCNCCNGGNGGNARNARNARRTGNGGNCCNGCYTGNGCNGCNARN";
     $rdets .= "CKRTCNGGNGGNGCNGCYTGRTGNGGYTGYTCNGGNCKYTGRTGYTCNGGYTGRTCNGGYTC";
     $rdets .= "NGGNARYTGYTGYTGNCKRTGRTCYTGRTGRTCNGGNGGRCANGGNGGNARRTARTTNGCRT";
     $rdets .= "TDATNARNGTRTARAACCAYTTNGCNGCNGGNCKNCKCCANGTCATNACYTCNGTNARYTTN";
     $rdets .= "ACNGTRTCNCKRTTNARYTTYTGYTTCCANSWNCKRTCCAT";
  is ($tdets, $rdets, "busted reverse complement");

  my $mixedcase = "AaaTTttCcGkGBbGgaA";
  my $tmixs = $GD->complement($mixedcase, 1);
  my $rmixs = "TTCCVVCMCGGAAAATTT";
  is ($tmixs, $rmixs, "busted mixed case complement");
};

#TESTING rcomplement()
subtest "reverse complementing" => sub
{
  plan tests => 3;

  my $tfro = $GD->rcomplement($orf);
  my $rfro = "TCACTGCTCAGGGGGGTGTTCAGGTCGCCGACGATGATGGTGTGGGGAGCGATGTGGGCCTTCA";
     $rfro .= "GCTTCACGAGGGTGTCCTTGATGAAGGTGGCGGCGCGGGCGTTGGGGGCGTAGATGTTCAGAA";
     $rfro .= "TGCTCAGCTCCTCCTGCAGGATCTTGCCCTTGATCAGGATGAAGTGGCCCTCCTTGTCCTTCT";
     $rfro .= "TGATCACCTTGGGCTGGAAGTCGATCTTGTCGCTGATCAGGATGGCCACGCCAGCCTGCTTCT";
     $rfro .= "TCAGGCCGTTGGCCTGAAAGATGGTCTTCCAGCCCTTCACCCGCAGGTAGTGCCGGTCCTTCT";
     $rfro .= "CGCGCAGGTGGGTCTCCTGGAGGCAACAGAAGGTGGGGTCCTGCTTGTGCAGCCAGTCGGTCA";
     $rfro .= "GGCGGTGCCGCTTGATGGGGCTGTTCAGGCCGTTGATGTTCAGGCTGATCAGGCTCAGGTAGT";
     $rfro .= "TGTTGCTGCCGGTGATCTTGGTGGTCGGGTGGGCATGGTGGCAAATAATTAGCATTAATTAAA";
     $rfro .= "GTATAAAACCATTTAGCGGCGGGTCTTCTCCAGGTCATCACCTCGGTCAGCTTCACGGTGTCG";
     $rfro .= "CGGTTCAGCTTCTGCTTCCAAGATCTGTCCAT";
  is ($tfro, $rfro, "rcomplement");

  my $tdets = $GD->rcomplement($busted);
  my $rdets = "YYAYTGYTCNGGNGGRTGYTCNGGNCKNCKNCKRTGRTGRTGNGGNSWNCKRTGNGGNCCYTC";
     $rdets .= "NGCYTCNCKNGGRTGNCCYTGRTGNARRTGNCKNCKNGGNCKYTGNGGNCKNARRTGYTCNS";
     $rdets .= "WRTGYTCNGCNCCNCCNGCNGGRTCYTGNCCYTGRTCNGGRTGNARNGGNCCNCCYTGNCCY";
     $rdets .= "TCYTGRTCNCCYTGNGCNGGNARNCKRTCYTGNCKYTGRTCNGGRTGNCCNCKCCANCCNGC";
     $rdets .= "YTCYTCNGGNCKYTGNCCNSWNARRTGRTCYTCNARNCCYTCNCCNGCNGGNARNGCNGGNC";
     $rdets .= "CYTCNCKNGCNGGNGGRTCNCCNGGNGGNARNARNARRTGNGGNCCNGCYTGNGCNGCNARN";
     $rdets .= "CKRTCNGGNGGNGCNGCYTGRTGNGGYTGYTCNGGNCKYTGRTGYTCNGGYTGRTCNGGYTC";
     $rdets .= "NGGNARYTGYTGYTGNCKRTGRTCYTGRTGRTCNGGNGGRCANGGNGGNARRTARTTNGCRT";
     $rdets .= "TDATNARNGTRTARAACCAYTTNGCNGCNGGNCKNCKCCANGTCATNACYTCNGTNARYTTN";
     $rdets .= "ACNGTRTCNCKRTTNARYTTYTGYTTCCANSWNCKRTCCAT";
  is ($tdets, $rdets, "busted rcomplement");

  my $mixedcase = "AaaTTttCcGkGBbGgaA";
  my $tmixs = $GD->rcomplement($mixedcase);
  my $rmixs = "TTCCVVCMCGGAAAATTT";
  is ($tmixs, $rmixs, "busted mixed case complement");
};


# TESTING count()
subtest "count" => sub
{
  plan tests => 2;

  my $torfcount = $GD->count($seqobj);
  my $rorfcount = {A => 159, T => 95, C => 197, G => 149, R => 0, Y => 0,
    W => 0, S => 0, M => 0, K => 0, B => 0, D => 0, H => 0, V => 0,
    N => 0, "?" => 0, d => 600, n => 0, GCp => 57.7, ATp => 42.3, len => 600};
  is_deeply($torfcount, $rorfcount, "count non ambiguous bases");

  my $tbustcount = $GD->count($bustedobj);
  my $rbustcount = {A => 91, T => 31, C => 125, G => 113, R => 43, Y => 54,
    W => 4, S => 4, M => 21, K => 0, B => 0, D => 0, H => 1, V => 0,
    N => 113, "?" => 0, d => 360, n => 240, GCp => 59.6, ATp => 40.4,
    len => 600};
  is_deeply($tbustcount, $rbustcount, "count ambiguous bases");
};

# TESTING melt()
subtest "melting temperatures" => sub
{
  plan tests => 4;

  my $shortorf = "ATGGACAGATCTTGGAAGCAGAAGCTGAACCGC";
  my $shortobj = Bio::Seq->new( -seq => $shortorf, -id => "shortorf");
  my $rlshortorf =  "ATGGACAGAT";
  my $othershort = "GTTCTTGGTGACGTTCTCGAA";
  my $otherobj = Bio::Seq->new( -seq => $othershort, -id => "otherorf");

  my $tmelt1 = $GD->melt(-sequence => $rlshortorf);
  my $rmelt1 = "28.0";
  is ($tmelt1, $rmelt1, "real short Tm");

  $tmelt1 = $GD->melt(-sequence => $shortobj);
  $rmelt1 = "75.2";
  is ($tmelt1, $rmelt1, "short Tm");

  $tmelt1 = $GD->melt(-sequence => $otherobj);
  $rmelt1 = "59.4";
  is ($tmelt1, $rmelt1, "other short Tm");

  my $tnmelt = $GD->melt(-sequence => $shortobj, -nearest_neighbor => 1);
  my $rnmelt = "67.3";
  is ($tnmelt, $rnmelt, "nearest neighbor Tm");
};

# TESTING positions()
subtest "positions" => sub
{
  plan tests => 2;

  my $tpos = $GD->positions(-sequence => $seqobj, -query => "ATCC");
  my $rpos = {367 => "ATCC", 433 => "ATCC", 451 => "ATCC"};
  is_deeply ($tpos, $rpos, "simple positions");

  $tpos = $GD->positions(-sequence => $bustedobj, -query => "YMGNC");
  $rpos = {146 => "YMGNC"};
  is_deeply($tpos, $rpos, "ambiguous search positions");
};

# TESTING amb_transcription()
subtest "ambiguous nucleotide transcription" => sub
{
  plan tests => 1;

  my $tnopep = $GD->ambiguous_transcription($shortamb);
  my $rnopep = [qw(ACGCAT ACGCGT ACGCTT AGGCAT AGGCGT AGGCTT ATGCAT ATGCGT
    ATGCTT)];
  is_deeply($tnopep, $rnopep, "ambiguous transcription");

};