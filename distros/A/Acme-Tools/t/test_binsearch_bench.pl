#!/usr/bin/perl
use Acme::Tools;
use List::MoreUtils 'bsearch'; #':all';
use Benchmark qw(:all) ;

my @a = map [$_,$_**1.6+1e4], 1e5..2e5;

my $t=time_fp();

my($h)=(List::MoreUtils::bsearch {$$_[0] cmp 194022} @a);

print time_fp()-$t,"\n";

print srlz(\$h,"h");
my($i,$h1,$h2,$h3);
my $cnt=3000;
my @find1=map random(1e5,2e5), 1..$cnt;
my @find2=@find1;
my @find3=@find1;
timethese($cnt, {   #for some mystical reason Acme::Tools seems 11x faster(?)
    'Name1' => sub { my$r=pop@find1;($h1)=(List::MoreUtils::bsearch {$$_[0] <=> $r} @a) },
#   'Name2' => sub { $i=Acme::Tools::binsearch(pop(@find2),\@a); $h2=$a[$i] },
    'Name3' => sub { $i=Acme::Tools::binsearch([pop@find3],\@a,undef,sub{$_[0][0]<=>$_[1][0]}); $h3=$a[$i] },
	  });

print srlz(\$h1,'h1');
print srlz(\$h3,'h3');
#print "i=$i   h=".srlz(\$h)."\n";

my @data=(    map {  {num=>$_,sqrt=>sqrt($_), square=>$_**2}  }
              grep !($_%7), 1..1000000                               );
my $i = binsearch( {num=>913374}, \@data, undef, sub {$_[0]{num} <=> $_[1]{num}} );
my $found = defined $i ? $data[$i] : undef;
print "i=$i\n";
print srlz(\$found,'f');

print "Binsearch_steps = $Acme::Tools::Binsearch_steps\n";
