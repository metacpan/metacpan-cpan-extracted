#!/usr/bin/perl
perm(shift()||"abcd");
#perm("abc",sub{shift;print join(",",@_)."\n"},sub{print"<--\n"});
sub perm {
  my($s,$swap,$out)=@_;
  if(!ref($s)){
    $swap||=sub{my($sr,$x,$y)=@_;(substr($s,$x,1),substr($s,$y,1))=(substr($s,$y,1),substr($s,$x,1))};
    $out||=sub{print"$_[0]\n"};
  }
  elsif(ref($s) eq 'ARRAY'){
    $swap||=die'todo';
    $out||=die'todo';
  }
  my$n=length($s)-1;
  my$p;($p=sub{my$i=shift;$i==$n?&$out($s):do{&$p($i+1);for($i+1..$n){&$swap(\$s,$i,$_);&$p($i+1);&$swap(\$s,$i,$_)}}})->(0);
 #my$p;($p=sub{my$i=shift;$i==$n?&$out($s):do{for($i..$n){&$swap(\$s,$i,$_);&$p($i+1);&$swap(\$s,$i,$_)}}})->(0);#slower
}
