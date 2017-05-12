# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl lut_suche.t'

use Test::More tests => 45;

BEGIN{use_ok('Business::KontoCheck','lut_init','lut_name1','lut_pz1','lut_plz1','lut_ort1',
      'lut_suche_ort','lut_suche_blz','pz2str','lut_suche_pz','lut_suche_plz','lut_suche_bic',
      'lut_suche_namen','lut_suche_namen_kurz','lut_suche_volltext','lut_suche_multiple',
      'retval2txt_short','%kto_retval')};

sub chk_int
{
   my($fkt,$fkt_name,$arg1,$arg2,@blz,@idx,@val,$c11,$c21,$c22,$c31,$c32,$c33,$r1,$r2,$r3,$i,$cnt);
   $fkt=$_[0];
   $fkt_name=$_[1];
   $arg1=$_[2];
   $arg2=$_[3];

      # Aufruf in skalarem Kontext
   $p_blz=$fkt->($arg1,$arg2,$r1);
   @blz=@$p_blz;
   $c11=scalar(@blz);

      # Aufruf in Array-Kontext, eine Referenz ignoriert
   ($p_blz,$p_idx)=$fkt->($arg1,$arg2,$r2);
   @blz=@$p_blz;
   @idx=@$p_idx;
   $c21=scalar(@blz);
   $c22=scalar(@idx);

      # Aufruf in Array-Kontext
   ($p_blz,$p_idx,$p_val)=$fkt->($arg1,$arg2,$r3);
   @blz=@$p_blz;
   @idx=@$p_idx;
   @val=@$p_val;
   $c31=scalar(@blz);
   $c32=scalar(@idx);
   $c33=scalar(@val);
   $ok_msg="$fkt_name($arg1,$arg2): $c11 Banken gefunden, Rückgabewerte: $r1 / $r2 / $r3  -> ".retval2txt_short($r1);
   ok(($c11>0 && $c11==$c21 && $c11==$c22 && $c11==$c31 && $c11==$c32 && $c11==$c33),$ok_msg);
   print "Hier die ersten Werte:\n";
   $cnt=($c11<10)?$c11:10;
   for($i=0;$i<$cnt;$i++){
      $b=$blz[$i];
      printf("%2d/%3d %s %2d [%d] %s, %s\n",$i+1,$c11,$b,$idx[$i],$val[$i],lut_name1($b),lut_ort1($b));
   }
   print "\n";

      # Aufruf in Array-Kontext mit uniq
   ($p_blz,$p_idx,$p_val,$r3x,$p_cntx)=$fkt->($arg1,$arg2,$r4,1);
   @blz=@$p_blz;
   @idx=@$p_idx;
   @val=@$p_val;
   @cntx=@$p_cntx;
   $c41=scalar(@blz);
   $ok_msg="$fkt_name($arg1,$arg2): $c41 Banken gefunden, uniq: 1, Rückgabewert: $r4  -> ".retval2txt_short($r4);
   ok(($c41>0),$ok_msg);
   print "Hier die ersten Werte mit uniq=1:\n";
   $cnt=($c41<10)?$c41:10;
   for($i=0;$i<$cnt;$i++){
      $b=$blz[$i];
      printf("%2d/%3d %s %2d (%d Zw.) [%d] %s, %s\n",$i+1,$c41,$b,$idx[$i],$cntx[$i],$val[$i],lut_name1($b),lut_ort1($b));
   }
   print "\n";

      # Aufruf in Array-Kontext mit sort
   ($p_blz,$p_idx,$p_val,$r3x,$p_cntx)=$fkt->($arg1,$arg2,$r5,0,1);
   @blz=@$p_blz;
   @idx=@$p_idx;
   @val=@$p_val;
   @cntx=@$p_cntx;
   $c51=scalar(@blz);
   $ok_msg="$fkt_name($arg1,$arg2): $c51 Banken gefunden, uniq 0, sort 1, Rückgabewert: $r5 -> ".retval2txt_short($r5);
   ok(($c51>0 && $c11==$c51),$ok_msg);
   print "Hier die ersten Werte mit sort=1 und uniq=0:\n";
   $cnt=($c51<10)?$c51:10;
   for($i=0;$i<$cnt;$i++){
      $b=$blz[$i];
      printf("%2d/%3d %s %2d [%d] %s, %s\n",$i+1,$c51,$b,$idx[$i],$val[$i],lut_name1($b),lut_ort1($b));
   }
   print "\n";
   return $c11;
}

sub chk_str
{
   my($fkt,$fkt_name,$arg,@blz,@idx,@val,$c11,$c21,$c22,$c31,$c32,$c33,$r1,$r2,$r3,$i,$cnt);
   $fkt=$_[0];
   $fkt_name=$_[1];
   $arg=$_[2];

      # Aufruf in skalarem Kontext
   $p_blz=$fkt->($arg,$r1);
   @blz=@$p_blz;
   $c11=scalar(@blz);

      # Aufruf in Array-Kontext, eine Referenz ignoriert
   ($p_blz,$p_idx)=$fkt->($arg,$r2);
   @blz=@$p_blz;
   @idx=@$p_idx;
   $c21=scalar(@blz);
   $c22=scalar(@idx);

      # Aufruf in Array-Kontext
   ($p_blz,$p_idx,$p_val)=$fkt->($arg,$r3);
   @blz=@$p_blz;
   @idx=@$p_idx;
   @val=@$p_val;
   $c31=scalar(@blz);
   $c32=scalar(@idx);
   $c33=scalar(@val);
   $ok_msg="$fkt_name('$arg'): $c11 Banken gefunden, Rückgabewerte: $r1 / $r2 / $r3 -> ".retval2txt_short($r1);
   if($fkt_name eq "lut_suche_volltext"){
      ok(($c11>0 && $c11==$c21 && $c11==$c22 && $c11==$c31 && $c11==$c32),$ok_msg);
   }
   else{
      ok(($c11>0 && $c11==$c21 && $c11==$c22 && $c11==$c31 && $c11==$c32 && $c11==$c33),$ok_msg);
   }
   print "Hier die ersten Werte:\n";
   $cnt=($c11<10)?$c11:10;
#   $cnt=$c11; # Ausgabe aller Werte (für Test)
   for($i=0;$i<$cnt;$i++){
      $b=$blz[$i];
      $zw=$idx[$i];
      if($fkt_name eq "lut_suche_volltext"){
         printf("%2d %s %2d %s, %d %s\n",$i+1,$b,$idx[$i],lut_name1($b,$zw),lut_plz1($b,$zw),lut_ort1($b,$zw));
      }
      else{
         printf("%2d %s %2d [%s] %s, %d %s\n",$i+1,$b,$idx[$i],$val[$i],lut_name1($b,$zw),lut_plz1($b,$zw),lut_ort1($b,$zw));
      }
   }
   if($fkt_name eq "lut_suche_volltext"){
      printf("\ngefundene Suchworte:\n",$i+1,$val[$i]);
      for($i=0;$i<$c33;$i++){
          printf("   %2d. %s\n",$i+1,$val[$i]);
      }

   }
   print "\n";

      # Aufruf in Array-Kontext mit uniq
   ($p_blz,$p_idx,$p_val,$r3x,$p_cntx)=$fkt->($arg,$r4,1);
   @blz=@$p_blz;
   @idx=@$p_idx;
   @val=@$p_val;
   @cntx=@$p_cntx;
   $c41=scalar(@blz);
   $ok_msg="$fkt_name('$arg'): $c41 Banken gefunden, uniq: 1, Rückgabewert: $r4 -> ".retval2txt_short($r4);
   ok(($c41>0),$ok_msg);
   print "Hier die ersten Werte mit uniq=1:\n";
   $cnt=($c41<10)?$c41:10;
   for($i=0;$i<$cnt;$i++){
      $b=$blz[$i];
      $zw=$idx[$i];
      if($fkt_name eq "lut_suche_volltext"){
         printf("%2d/%3d %s %2d (%d Zw.) %s, %d %s\n",$i+1,$c41,$b,$idx[$i],$cntx[$i],lut_name1($b,$zw),lut_plz1($b,$zw),lut_ort1($b,$zw));
      }
      else{
         printf("%2d/%3d %s %2d (%d Zw.) [%s] %s, %s\n",$i+1,$c41,$b,$idx[$i],$cntx[$i],$val[$i],lut_name1($b,$zw),lut_ort1($b,$zw));
      }
   }
   print "\n";

      # Aufruf in Array-Kontext mit sort
   ($p_blz,$p_idx,$p_val,$r3x,$p_cntx)=$fkt->($arg,$r5,0,1);
   @blz=@$p_blz;
   @idx=@$p_idx;
   @val=@$p_val;
   @cntx=@$p_cntx;
   $c51=scalar(@blz);
   $ok_msg="$fkt_name('$arg'): $c51 Banken gefunden, uniq 0, sort 1, Rückgabewert: $r5 -> ".retval2txt_short($r5);
   ok(($c51>0 && $c11==$c51),$ok_msg);
   print "Hier die ersten Werte mit sort=1 und uniq=0:\n";
   $cnt=($c51<10)?$c51:10;
   for($i=0;$i<$cnt;$i++){
      $b=$blz[$i];
      $zw=$idx[$i];
      printf("%2d/%3d %s %2d %s, %s\n",$i+1,$c51,$b,$idx[$i],lut_name1($b,$zw),lut_ort1($b,$zw));
   }
   print "\n";
   return $c11;
}

sub suche_multiple
{
   my($fkt,$fkt_name,$such_string,@blz,@idx,$c11,$c21,$c22,$r1,$r2,$i,$cnt,$uniq);
   $such_string=$_[0];
   $uniq=$_[1];

      # Aufruf in skalarem Kontext
   $p_blz=lut_suche_multiple($such_string,$uniq,"",$r1);
   @blz=@$p_blz;
   $c11=scalar(@blz);

      # Aufruf in Array-Kontext
   ($p_blz,$p_idx)=lut_suche_multiple($such_string,$uniq,"",$r2);
   @blz=@$p_blz;
   @idx=@$p_idx;
   $c21=scalar(@blz);
   $c22=scalar(@idx);

   $ok_msg="lut_suche_multiple('$such_string',$uniq): $c11 Banken gefunden, Rückgabewerte: $r1 / $r2 -> ".retval2txt_short($r1);
   ok(($c11>0 && $c11==$c21 && $c11==$c22),$ok_msg);
   print "Hier die ersten Werte:\n";
   $cnt=($c11<10)?$c11:10;
#   $cnt=$c11; # Ausgabe aller Werte (für Test)
   for($i=0;$i<$cnt;$i++){
      $b=$blz[$i];
      $zw=$idx[$i];
     printf("%2d %s %2d %s, %d %s\n",$i+1,$b,$idx[$i],lut_name1($b,$zw),lut_plz1($b,$zw),lut_ort1($b,$zw));
   }
   print "\n";
   return $c11;
}

$retval=lut_init("blz.lut");
ok(($retval gt 0 || $retval==-38),"init: $retval => $kto_retval{$retval}");

chk_int(\&lut_suche_blz,"lut_suche_blz",10000000,10100000);
chk_int(\&lut_suche_plz,"lut_suche_plz",67000,67200);
chk_int(\&lut_suche_pz,"lut_suche_pz",98,102);
chk_str(\&lut_suche_ort,"lut_suche_ort","aa");
chk_str(\&lut_suche_namen,"lut_suche_namen","volksbank hei");
chk_str(\&lut_suche_namen_kurz,"lut_suche_namen_kurz","aachener");
chk_str(\&lut_suche_ort,"lut_suche_ort","mannheim");
chk_str(\&lut_suche_bic,"lut_suche_bic","genodef1a");

$retval=lut_init("blz.lut",9);
ok(($retval gt 0 || $retval==-38),"init: $retval => $kto_retval{$retval}");

chk_str(\&lut_suche_ort,"lut_suche_ort","aa");
chk_str(\&lut_suche_namen,"lut_suche_namen","volksbank hei");
chk_str(\&lut_suche_volltext,"lut_suche_volltext","skat");
chk_str(\&lut_suche_volltext,"lut_suche_volltext","lin");

suche_multiple("sparkasse man",0);
suche_multiple('sparkasse ma@o',0);
suche_multiple('sparkasse ma@o',1);
suche_multiple('sparkasse 68000-68900@plz',0);
suche_multiple('sparkasse 68000-68900@plz',1);
suche_multiple('sparkasse 68000-68900@plz al',1);
