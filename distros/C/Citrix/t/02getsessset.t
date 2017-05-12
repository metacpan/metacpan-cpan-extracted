#!/usr/local/bin/perl
# To do more persistent testing set following vars in ENV
my @parakeys = ('CITRIX_MH', 'CITRIX_DS');
#use Test::Simple tests => 7;
use Test::More ; # tests => 3; # ('no_plan')
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use lib('..');
use lib('../..');

#use Citrix::Config;
#use Citrix::LaunchMesg;
#use Citrix::SessOp;
#use Citrix::SessionSet;
use Citrix;


#DEBUG:print(STDERR Dumper(\%ENV));exit(0);
#DEBUG:print(STDERR Dumper([@ENV{@parakeys}]));exit(0);
my ($host, $dsuff) = (@ENV{@parakeys});
my $psrc = 'ENV';
# Allow params to come from %ENV
#my $pcnt = scalar();
#DEBUG:print(STDERR "Params: $pcnt\n");
if ($host && $dsuff) {
   #($host, $dsuff) = @ENV{@parakeys};
   plan('tests' => 3, ); # "3 tests"
}
else {
  #$host  = prompt("Enter Citrix servername (by DNS name):\n");
  #$dsuff = prompt("Enter DNS Domain suffix:\n");
  #$psrc = 'PROMPT';
  SKIP: {
    plan(skip_all => "No ENV Settings 'CITRIX_MH', 'CITRIX_DS' Found");
  };
}
#print(STDERR "Using $host / $dsuff (from: $psrc)\n");
my $fc = {'mh' => $host, 'ds' => $dsuff, 'debug' => 5, };
#ok($host, "Got Host name");
#print(STDERR "Trying construction by '$host.$dsuff'\n");
my $ss = Citrix::SessionSet->new($fc);
#DEBUG:print(Dumper($ss));
ok($ss, "Constructed session set instance");
my $err = $ss->gethostsess($host);
if ($err) {print(STDERR "Failed gethostsess() err=$err".$ss->{'errstr'}."\n");}
ok(!$err, "Got sessionset without errors");
#DEBUG:print(Dumper($ss));
# Any Real Farm would give session results (at least some disconnected sessions)
my $sesscnt = $ss->count();
#print(STDERR "Got $sesscnt Sessions\n");
ok($sesscnt > 0, "Got a set of Sessions");
$! = 0;
$? = 0;

sub prompt {
   my ($ptext) = @_;
   print(STDERR "$ptext\n");
   my $resp = <STDIN>;
   chomp($resp);
   return($resp);
}



