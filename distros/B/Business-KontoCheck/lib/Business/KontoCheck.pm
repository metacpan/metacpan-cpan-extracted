#vim:tw=70:ft=perl:si

package Business::KontoCheck;

use 5.006000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(kto_check kto_check_str kto_check_blz
   kto_check_pz kto_check_regel kto_check_regel_dbg
   generate_lut generate_lut2 lut_cleanup lut_valid
   lut_init kto_check_init copy_lutfile lut_multiple lut_filialen
   lut_blz lut_name lut_name_kurz lut_plz lut_ort lut_pan lut_bic
   lut_pz lut_aenderung lut_loeschung lut_nachfolge_blz lut_iban_regel
   lut_blz1 lut_name1 lut_name_kurz1 lut_plz1 lut_ort1 lut_pan1 lut_bic1
   lut_pz1 lut_aenderung1 lut_loeschung1 lut_nachfolge_blz1
   bic_name bic_name_kurz bic_plz bic_ort bic_pan bic_bic bic_pz
   bic_aenderung bic_loeschung bic_nachfolge_blz bic_iban_regel
   biq_name biq_name_kurz biq_plz biq_ort biq_pan biq_bic biq_pz
   biq_aenderung biq_loeschung biq_nachfolge_blz biq_iban_regel
   iban_name iban_name_kurz iban_plz iban_ort iban_pan iban_bic
   iban_pz iban_aenderung iban_loeschung iban_nachfolge_blz
   iban_iban_regel bic_name1 bic_name_kurz1 bic_plz1 bic_ort1 bic_pan1
   bic_bic1 bic_pz1 bic_aenderung1 bic_loeschung1 bic_nachfolge_blz1
   bic_iban_regel1 biq_name1 biq_name_kurz1 biq_plz1 biq_ort1 biq_pan1
   biq_bic1 biq_pz1 biq_aenderung1 biq_loeschung1 biq_nachfolge_blz1
   biq_iban_regel1 iban_name1 iban_name_kurz1 iban_plz1 iban_ort1
   iban_pan1 iban_bic1 iban_pz1 iban_aenderung1 iban_loeschung1
   iban_nachfolge_blz1 iban_iban_regel1 bic_info
   iban_gen check_iban ipi_check ipi_gen set_verbose_debug lut_info lut_blocks
   ci_check bic_check iban_check pz_aenderungen_enable rebuild_blzfile
   set_default_compression iban2bic pz2str kto_check_encoding
   kto_check_encoding_str keep_raw_data retval2txt retval2txt_short
   retval2iso retval2utf8 retval2html retval2dos kto_check_retval2txt
   kto_check_retval2txt_short kto_check_retval2utf8
   kto_check_retval2html dump_lutfile kto_check_retval2dos
   lut_suche_blz lut_suche_pz lut_suche_plz lut_suche_regel lut_suche_bic
   lut_suche_volltext lut_suche_namen lut_suche_namen_kurz
   lut_suche_ort lut_suche_multiple konto_check_at kto_check_at_str
   generate_lut_at %kto_retval %kto_retval_kurz lut_keine_iban_berechnung
   lut_scl_multi lut_scl_init lut_scl_sct lut_scl_sdd lut_scl_cor1 lut_scl_b2b lut_scl_scc
   lut_scl_multi_blz lut_scl_sct_blz lut_scl_sdd_blz lut_scl_cor1_blz lut_scl_b2b_blz lut_scl_scc_blz );

our @EXPORT = qw( lut_init kto_check kto_check_blz kto_check_at %kto_retval );

our $VERSION = '6.10';

require XSLoader;
XSLoader::load('Business::KontoCheck', $VERSION);

# Preloaded methods go here.

sub lut_info
{
   my $lut_name;
   my $ret=1;
   my $info1;
   my $info2;
   my $valid1;
   my $valid2;
   my $lut_dir;
   my $args;

   if(scalar(@_)==1){
      $lut_name=$_[0];
      $args=0;
   }
   else{
      $lut_name="";
      $args=-2;
   }
   if(wantarray()){
      $ret=lut_info_i($lut_name,1+$args,$info1,$valid1,$info2,$valid2,$lut_dir);
      return ($ret,$info1,$valid1,$info2,$valid2,$lut_dir);
   }
   else{
      $ret=lut_info_i($lut_name,$args,$info1,$valid1,$info2,$valid2,$lut_dir);
      return $ret;
   }
}

sub kto_check_regel_dbg
{
   my $ret;
   my $blz;
   my $kto;
   my $blz2;
   my $kto2;
   my $bic;
   my $regel;
   my $methode;
   my $pz_methode;
   my $pz;
   my $pz_pos;

   $blz=$_[0];
   $kto=$_[1];
   $ret=kto_check_regel_dbg_i($blz,$kto,$blz2,$kto2,$bic,$regel,$methode,$pz_methode,$pz,$pz_pos);

   if(wantarray()){
      return ($ret,$blz2,$kto2,$bic,$regel,$methode,$pz_methode,$pz,$pz_pos);
   }
   else{
      return $ret;
   }
}

sub iban_gen
{
   my $blz;
   my $kto;
   my $kto2;
   my $blz2;
   my $ret;
   my $iban;
   my $papier;
   my $bic;
   my $regel;
   my $pz_methode;
   my $argc;

   $blz=$_[0];
   $kto=$_[1];
   $ret=iban_gen_i($blz,$kto,$iban,$papier,$bic,$regel,$pz_methode,$blz2,$kto2);
   if(wantarray()){
      return ($ret,$iban,$papier,$bic,$regel,$pz_methode,$blz2,$kto2);
   }
   else{
      return $iban;
   }
}

sub iban2bic
{
   my $bic;
   my $iban;
   my $kto;
   my $blz;
   my $ret;
   my $argc;

   $iban=$_[0];
   if(wantarray()){
      $bic=iban2bic_i($iban,$ret,$blz,$kto);
      return ($bic,$ret,$blz,$kto);
   }
   else{
      $bic=iban2bic_i($iban,$ret,$blz,$kto);
      return $bic;
   }
}

sub current_lutfile_name
{
   my $lut_name;
   my $set;
   my $level;
   my $retval;

   if(wantarray()){
      $lut_name=current_lutfile_name_i(1,$set,$level,$retval);
      return ($lut_name,$set,$level,$retval);
   }
   else{
      $lut_name=current_lutfile_name_i(0,$set,$level,$retval);
      return $lut_name;
   }
}

sub lut_multiple
{
   my $blz;
   my $filiale;
   my $cnt;
   my $name;
   my $name_kurz;
   my $plz;
   my $ort;
   my $pan;
   my $bic;
   my $pz;
   my $nr;
   my $aenderung;
   my $loeschung;
   my $nachfolge_blz;
   my $id;
   my $ret;

   if(scalar(@_)<1){ #keine BLZ angegeben, leere Liste zurück
      return ();
   }
   if(scalar(@_)<2){ #keine Filiale angegeben, Hauptstelle nehmen
      $filiale=0;
   }
   else{
      $filiale=$_[1];
   }
   $blz=$_[0];
   $cnt=$name=$name_kurz=$plz=$ort=$pan=$bic=$pz=$nr=$aenderung=$loeschung=$nachfolge_blz=0;
   $ret=lut_multiple_i($blz,$filiale,$cnt,$name,$name_kurz,$plz,$ort,$pan,$bic,$pz,$nr,$aenderung,$loeschung,$nachfolge_blz);
   if(wantarray()){
      return ($ret,$cnt,$name,$name_kurz,$plz,$ort,$pan,$bic,$pz,$nr,$aenderung,$loeschung,$nachfolge_blz);
   }
   else{
      return $ret;
   }
}

sub ipi_gen
{
   my $r;
   my $zweck;
   my $retval;
   my $papier;

   if(scalar(@_)==0){
      return "";
   }
   else{
      $zweck=$_[0];
   }
   $r=ipi_gen_i($zweck,$retval,$papier);
   if(wantarray()){
      return ($retval,$papier,$r);
   }
   else{
      return $retval;
   }
}

sub lut_filialen
{
   my $r=1;
   my $v;

   $v=lut_filialen_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub lut_suche_bic
{
   if(wantarray()){
      return lut_suche_c(1,1,@_);
   }
   else{
      return lut_suche_c(0,1,@_);
   }
}

sub lut_suche_namen
{
   if(wantarray()){
      return lut_suche_c(1,2,@_);
   }
   else{
      return lut_suche_c(0,2,@_);
   }
}

sub lut_suche_namen_kurz
{
   if(wantarray()){
      return lut_suche_c(1,3,@_);
   }
   else{
      return lut_suche_c(0,3,@_);
   }
}

sub lut_suche_ort
{
   if(wantarray()){
      return lut_suche_c(1,4,@_);
   }
   else{
      return lut_suche_c(0,4,@_);
   }
}

sub lut_suche_blz
{
   if(wantarray()){
      return lut_suche_i(1,1,@_);
   }
   else{
      return lut_suche_i(0,1,@_);
   }
}

sub lut_suche_pz
{
   if(wantarray()){
      return lut_suche_i(1,2,@_);
   }
   else{
      return lut_suche_i(0,2,@_);
   }
}

sub lut_suche_plz
{
   if(wantarray()){
      return lut_suche_i(1,3,@_);
   }
   else{
      return lut_suche_i(0,3,@_);
   }
}

sub lut_suche_regel
{
   if(wantarray()){
      return lut_suche_i(1,4,@_);
   }
   else{
      return lut_suche_i(0,4,@_);
   }
}


sub lut_suche_volltext
{
   if(wantarray()){
      return lut_suche_volltext_i(1,@_);
   }
   else{
      return lut_suche_volltext_i(0,@_);
   }
}

sub lut_suche_multiple
{
   if(wantarray()){
      return lut_suche_multiple_i(1,@_);
   }
   else{
      return lut_suche_multiple_i(0,@_);
   }
}

sub lut_blz
{
   my $r;

   $r=lut_blz_i(@_);
   if(wantarray()){
      return ($r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $r;
   }
}

sub lut_blz1
{
   return lut_blz_i(@_);
}

sub bic_info
{
   my $r;

   $r=bic_info_i(@_);
   return $r;
}

sub lut_name
{
   my $r=1;
   my $v;

   $v=lut_name_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub lut_name1
{
   my $r=1;

   return lut_name_i($r,@_);
}

sub lut_name_kurz
{
   my $r=1;
   my $v;

   $v=lut_name_kurz_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub lut_name_kurz1
{
   my $r=1;

   return lut_name_kurz_i($r,@_);
}

sub lut_plz
{
   my $r=1;
   my $v;

   $v=lut_plz_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub lut_plz1
{
   my $r=1;

   return lut_plz_i($r,@_);
}

sub lut_ort
{
   my $r=1;
   my $v;

   $v=lut_ort_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub lut_ort1
{
   my $r=1;

   return lut_ort_i($r,@_);
}

sub lut_pan
{
   my $r=1;
   my $v;

   $v=lut_pan_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub lut_pan1
{
   my $r=1;

   return lut_pan_i($r,@_);
}

sub lut_bic
{
   my $r=1;
   my $v;

   $v=lut_bic_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub lut_bic1
{
   my $r=1;

   return lut_bic_i($r,@_);
}

sub lut_pz
{
   my $r=1;
   my $v;

   $v=lut_pz_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub lut_pz1
{
   my $r=1;

   return lut_pz_i($r,@_);
}

sub lut_aenderung
{
   my $r=1;
   my $v;

   $v=lut_aenderung_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub lut_aenderung1
{
   my $r=1;

   return lut_aenderung_i($r,@_);
}

sub lut_loeschung
{
   my $r=1;
   my $v;

   $v=lut_loeschung_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub lut_loeschung1
{
   my $r=1;

   return lut_loeschung_i($r,@_);
}

sub lut_nachfolge_blz
{
   my $r=1;
   my $v;

   $v=lut_nachfolge_blz_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub lut_nachfolge_blz1
{
   my $r=1;

   return lut_nachfolge_blz_i($r,@_);
}

sub lut_iban_regel
{
   my $r=1;
   my $v;

   $v=lut_iban_regel_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub lut_iban_regel1
{
   my $r=1;

   return lut_iban_regel_i($r,@_);
}


sub bic_name
{
   my $r=1;
   my $v;

   $v=bic_name_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub bic_name1
{
   my $r=1;

   return bic_name_i($r,@_);
}

sub bic_name_kurz
{
   my $r=1;
   my $v;

   $v=bic_name_kurz_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub bic_name_kurz1
{
   my $r=1;

   return bic_name_kurz_i($r,@_);
}

sub bic_plz
{
   my $r=1;
   my $v;

   $v=bic_plz_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub bic_plz1
{
   my $r=1;

   return bic_plz_i($r,@_);
}

sub bic_ort
{
   my $r=1;
   my $v;

   $v=bic_ort_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub bic_ort1
{
   my $r=1;

   return bic_ort_i($r,@_);
}

sub bic_pan
{
   my $r=1;
   my $v;

   $v=bic_pan_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub bic_pan1
{
   my $r=1;

   return bic_pan_i($r,@_);
}

sub bic_bic
{
   my $r=1;
   my $v;

   $v=bic_bic_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub bic_bic1
{
   my $r=1;

   return bic_bic_i($r,@_);
}

sub bic_pz
{
   my $r=1;
   my $v;

   $v=bic_pz_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub bic_pz1
{
   my $r=1;

   return bic_pz_i($r,@_);
}

sub bic_aenderung
{
   my $r=1;
   my $v;

   $v=bic_aenderung_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub bic_aenderung1
{
   my $r=1;

   return bic_aenderung_i($r,@_);
}

sub bic_loeschung
{
   my $r=1;
   my $v;

   $v=bic_loeschung_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub bic_loeschung1
{
   my $r=1;

   return bic_loeschung_i($r,@_);
}

sub bic_nachfolge_blz
{
   my $r=1;
   my $v;

   $v=bic_nachfolge_blz_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub bic_nachfolge_blz1
{
   my $r=1;

   return bic_nachfolge_blz_i($r,@_);
}

sub bic_iban_regel
{
   my $r=1;
   my $v;

   $v=bic_iban_regel_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub bic_iban_regel1
{
   my $r=1;

   return bic_iban_regel_i($r,@_);
}


sub biq_name
{
   my $r=1;
   my $v;

   $v=biq_name_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub biq_name1
{
   my $r=1;

   return biq_name_i($r,@_);
}

sub biq_name_kurz
{
   my $r=1;
   my $v;

   $v=biq_name_kurz_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub biq_name_kurz1
{
   my $r=1;

   return biq_name_kurz_i($r,@_);
}

sub biq_plz
{
   my $r=1;
   my $v;

   $v=biq_plz_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub biq_plz1
{
   my $r=1;

   return biq_plz_i($r,@_);
}

sub biq_ort
{
   my $r=1;
   my $v;

   $v=biq_ort_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub biq_ort1
{
   my $r=1;

   return biq_ort_i($r,@_);
}

sub biq_pan
{
   my $r=1;
   my $v;

   $v=biq_pan_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub biq_pan1
{
   my $r=1;

   return biq_pan_i($r,@_);
}

sub biq_bic
{
   my $r=1;
   my $v;

   $v=biq_bic_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub biq_bic1
{
   my $r=1;

   return biq_bic_i($r,@_);
}

sub biq_pz
{
   my $r=1;
   my $v;

   $v=biq_pz_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub biq_pz1
{
   my $r=1;

   return biq_pz_i($r,@_);
}

sub biq_aenderung
{
   my $r=1;
   my $v;

   $v=biq_aenderung_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub biq_aenderung1
{
   my $r=1;

   return biq_aenderung_i($r,@_);
}

sub biq_loeschung
{
   my $r=1;
   my $v;

   $v=biq_loeschung_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub biq_loeschung1
{
   my $r=1;

   return biq_loeschung_i($r,@_);
}

sub biq_nachfolge_blz
{
   my $r=1;
   my $v;

   $v=biq_nachfolge_blz_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub biq_nachfolge_blz1
{
   my $r=1;

   return biq_nachfolge_blz_i($r,@_);
}

sub biq_iban_regel
{
   my $r=1;
   my $v;

   $v=biq_iban_regel_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub biq_iban_regel1
{
   my $r=1;

   return biq_iban_regel_i($r,@_);
}


sub iban_name
{
   my $r=1;
   my $v;

   $v=iban_name_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub iban_name1
{
   my $r=1;

   return iban_name_i($r,@_);
}

sub iban_name_kurz
{
   my $r=1;
   my $v;

   $v=iban_name_kurz_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub iban_name_kurz1
{
   my $r=1;

   return iban_name_kurz_i($r,@_);
}

sub iban_plz
{
   my $r=1;
   my $v;

   $v=iban_plz_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub iban_plz1
{
   my $r=1;

   return iban_plz_i($r,@_);
}

sub iban_ort
{
   my $r=1;
   my $v;

   $v=iban_ort_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub iban_ort1
{
   my $r=1;

   return iban_ort_i($r,@_);
}

sub iban_pan
{
   my $r=1;
   my $v;

   $v=iban_pan_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub iban_pan1
{
   my $r=1;

   return iban_pan_i($r,@_);
}

sub iban_bic
{
   my $r=1;
   my $v;

   $v=iban_bic_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub iban_bic1
{
   my $r=1;

   return iban_bic_i($r,@_);
}

sub iban_pz
{
   my $r=1;
   my $v;

   $v=iban_pz_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub iban_pz1
{
   my $r=1;

   return iban_pz_i($r,@_);
}

sub iban_aenderung
{
   my $r=1;
   my $v;

   $v=iban_aenderung_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub iban_aenderung1
{
   my $r=1;

   return iban_aenderung_i($r,@_);
}

sub iban_loeschung
{
   my $r=1;
   my $v;

   $v=iban_loeschung_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub iban_loeschung1
{
   my $r=1;

   return iban_loeschung_i($r,@_);
}

sub iban_nachfolge_blz
{
   my $r=1;
   my $v;

   $v=iban_nachfolge_blz_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub iban_nachfolge_blz1
{
   my $r=1;

   return iban_nachfolge_blz_i($r,@_);
}

sub iban_iban_regel
{
   my $r=1;
   my $v;

   $v=iban_iban_regel_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub iban_iban_regel1
{
   my $r=1;

   return iban_iban_regel_i($r,@_);
}


sub lut_scl_sct
{
   my $r=1;
   my $v;

   $v=lut_scl_sct_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub lut_scl_sct_blz
{
   my $r=1;
   my $used_bic="";
   my $v;

   $v=lut_scl_sct_blz_i($r,$used_bic,@_);
   if(wantarray()){
      return ($v,$used_bic,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub lut_scl_sdd
{
   my $r=1;
   my $v;

   $v=lut_scl_sdd_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub lut_scl_sdd_blz
{
   my $r=1;
   my $used_bic="";
   my $v;

   $v=lut_scl_sdd_blz_i($r,$used_bic,@_);
   if(wantarray()){
      return ($v,$used_bic,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub lut_scl_cor1
{
   my $r=1;
   my $v;

   $v=lut_scl_cor1_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub lut_scl_cor1_blz
{
   my $r=1;
   my $used_bic="";
   my $v;

   $v=lut_scl_cor1_blz_i($r,$used_bic,@_);
   if(wantarray()){
      return ($v,$used_bic,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub lut_scl_b2b
{
   my $r=1;
   my $v;

   $v=lut_scl_b2b_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub lut_scl_b2b_blz
{
   my $r=1;
   my $used_bic="";
   my $v;

   $v=lut_scl_b2b_blz_i($r,$used_bic,@_);
   if(wantarray()){
      return ($v,$used_bic,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub lut_scl_scc
{
   my $r=1;
   my $v;

   $v=lut_scl_scc_i($r,@_);
   if(wantarray()){
      return ($v,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}

sub lut_scl_scc_blz
{
   my $r=1;
   my $used_bic="";
   my $v;

   $v=lut_scl_scc_blz_i($r,$used_bic,@_);
   if(wantarray()){
      return ($v,$used_bic,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $v;
   }
}


sub lut_scl_multi
{
   my $r=1;
   my $scl_flags="";
   my $used_bic="";
   my $scl_name="";

   $r=lut_scl_multi_i($scl_flags,$used_bic,$scl_name,@_);
   if(wantarray()){
      return ($scl_flags,$used_bic,$scl_name,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $scl_flags;
   }
}

sub lut_scl_multi_blz
{
   my $r=1;
   my $scl_flags="";
   my $used_bic="";
   my $scl_name="";

   $r=lut_scl_multi_blz_i($scl_flags,$used_bic,$scl_name,@_);
   if(wantarray()){
      return ($scl_flags,$used_bic,$scl_name,$r,$Business::KontoCheck::kto_retval{$r},$Business::KontoCheck::kto_retval_kurz{$r});
   }
   else{
      return $scl_flags;
   }
}

%Business::KontoCheck::kto_retval = (
-158 => 'die SCL-Blocks wurden noch nicht eingelesen',
-157 => 'Der Info-Block des SCL-Verzeichnisses wurde noch nicht eingelesen',
-156 => 'Der BIC wurde im SCL-Verzeichnis nicht gefunden',
-155 => 'Ungültiger SCL-Info-Block in der LUT-Datei',
-154 => 'Keine SCL-Blocks in der LUT-Datei enthalten',
-153 => 'Ungültige Eingabewerte in der SCL-Datei',
-152 => 'Ungültiger Zähler in regulärem Ausdruck (innerhalb von {})',
-151 => 'Ungültiger regulärer Ausdruck (enthält zwei Zeichen aus [+?*] nacheinander)',
-150 => 'Ungültiges Handle angegeben',
-149 => 'Ungültiger Index für die biq_*() Funktionen',
-148 => 'Der Array-Index liegt außerhalb des gültigen Bereichs',
-147 => 'Es werden nur deutsche IBANs unterstützt',
-146 => 'Falscher Parametertyp für die Funktion',
-145 => 'Es werden nur deutsche BICs unterstützt',
-144 => 'Die Länge des BIC muß genau 8 oder 11 Zeichen sein',
-143 => 'Die IBAN-Prüfsumme stimmt, die BLZ sollte aber durch eine zentrale BLZ ersetzt werden. Die Richtigkeit der IBAN kann nur mit einer Anfrage bei der Bank ermittelt werden',
-142 => 'Die IBAN-Prüfsumme stimmt, konto_check wurde jedoch noch nicht initialisiert (Kontoprüfung nicht möglich)',
-141 => 'Die IBAN-Prüfsumme stimmt, die BLZ ist allerdings ungültig',
-140 => 'Die IBAN-Prüfsumme stimmt, für die Bank gibt es allerdings eine (andere) Nachfolge-BLZ',
-139 => 'es konnten nicht alle Datenblocks die für die IBAN-Berechnung notwendig sind geladen werden',
-138 => 'Der Datensatz ist noch nicht gültig, außerdem konnten nicht alle Blocks geladen werden',
-137 => 'Der Datensatz ist nicht mehr gültig, außerdem konnten nicht alle Blocks geladen werdeng',
-136 => 'ok, bei der Initialisierung konnten allerdings ein oder mehrere Blocks nicht geladen werden',
-135 => 'falsch, es wurde ein Unterkonto hinzugefügt (IBAN-Regel)',
-134 => 'Die BLZ findet sich in der Ausschlussliste für IBAN-Berechnungen',
-133 => 'Die BLZ ist in der Bundesbank-Datei als gelöscht markiert und somit ungültig',
-132 => 'Die IBAN-Prüfsumme stimmt, es gibt allerdings einen Fehler in der eigenen IBAN-Bestimmung (wahrscheinlich falsch)',
-131 => 'Die IBAN-Prüfsumme stimmt. Die Bank gibt IBANs nach nicht veröffentlichten Regeln heraus, die Richtigkeit der IBAN kann nur mit einer Anfrage bei der Bank ermittelt werden',
-130 => 'Die IBAN-Prüfsumme stimmt, es wurde allerdings eine IBAN-Regel nicht beachtet (wahrscheinlich falsch)',
-129 => 'Die IBAN-Prüfsumme stimmt, es fehlt aber ein Unterkonto (wahrscheinlich falsch)',
-128 => 'Die BLZ passt nicht zur angegebenen IBAN-Regel',
-127 => 'Die Kontonummer ist nicht eindeutig (es gibt mehrere Möglichkeiten)',
-126 => 'Die IBAN-Regel ist noch nicht implementiert',
-125 => 'Die IBAN-Regel ist nicht bekannt',
-124 => 'Für die Bankverbindung ist keine IBAN-Berechnung erlaubt',
-123 => 'Die Bankverbindung ist mit der alten BLZ stimmig, mit der Nachfolge-BLZ nicht',
-122 => 'Das Feld IBAN-Regel wurde nicht initialisiert',
-121 => 'Die Länge der IBAN für das angegebene Länderkürzel ist falsch',
-120 => 'Keine Bankverbindung/IBAN angegeben',
-119 => 'Ungültiges Zeichen ( ()+-/&.,\' ) für die Volltextsuche gefunden',
-118 => 'Die Volltextsuche sucht jeweils nur ein einzelnes Wort, benutzen Sie lut_suche_multiple() zur Suche nach mehreren Worten',
-117 => 'die angegebene Suchresource ist ungültig',
-116 => 'bei der Suche sind im Verknüpfungsstring nur die Zeichen a-z sowie + und - erlaubt',
-115 => 'bei der Suche müssen zwischen 1 und 26 Suchmuster angegeben werden',
-114 => 'Das Feld Volltext wurde nicht initialisiert',
-113 => 'das Institut erlaubt keine eigene IBAN-Berechnung',
-112 => 'die notwendige Kompressions-Bibliothek wurde beim Kompilieren nicht eingebunden',
-111 => 'der angegebene Wert für die Default-Kompression ist ungültig',
-110 => '(nicht mehr als Fehler, sondern positive Ausgabe - Dummy für den alten Wert)',
-109 => 'Ungültige Signatur im Default-Block',
-108 => 'Die maximale Anzahl Einträge für den Default-Block wurde erreicht',
-107 => 'Es wurde noch kein Default-Block angelegt',
-106 => 'Der angegebene Schlüssel wurde im Default-Block nicht gefunden',
-105 => 'Beide Datensätze sind nicht mehr gültig, dieser ist aber jünger als der andere',
 -79 => 'ungültiger Suchbereich angegeben (unten>oben)',
 -78 => 'Die Suche lieferte kein Ergebnis',
 -77 => 'BAV denkt, das Konto ist falsch (konto_check hält es für richtig)',
 -76 => 'User-Blocks müssen einen Typ > 500 haben',
 -75 => 'für ein LUT-Set sind nur die Werte 0, 1 oder 2 möglich',
 -74 => 'Ein Konto kann kann nur für deutsche Banken geprüft werden',
 -73 => 'Der zu validierende strukturierete Verwendungszweck muß genau 20 Zeichen enthalten',
 -72 => 'Im strukturierten Verwendungszweck dürfen nur alphanumerische Zeichen vorkommen',
 -71 => 'Die Länge des IPI-Verwendungszwecks darf maximal 18 Byte sein',
 -70 => 'Es wurde eine LUT-Datei im Format 1.0/1.1 geladen',
 -69 => 'Für die aufgerufene Funktion fehlt ein notwendiger Parameter',
 -68 => 'Die Funktion iban2bic() arbeitet nur mit deutschen Bankleitzahlen',
 -67 => 'Die Prüfziffer der IBAN stimmt, die der Kontonummer nicht',
 -66 => 'Die Prüfziffer der Kontonummer stimmt, die der IBAN nicht',
 -65 => 'Es sind nur maximal 500 Slots pro LUT-Datei möglich (Neukompilieren erforderlich)',
 -64 => 'Initialisierung fehlgeschlagen (init_wait geblockt)',
 -63 => 'Ein inkrementelles Initialisieren benötigt einen Info-Block in der LUT-Datei',
 -62 => 'Ein inkrementelles Initialisieren mit einer anderen LUT-Datei ist nicht möglich',
 -61 => 'Die Funktion ist nur in der Debug-Version vorhanden',
 -60 => 'Kein Datensatz der LUT-Datei ist aktuell gültig',
 -59 => 'Der Datensatz ist noch nicht gültig',
 -58 => 'Der Datensatz ist nicht mehr gültig',
 -57 => 'Im Gültigkeitsdatum sind Anfangs- und Enddatum vertauscht',
 -56 => 'Das angegebene Gültigkeitsdatum ist ungültig (Sollformat ist JJJJMMTT-JJJJMMTT)',
 -55 => 'Der Index für die Filiale ist ungültig',
 -54 => 'Die Bibliothek wird gerade neu initialisiert',
 -53 => 'Das Feld BLZ wurde nicht initialisiert',
 -52 => 'Das Feld Filialen wurde nicht initialisiert',
 -51 => 'Das Feld Bankname wurde nicht initialisiert',
 -50 => 'Das Feld PLZ wurde nicht initialisiert',
 -49 => 'Das Feld Ort wurde nicht initialisiert',
 -48 => 'Das Feld Kurzname wurde nicht initialisiert',
 -47 => 'Das Feld PAN wurde nicht initialisiert',
 -46 => 'Das Feld BIC wurde nicht initialisiert',
 -45 => 'Das Feld Prüfziffer wurde nicht initialisiert',
 -44 => 'Das Feld NR wurde nicht initialisiert',
 -43 => 'Das Feld Änderung wurde nicht initialisiert',
 -42 => 'Das Feld Löschung wurde nicht initialisiert',
 -41 => 'Das Feld Nachfolge-BLZ wurde nicht initialisiert',
 -40 => 'die Programmbibliothek wurde noch nicht initialisiert',
 -39 => 'der Block mit der Filialenanzahl fehlt in der LUT-Datei',
 -38 => 'es wurden nicht alle Blocks geladen',
 -37 => 'Buffer error in den ZLIB Routinen',
 -36 => 'Memory error in den ZLIB-Routinen',
 -35 => 'Datenfehler im komprimierten LUT-Block',
 -34 => 'Der Block ist nicht in der LUT-Datei enthalten',
 -33 => 'Fehler beim Dekomprimieren eines LUT-Blocks',
 -32 => 'Fehler beim Komprimieren eines LUT-Blocks',
 -31 => 'Die LUT-Datei ist korrumpiert',
 -30 => 'Im Inhaltsverzeichnis der LUT-Datei ist kein Slot mehr frei',
 -29 => 'Die (Unter)Methode ist nicht definiert',
 -28 => 'Der benötigte Programmteil wurde beim Kompilieren deaktiviert',
 -27 => 'Die Versionsnummer für die LUT-Datei ist ungültig',
 -26 => 'ungültiger Prüfparameter (erste zu prüfende Stelle)',
 -25 => 'ungültiger Prüfparameter (Anzahl zu prüfender Stellen)',
 -24 => 'ungültiger Prüfparameter (Position der Prüfziffer)',
 -23 => 'ungültiger Prüfparameter (Wichtung)',
 -22 => 'ungültiger Prüfparameter (Rechenmethode)',
 -21 => 'Problem beim Initialisieren der globalen Variablen',
 -20 => 'Prüfsummenfehler in der blz.lut Datei',
 -19 => 'falsch (die BLZ wurde außerdem gelöscht)',
 -18 => 'ok, ohne Prüfung (die BLZ wurde allerdings gelöscht)',
 -17 => 'ok (die BLZ wurde allerdings gelöscht)',
 -16 => 'die Bankleitzahl wurde gelöscht',
 -15 => 'Fehler in der blz.txt Datei (falsche Zeilenlänge)',
 -14 => 'undefinierte Funktion, die library wurde mit THREAD_SAFE=0 kompiliert',
 -13 => 'schwerer Fehler im Konto_check-Modul',
 -12 => 'ein Konto muß zwischen 1 und 10 Stellen haben',
 -11 => 'kann Datei nicht schreiben',
 -10 => 'kann Datei nicht lesen',
  -9 => 'kann keinen Speicher allokieren',
  -8 => 'die blz.txt Datei wurde nicht gefunden',
  -7 => 'die blz.lut Datei ist inkosistent/ungültig',
  -6 => 'die blz.lut Datei wurde nicht gefunden',
  -5 => 'die Bankleitzahl ist nicht achtstellig',
  -4 => 'die Bankleitzahl ist ungültig',
  -3 => 'das Konto ist ungültig',
  -2 => 'die Methode wurde noch nicht implementiert',
  -1 => 'die Methode ist nicht definiert',
   0 => 'falsch',
   1 => 'ok',
   2 => 'ok, ohne Prüfung',
   3 => 'ok, für den Test wurde eine Test-BLZ verwendet',
   4 => 'Der Datensatz ist aktuell gültig',
   5 => 'Der Datensatz enthält kein Gültigkeitsdatum',
   6 => 'Die Datei ist im alten LUT-Format (1.0/1.1)',
   7 => 'ok, es wurde allerdings eine LUT-Datei im alten Format (1.0/1.1) generiert',
   9 => 'ok, es wurde allerdings eine LUT-Datei im Format 2.0 generiert (Compilerswitch)',
  10 => 'ok, der Wert für den Schlüssel wurde überschrieben',
  11 => 'wahrscheinlich ok, die Kontonummer kann allerdings (nicht angegebene) Unterkonten enthalten',
  12 => 'wahrscheinlich ok, die Kontonummer enthält eine Unterkontonummer',
  13 => 'ok, die Anzahl Slots wurde auf SLOT_CNT_MIN (60) hochgesetzt',
  14 => 'ok, ein(ige) Schlüssel wurden nicht gefunden',
  15 => 'Die Bankverbindung wurde nicht getestet',
  16 => 'Es wurden fast alle Blocks (außer den IBAN-Regeln) geladen',
  17 => 'ok, für die BLZ wurde allerdings die Nachfolge-BLZ eingesetzt',
  18 => 'ok, die Kontonummer wurde allerdings ersetzt',
  19 => 'ok, die Bankleitzahl wurde allerdings ersetzt',
  20 => 'ok, die Bankleitzahl und Kontonummer wurden allerdings ersetzt',
  21 => 'ok, die Bankverbindung ist (ohne Test) als richtig anzusehen',
  22 => 'ok, für die die IBAN ist (durch eine Regel) allerdings ein anderer BIC definiert',
  23 => 'ok, für die BIC-Bestimmung der ehemaligen Hypo-Bank für IBAN wird i.A. zusätzlich die Kontonummer benötigt',
  24 => 'ok, die Kontonummer wurde ersetzt, die neue Kontonummer hat keine Prüfziffer',
  25 => 'ok, es wurde ein (weggelassenes) Unterkonto angefügt',
  26 => 'ok, für den BIC wurde die Zweigstellennummer allerdings durch XXX ersetzt',
  27 => 'ok, für den BIC wurde die Extension XXX angehängt',
  28 => 'ok, für den BIC wurde die Wildcard-Version (8stellig) benutzt',

'NO_SCL_BLOCKS_LOADED'                   => 'die SCL-Blocks wurden noch nicht eingelesen',
'NO_SCL_INFO_BLOCK'                      => 'Der Info-Block des SCL-Verzeichnisses wurde noch nicht eingelesen',
'SCL_BIC_NOT_FOUND'                      => 'Der BIC wurde im SCL-Verzeichnis nicht gefunden',
'INVALID_SCL_INFO_BLOCK'                 => 'Ungültiger SCL-Info-Block in der LUT-Datei',
'NO_SCL_BLOCKS'                          => 'Keine SCL-Blocks in der LUT-Datei enthalten',
'SCL_INPUT_FORMAT_ERROR'                 => 'Ungültige Eingabewerte in der SCL-Datei',
'INVALID_REGULAR_EXPRESSION_CNT'         => 'Ungültiger Zähler in regulärem Ausdruck (innerhalb von {})',
'INVALID_REGULAR_EXPRESSION'             => 'Ungültiger regulärer Ausdruck (enthält zwei Zeichen aus [+?*] nacheinander)',
'INVALID_HANDLE'                         => 'Ungültiges Handle angegeben',
'INVALID_BIQ_INDEX'                      => 'Ungültiger Index für die biq_*() Funktionen',
'ARRAY_INDEX_OUT_OF_RANGE'               => 'Der Array-Index liegt außerhalb des gültigen Bereichs',
'IBAN_ONLY_GERMAN'                       => 'Es werden nur deutsche IBANs unterstützt',
'INVALID_PARAMETER_TYPE'                 => 'Falscher Parametertyp für die Funktion',
'BIC_ONLY_GERMAN'                        => 'Es werden nur deutsche BICs unterstützt',
'INVALID_BIC_LENGTH'                     => 'Die Länge des BIC muß genau 8 oder 11 Zeichen sein',
'IBAN_CHKSUM_OK_RULE_IGNORED_BLZ'        => 'Die IBAN-Prüfsumme stimmt, die BLZ sollte aber durch eine zentrale BLZ ersetzt werden. Die Richtigkeit der IBAN kann nur mit einer Anfrage bei der Bank ermittelt werden',
'IBAN_CHKSUM_OK_KC_NOT_INITIALIZED'      => 'Die IBAN-Prüfsumme stimmt, konto_check wurde jedoch noch nicht initialisiert (Kontoprüfung nicht möglich)',
'IBAN_CHKSUM_OK_BLZ_INVALID'             => 'Die IBAN-Prüfsumme stimmt, die BLZ ist allerdings ungültig',
'IBAN_CHKSUM_OK_NACHFOLGE_BLZ_DEFINED'   => 'Die IBAN-Prüfsumme stimmt, für die Bank gibt es allerdings eine (andere) Nachfolge-BLZ',
'LUT2_NOT_ALL_IBAN_BLOCKS_LOADED'        => 'es konnten nicht alle Datenblocks die für die IBAN-Berechnung notwendig sind geladen werden',
'LUT2_NOT_YET_VALID_PARTIAL_OK'          => 'Der Datensatz ist noch nicht gültig, außerdem konnten nicht alle Blocks geladen werden',
'LUT2_NO_LONGER_VALID_PARTIAL_OK'        => 'Der Datensatz ist nicht mehr gültig, außerdem konnten nicht alle Blocks geladen werdeng',
'LUT2_BLOCKS_MISSING'                    => 'ok, bei der Initialisierung konnten allerdings ein oder mehrere Blocks nicht geladen werden',
'FALSE_UNTERKONTO_ATTACHED'              => 'falsch, es wurde ein Unterkonto hinzugefügt (IBAN-Regel)',
'BLZ_BLACKLISTED'                        => 'Die BLZ findet sich in der Ausschlussliste für IBAN-Berechnungen',
'BLZ_MARKED_AS_DELETED'                  => 'Die BLZ ist in der Bundesbank-Datei als gelöscht markiert und somit ungültig',
'IBAN_CHKSUM_OK_SOMETHING_WRONG'         => 'Die IBAN-Prüfsumme stimmt, es gibt allerdings einen Fehler in der eigenen IBAN-Bestimmung (wahrscheinlich falsch)',
'IBAN_CHKSUM_OK_NO_IBAN_CALCULATION'     => 'Die IBAN-Prüfsumme stimmt. Die Bank gibt IBANs nach nicht veröffentlichten Regeln heraus, die Richtigkeit der IBAN kann nur mit einer Anfrage bei der Bank ermittelt werden',
'IBAN_CHKSUM_OK_RULE_IGNORED'            => 'Die IBAN-Prüfsumme stimmt, es wurde allerdings eine IBAN-Regel nicht beachtet (wahrscheinlich falsch)',
'IBAN_CHKSUM_OK_UNTERKTO_MISSING'        => 'Die IBAN-Prüfsumme stimmt, es fehlt aber ein Unterkonto (wahrscheinlich falsch)',
'IBAN_INVALID_RULE'                      => 'Die BLZ passt nicht zur angegebenen IBAN-Regel',
'IBAN_AMBIGUOUS_KTO'                     => 'Die Kontonummer ist nicht eindeutig (es gibt mehrere Möglichkeiten)',
'IBAN_RULE_NOT_IMPLEMENTED'              => 'Die IBAN-Regel ist noch nicht implementiert',
'IBAN_RULE_UNKNOWN'                      => 'Die IBAN-Regel ist nicht bekannt',
'NO_IBAN_CALCULATION'                    => 'Für die Bankverbindung ist keine IBAN-Berechnung erlaubt',
'OLD_BLZ_OK_NEW_NOT'                     => 'Die Bankverbindung ist mit der alten BLZ stimmig, mit der Nachfolge-BLZ nicht',
'LUT2_IBAN_REGEL_NOT_INITIALIZED'        => 'Das Feld IBAN-Regel wurde nicht initialisiert',
'INVALID_IBAN_LENGTH'                    => 'Die Länge der IBAN für das angegebene Länderkürzel ist falsch',
'LUT2_NO_ACCOUNT_GIVEN'                  => 'Keine Bankverbindung/IBAN angegeben',
'LUT2_VOLLTEXT_INVALID_CHAR'             => 'Ungültiges Zeichen ( ()+-/&.,\' ) für die Volltextsuche gefunden',
'LUT2_VOLLTEXT_SINGLE_WORD_ONLY'         => 'Die Volltextsuche sucht jeweils nur ein einzelnes Wort, benutzen Sie lut_suche_multiple() zur Suche nach mehreren Worten',
'LUT_SUCHE_INVALID_RSC'                  => 'die angegebene Suchresource ist ungültig',
'LUT_SUCHE_INVALID_CMD'                  => 'bei der Suche sind im Verknüpfungsstring nur die Zeichen a-z sowie + und - erlaubt',
'LUT_SUCHE_INVALID_CNT'                  => 'bei der Suche müssen zwischen 1 und 26 Suchmuster angegeben werden',
'LUT2_VOLLTEXT_NOT_INITIALIZED'          => 'Das Feld Volltext wurde nicht initialisiert',
'NO_OWN_IBAN_CALCULATION'                => 'das Institut erlaubt keine eigene IBAN-Berechnung',
'KTO_CHECK_UNSUPPORTED_COMPRESSION'      => 'die notwendige Kompressions-Bibliothek wurde beim Kompilieren nicht eingebunden',
'KTO_CHECK_INVALID_COMPRESSION_LIB'      => 'der angegebene Wert für die Default-Kompression ist ungültig',
'OK_UNTERKONTO_ATTACHED_OLD'             => '(nicht mehr als Fehler, sondern positive Ausgabe - Dummy für den alten Wert)',
'KTO_CHECK_DEFAULT_BLOCK_INVALID'        => 'Ungültige Signatur im Default-Block',
'KTO_CHECK_DEFAULT_BLOCK_FULL'           => 'Die maximale Anzahl Einträge für den Default-Block wurde erreicht',
'KTO_CHECK_NO_DEFAULT_BLOCK'             => 'Es wurde noch kein Default-Block angelegt',
'KTO_CHECK_KEY_NOT_FOUND'                => 'Der angegebene Schlüssel wurde im Default-Block nicht gefunden',
'LUT2_NO_LONGER_VALID_BETTER'            => 'Beide Datensätze sind nicht mehr gültig, dieser ist aber jünger als der andere',
'INVALID_SEARCH_RANGE'                   => 'ungültiger Suchbereich angegeben (unten>oben)',
'KEY_NOT_FOUND'                          => 'Die Suche lieferte kein Ergebnis',
'BAV_FALSE'                              => 'BAV denkt, das Konto ist falsch (konto_check hält es für richtig)',
'LUT2_NO_USER_BLOCK'                     => 'User-Blocks müssen einen Typ > 500 haben',
'INVALID_SET'                            => 'für ein LUT-Set sind nur die Werte 0, 1 oder 2 möglich',
'NO_GERMAN_BIC'                          => 'Ein Konto kann kann nur für deutsche Banken geprüft werden',
'IPI_CHECK_INVALID_LENGTH'               => 'Der zu validierende strukturierete Verwendungszweck muß genau 20 Zeichen enthalten',
'IPI_INVALID_CHARACTER'                  => 'Im strukturierten Verwendungszweck dürfen nur alphanumerische Zeichen vorkommen',
'IPI_INVALID_LENGTH'                     => 'Die Länge des IPI-Verwendungszwecks darf maximal 18 Byte sein',
'LUT1_FILE_USED'                         => 'Es wurde eine LUT-Datei im Format 1.0/1.1 geladen',
'MISSING_PARAMETER'                      => 'Für die aufgerufene Funktion fehlt ein notwendiger Parameter',
'IBAN2BIC_ONLY_GERMAN'                   => 'Die Funktion iban2bic() arbeitet nur mit deutschen Bankleitzahlen',
'IBAN_OK_KTO_NOT'                        => 'Die Prüfziffer der IBAN stimmt, die der Kontonummer nicht',
'KTO_OK_IBAN_NOT'                        => 'Die Prüfziffer der Kontonummer stimmt, die der IBAN nicht',
'TOO_MANY_SLOTS'                         => 'Es sind nur maximal 500 Slots pro LUT-Datei möglich (Neukompilieren erforderlich)',
'INIT_FATAL_ERROR'                       => 'Initialisierung fehlgeschlagen (init_wait geblockt)',
'INCREMENTAL_INIT_NEEDS_INFO'            => 'Ein inkrementelles Initialisieren benötigt einen Info-Block in der LUT-Datei',
'INCREMENTAL_INIT_FROM_DIFFERENT_FILE'   => 'Ein inkrementelles Initialisieren mit einer anderen LUT-Datei ist nicht möglich',
'DEBUG_ONLY_FUNCTION'                    => 'Die Funktion ist nur in der Debug-Version vorhanden',
'LUT2_INVALID'                           => 'Kein Datensatz der LUT-Datei ist aktuell gültig',
'LUT2_NOT_YET_VALID'                     => 'Der Datensatz ist noch nicht gültig',
'LUT2_NO_LONGER_VALID'                   => 'Der Datensatz ist nicht mehr gültig',
'LUT2_GUELTIGKEIT_SWAPPED'               => 'Im Gültigkeitsdatum sind Anfangs- und Enddatum vertauscht',
'LUT2_INVALID_GUELTIGKEIT'               => 'Das angegebene Gültigkeitsdatum ist ungültig (Sollformat ist JJJJMMTT-JJJJMMTT)',
'LUT2_INDEX_OUT_OF_RANGE'                => 'Der Index für die Filiale ist ungültig',
'LUT2_INIT_IN_PROGRESS'                  => 'Die Bibliothek wird gerade neu initialisiert',
'LUT2_BLZ_NOT_INITIALIZED'               => 'Das Feld BLZ wurde nicht initialisiert',
'LUT2_FILIALEN_NOT_INITIALIZED'          => 'Das Feld Filialen wurde nicht initialisiert',
'LUT2_NAME_NOT_INITIALIZED'              => 'Das Feld Bankname wurde nicht initialisiert',
'LUT2_PLZ_NOT_INITIALIZED'               => 'Das Feld PLZ wurde nicht initialisiert',
'LUT2_ORT_NOT_INITIALIZED'               => 'Das Feld Ort wurde nicht initialisiert',
'LUT2_NAME_KURZ_NOT_INITIALIZED'         => 'Das Feld Kurzname wurde nicht initialisiert',
'LUT2_PAN_NOT_INITIALIZED'               => 'Das Feld PAN wurde nicht initialisiert',
'LUT2_BIC_NOT_INITIALIZED'               => 'Das Feld BIC wurde nicht initialisiert',
'LUT2_PZ_NOT_INITIALIZED'                => 'Das Feld Prüfziffer wurde nicht initialisiert',
'LUT2_NR_NOT_INITIALIZED'                => 'Das Feld NR wurde nicht initialisiert',
'LUT2_AENDERUNG_NOT_INITIALIZED'         => 'Das Feld Änderung wurde nicht initialisiert',
'LUT2_LOESCHUNG_NOT_INITIALIZED'         => 'Das Feld Löschung wurde nicht initialisiert',
'LUT2_NACHFOLGE_BLZ_NOT_INITIALIZED'     => 'Das Feld Nachfolge-BLZ wurde nicht initialisiert',
'LUT2_NOT_INITIALIZED'                   => 'die Programmbibliothek wurde noch nicht initialisiert',
'LUT2_FILIALEN_MISSING'                  => 'der Block mit der Filialenanzahl fehlt in der LUT-Datei',
'LUT2_PARTIAL_OK'                        => 'es wurden nicht alle Blocks geladen',
'LUT2_Z_BUF_ERROR'                       => 'Buffer error in den ZLIB Routinen',
'LUT2_Z_MEM_ERROR'                       => 'Memory error in den ZLIB-Routinen',
'LUT2_Z_DATA_ERROR'                      => 'Datenfehler im komprimierten LUT-Block',
'LUT2_BLOCK_NOT_IN_FILE'                 => 'Der Block ist nicht in der LUT-Datei enthalten',
'LUT2_DECOMPRESS_ERROR'                  => 'Fehler beim Dekomprimieren eines LUT-Blocks',
'LUT2_COMPRESS_ERROR'                    => 'Fehler beim Komprimieren eines LUT-Blocks',
'LUT2_FILE_CORRUPTED'                    => 'Die LUT-Datei ist korrumpiert',
'LUT2_NO_SLOT_FREE'                      => 'Im Inhaltsverzeichnis der LUT-Datei ist kein Slot mehr frei',
'UNDEFINED_SUBMETHOD'                    => 'Die (Unter)Methode ist nicht definiert',
'EXCLUDED_AT_COMPILETIME'                => 'Der benötigte Programmteil wurde beim Kompilieren deaktiviert',
'INVALID_LUT_VERSION'                    => 'Die Versionsnummer für die LUT-Datei ist ungültig',
'INVALID_PARAMETER_STELLE1'              => 'ungültiger Prüfparameter (erste zu prüfende Stelle)',
'INVALID_PARAMETER_COUNT'                => 'ungültiger Prüfparameter (Anzahl zu prüfender Stellen)',
'INVALID_PARAMETER_PRUEFZIFFER'          => 'ungültiger Prüfparameter (Position der Prüfziffer)',
'INVALID_PARAMETER_WICHTUNG'             => 'ungültiger Prüfparameter (Wichtung)',
'INVALID_PARAMETER_METHODE'              => 'ungültiger Prüfparameter (Rechenmethode)',
'LIBRARY_INIT_ERROR'                     => 'Problem beim Initialisieren der globalen Variablen',
'LUT_CRC_ERROR'                          => 'Prüfsummenfehler in der blz.lut Datei',
'FALSE_GELOESCHT'                        => 'falsch (die BLZ wurde außerdem gelöscht)',
'OK_NO_CHK_GELOESCHT'                    => 'ok, ohne Prüfung (die BLZ wurde allerdings gelöscht)',
'OK_GELOESCHT'                           => 'ok (die BLZ wurde allerdings gelöscht)',
'BLZ_GELOESCHT'                          => 'die Bankleitzahl wurde gelöscht',
'INVALID_BLZ_FILE'                       => 'Fehler in der blz.txt Datei (falsche Zeilenlänge)',
'LIBRARY_IS_NOT_THREAD_SAFE'             => 'undefinierte Funktion, die library wurde mit THREAD_SAFE=0 kompiliert',
'FATAL_ERROR'                            => 'schwerer Fehler im Konto_check-Modul',
'INVALID_KTO_LENGTH'                     => 'ein Konto muß zwischen 1 und 10 Stellen haben',
'FILE_WRITE_ERROR'                       => 'kann Datei nicht schreiben',
'FILE_READ_ERROR'                        => 'kann Datei nicht lesen',
'ERROR_MALLOC'                           => 'kann keinen Speicher allokieren',
'NO_BLZ_FILE'                            => 'die blz.txt Datei wurde nicht gefunden',
'INVALID_LUT_FILE'                       => 'die blz.lut Datei ist inkosistent/ungültig',
'NO_LUT_FILE'                            => 'die blz.lut Datei wurde nicht gefunden',
'INVALID_BLZ_LENGTH'                     => 'die Bankleitzahl ist nicht achtstellig',
'INVALID_BLZ'                            => 'die Bankleitzahl ist ungültig',
'INVALID_KTO'                            => 'das Konto ist ungültig',
'NOT_IMPLEMENTED'                        => 'die Methode wurde noch nicht implementiert',
'NOT_DEFINED'                            => 'die Methode ist nicht definiert',
'FALSE'                                  => 'falsch',
'OK'                                     => 'ok',
'OK_NO_CHK'                              => 'ok, ohne Prüfung',
'OK_TEST_BLZ_USED'                       => 'ok, für den Test wurde eine Test-BLZ verwendet',
'LUT2_VALID'                             => 'Der Datensatz ist aktuell gültig',
'LUT2_NO_VALID_DATE'                     => 'Der Datensatz enthält kein Gültigkeitsdatum',
'LUT1_SET_LOADED'                        => 'Die Datei ist im alten LUT-Format (1.0/1.1)',
'LUT1_FILE_GENERATED'                    => 'ok, es wurde allerdings eine LUT-Datei im alten Format (1.0/1.1) generiert',
'LUT_V2_FILE_GENERATED'                  => 'ok, es wurde allerdings eine LUT-Datei im Format 2.0 generiert (Compilerswitch)',
'KTO_CHECK_VALUE_REPLACED'               => 'ok, der Wert für den Schlüssel wurde überschrieben',
'OK_UNTERKONTO_POSSIBLE'                 => 'wahrscheinlich ok, die Kontonummer kann allerdings (nicht angegebene) Unterkonten enthalten',
'OK_UNTERKONTO_GIVEN'                    => 'wahrscheinlich ok, die Kontonummer enthält eine Unterkontonummer',
'OK_SLOT_CNT_MIN_USED'                   => 'ok, die Anzahl Slots wurde auf SLOT_CNT_MIN (60) hochgesetzt',
'SOME_KEYS_NOT_FOUND'                    => 'ok, ein(ige) Schlüssel wurden nicht gefunden',
'LUT2_KTO_NOT_CHECKED'                   => 'Die Bankverbindung wurde nicht getestet',
'LUT2_OK_WITHOUT_IBAN_RULES'             => 'Es wurden fast alle Blocks (außer den IBAN-Regeln) geladen',
'OK_NACHFOLGE_BLZ_USED'                  => 'ok, für die BLZ wurde allerdings die Nachfolge-BLZ eingesetzt',
'OK_KTO_REPLACED'                        => 'ok, die Kontonummer wurde allerdings ersetzt',
'OK_BLZ_REPLACED'                        => 'ok, die Bankleitzahl wurde allerdings ersetzt',
'OK_BLZ_KTO_REPLACED'                    => 'ok, die Bankleitzahl und Kontonummer wurden allerdings ersetzt',
'OK_IBAN_WITHOUT_KC_TEST'                => 'ok, die Bankverbindung ist (ohne Test) als richtig anzusehen',
'OK_INVALID_FOR_IBAN'                    => 'ok, für die die IBAN ist (durch eine Regel) allerdings ein anderer BIC definiert',
'OK_HYPO_REQUIRES_KTO'                   => 'ok, für die BIC-Bestimmung der ehemaligen Hypo-Bank für IBAN wird i.A. zusätzlich die Kontonummer benötigt',
'OK_KTO_REPLACED_NO_PZ'                  => 'ok, die Kontonummer wurde ersetzt, die neue Kontonummer hat keine Prüfziffer',
'OK_UNTERKONTO_ATTACHED'                 => 'ok, es wurde ein (weggelassenes) Unterkonto angefügt',
'OK_SHORT_BIC_USED'                      => 'ok, für den BIC wurde die Zweigstellennummer allerdings durch XXX ersetzt',
'OK_SCL_EXTENSION_BIC_USED'              => 'ok, für den BIC wurde die Extension XXX angehängt',
'OK_SCL_WILDCARD_BIC_USED'               => 'ok, für den BIC wurde die Wildcard-Version (8stellig) benutzt',
);

%Business::KontoCheck::kto_retval_kurz = (
-158 => 'NO_SCL_BLOCKS_LOADED',
-157 => 'NO_SCL_INFO_BLOCK',
-156 => 'SCL_BIC_NOT_FOUND',
-155 => 'INVALID_SCL_INFO_BLOCK',
-154 => 'NO_SCL_BLOCKS',
-153 => 'SCL_INPUT_FORMAT_ERROR',
-152 => 'INVALID_REGULAR_EXPRESSION_CNT',
-151 => 'INVALID_REGULAR_EXPRESSION',
-150 => 'INVALID_HANDLE',
-149 => 'INVALID_BIQ_INDEX',
-148 => 'ARRAY_INDEX_OUT_OF_RANGE',
-147 => 'IBAN_ONLY_GERMAN',
-146 => 'INVALID_PARAMETER_TYPE',
-145 => 'BIC_ONLY_GERMAN',
-144 => 'INVALID_BIC_LENGTH',
-143 => 'IBAN_CHKSUM_OK_RULE_IGNORED_BLZ',
-142 => 'IBAN_CHKSUM_OK_KC_NOT_INITIALIZED',
-141 => 'IBAN_CHKSUM_OK_BLZ_INVALID',
-140 => 'IBAN_CHKSUM_OK_NACHFOLGE_BLZ_DEFINED',
-139 => 'LUT2_NOT_ALL_IBAN_BLOCKS_LOADED',
-138 => 'LUT2_NOT_YET_VALID_PARTIAL_OK',
-137 => 'LUT2_NO_LONGER_VALID_PARTIAL_OK',
-136 => 'LUT2_BLOCKS_MISSING',
-135 => 'FALSE_UNTERKONTO_ATTACHED',
-134 => 'BLZ_BLACKLISTED',
-133 => 'BLZ_MARKED_AS_DELETED',
-132 => 'IBAN_CHKSUM_OK_SOMETHING_WRONG',
-131 => 'IBAN_CHKSUM_OK_NO_IBAN_CALCULATION',
-130 => 'IBAN_CHKSUM_OK_RULE_IGNORED',
-129 => 'IBAN_CHKSUM_OK_UNTERKTO_MISSING',
-128 => 'IBAN_INVALID_RULE',
-127 => 'IBAN_AMBIGUOUS_KTO',
-126 => 'IBAN_RULE_NOT_IMPLEMENTED',
-125 => 'IBAN_RULE_UNKNOWN',
-124 => 'NO_IBAN_CALCULATION',
-123 => 'OLD_BLZ_OK_NEW_NOT',
-122 => 'LUT2_IBAN_REGEL_NOT_INITIALIZED',
-121 => 'INVALID_IBAN_LENGTH',
-120 => 'LUT2_NO_ACCOUNT_GIVEN',
-119 => 'LUT2_VOLLTEXT_INVALID_CHAR',
-118 => 'LUT2_VOLLTEXT_SINGLE_WORD_ONLY',
-117 => 'LUT_SUCHE_INVALID_RSC',
-116 => 'LUT_SUCHE_INVALID_CMD',
-115 => 'LUT_SUCHE_INVALID_CNT',
-114 => 'LUT2_VOLLTEXT_NOT_INITIALIZED',
-113 => 'NO_OWN_IBAN_CALCULATION',
-112 => 'KTO_CHECK_UNSUPPORTED_COMPRESSION',
-111 => 'KTO_CHECK_INVALID_COMPRESSION_LIB',
-110 => 'OK_UNTERKONTO_ATTACHED_OLD',
-109 => 'KTO_CHECK_DEFAULT_BLOCK_INVALID',
-108 => 'KTO_CHECK_DEFAULT_BLOCK_FULL',
-107 => 'KTO_CHECK_NO_DEFAULT_BLOCK',
-106 => 'KTO_CHECK_KEY_NOT_FOUND',
-105 => 'LUT2_NO_LONGER_VALID_BETTER',
 -79 => 'INVALID_SEARCH_RANGE',
 -78 => 'KEY_NOT_FOUND',
 -77 => 'BAV_FALSE',
 -76 => 'LUT2_NO_USER_BLOCK',
 -75 => 'INVALID_SET',
 -74 => 'NO_GERMAN_BIC',
 -73 => 'IPI_CHECK_INVALID_LENGTH',
 -72 => 'IPI_INVALID_CHARACTER',
 -71 => 'IPI_INVALID_LENGTH',
 -70 => 'LUT1_FILE_USED',
 -69 => 'MISSING_PARAMETER',
 -68 => 'IBAN2BIC_ONLY_GERMAN',
 -67 => 'IBAN_OK_KTO_NOT',
 -66 => 'KTO_OK_IBAN_NOT',
 -65 => 'TOO_MANY_SLOTS',
 -64 => 'INIT_FATAL_ERROR',
 -63 => 'INCREMENTAL_INIT_NEEDS_INFO',
 -62 => 'INCREMENTAL_INIT_FROM_DIFFERENT_FILE',
 -61 => 'DEBUG_ONLY_FUNCTION',
 -60 => 'LUT2_INVALID',
 -59 => 'LUT2_NOT_YET_VALID',
 -58 => 'LUT2_NO_LONGER_VALID',
 -57 => 'LUT2_GUELTIGKEIT_SWAPPED',
 -56 => 'LUT2_INVALID_GUELTIGKEIT',
 -55 => 'LUT2_INDEX_OUT_OF_RANGE',
 -54 => 'LUT2_INIT_IN_PROGRESS',
 -53 => 'LUT2_BLZ_NOT_INITIALIZED',
 -52 => 'LUT2_FILIALEN_NOT_INITIALIZED',
 -51 => 'LUT2_NAME_NOT_INITIALIZED',
 -50 => 'LUT2_PLZ_NOT_INITIALIZED',
 -49 => 'LUT2_ORT_NOT_INITIALIZED',
 -48 => 'LUT2_NAME_KURZ_NOT_INITIALIZED',
 -47 => 'LUT2_PAN_NOT_INITIALIZED',
 -46 => 'LUT2_BIC_NOT_INITIALIZED',
 -45 => 'LUT2_PZ_NOT_INITIALIZED',
 -44 => 'LUT2_NR_NOT_INITIALIZED',
 -43 => 'LUT2_AENDERUNG_NOT_INITIALIZED',
 -42 => 'LUT2_LOESCHUNG_NOT_INITIALIZED',
 -41 => 'LUT2_NACHFOLGE_BLZ_NOT_INITIALIZED',
 -40 => 'LUT2_NOT_INITIALIZED',
 -39 => 'LUT2_FILIALEN_MISSING',
 -38 => 'LUT2_PARTIAL_OK',
 -37 => 'LUT2_Z_BUF_ERROR',
 -36 => 'LUT2_Z_MEM_ERROR',
 -35 => 'LUT2_Z_DATA_ERROR',
 -34 => 'LUT2_BLOCK_NOT_IN_FILE',
 -33 => 'LUT2_DECOMPRESS_ERROR',
 -32 => 'LUT2_COMPRESS_ERROR',
 -31 => 'LUT2_FILE_CORRUPTED',
 -30 => 'LUT2_NO_SLOT_FREE',
 -29 => 'UNDEFINED_SUBMETHOD',
 -28 => 'EXCLUDED_AT_COMPILETIME',
 -27 => 'INVALID_LUT_VERSION',
 -26 => 'INVALID_PARAMETER_STELLE1',
 -25 => 'INVALID_PARAMETER_COUNT',
 -24 => 'INVALID_PARAMETER_PRUEFZIFFER',
 -23 => 'INVALID_PARAMETER_WICHTUNG',
 -22 => 'INVALID_PARAMETER_METHODE',
 -21 => 'LIBRARY_INIT_ERROR',
 -20 => 'LUT_CRC_ERROR',
 -19 => 'FALSE_GELOESCHT',
 -18 => 'OK_NO_CHK_GELOESCHT',
 -17 => 'OK_GELOESCHT',
 -16 => 'BLZ_GELOESCHT',
 -15 => 'INVALID_BLZ_FILE',
 -14 => 'LIBRARY_IS_NOT_THREAD_SAFE',
 -13 => 'FATAL_ERROR',
 -12 => 'INVALID_KTO_LENGTH',
 -11 => 'FILE_WRITE_ERROR',
 -10 => 'FILE_READ_ERROR',
  -9 => 'ERROR_MALLOC',
  -8 => 'NO_BLZ_FILE',
  -7 => 'INVALID_LUT_FILE',
  -6 => 'NO_LUT_FILE',
  -5 => 'INVALID_BLZ_LENGTH',
  -4 => 'INVALID_BLZ',
  -3 => 'INVALID_KTO',
  -2 => 'NOT_IMPLEMENTED',
  -1 => 'NOT_DEFINED',
   0 => 'FALSE',
   1 => 'OK',
   2 => 'OK_NO_CHK',
   3 => 'OK_TEST_BLZ_USED',
   4 => 'LUT2_VALID',
   5 => 'LUT2_NO_VALID_DATE',
   6 => 'LUT1_SET_LOADED',
   7 => 'LUT1_FILE_GENERATED',
   9 => 'LUT_V2_FILE_GENERATED',
  10 => 'KTO_CHECK_VALUE_REPLACED',
  11 => 'OK_UNTERKONTO_POSSIBLE',
  12 => 'OK_UNTERKONTO_GIVEN',
  13 => 'OK_SLOT_CNT_MIN_USED',
  14 => 'SOME_KEYS_NOT_FOUND',
  15 => 'LUT2_KTO_NOT_CHECKED',
  16 => 'LUT2_OK_WITHOUT_IBAN_RULES',
  17 => 'OK_NACHFOLGE_BLZ_USED',
  18 => 'OK_KTO_REPLACED',
  19 => 'OK_BLZ_REPLACED',
  20 => 'OK_BLZ_KTO_REPLACED',
  21 => 'OK_IBAN_WITHOUT_KC_TEST',
  22 => 'OK_INVALID_FOR_IBAN',
  23 => 'OK_HYPO_REQUIRES_KTO',
  24 => 'OK_KTO_REPLACED_NO_PZ',
  25 => 'OK_UNTERKONTO_ATTACHED',
  26 => 'OK_SHORT_BIC_USED',
  27 => 'OK_SCL_EXTENSION_BIC_USED',
  28 => 'OK_SCL_WILDCARD_BIC_USED',
);

END{ lut_cleanup(); }

1;
__END__

=encoding ISO8859-1

=head1 NAME

Business::KontoCheck - Perl extension for checking German and Austrian Bank Account Numbers

=head1 NOTE

Because the module is for use mainly in Germany, the following documentation
language is german too.

=head1 SYNOPSIS

   use Business::KontoCheck;
   use Business::KontoCheck qw( kto_check lut_name lut_blz lut_ort %kto_retval [...] );

   $retval=lut_init([$lut_name[,$required[,$set]]]);
   $retval=kto_check_init($lut_name[,$required[,$set[,$incremental]]]);
   $retval=lut_blocks([$mode[,$filename[,$blocks_ok[,$blocks_fehler]]]);
   $retval=kto_check($blz,$kto,$lut_name);
   $retval=kto_check_str($blz,$kto,$lut_name);
   $retval=kto_check_blz($blz,$kto);
   $retval=kto_check_pz($pz,$kto,$blz);
   $retval=kto_check_regel($blz,$kto);
   $retval=pz_aenderungen_enable($set);

   $retval=generate_lut($inputname,$outputname,$user_info,$lut_version);
   $retval=generate_lut2($inputname,$outputname[,$user_info[,$gueltigkeit[,$felder[,$filialen[,$slots[,$lut_version[,$set]]]]]]]);
   $retval=rebuild_blzfile($inputname,$outputname,$set);

   [$@]retval=lut_blz($blz[,$offset[,$ret]]);
   [$@]retval=lut_info($lut_name);
   [$@]retval=lut_filialen($blz[,$offset[,$ret]]);
   [$@]retval=lut_name($blz[,$offset[,$ret]]);
   [$@]retval=lut_name_kurz($blz[,$offset[,$ret]]);
   [$@]retval=lut_plz($blz[,$offset[,$ret]]);
   [$@]retval=lut_ort($blz[,$offset[,$ret]]);
   [$@]retval=lut_pan($blz[,$offset[,$ret]]);
   [$@]retval=lut_bic($blz[,$offset[,$ret]]);
   [$@]retval=lut_pz($blz[,$offset[,$ret]]);
   [$@]retval=lut_aenderung($blz[,$offset[,$ret]]);
   [$@]retval=lut_loeschung($blz[,$offset[,$ret]]);
   [$@]retval=lut_nachfolge_blz($blz[,$offset[,$ret]]);
   [$@]retval=lut_iban_regel($blz[,$offset[,$ret]]);

   $retval=lut_valid();
   $ret=pz2str($pz[,$ret]);

   [$@]ret=lut_suche_bic($bic[,$retval]);
   [$@]ret=lut_suche_namen($namen[,$retval]);
   [$@]ret=lut_suche_namen_kurz($namen_kurz]);
   [$@]ret=lut_suche_ort($ort[,$retval]);
   [$@]ret=lut_suche_blz($blz1[,$blz2[,$retval]]);
   [$@]ret=lut_suche_pz($pz1[,$pz2[,$retval]]);
   [$@]ret=lut_suche_plz($plz1[,$plz2[,$retval]]);
   [$@]ret=lut_suche_regel($regel1[,$regel2[,$retval]]);
   [$@]ret=lut_suche_volltext($suchworte[,$retval]);
   [$@]ret=lut_suche_multiple($suchworte[,$uniq[,$such_cmd[,$retval]]]);

   $retval=copy_lutfile($old_name,$new_name,$new_slots);
   $retval=dump_lutfile($outputname,$felder);
   $retval=lut_cleanup();

   $retval=ci_check($ci);
   $retval=bic_check($bic[,$cnt]);
   $retval=iban_check($iban[,$ret_kc]);
   [$@]retval=iban2bic($iban);
   [$@]retval=iban_gen($blz,$kto);

   $enc=kto_check_encoding($encoding);
   $enc_str=kto_check_encoding_str($encoding);
   $keep=keep_raw_data($flag);
   $retval=retval2txt($retval);
   $retval=retval2txt_short($retval);
   $retval=retval2iso($retval);
   $retval=retval2html($retval);
   $retval=retval2utf8($retval);
   $retval=retval2dos($retval);
   $retval=kto_check_retval2txt($retval);
   $retval=kto_check_retval2txt_short($retval);
   $retval=kto_check_retval2html($retval);
   $retval=kto_check_retval2utf8($retval);
   $retval=kto_check_retval2dos($retval);
   $retval_txt=$kto_retval{$retval};

   $retval=kto_check_at($blz,$kto,$lut_name);
   $retval=kto_check_at_str($blz,$kto,$lut_name);
   $retval=generate_lut_at($inputname,$outputname,$plain_name,$plain_format);

=head1 DESCRIPTION

Dies ist Business::KontoCheck, ein Programm zum Testen der Prüfziffern
von deutschen und österreichischen Bankkonten. Dies ist die Perl-
Version der C-Library (als XSUB Modul).

=head1 EXPORT

Es werden defaultmäßig die Funkionen kto_check und kto_check_str,
(aus dem deutschen Modul), kto_check_at, kto_check_at_str (aus
dem österreichischen Modul) sowie die Variable %kto_retval (für
beide Module) exportiert.

Optional können auch eine Reihe weiterer Funktionen exportiert werden;
diese müssen dann in der use Klausel anzugeben werden.

=head1 DESCRIPTION

  Funktion:  kto_check()
             kto_check_str()

  Aufgabe:   Testen eines Kontos

  Aufruf:    $retval=kto_check($blz,$kto,$lut_name);
             $retval=kto_check_str($blz,$kto,$lut_name);

  Parameter:
     $blz:      falls 2- oder 3-stellig: Prüfziffermethode
                (evl. mit Untermethode a, b, c... oder 1, 2, 3)
                falls 8-stellig: Bankleitzahl

     $kto:      Kontonummer (wird vor der Berechnung
                linksbündig mit Nullen auf 10 Stellen
                aufgefüllt)

     $lut_name: Dateiname der Lookup-Tabelle mit Bankleitzahlen.
                Falls NULL oder ein leerer String übergeben wird,
                wird der Dateiname blz.lut benutzt.
                Diese Datei enthält die Prüfziffermethoden für die
                einzelnen Bankleitzahlen; sie kann mit der Funktion
                generate_lut() aus der Bundesbanktabelle generiert
                werden.

  Rückgabewerte:
     Die Funktion kto_check gibt einen numerischen Wert zurück,
     während die Funktion kto_check_str einen kurzen String
     zurückgibt.

     Mittels des assoziativen Arrays %kto_retval lassen sich die
     numerischen Rückgabewerte in einen etwas ausführlicheren
     Rückgabetext umwandeln:

     $retval_txt=$kto_retval{$retval};

-------------------------------------------------------------------------

  Funktion:  generate_lut()      (LUT-Version 1.0 oder 1.1; obsolet)
             generate_lut2()     (LUT-Version 1.0, 1.1 oder 2.0)

  Aufgabe:   LUT-Datei generieren

  Aufruf: $retval=generate_lut($inputname,$outputname,$user_info,$lut_version);

          $retval=generate_lut2($inputname,$outputname[,$user_info[,$gueltigkeit
               [,$felder[,$filialen[,$slots[,$lut_version[,$set]]]]]]]);

  Parameter:
     inputname:   Name der Bankleitzahlendatei der Deutschen
                  Bundesbank (z.B. blz0303pc.txt)

     outputname:  Name der Zieldatei (z.B. blz.lut)

     user_info:   Info-Zeile, die zusätzlich in die LUT-Datei
                  geschrieben wird. Diese Zeile wird von der
                  Funktion get_lut_info() in zurückgegeben,
                  aber ansonsten nicht ausgewertet.

     lut_version: Format der LUT-Datei. Mögliche Werte:
                  1: altes Format (1.0)
                  2: altes Format (1.1) mit Infozeile
                  3: neues Format (2.0).

                  Die Werte 1 und 2 werden defaultmäßig nicht mehr
                  unterstützt, da sie komplett obsolet sind; falls
                  jemand eine Datei im alten Format generieren will,
                  muß in konto_check.h das Makro GENERATE_OLD_LUTFILE
                  auf 1 gesetzt werden. Andernfalls wird immer eine
                  Datei im neuen Format generiert.

   Die folgenden Parameter gelten nur für generate_lut2():

     gueltigkeit: Gültigkeitsbereich der LUT-Datei, im Format
                  JJJJMMTT-JJJJMMTT, z.B. 20120305-20120603

     felder:      (Integer, 0-9) Felder, die in die LUT-Datei
                  aufgenommen werden sollen. Folgende Felder werden
                  in die Datei aufgenommen (nicht aufgeführt, aber
                  immer dabei sind Infoblock, BLZ und Prüfziffer).
                  Name+Kn. steht dabei für einen Block, der Name und
                  Kurzname der Bank enthält; dieser läßt sich besser
                  komprimieren, als wenn die beiden Blocks getrennt
                  sind. Lfd.Nr. ist die laufende Nr. in der BLZ-Datei;
                  praktisch wird sie wohl nicht benötigt, ist aber zur
                  Vollständigkeit mit enthalten.

    0: (nur die drei Defaultblocks) (3 Slots)
    1: Name+Kn. (4 Slots)
    2: Name+Kn.,BIC (5 Slots)
    3: Name,PLZ,Ort (6 Slots)
    4: Name,PLZ,Ort,BIC (7 Slots)
    5: Name+Kn.,PLZ,Ort,BIC (7 Slots)
    6: Name+Kn.,PLZ,Ort,BIC,Nachfolge-BLZ (8 Slots)
    7: Name+Kn.,PLZ,Ort,BIC,Nachfolge-BLZ,Änderung (9 Slots)
    8: Name+Kn.,PLZ,Ort,BIC,Nachfolge-BLZ,Änderung,Löschung (10 Slots)
    9: Name+Kn.,PLZ,Ort,BIC,Nachfolge-BLZ,Änderung,Löschung,PAN,Lfd.Nr. (12 Slots)

     filialen:    Flag (0 oder 1), ob die Filialdaten ebenfalls
                  aufgenommen werden sollen.

     slots:       Anzahl Slots (mögliche Verzeichniseinträge) der
                  LUT-Datei. Für einen vollen Datensatz (felder=9)
                  werden 12 Slots benötigt; falls die Datei zwei
                  Datensätze enthalten soll, braucht man mindestens
                  24 Slots.

                  In konto_check.h ist das Makro SLOT_CNT_MIN
                  definiert, das die minimale Anzahl Slots angibt.
                  Falls beim Aufruf dieser Funktion weniger Slots
                  angegeben werden, erhält man den Rückgabewert
                  OK_SLOT_CNT_MIN_USED, und die Anzahl der Slots wird
                  auf den Minimalwert gesetzt. Falls nicht genügend
                  Slots verfügbar sind, um die Datei zu generieren,
                  wird der (Fehler-)Wert LUT2_NO_SLOT_FREE zurückgegeben.

     set:         (Integer, 0, 1 oder 2) Angabe, ob das primäre Set (0
                  bzw. 1) oder sekundäre Datensatz (2) geschrieben
                  werden soll. Falls für set 0 angegeben wird, wird
                  eine neue Datei angelegt, bei 1 und 2 wird der
                  Datensatz an eine vorhandene LUT-Datei angehängt.
                  Das setzt natürlich voraus, daß noch genügend
                  Verzeichnisslots vorhanden sind, um alle Blocks
                  schreiben zu können. Bei Bedarf kann mittels
                  copy_lutfile() die Anzahl der Verzeichnisslots auch
                  erhöht werden.

-------------------------------------------------------------------------

  Funktion:       rebuild_blzfile()

  Aufgabe:        aus einer LUT-Datei die entsprechende Bank-Datei generieren

  Aufruf:         $retval=rebuild_blzfile($inputname,$outputname,$set);

  Parameter:
     inputname:   Name der LUT-Datei (oder evl. einer BLZ-Datei der
                  Deutschen Bundesbank)

     outputname:  Name der Zieldatei (Klartext-Datei)

     set:         Set (0, 1 oder 2)
                  Falls der Parameter 1 oder 2 ist, wird das entsprechende
                  set der LUT-Datei im Klartext ausgegeben. Die Ausgabedatei
                  sollte (bis auf die vier Testbanken und evl. die Reihenfolge)
                  mit der ursprünglichen Bundesbank-Datei übereinstimmen.

                  Falls der Parameter set 0 ist, wird als Eingabedatei eine
                  BLZ-Datei der Deutschen Bundesbank erwartet; diese wird
                  zunächst in eine temporäre LUT-Datei umgewandelt, und die
                  LUT-Datei wieder zurück in die Klartextform. Dieser Aufruf
                  wurde ursprünglich für den Test der LUT-Routinen benutzt.

  Rückgabewerte:
      Die Funktion gibt einen numerischen Wert zurück, der Aufschluss über
      den Erfolg gibt. Die Rückgabe kann die folgenden Werte annehmen:

 -112  (KTO_CHECK_UNSUPPORTED_COMPRESSION) "die notwendige Kompressions-Bibliothek wurde beim Kompilieren nicht eingebunden"
  -64  (INIT_FATAL_ERROR)           "Initialisierung fehlgeschlagen (init_wait geblockt)"
  -57  (LUT2_GUELTIGKEIT_SWAPPED)   "Im Gültigkeitsdatum sind Anfangs- und Enddatum vertauscht"
  -56  (LUT2_INVALID_GUELTIGKEIT)   "Das angegebene Gültigkeitsdatum ist ungültig (Soll: JJJJMMTT-JJJJMMTT)"
  -38  (LUT2_PARTIAL_OK)            "es wurden nicht alle Blocks geladen"
  -36  (LUT2_Z_MEM_ERROR)           "Memory error in den ZLIB-Routinen"
  -35  (LUT2_Z_DATA_ERROR)          "Datenfehler im komprimierten LUT-Block"
  -34  (LUT2_BLOCK_NOT_IN_FILE)     "Der Block ist nicht in der LUT-Datei enthalten"
  -33  (LUT2_DECOMPRESS_ERROR)      "Fehler beim Dekomprimieren eines LUT-Blocks"
  -32  (LUT2_COMPRESS_ERROR)        "Fehler beim Komprimieren eines LUT-Blocks"
  -31  (LUT2_FILE_CORRUPTED)        "Die LUT-Datei ist korrumpiert"
  -20  (LUT_CRC_ERROR)              "Prüfsummenfehler in der blz.lut Datei"
  -15  (INVALID_BLZ_FILE)           "Fehler in der blz.txt Datei (falsche Zeilenlänge)"
  -13  (FATAL_ERROR)                "schwerer Fehler im Konto_check-Modul"
  -11  (FILE_WRITE_ERROR)           "kann Datei nicht schreiben"
  -10  (FILE_READ_ERROR)            "kann Datei nicht lesen"
   -9  (ERROR_MALLOC)               "kann keinen Speicher allokieren"
   -7  (INVALID_LUT_FILE)           "die blz.lut Datei ist inkosistent/ungültig"
   -6  (NO_LUT_FILE)                "die blz.lut Datei wurde nicht gefunden"
    1  (OK)                         "ok"

-------------------------------------------------------------------------

  Funktion:  lut_blz()
             lut_filialen()
             lut_name()
             lut_name_kurz()
             lut_plz()
             lut_ort()
             lut_pan()
             lut_bic()
             lut_pz()
             lut_aenderung()
             lut_loeschung()
             lut_nachfolge_blz()
             lut_iban_regel()

  Aufgabe:   Bestimmung von Feldern der BLZ-Datei

  Aufruf:    [$@]ret=lut_blz($blz[,$filiale[,$ret]])
             [$@]ret=lut_name($blz[,$filiale[,$ret]])
             [$@]ret=lut_name_kurz($blz[,$filiale[,$ret]])
             [$@]ret=lut_plz($blz[,$filiale[,$ret]])
             [$@]ret=lut_ort($blz[,$filiale[,$ret]])
             [$@]ret=lut_pan($blz[,$filiale[,$ret]])
             [$@]ret=lut_bic($blz[,$filiale[,$ret]])
             [$@]ret=lut_pz($blz[,$filiale[,$ret]])
             [$@]ret=lut_aenderung($blz[,$filiale[,$ret]])
             [$@]ret=lut_loeschung($blz[,$filiale[,$ret]])
             [$@]ret=lut_nachfolge_blz($blz[,$filiale[,$ret]])
             [$@]ret=lut_iban_regel($blz[,$filiale[,$ret]])
             $ret=pz2str($pz[,$ret])

   Die Funktionen bestimmen die diversen Felder der BLZ-Datei zu einer
   gegebenen BLZ. Falls der optionale Parameter $filiale angegeben
   wird, wird der Wert für eine Filiale bestimmt, ansonsten (und bei
   $filiale==0) der Wert der Hauptstelle. Die Anzahl der Filialen zu
   einer BLZ läßt sich mittels der Funktion $cnt=lut_filialen($blz)
   bestimmen.

   Die Funktion pz2str() wandelt eine numerische Prüfziffermethode
   (wie sie z.B. von lut_pz() zurückgegeben wird) in einen
   zweistelligen String um.

   Alle Funktionen (außer pz2str) lassen sich sowohl im skalaren als
   auch im Array-Kontext aufrufen. Bei Aufruf in skalarem Kontext wird
   der jeweilige Wert zurückgegeben; bei Aufruf im Array-Kontext wird
   außerdem noch der Rückgabestatus der Funktion als Zahl, String
   (lang) und String (kurz) zurückgegeben. Beispiel:

   $ret=lut_name("66090800") liefert für $ret den Wert "BBBank",
   @ret=lut_name("66090800") liefert ein Array mit den Werten
   @ret=("BBBank",1,"ok","OK")

   der Aufruf
   @ret=lut_name("660908") liefert ein Array mit den Werten
   @ret=("",-5,"die Bankleitzahl ist nicht achtstellig","INVALID_BLZ_LENGTH")

   Falls der Aufruf im Array-Kontext nicht gewünscht ist, gibt es noch
   alternative Funktionen, die nur in skalarem Kontext arbeiten: 

   -------------------------------------------------------------------------

  Funktion:  keep_raw_data
             kto_check_encoding
             kto_check_encoding_str

  Aufgabe:   Diese Funktionen setzen die Ausgabekodierung (sowohl für
      die Felder der LUT-Datei als auch für Statusmeldungen mit der
      Funktion kto_check_retval2txt()) fest.


  Aufruf:    $flag=keep_raw_data($flag)
             $encoding=kto_check_encoding($mode)
             $encoding_str=kto_check_encoding_str($mode)

    Diese Funktion legt den benutzten Zeichensatz für Fehlermeldungen
    durch die Funktion retval2txt() und einige Felder der LUT-Datei
    (Name, Kurzname, Ort) fest. Wenn die Funktion nicht aufgerufen
    wird, wird der Wert DEFAULT_ENCODING aus konto_check.h benutzt.

    _Achtung_: Das Verhalten der Funktionen hängt von dem Flag
    keep_raw_data_flag der C-Bibliothek ab. Falls das Flag gesetzt
    ist, werden die Rohdaten der Blocks Name, Kurzname und Ort im
    Speicher gehalten; bei einem Wechsel der Kodierung wird auch für
    diese Blocks die Kodierung umgesetzt. Falls das Flag nicht gesetzt
    ist, sollte die Funktion *vor* der Initialisierung aufgerufen
    werden, da in dem Fall die Daten der LUT-Datei nur bei der
    Initialisierung konvertiert werden. Mit der Funktion
    keep_raw_data() kann das Flag gesetzt oder gelöscht werden.

    Für den Parameter mode werden die folgenden Werte akzeptiert:

    1:   ISO-8859-1
    2:   UTF-8
    3:   HTML
    4:   DOS CP 850
    51:  ISO-8859-1, Makro für Fehlermeldungen
    52:  UTF-8, Makro für Fehlermeldungen
    53:  HTML, Makro für Fehlermeldungen
    54:  DOS CP 850, Makro für Fehlermeldungen

    Rückgabewert ist die aktuelle Kodierung als Integer oder (bei
    kto_check_encoding_str()) als String. Falls zwei Kodierungen
    angegeben sind, ist die erste die der Statusmeldungen, die zweite
    die der LUT-Blocks:

     1:  "ISO-8859-1";
     2:  "UTF-8";
     3:  "HTML entities";
     4:  "DOS CP 850";
     12: "ISO-8859-1/UTF-8";
     13: "ISO-8859-1/HTML";
     14: "ISO-8859-1/DOS CP 850";
     21: "UTF-8/ISO-8859-1";
     23: "UTF-8/HTML";
     24: "UTF-8/DOS CP-850";
     31: "HTML entities/ISO-8859-1";
     32: "HTML entities/UTF-8";
     34: "HTML entities/DOS CP-850";
     41: "DOS CP-850/ISO-8859-1";
     42: "DOS CP-850/UTF-8";
     43: "DOS CP-850/HTML";
     51: "Makro/ISO-8859-1";
     52: "Makro/UTF-8";
     53: "Makro/HTML";
     54: "Makro/DOS CP 850";

    Mit der Funktion keep_raw_data() läßt sich einstellen, ob die
    Rohwerte der LUT-Datei gespeichert werden sollen (das erfordert
    etwa 900 KB zusätzlichen Hauptspeicher, erlaubt aber das
    Umkodieren der LUT-Blocks nach der Initialisierung).

   -------------------------------------------------------------------------

  Funktion:  kto_check_retval2txt
             kto_check_retval2iso
             kto_check_retval2utf8
             kto_check_retval2html
             kto_check_retval2dos
             kto_check_retval2txt_short

  Aufgabe:   Ausgabe numerischer Statusmeldungen als Klartext.

  Aufruf:    $retval_txt=kto_check_retval2txt($retval)
             $retval_txt=kto_check_retval2iso($retval)
             $retval_txt=kto_check_retval2utf8($retval)
             $retval_txt=kto_check_retval2html($retval)
             $retval_txt=kto_check_retval2dos($retval)
             $retval_txt=kto_check_retval2txt_short($retval)

   Diese Funktionen wandeln die numerischen Rückgabewerte in einen
   Klartext-String der gewünschten Kodierung um. Die Kodierung der
   Funktion kto_check_retval2txt() wird dabei durch die Funktion
   kto_check_encoding() (s.o.) festgelegt; die anderen Funktionen
   geben jeweils eine feste Kodierung zurück.

   -------------------------------------------------------------------------

  Funktion:  lut_blz1()
             lut_filialen1()
             lut_name1()
             lut_name_kurz1()
             lut_plz1()
             lut_ort1()
             lut_pan1()
             lut_bic1()
             lut_pz1()
             lut_aenderung1()
             lut_loeschung1()
             lut_nachfolge_blz1()

  Aufgabe:   Bestimmung von Feldern der BLZ-Datei (skalarer Kontext)

  Aufruf:    $ret=lut_blz1($blz[,$filiale[,$ret]])
             $ret=lut_name1($blz[,$filiale[,$ret]])
             $ret=lut_name_kurz1($blz[,$filiale[,$ret]])
             $ret=lut_plz1($blz[,$filiale[,$ret]])
             $ret=lut_ort1($blz[,$filiale[,$ret]])
             $ret=lut_pan1($blz[,$filiale[,$ret]])
             $ret=lut_bic1($blz[,$filiale[,$ret]])
             $ret=lut_pz1($blz[,$filiale[,$ret]])
             $ret=lut_aenderung1($blz[,$filiale[,$ret]])
             $ret=lut_loeschung1($blz[,$filiale[,$ret]])
             $ret=lut_nachfolge_blz1($blz[,$filiale[,$ret]])
             $ret=pz2str1($pz[,$ret])

   Die Funktionen entsprechen den Funktionen ohne die angehängte "1";
   allerdings arbeiten sie ausschließlich im skalaren Kontext. Das ist
   z.B. vorteilhaft, wenn man den Rückgabewert der Funktion in einem
   anderen Funktionsaufruf benutzen will. Der Rückgabewert der
   Funktion kann mittels des optionalen Parameters $ret bestimmt
   werden.

-------------------------------------------------------------------------

  Funktion:  lut_suche_blz()
             lut_suche_bic()
             lut_suche_namen()
             lut_suche_namen_kurz()
             lut_suche_ort()
             lut_suche_pz()
             lut_suche_plz()
             lut_suche_regel()
             lut_suche_volltext()
             lut_suche_multiple()

  Aufgabe:  Suche von Banken (nach Feldern der BLZ-Datei)

  Aufruf:    [$@]ret=lut_suche_bic($bic[,$retval[,$uniq[,$sort]]])
             [$@]ret=lut_suche_namen($namen[,$retval[,$uniq[,$sort]]])
             [$@]ret=lut_suche_namen_kurz($namen_kurz[,$retval[,$uniq[,$sort]]])
             [$@]ret=lut_suche_ort($ort[,$retval[,$uniq[,$sort]]])

             [$@]ret=lut_suche_blz($blz1[,$blz2[,$retval[,$uniq[,$sort]]]])
             [$@]ret=lut_suche_pz($pz1[,$pz2[,$retval[,$uniq[,$sort]]]])
             [$@]ret=lut_suche_plz($plz1[,$plz2[,$retval[,$uniq[,$sort]]]])
             [$@]ret=lut_suche_regel($plz1[,$plz2[,$retval[,$uniq[,$sort]]]])

             [$@]ret=lut_suche_volltext($suchworte[,$retval[,$uniq[,$sort]]])
             [$@]ret=lut_suche_multiple($suchworte[,$uniq[,$such_cmd[,$retval]]])

   Mit diesen Funktionen lassen sich Banken suchen, die bestimmte
   Kriterien erfüllen. Bei alphanumerischer Suche (BIC, Name,
   Kurzname, Ort, Volltext, multiple) kann ein vollständiger Name
   oder Namensanfang angegeben werden. So findet z.B. eine Suche
   lut_suche_ort("aa") die Banken in in Aach, Aachen, Aalen und
   Aarbergen, während eine Suche wie lut_suche_ort("aac") nur die
   Banken in Aach und Aachen findet. Soll die Suche exakt sein,
   d.h. das Suchwort nicht als Wortanfang verstanden werden, ist
   diesem ein ! voranzustellen. Eine Suche wie lut_suche_ort("!aach")
   findet dann nur Aach, nicht mehr Aachen. Diese Syntaxt läßt sich
   auch für lut_suche_multiple() anwenden.

   Bei numerischer Suche (BLZ, Prüfziffer oder PLZ) kann ein Bereich
   spezifiziert werden. Falls der zweite Suchparameter nicht angegeben
   wird (oder 0 ist), werden Banken gesucht, die genau auf den
   Parameter passen.

   Diese Funktionen können sowohl in skalarem als auch im
   Listenkontext aufgerufen werden. Bei Aufruf in skalarem Kontext
   geben sie eine Referenz auf ein Array mit Bankleitzahlen zurück,
   die die Kriterien erfüllen; bei Aufruf im Listenkontext werden
   zwei (bei lut_suche_multiple()) bzw. vier (bei allen anderen
   Suchfunktionen) Array-Referenzen sowie der Rückgabewert der
   Funktion zurückgegeben.

   Die erste zeigt auf das Array mit Bankleitzahlen, die zweite auf
   ein Array mit Indizes der jeweiligen Zweigstellen und die dritte
   (nicht lut_suche_multiple()!) auf ein Array mit den jeweiligen Werten
   des gesuchten Feldes. Der nächste Parameter ist der Statuscode; als
   letzter Parameter kommt bei allen Suchfunktionen (außer
   lut_suche_multiple()) noch eine Referenz auf ein Array, in dem zu
   jeder gefundenen BLZ die Anzahl der Zweigstellen zurückgegeben
   wird, falls der Parameter uniq auf 1 gesetzt war.

   In dem optionalen Parameter $retval wird ebenfalls der numerischer
   Rückgabewert der Funktion (wie im 4. Parameter bei Array-Kontext; 1
   bei Erfolg, oder negative Statusmeldung) zurückgeliefert.. Mittels
   des assoziativen Arrays %kto_retval{$retval} können diese
   Rückgabewerte in Klartext konvertiert werden.

   Die Funktion lut_suche_multiple() sucht alle Banken, die mehreren
   Kriterien entsprechen. Dabei können bis zu 26 Teilsuchen definiert
   werden, die beliebig miteinander verknüpft werden können (additiv,
   subtraktiv und multiplikativ).

   Parameter:
   such_string: Dieser Parameter gibt die Felder an, nach denen
   gesucht wird. Er besteht aus einem oder mehreren Suchbefehlen, die
   jeweils folgenden Aufbau haben: [suchindex:]suchwert[@suchfeld]

   Der (optionale) Suchindex ist ein Buchstabe von a-z, mit dem das
   Suchfeld im Suchkommando (zweiter Parameter) referenziert werden
   kann. Falls er nicht angegeben wird, erhält der erste Suchstring
   den Index a, der zweite den Index b etc.

   Der Suchwert ist der Wert nach dem gesucht werden soll. Für die
   Textfelder ist es der Beginn des Wortes (aa passt z.B. auf Aach,
   Aachen, Aalen, Aarbergen), für numerische Felder kann es eine
   Zahl oder ein Zahlbereich in der Form 22-33 sein.

   Das Suchfeld gibt an, nach welchem Feld der BLZ-Datei gesucht
   werden soll. Falls das Suchfeld nicht angegeben wird, wird eine
   Volltextsuche (alle Einzelworte in Name, Kurzname und Ort)
   gemacht. Die folgende Werte sind möglich:

      bl    BLZ
      bi    BIC
      k     Kurzname
      n     Name
      o     Ort
      pl    PLZ
      pr    Prüfziffer
      pz    Prüfziffer
      v     Volltext

   In der obigen Tabelle der Suchfelder sind nur die Kurzversionen
   angegeben; eine Angabe wie aa@ort oder 57000-58000@plz ist auch
   problemlos möglich.

   such_cmd: Dieser Parameter gibt an, wie die Teilsuchen miteinander
   verknüpft werden sollen. Der Ausdruck abc bedeutet, daß die BLZs in
   den Teilsuchen a, b und c enthalten sein müssen; der Ausdruck
   a+b+c, daß sie in mindestens einer Teilsuche enthalten sein muß;
   der Ausdruck a-b, daß sie in a, aber nicht in b enthalten sein darf
   (Beispiel s.u.). Falls das Suchkommando nicht angegeben wird,
   müssen die Ergebnis-BLZs in allen Teilsuchen enthalten sein.

   uniq: Falls dieser Parameter 1 ist, wird für jede Bank nur eine
   Zweigstelle ausgegeben; falls er 0 ist, werden alle gefundenen
   Zweigstellen ausgegeben. Falls der Parameter weggelassen wird, wird
   der Standardwert (UNIQ_DEFAULT_PERL aus konto_check.h) benutzt.

   sort: Falls dieser Parameter 1 ist, werden die Banken nach BLZ
   sortiert, nicht in der Reihenfolge der Suchbegriffe (Standard).
   Falls der Parameter uniq 1 ist, wird immer nach BLZ sortiert.

   Beispiele:
   $blz_p=lut_suche_ort("mannheim",$retval);
   @blz=@$blz_p;     # Array mit allen Banken in Mannheim
                     # $retval enthält den Rückgabestatus der Funktion

   ($blz_p,$idx_p)=lut_suche_ort("mannheim");
   @blz=@$blz_p;     # Array mit allen Banken in Mannheim
   @idx=@$idx_p;     # Array der Zweigstellen

   ($blz_p,$idx_p,$ort_p)=lut_suche_ort("aa");
   @blz=@$blz_p;     # Array mit Banken in Städten, die mit "aa" beginnen
   @idx=@$idx_p;     # Array der Zweigstellen
   @ort=@$ort_p;     # Array der jeweiligen Orte

   ($blz_p,$idx_p,$ort_p,$retval,$cnt_p)=lut_suche_ort("aa",$rv,1);
   @blz=@$blz_p;     # Array mit Banken in Städten, die mit "aa" beginnen
   @idx=@$idx_p;     # Array der Zweigstellen
   @ort=@$ort_p;     # Array der jeweiligen Orte
   @cnt=@$cpt_p;     # Array mit Anzahl der gefundenen Zweigstellen (bei $uniq=1)
                     # $retval enthält den Rückgabestatus der Funktion

   ($blz_p,$idx_p,$retval)
         =lut_suche_multiple("b:55000000-55100000@blz o:67000-68000@plz sparkasse","bo")
      # Bei diesem Aufruf werden nur die beiden ersten Teilsuchen (nach
      # BLZ und PLZ) benutzt; die Suche findet alle Banken mit einer BLZ
      # zwischen 55000000 und 55100000 im PLZ-Bereich 67000 bis 68000.

   ($blz_p,$idx_p,$retval)
         =lut_suche_multiple("b:55000000-55030000@blz o:67000-68000@plz sparkasse","co")
      # Ähnlicher Suche wie oben, allerdings werden nur die beiden
      # letzten Teilsuchen berücksichtigt.

   ($blz_p,$idx_p,$retval)=lut_suche_multiple("67000-68000@plz sparda",0)
      # Dieser Aufruf gibt alle Filialen der Sparda-Bank im PLZ-Bereich
      # 67000 bis 68000 zurück.

   ($blz_p,$idx_p,$retval)=lut_suche_multiple("skat")
      # Dieser Aufruf ist einfach eine Volltextsuche nach der Skat-Bank.
      # Der direkte Aufruf von bank_suche_volltext() ist intern
      # natürlich wesentlich leichtgewichtiger, aber die Suche so auch
      # möglich.


  Funktion:  kto_check_at()
             kto_check_at_str()

  Aufgabe:   Testen eines österreichischen Kontos

  Aufruf:    $retval=kto_check_at($blz,$kto,$lut_name);
             $retval=kto_check_at_str($blz,$kto,$lut_name);

  Parameter:
  $blz:     BLZ (5-stellig) oder Prüfparameter (mit vorangestelltem p)
            Falls der BLZ ein - vorausgestellt wird, werden auch gelöschte
            Bankleitzahlen geprüft.
            Falls der BLZ ein p vorausgestellt wird, wird der folgende
            Teil (bis zum Blank/Tab) als Prüfparameter angesehen.

  $kto:     Kontonummer

  $lut_name: Name der Lookup-Datei oder Leerstring
            Falls für $lut_name ein Leerstring angegeben wird, versucht
            die Funktion, die Datei blz-at.lut zu lesen.

-------------------------------------------------------------------------

  Funktion:  generate_lut_at()

  Aufgabe:   LUT-Datei für das österreichische Modul generieren

  Aufruf:    $retval=generate_lut_at($inputname,$outputname,$plain_name,$plain_format);

  Parameter:
     $inputname:  Name der INPAR-Datei (nur komplett, nicht inkrementell!)
     $outputname: Name der Zieldatei (z.B. blz-at.lut)
     $plain_name: (optional) Name einer Ausgabedatei für die Klartextausgabe.
     $plain_format: Format der Klartextausgabe (s.u.)

  Bugs:
     Diese Funktion sollte nicht von einem Programm aufgerufen werden,
     das zum Testen von Kontoverbindungen benutzt wird, da teilweise
     dieselben Variablen benutzt werden, und so falsche Ergebnisse
     erzeugt werden können. 

  Die Funktion generate_lut_at() generiert aus der Institutsparameter-
  Datenbankdatei (5,3 MB) eine kleine Datei (8,3 KB), in der nur die
  Bankleitzahlen und Prüfziffermethoden gespeichert sind. Um die Datei
  klein zu halten, wird der größte Teil der Datei binär gespeichert.

  Falls der Parameter plain_name angegeben wird, wird zu jeder INPAR-
  Eintrag außerdem (in einem frei wählbaren Format) noch in eine Klartext-
  datei geschrieben. Das Format der Datei wird durch den 4. Parameter
  ($plain_format) bestimmt. Es sind die folgenden Felder und Escape-
  Sequenzen definiert (der Sortierparameter muß als erstes Zeichen
  kommen!):

     @i   Sortierung nach Identnummern
     @b   Sortierung nach Bankleitzahlen (default)
     %b   Bankleitzahl
     %B   Bankleitzahl (5-stellig, links mit Nullen aufgefüllt)
     %f   Kennzeichen fiktive Bankleitzahl
     %h   Kennzeichen Hauptstelle/Zweigstelle
     %i   Identnummer der Österreichischen Nationalbank
     %I   Identnummer der Österreichischen Nationalbank (7-stellig)
     %l   Löschdatum (DD.MM.YYYY falls vorhanden, sonst nichts)
     %L   Löschdatum (DD.MM.YYYY falls vorhanden, sonst 10 Blanks)
     %n1  Erster Teil des Banknamens
     %n2  Zweiter Teil des Banknamens
     %n3  Dritter Teil des Banknamens
     %N   kompletter Bankname (alle drei Teile zusammengesetzt)
     %p   Kontoprüfparameter
     %t   Name der Prüftabelle
     %z   zugeordnete BLZ (nur bei fiktiver BLZ, sonst nichts)
     %Z   zugeordnete BLZ (5-stellig bei fiktiver BLZ, sonst 5 Blanks)
     %%   das % Zeichen selbst

     \n   Zeilenvorschub
     \r   CR (für M$DOS)
     \t   Tabulatorzeichen
     \\   ein \

  @i (bzw. @b) muß am Anfang des Formatstrings stehen; falls keine
  Sortierung angegeben wird, wird @b benutzt.

  Nicht definierte Felder und Escape-Sequenzen werden (zumindest momentan
  noch) direkt in die Ausgabedatei übernommen. D.h., wenn man %x schreibt,
  erscheint in der Ausgabedatei auch ein %x, ohne daß ein Fehler gemeldet
  wird. Ob dies ein Bug oder Feature ist, sei dahingestellt; momentan
  scheint es eher ein Feature zu sein ;-))).

  Falls kein plain_format angegeben wird, wird "@B%I %B %t %N"
  benutzt. Die Datei ist (anders als die INPAR-Datei) nach
  Bankleitzahlen sortiert. Nähres zur Sortierung findet sich in der
  Einleitung zur Funktion cmp_blz().

  Die Funktion ist **nicht** threadfest, da dies aufgrund der gewählten
  Implementierung nur schwer zu machen wäre, und auch nicht sehr sinnvoll
  ist (sie wird nur benötigt, um die blz-at.lut Datei zu erstellen).

-------------------------------------------------------------------------

=head1 SEE ALSO

Eine ausführliche Beschreibung der Prüfziffermethoden und das Format
der LUT-Datei findet sich im C-Quellcode. Ein Link zur offiziellen
Beschreibung der Prüfziffermethoden u.a. (von der Deutschen
Bundesbank) findet sich auf der Webseite zu konto_check unter
http://www.informatik.hs-mannheim.de/konto_check/konto_check.php?ausgabe=3

Auf SourceForge.net gibt es unter http://sourceforge.net/mail/?group_id=199719
auch eine Mailingliste. Der Traffic ist sehr gering, maximal meist ein bis zwei
Emails/Monat.

Die aktuelle Version findet sich auf CPAN unter
http://search.cpan.org/~michel/Business-KontoCheck oder auf
Sourceforge unter http://sourceforge.net/projects/kontocheck/develop
Dort ist auch ein SVN Repository, in dem die neuesten Versionen und
Bugfixes zu finden sind.

=head1 AUTHOR

Michael Plugge, E<lt>m.plugge@hs-mannheim.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2012 by Michael Plugge

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.8.8 or, at your option,
any later version of Perl 5 you may have available (perl and glue code).

The C library is covered by the GNU Lesser General Public License:

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
details.

You should have received a copy of the GNU Lesser General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 51
Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
or download it from http://www.gnu.org/licenses/lgpl.html

=cut
