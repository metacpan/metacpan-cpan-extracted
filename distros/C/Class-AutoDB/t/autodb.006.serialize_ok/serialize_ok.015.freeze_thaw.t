# Updated version of Chris's dd_freeze_thaw.t
# tests freeze/thaw behavior of our modified Dumper

use t::lib;
use strict;
use Class::AutoDB::Dumper;
use Test::More;
use Test::Deep;
use FreezeThaw;		# defines all test classes

my $dumper_class='Class::AutoDB::Dumper';
# my $dumper_class='Data::Dumper';

# test that classes defined as we expect
my @classes=qw(freeze_thaw freeze freeze2thaw thaw nada);
my %correct_canfreeze=(freeze_thaw=>1,freeze=>1,freeze2thaw=>1);
my %correct_canthaw=(freeze_thaw=>1,thaw=>1);
for my $class (@classes) {
  ok(UNIVERSAL::can($class,'DUMPER_freeze'),"$class can freeze") if $correct_canfreeze{$class};
  ok(!UNIVERSAL::can($class,'DUMPER_freeze'),"$class can't freeze") if !$correct_canfreeze{$class};
  ok(UNIVERSAL::can($class,'DUMPER_thaw'),"$class can thaw") if $correct_canthaw{$class};
  ok(!UNIVERSAL::can($class,'DUMPER_thaw'),"$class can't thaw") if !$correct_canthaw{$class};
}
my $DUMPER=$dumper_class->new([undef],['thaw']) ->
  Purity(1)->Indent(1)->Freezer('DUMPER_freeze')->Toaster('DUMPER_thaw');

for my $useperl (0..1) {
  $DUMPER->Reset->Useperl($useperl);
  my $label=$useperl? 'perl:': 'xs:';
  
  # note(("-" x 40)."\n"."$label tests\n".("-" x 40));
  for my $class (@classes) {
    do_test0($class,$label);
  }
  for my $class (@classes) {
    do_test1($class,$label);
  }
}
done_testing();

sub do_test0 {
  my($class,$label)=@_;
  $label.=" class=$class fill=0";
  my $thaw;
  my $obj=new $class(name=>$class,fill=>0);
  my $freeze = $DUMPER->Values([$obj])->Dump;
  eval $freeze;			#sets $thaw
  if ($@) {
    fail("$label: eval. error is ".substr($@,0,20).' ...');
    diag("$label: skipping rest of tests");
    return;
  }
  my $thaw_class=$class eq 'freeze2thaw'? 'thaw': $class;
  isa_ok($thaw,$thaw_class,"$label: thawed object");
  is($obj->fresh,'fresh',"$label: original object unchanged by freeze/thaw");
  my($ok,$correct)=chk_fresh($obj,$thaw);
  ok($ok,($correct?
	  "$label: thawed object reflects DUMPER_freeze effects": 
	  "$label: thawed object unchanged by DUMPER_freeze"));
}
sub do_test1 {
  my($class,$label)=@_;
  $label.=" class=$class fill=1";
  my $thaw;
  my $obj=new $class(name=>$class,fill=>1);
  my $freeze = $DUMPER->Values([$obj])->Dump;
  eval $freeze;			#sets $thaw
  if ($@) {
    fail("$label: eval. error is ".substr($@,0,20).' ...');
    diag("$label: skipping rest of tests");
    return;
  }
  my $thaw_class=$class eq 'freeze2thaw'? 'thaw': $class;
  isa_ok($thaw,$thaw_class,"$label: thawed object");
  is($obj->fresh,'fresh',"$label: original object unchanged by freeze/thaw");
  for my $attr (@classes) {
    unless (ref $thaw->$attr) {
      fail("$label: bad news. thaw has no $attr attribute");
      diag("$label: skipping rest of $attr tests");
      next;
    }
    my $other=$thaw->$attr;
    my $other_class=$attr eq 'freeze2thaw'? 'thaw': $attr;
    isa_ok($other,$other_class,"$label: thawed -> $attr");
    is($obj->$attr->fresh,'fresh',
       "$label: original -> $attr unchanged by freeze/thaw");
    my($ok,$correct)=chk_fresh($obj->$attr,$other);
    ok($ok,($correct?
	    "$label: thawed -> $attr reflects DUMPER_freeze effects": 
	    "$label: thawed -> $attr unchanged by DUMPER_freeze"));
  }
}
# return ($ok,$correct). $correct indicates whether object should be changed
sub chk_fresh {
  my($obj,$thaw)=@_;
  my $class=ref $obj;
  $correct_canfreeze{$class}?
    (($thaw->fresh eq 'nope. frozen and thawed'),1): 
      (($thaw->fresh eq 'fresh'),0);
}
