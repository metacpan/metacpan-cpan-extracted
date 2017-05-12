#!/usr/bin/perl
use Acme::Tools;
my $jobs=16;
my $cap=1000000;
my $error_rate=0.01;
my($pid,@pid);
for my $job (0..$jobs-1){
  unlink"/tmp/bf$job.bf";
  next if fork();
  my $t=time_fp();
  my @keys=grep$_%$jobs==$job,1..$cap;
  #my @keys=map rand(), 1..$cap/$jobs;
  my $bf=bfinit(error_rate=>$error_rate,capacity=>$cap,keys=>\@keys);
  bfstore($bf,"/tmp/bf$job.bf");
  print "job $job finished, ".(time_fp()-$t)." sec\n";
  exit;
}
1 while wait() != -1;
print "building finished\n";
my $bf=bfinit(error_rate=>$error_rate,capacity=>$cap);
for my $job (0..$jobs-1){
  print "Adding bloom filter $job...";
  my $t=time_fp();
  bfaddbf($bf,bfretrieve("/tmp/bf$job.bf"));
  print "took ".(time_fp()-$t)." sec\n";
}
print int($$bf{filterlength}/8)," bytes\n";
printf "%.1f%%\n",100*bfsum($bf)/$$bf{filterlength};
print "keys: $$bf{key_count}\n";
print "found: ".bfgrep($bf,[1..$cap/10])."\n";
my $tests=10000;
my $errs=bfgrep($bf,[$cap+1..$cap+1+$tests]);
print "Error rate: $errs/$tests = ".($errs/$tests)."\n";

bfstore($bf,"/tmp/bfall.bf");

$$bf{filter}="gone";
print serialize($bf,'bf','',2);
