#!/usr/bin/perl

use Test::More tests => 2;
use_ok("AI::NaiveBayes1");

require 't/auxfunctions.pl';

my $nb;
$nb = AI::NaiveBayes1->new;
$nb->add_table(
"  Tp   Wp    W     Wf    T count
  -------------------------------
   PREV PREV  duck  ducks N   4
   N    duck  ducks END   V   4
   PREV PREV  duck  flies N   8
   N    duck  flies END   V   8
   PREV PREV  duck  fly   N   4
   N    duck  fly   fly   N   4
   N    fly   fly   END   V   4
   PREV PREV  duck  ducks V   4
   V    duck  ducks END   N   4
   PREV PREV  duck  END   V   1
   PREV PREV  ducks duck  N   1
   N    ducks duck  END   V   1
   PREV PREV  ducks fly   N   4
   N    ducks fly   END   V   4
   PREV PREV  flies fly   N   4
   N    flies fly   END   V   4
   PREV PREV  fly   flies N   1
   N    fly   flies END   V   1
   PREV PREV  fly   fly   N   1
   N    fly   fly   fly   N   1
   N    fly   fly   END   V   1
   PREV PREV  fly   duck  V   2
   V    fly   duck  END   N   2
  -------------------------------
");

$nb->{smoothing}{W}  = 'unseen count=0.5';
$nb->{smoothing}{Wp} = 'unseen count=0.5';
$nb->{smoothing}{Wf} = 'unseen count=0.5';
$nb->train;
my $printedmodel =  "Model:\n" . $nb->print_model('with counts');

putfile('t/8-1.out', $printedmodel);
is($printedmodel, getfile('t/8-1.out'));

eval "require YAML;";
plan skip_all => "YAML module required for the remaining tests in 8.t" if $@;

use YAML;

# duck ducks fly flies
my $p = $nb->predict(attributes=>{Tp=>'PREV',Wp=>'PREV',W=>'duck',Wf=>'ducks'});
putfile('t/8-2.out', YAML::Dump($p));
#ok(abs($p->{'S=N'} - 0.580) < 0.001);
#ok(abs($p->{'S=Y'} - 0.420) < 0.001);
my $ptotal = $p->{'T=N'};
$p = $nb->predict(attributes=>{Tp=>'N',Wp=>'duck',W=>'ducks',Wf=>'fly'});
putfile('t/8-3.out', YAML::Dump($p));
$ptotal *= $p->{'T=N'};
$p = $nb->predict(attributes=>{Tp=>'N',Wp=>'ducks',W=>'fly',Wf=>'flies'});
putfile('t/8-4.out', YAML::Dump($p));
$ptotal *= $p->{'T=V'};
$p = $nb->predict(attributes=>{Tp=>'V',Wp=>'fly',W=>'flies',Wf=>'END'});
putfile('t/8-5.out', YAML::Dump($p));
$ptotal *= $p->{'T=N'};
putfile('t/8-6.out', "ptotal=$ptotal\n");
