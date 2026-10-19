use strict; use warnings; use Time::HiRes 'time';
# Primitive costs: consume 4KB chunks off front of an N-byte buffer
for my $N (4e6, 16e6) {
  my $b = 'x' x $N; my $t=time; my $n=0;
  while (length $b) { my $p = substr($b,0,4096,''); $n++ }
  printf "substr4  N=%3dMB %.3fs\n",$N/1e6,time-$t;
  $b = ('x' x 4095 . "\x0E") x ($N/4096); $t=time;
  while (length $b) { my ($a,$d,$r) = split /(\x0E)/, $b, 2; $b = $r // '' }
  printf "split    N=%3dMB %.3fs\n",$N/1e6,time-$t;
  # reassembly pattern from _extract_message
  my %h; $t=time; my $c='y' x 4080;
  for (1..$N/4080) { $h{k} = $h{k} ? $h{k} . $c : $c }
  printf "a?a.d:d  N=%3dMB %.3fs\n",$N/1e6,time-$t;
  %h=(); $t=time; for (1..$N/4080) { $h{k} .= $c } printf ".=       N=%3dMB %.3fs\n",$N/1e6,time-$t;
}
