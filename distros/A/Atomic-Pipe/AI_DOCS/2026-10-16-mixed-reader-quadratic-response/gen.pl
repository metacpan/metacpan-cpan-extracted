use strict; use warnings; use Cpanel::JSON::XS; srand 42;
my $J=Cpanel::JSON::XS->new->canonical; my @w=qw(ok not subtest plan diag note assert pass fail file line package tool trace frame hub stamp uuid event facet about info);
open my $o,'>','events.jsonl' or die; my $t=0;
while ($t < 14.4e6) { my %e=(stamp=>1.7e9+rand 1e6, event_id=>sprintf('%08x-%04x',rand 2**32,rand 65536), facet_data=>{about=>{package=>'Test2::Event::Ok',details=>join(' ',map{$w[rand @w]}1..20)}, trace=>{frame=>['main','t/foo.t',int rand 900,'Test2::Tools::Basic::ok'],pid=>$$,tid=>0,hid=>'abc-'.int(rand 99)}, assert=>{pass=>1,details=>join(' ',map{$w[rand @w]}1..60)}, info=>[map{{tag=>'NOTE',details=>join(' ',map{$w[rand @w]}1..25)}}1..3]});
  my $l=$J->encode(\%e); print $o "$l\n"; $t+=length $l }
