use strict;
use warnings;
#use Test::More;
use Acme::Tools 0.20;
sub deb($) { print STDERR @_ if $ENV{ATDEBUG} }
sub tmp    { require File::Temp;File::Temp::tempdir(CLEANUP=>1,@_) }
sub ok_ca  { ok( abs( 1 - $_[0]/$_[1] ) < 1e-4, $_[2]) }
sub ok_str { my($s1,$s2)=@_; if($s1 eq $s2){ok(1)}else{ok(0,"s1: $s1   not eq   s2: $s2")}}
sub ok_ref {
  my($s1,$s2) = map serialize($_),@_[0,1];
  my $ok = ok($s1 eq $s2, $_[2]) or deb "s1=$s1\ns2=$s2\n";
  $ok
}
sub gz {
  return gzip(shift()) if $] >= 5.010;
  my $t=tmp().'/acme-tools.wipe2.tmp';
  writefile($t,shift());
  ''.qx(gzip<$t);
}
1;
