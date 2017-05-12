use Test::More tests => 21;
BEGIN { use_ok( 'B::Flags' ); }

ok B::main_root->flagspv =~ /VOID/, "main_root VOID";
ok B::main_root->privatepv =~ /REFCOUNTED/, "main_root->privatepv REFCOUNTED";
ok B::svref_2object(\3)->flagspv =~ /READONLY/, "warning 3 READONLY";

# for AV, CV and GV print its flags combined and splitted
@Typed::ISA=('main');
@a = (0..4);
use Devel::Peek;
my $SVt_PVAV  = $] < 5.010 ? 10 : 11;
my $BothFlags = 'REAL';
my $AvFlags   = $] < 5.010 ? 'REAL' : '';
my $SvFlags   = $] < 5.010 ? '' : 'REAL';
my $av = B::svref_2object( \@a );
is $av->flagspv, $BothFlags,          "AV default ".$av->flagspv." both flags"
  or Dump(\@a);
is $av->flagspv($SVt_PVAV), $AvFlags, "AvFLAGS only ".$av->flagspv($SVt_PVAV);
is $av->flagspv(0), $SvFlags,         "SvFLAGS only ".$av->flagspv(0);

sub mycv { my $n=1; my Typed $x = 0; 1}
my $cv = B::svref_2object( \&main::mycv );
my $pad = ($cv->PADLIST->ARRAY)[1];
is $pad->flagspv, $BothFlags,           "PAD default ".$pad->flagspv." both flags";
is $pad->flagspv($SVt_PVAV),  $AvFlags, "PAD AvFLAG only ".$pad->flagspv($SVt_PVAV);
is $pad->flagspv(0), $SvFlags,          "PAD SvFLAGS only ".$pad->flagspv(0). " - fallthrough";

sub lvalcv:lvalue {my $n=1;}
my $SVt_PVCV = $] < 5.010 ? 12 : 13;
my $cv1 = B::svref_2object( \&main::lvalcv );
like $cv1->flagspv, qr/LVALUE/, "LVCV SvFLAGS+CvFLAGS";
like $cv1->flagspv($SVt_PVCV), qr/^LVALUE/, "LVCV CvFLAGS only";
unlike $cv1->flagspv(0), qr/LVALUE/, "LVCV SvFLAGS only";

my $SVt_PVGV = $] < 5.010 ? 13 : 9;
my $gv = B::svref_2object( \*mycv );
like $gv->flagspv, qr/MULTI/, "GV SvFLAGS+GvFLAGS";
like $gv->flagspv($SVt_PVGV), qr/^(MULTI|THINKFIRST,MULTI)/, "GvFLAGS only";
unlike $gv->flagspv(0), qr/MULTI/, "SvFLAGS only";

my $padnl = ($cv->PADLIST->ARRAY)[0];
my $result = $] >= 5.022 ? ''
           : $] >= 5.020 ? 'NAMELIST,REAL'
           : 'REAL';
is $padnl->flagspv, $result, "PADNAMELIST as ".ref($padnl);

my $padn1 = ($padnl->ARRAY)[1];
my $padl1 = ($pad->ARRAY)[1];
SKIP: {
  skip "empty PADNAME", 1 if ref $padn1 eq 'B::SPECIAL';
  my $pv = ref $padn1 eq 'B::SPECIAL' ? "" : $padn1->PV;
  $result = $] >= 5.022 ? "" : "POK,pPOK";
  is $padn1->flagspv, $result, "PADNAME $pv as ".ref($padn1);
}
SKIP: {
  skip "empty PAD", 1 if ref $padl1 eq 'B::SPECIAL';
  $result = $] >= 5.022 ? "PADSTALE"
          : $] >= 5.016 ? "PADSTALE,PADTMP,PADMY"
          : $] >= 5.014 ? "PADSTALE,PADMY"
          : $] >= 5.010 ? "PADMY"
          : "PADBUSY,PADMY";
  is $padl1->flagspv, $result, "PAD as ".ref($padl1);
}

my $padt = ($padnl->ARRAY)[2];
SKIP: {
  skip "empty typed PADNAME", 1 if !$padt or ref $padt eq 'B::SPECIAL';
  my $pv = ref $padt eq 'B::SPECIAL' ? "" : $padt->PV;
  $result = $] >= 5.022 ? "TYPED"
          : $] >= 5.016 ? "PADSTALE,PADTMP,POK,pPOK,TYPED"
          : $] >= 5.010 ? "PADTMP,POK,pPOK,TYPED,VALID"
          : $] >= 5.008 ? "POK,pPOK,TYPED"
          : "OBJECT,POK,pPOK";
  is $padt->flagspv, $result, "typed PADNAME $pv as ".ref($padt);
}

my $padl = $cv->PADLIST;
$result = ($] >= 5.016 and $] < 5.018) ? "REAL" : "";
is $padl->flagspv, $result, "PADLIST as ".ref($padl);
