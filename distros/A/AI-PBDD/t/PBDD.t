# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl PBDD.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 39;
BEGIN { use_ok('AI::PBDD') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

sub DumpBDD {
    my ($bdd,$names) = @_;
    my ($idx, $then, $else);

    if (AI::PBDD::internal_isconst($bdd) && AI::PBDD::internal_constvalue($bdd)) {
      return 'T';
    }
    if (AI::PBDD::internal_isconst($bdd) && !AI::PBDD::internal_constvalue($bdd)) {
      return 'F';
    }
    $idx = AI::PBDD::internal_index($bdd);
    $then = DumpBDD(AI::PBDD::internal_then($bdd), $names);
    $else = DumpBDD(AI::PBDD::internal_else($bdd), $names);

    return $$names{$idx} . " ($then) ($else)";
}

{
  #
  # getOne
  #
  AI::PBDD::init(100,1000000);
  my $v = AI::PBDD::getOne();
  is($v, 1, "getOne()");  
  AI::PBDD::kill();
}

{
  #
  # getZero
  #
  AI::PBDD::init(100,1000000);
  my $v = AI::PBDD::getZero();
  is($v, 0, "getZero()"); 
  AI::PBDD::kill();
}

{
  #
  # createBDD
  #

  # created BDDs (variables) are even integers
  AI::PBDD::init(100,1000000);
  my $v = AI::PBDD::createBDD();

  ok(!($v % 2), "first createBDD()");  

  ok(!($v % 2), "second createBDD()");  
  AI::PBDD::kill();
}

{
  #
  # getVarCount
  # getBDD
  #
  AI::PBDD::init(100,1000000);
  my $v1 = AI::PBDD::createBDD();
  my $v2 = AI::PBDD::createBDD();
  my $v3 = AI::PBDD::createBDD();
  my $v4 = AI::PBDD::createBDD();

  my $n = AI::PBDD::getVarCount();

  is($n, 4, "getVarCount()");  
  
  my $i = AI::PBDD::getBDD(2);
  is($i, $v3, "getBDD()");  

  AI::PBDD::kill();
}

{
  #
  # ref
  # deref
  # localDeref
  #
  AI::PBDD::init(100,1000000);
  my $bdd1 = AI::PBDD::createBDD();
  my $bdd2 = AI::PBDD::createBDD();
  # need a composite BDD: variables refcount is always 1023	
  my $bdd = AI::PBDD::and($bdd1,$bdd2); 

  AI::PBDD::ref($bdd);
  AI::PBDD::ref($bdd);

  my $rc = AI::PBDD::internal_refcount($bdd);
  is($rc, 3, "ref()");  

  AI::PBDD::deref($bdd);

  $rc = AI::PBDD::internal_refcount($bdd);
  is($rc, 2, "deref()");  

  AI::PBDD::localDeref($bdd);

  $rc = AI::PBDD::internal_refcount($bdd);
  is($rc, 1, "localDeref()");  
  
  AI::PBDD::kill();
}

{
  #
  # and
  # andTo
  #
  AI::PBDD::init(100,1000000);
  my %names = ();
  my $bdd1 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd1)} = 'A';
  my $bdd2 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd2)} = 'B';
  my $bdd3 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd3)} = 'C';

  my $bdd = AI::PBDD::and($bdd1,$bdd2);
  my $dmp = DumpBDD($bdd, \%names);
  is($dmp, "A (B (T) (F)) (F)", "and()");  
  
  my $bddTo = AI::PBDD::andTo($bdd,$bdd3);
  $dmp = DumpBDD($bddTo, \%names);
  my $rc = AI::PBDD::internal_refcount($bdd);
  ok($dmp eq "A (B (C (T) (F)) (F)) (F)" && $rc == 0, "andTo()");  

  AI::PBDD::kill();
}

{
  #
  # or
  # orTo
  #
  AI::PBDD::init(100,1000000);
  my %names = ();
  my $bdd1 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd1)} = 'A';
  my $bdd2 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd2)} = 'B';
  my $bdd3 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd3)} = 'C';

  my $bdd = AI::PBDD::or($bdd1,$bdd2);
  my $dmp = DumpBDD($bdd, \%names);
  is($dmp, "A (T) (B (T) (F))", "or()");  

  my $bddTo = AI::PBDD::orTo($bdd,$bdd3);
  $dmp = DumpBDD($bddTo, \%names);
  my $rc = AI::PBDD::internal_refcount($bdd);
  ok($dmp eq "A (T) (B (T) (C (T) (F)))" && $rc == 0, "orTo()");  
  
  AI::PBDD::kill();
}

{
  #
  # nand
  #
  AI::PBDD::init(100,1000000);
  my %names = ();
  my $bdd1 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd1)} = 'A';
  my $bdd2 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd2)} = 'B';

  my $bdd = AI::PBDD::nand($bdd1,$bdd2);
  my $dmp = DumpBDD($bdd, \%names);
  is($dmp, "A (B (F) (T)) (T)", "nand()");  

  AI::PBDD::kill();
}

{
  #
  # nor
  #
  AI::PBDD::init(100,1000000);
  my %names = ();
  my $bdd1 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd1)} = 'A';
  my $bdd2 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd2)} = 'B';

  my $bdd = AI::PBDD::nor($bdd1,$bdd2);
  my $dmp = DumpBDD($bdd, \%names);
  is($dmp, "A (F) (B (F) (T))", "nor()");  

  AI::PBDD::kill();
}

{
  #
  # xor
  #
  AI::PBDD::init(100,1000000);
  my %names = ();
  my $bdd1 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd1)} = 'A';
  my $bdd2 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd2)} = 'B';

  my $bdd = AI::PBDD::xor($bdd1,$bdd2);
  my $dmp = DumpBDD($bdd, \%names);
  is($dmp, "A (B (F) (T)) (B (T) (F))", "xor()");  

  AI::PBDD::kill();
}

{
  #
  # ite
  #
  AI::PBDD::init(100,1000000);
  my %names = ();
  my $bdd1 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd1)} = 'A';
  my $bdd2 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd2)} = 'B';
  my $bdd3 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd3)} = 'C';

  my $bdd = AI::PBDD::ite($bdd1,$bdd2, $bdd3);
  my $dmp = DumpBDD($bdd, \%names);
  is($dmp, "A (B (T) (F)) (C (T) (F))", "ite()");  

  AI::PBDD::kill();
}

{
  #
  # imp
  #
  AI::PBDD::init(100,1000000);
  my %names = ();
  my $bdd1 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd1)} = 'A';
  my $bdd2 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd2)} = 'B';

  my $bdd = AI::PBDD::imp($bdd1,$bdd2);
  my $dmp = DumpBDD($bdd, \%names);
  is($dmp, "A (B (T) (F)) (T)", "imp()");  

  AI::PBDD::kill();
}

{
  #
  # biimp
  #
  AI::PBDD::init(100,1000000);
  my %names = ();
  my $bdd1 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd1)} = 'A';
  my $bdd2 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd2)} = 'B';

  my $bdd = AI::PBDD::biimp($bdd1,$bdd2);
  my $dmp = DumpBDD($bdd, \%names);
  is($dmp, "A (B (T) (F)) (B (F) (T))", "biimp()");  

  AI::PBDD::kill();
}

{
  #
  # not
  #
  AI::PBDD::init(100,1000000);
  my %names = ();
  my $bdd1 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd1)} = 'A';

  my $bdd = AI::PBDD::not($bdd1);
  my $dmp = DumpBDD($bdd, \%names);
  is($dmp, "A (F) (T)", "not()");  

  AI::PBDD::kill();
}

{
  #
  # makeSet
  #
  my @vars;
  my %names = ();
  AI::PBDD::init(100,1000000);
  my $bdd1 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd1)} = 'A';
  push @vars, $bdd1;
  my $bdd2 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd2)} = 'B';
  push @vars, $bdd2;
  
  my $set = AI::PBDD::makeSet(\@vars, 2);
  my $dmp = DumpBDD($set, \%names);

  is($dmp, "A (B (T) (F)) (F)", "first makeSet()");  

  $set = AI::PBDD::makeSet(\@vars, 1, 1);
  $dmp = DumpBDD($set, \%names);

  is($dmp, "B (T) (F)", "second makeSet()");  

  AI::PBDD::kill();
}

{
  #
  # exists
  #
  AI::PBDD::init(100,1000000);
  my %names = ();
  my $bdd1 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd1)} = 'A';
  my $bdd2 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd2)} = 'B';
  my $bdd3 = AI::PBDD::and($bdd1,$bdd2);

  my $bdd = AI::PBDD::exists($bdd3, $bdd1);
  my $dmp = DumpBDD($bdd, \%names);
  is($dmp, "B (T) (F)", "first exists()");  

  $bdd = AI::PBDD::exists($bdd3, $bdd2);
  $dmp = DumpBDD($bdd, \%names);
  is($dmp, "A (T) (F)", "second exists()");  

  AI::PBDD::kill();
}

{
  #
  # forall
  #
  AI::PBDD::init(100,1000000);
  my %names = ();
  my $bdd1 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd1)} = 'A';
  my $bdd2 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd2)} = 'B';
  my $bdd3 = AI::PBDD::or($bdd1,$bdd2);

  my $bdd = AI::PBDD::forall($bdd3, $bdd1);
  my $dmp = DumpBDD($bdd, \%names);
  is($dmp, "B (T) (F)", "first forall()");  

  $bdd = AI::PBDD::forall($bdd3, $bdd2);
  $dmp = DumpBDD($bdd, \%names);
  is($dmp, "A (T) (F)", "second forall()");  

  AI::PBDD::kill();
}

{
  #
  # relProd
  #
  AI::PBDD::init(100,1000000);
  my %names = ();
  my $bdd1 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd1)} = 'A';
  my $bdd2 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd2)} = 'B';
  my $bdd3 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd3)} = 'C';
  my $bdd4 = AI::PBDD::and($bdd1,$bdd2);
  my $bdd5 = AI::PBDD::and($bdd2,$bdd3);

  my $bdd = AI::PBDD::relProd($bdd4, $bdd5, $bdd2);
  my $dmp = DumpBDD($bdd, \%names);
  is($dmp, "A (C (T) (F)) (F)", "relProd()");  

  AI::PBDD::kill();
}

{
  #
  # restrict
  #
  AI::PBDD::init(100,1000000);
  my %names = ();
  my $bdd1 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd1)} = 'A';
  my $bdd2 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd2)} = 'B';
  my $bdd3 = AI::PBDD::and($bdd1,$bdd2);

  my $bdd = AI::PBDD::restrict($bdd3, $bdd1);
  my $dmp = DumpBDD($bdd, \%names);
  is($dmp, "B (T) (F)", "first restrict()");  

  $bdd = AI::PBDD::restrict($bdd3, AI::PBDD::not($bdd1));
  $dmp = DumpBDD($bdd, \%names);
  is($dmp, "F", "second restrict()");  

  AI::PBDD::kill();
}

{
  #
  # constrain
  #
  AI::PBDD::init(100,1000000);
  my %names = ();
  my $bdd1 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd1)} = 'A';
  my $bdd2 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd2)} = 'B';
  my $bdd3 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd3)} = 'C';
  my $bdd4 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd4)} = 'D';
  my $bdd5 = AI::PBDD::or($bdd1,$bdd2);
  my $bdd6 = AI::PBDD::or($bdd3,$bdd4);
  my $bdd7 = AI::PBDD::and($bdd5,$bdd6);
  my $bdd8 = AI::PBDD::or($bdd1,$bdd3);

  my $bdd = AI::PBDD::constrain($bdd7, $bdd8);
  my $dmp = DumpBDD($bdd, \%names);
  is($dmp, "A (C (T) (D (T) (F))) (B (T) (F))", "constrain()");  

  AI::PBDD::kill();
}

{
  #
  # replace
  #
  AI::PBDD::init(100,1000000);
  my %names = ();
  my $bdd1 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd1)} = 'A';
  my $bdd2 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd2)} = 'B';
  my $bdd3 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd3)} = 'C';
  my $bdd4 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd4)} = 'D';
  my $bdd5 = AI::PBDD::or($bdd1, $bdd2);

  my @old = ($bdd1,$bdd2);
  my @new = ($bdd3,$bdd4);

  my $pair = AI::PBDD::createPair(\@old, \@new);

  my $bdd = AI::PBDD::replace($bdd5, $pair);
  my $dmp = DumpBDD($bdd, \%names);
  is($dmp, "C (T) (D (T) (F))", "replace()");  

  AI::PBDD::deletePair($pair);

  AI::PBDD::kill();
}

{
  #
  # support
  #
  AI::PBDD::init(100,1000000);
  my %names = ();
  my $bdd1 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd1)} = 'A';
  my $bdd2 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd2)} = 'B';
  my $bdd = AI::PBDD::and($bdd1, $bdd2);

  my $cube = AI::PBDD::support($bdd);
  my $dmp = DumpBDD($cube, \%names);
  is($dmp, "A (B (T) (F)) (F)", "support()");  

  AI::PBDD::kill();
}

{
  #
  # nodeCount
  #
  AI::PBDD::init(100,1000000);
  my %names = ();
  my $bdd1 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd1)} = 'A';
  my $bdd2 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd2)} = 'B';
  my $bdd3 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd3)} = 'C';
  my $bdd4 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd4)} = 'D';
  my $bdd5 = AI::PBDD::or($bdd1, $bdd2);
  my $bdd6 = AI::PBDD::or($bdd3, $bdd4);
  my $bdd7 = AI::PBDD::and($bdd5, $bdd6);

  my $cnt = AI::PBDD::nodeCount($bdd7);
  is($cnt, 4, "nodeCount()");  

  AI::PBDD::kill();
}

{
  #
  # satOne
  # satCount
  #
  AI::PBDD::init(100,1000000);
  my %names = ();
  my $bdd1 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd1)} = 'A';
  my $bdd2 = AI::PBDD::createBDD();
  $names{AI::PBDD::internal_index($bdd2)} = 'B';

  my $bdd = AI::PBDD::xor($bdd1, $bdd2);
  my $minterm = AI::PBDD::satOne($bdd);
  my $dmp = DumpBDD($minterm, \%names);
  ok($dmp eq "A (B (F) (T)) (F)" ||
     $dmp eq "A (F) (B (T) (F))", "satOne()");  

  my $cnt = AI::PBDD::satCount($bdd);
  is($cnt, 2*2**98, "first satCount()");

  $cnt = AI::PBDD::satCount($bdd,98);
  is($cnt, 2, "second satCount()");

  $bdd = AI::PBDD::or($bdd1, $bdd2);
  $cnt = AI::PBDD::satCount($bdd);
  is($cnt, 3*2**98, "third satCount()");

  $cnt = AI::PBDD::satCount($bdd,98);
  is($cnt, 3, "fourth satCount()");

  AI::PBDD::kill();
}
