#!perl -T

use strict;
use Test::More tests => 11;
use Chorus::Frame;
use Chorus::Engine;
use Chorus::Expert;

diag("Testing Chorus::Expert $Chorus::Expert::VERSION, Perl $], $^X");

# Test 1 : new() crée bien un objet Chorus::Expert
{
  my $xprt = Chorus::Expert->new();
  isa_ok($xprt, 'Chorus::Expert', 'Test 1 - new() creates a Chorus::Expert object');
}

# Test 2 : register() injecte BOARD sur chaque agent
{
  my $xprt = Chorus::Expert->new();
  my $e    = Chorus::Engine->new();
  $xprt->register($e);
  ok($e->BOARD, 'Test 2 - register() sets BOARD on engine');
}

# Test 3 : register() injecte EXPERT (back-ref) sur chaque agent
{
  my $xprt = Chorus::Expert->new();
  my $e    = Chorus::Engine->new();
  $xprt->register($e);
  is($e->EXPERT, $xprt, 'Test 3 - register() sets EXPERT back-ref on engine');
}

# Test 4 : BOARD est le même objet pour tous les agents enregistrés
{
  my $xprt       = Chorus::Expert->new();
  my ($e1, $e2)  = (Chorus::Engine->new(), Chorus::Engine->new());
  $xprt->register($e1, $e2);
  is($e1->BOARD, $e2->BOARD, 'Test 4 - BOARD is shared between agents');
}

# Test 5 : process($input) expose INPUT sur le BOARD partagé
{
  my $xprt = Chorus::Expert->new();
  my $e    = Chorus::Engine->new();
  my $seen;
  $xprt->register($e);
  $e->addrule(
    _SCOPE => { x => [1] },
    _APPLY => sub {
      $seen = $e->BOARD->INPUT;
      $e->solved();
      return 1;
    }
  );
  $xprt->process('hello');
  is($seen, 'hello', 'Test 5 - process($input) sets BOARD->INPUT');
}

# Test 6 : process() retourne 1 quand un agent appelle solved()
{
  my $xprt = Chorus::Expert->new();
  my $e    = Chorus::Engine->new();
  $xprt->register($e);
  $e->addrule(
    _SCOPE => { x => [1] },
    _APPLY => sub { $e->solved(); return 1; }
  );
  my $res = $xprt->process();
  is($res, 1, 'Test 6 - process() returns 1 on SOLVED');
}

# Test 7 : process() retourne undef quand un agent appelle failed()
{
  my $xprt = Chorus::Expert->new();
  my $e    = Chorus::Engine->new();
  $xprt->register($e);
  $e->addrule(
    _SCOPE => { x => [1] },
    _APPLY => sub { $e->failed(); return 1; }
  );
  my $res = $xprt->process();
  ok(!defined($res), 'Test 7 - process() returns undef on FAILED');
}

# Test 8 : multi-agents — les agents sont appelés dans l'ordre d'enregistrement
{
  my $xprt      = Chorus::Expert->new();
  my ($e1, $e2) = (Chorus::Engine->new(), Chorus::Engine->new());
  my @order;
  $xprt->register($e1);
  $xprt->register($e2);
  $e1->addrule(
    _SCOPE => { x => [1] },
    _APPLY => sub { push @order, 'e1'; return; }
  );
  $e2->addrule(
    _SCOPE => { x => [1] },
    _APPLY => sub { push @order, 'e2'; $e2->solved(); return 1; }
  );
  $xprt->process();
  is_deeply(\@order, ['e1', 'e2'], 'Test 8 - agents called in registration order');
}

# Test 9 : loop() émet un warning et converge si _MAX_CYCLES est dépassé
{
  my $xprt = Chorus::Expert->new();
  my $e    = Chorus::Engine->new();
  $e->set('_MAX_CYCLES', 3);   # limite basse pour le test
  $xprt->register($e);
  $e->addrule(
    _SCOPE => { x => [1] },
    _APPLY => sub { return 1; }  # toujours vrai → jamais solved ni failed
  );
  my $warned = 0;
  local $SIG{__WARN__} = sub { $warned = 1 if $_[0] =~ /max cycles/ };
  $e->loop();
  ok($warned, 'Test 9 - loop() emits a warning when _MAX_CYCLES is exceeded');
}

# Test 10 : deux instances Expert sont indépendantes (agents isolés)
{
  my $xprt1 = Chorus::Expert->new();
  my $xprt2 = Chorus::Expert->new();
  my $e1    = Chorus::Engine->new();
  my $e2    = Chorus::Engine->new();
  $xprt1->register($e1);
  $xprt2->register($e2);
  isnt($e1->BOARD, $e2->BOARD,
    'Test 10 - two Expert instances have separate BOARDs');
}

# Test 11 : process() de xprt1 ne déclenche pas les agents de xprt2
{
  my $xprt1 = Chorus::Expert->new();
  my $xprt2 = Chorus::Expert->new();
  my ($e1, $e2) = (Chorus::Engine->new(), Chorus::Engine->new());
  my $fired2 = 0;
  $xprt1->register($e1);
  $xprt2->register($e2);
  $e1->addrule(
    _SCOPE => { x => [1] },
    _APPLY => sub { $e1->solved(); return 1; }
  );
  $e2->addrule(
    _SCOPE => { x => [1] },
    _APPLY => sub { $fired2++; $e2->solved(); return 1; }
  );
  $xprt1->process();
  is($fired2, 0, 'Test 11 - process() on xprt1 does not fire agents of xprt2');
}

done_testing();
