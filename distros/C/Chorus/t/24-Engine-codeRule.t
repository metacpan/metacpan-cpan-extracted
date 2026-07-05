#!perl -T

# Note on test design:
#   Rules loaded via loadRules() are executed by loop(), which iterates as long
#   as at least one rule returns a truthy value. To avoid infinite loops, each
#   test rule uses an EXCEPTION guard on the slot it sets, making it idempotent:
#   the rule fires once per frame (marks it), then the exception prevents re-firing.

use strict;
use Test::More tests => 12;
use Chorus::Frame;
use Chorus::Engine;
use File::Temp qw(tempdir);
use YAML qw(DumpFile);

diag("Testing Chorus::Engine::codeRule/loadRules $Chorus::Engine::VERSION, Perl $], $^X");

sub make_engine {
  my $e = Chorus::Engine->new();
  $e->set('BOARD', Chorus::Frame->new());
  return $e;
}

sub rule_dir {
  my %rules = @_;
  my $dir = tempdir(CLEANUP => 1);
  DumpFile("$dir/$_.yml", $rules{$_}) for keys %rules;
  return $dir;
}

# -----------------------------------------------------------------------
# Test 1 : _ID généré depuis le champ REGLE
# -----------------------------------------------------------------------
{
  my $e   = make_engine();
  my $dir = rule_dir(rule01 => {
    REGLE     => 'mark-all',
    CHERCHER  => { x => { attribut => 'color' } },
    EXCEPTION => q{$x->{tagged}},
    EFFET     => q{$x->set('tagged','y'); 1},
  });
  $e->loadRules($dir);
  is($e->{_RULES}[0]->_ID, 'mark-all', 'Test 1 - codeRule sets _ID from REGLE');
}

# -----------------------------------------------------------------------
# Test 2 : EFFET appliqué à tous les frames du scope
# -----------------------------------------------------------------------
{
  my $e   = make_engine();
  my $f1  = Chorus::Frame->new(color => 'blue');
  my $f2  = Chorus::Frame->new(color => 'red');
  my $dir = rule_dir(rule01 => {
    REGLE     => 'tag-all',
    CHERCHER  => { x => { attribut => 'color' } },
    EXCEPTION => q{$x->{tagged}},
    EFFET     => q{$x->set('tagged','y'); 1},
  });
  $e->loadRules($dir);
  $e->loop();
  ok($f1->tagged, 'Test 2 - EFFET applied to all frames in scope (f1)');
  ok($f2->tagged, 'Test 2b - EFFET applied to all frames in scope (f2)');
}

# -----------------------------------------------------------------------
# Test 3 : CONDITION — seuls les frames satisfaisant la condition sont traités
# -----------------------------------------------------------------------
{
  my $e   = make_engine();
  my $f1  = Chorus::Frame->new(color => 'blue');
  my $f2  = Chorus::Frame->new(color => 'red');
  my $dir = rule_dir(rule01 => {
    REGLE     => 'only-blue',
    CHERCHER  => { x => { attribut => 'color' } },
    CONDITION => q{$x->{color} eq 'blue'},
    EXCEPTION => q{$x->{is_blue}},
    EFFET     => q{$x->set('is_blue','y'); 1},
  });
  $e->loadRules($dir);
  $e->loop();
  ok($f1->is_blue,  'Test 3 - CONDITION: matching frame gets effect');
  ok(!$f2->is_blue, 'Test 3b - CONDITION: non-matching frame is skipped');
}

# -----------------------------------------------------------------------
# Test 4 : EXCEPTION — les frames vérifiant l'exception sont sautés
# -----------------------------------------------------------------------
{
  my $e   = make_engine();
  my $f1  = Chorus::Frame->new(color => 'blue');
  my $f2  = Chorus::Frame->new(color => 'blue', frozen => 'y');
  my $dir = rule_dir(rule01 => {
    REGLE     => 'skip-frozen',
    CHERCHER  => { x => { attribut => 'color' } },
    EXCEPTION => q{$x->{frozen} or $x->{processed}},
    EFFET     => q{$x->set('processed','y'); 1},
  });
  $e->loadRules($dir);
  $e->loop();
  ok($f1->processed,  'Test 4 - EXCEPTION: non-frozen frame gets effect');
  ok(!$f2->processed, 'Test 4b - EXCEPTION: frozen frame is skipped');
}

# -----------------------------------------------------------------------
# Test 5 : CONDITION + EXCEPTION combinés
# -----------------------------------------------------------------------
{
  my $e   = make_engine();
  my $f1  = Chorus::Frame->new(color => 'blue');                 # passes both
  my $f2  = Chorus::Frame->new(color => 'red');                  # fails condition
  my $f3  = Chorus::Frame->new(color => 'blue', frozen => 'y');  # fails exception
  my $dir = rule_dir(rule01 => {
    REGLE     => 'blue-not-frozen',
    CHERCHER  => { x => { attribut => 'color' } },
    CONDITION => q{$x->{color} eq 'blue'},
    EXCEPTION => q{$x->{frozen} or $x->{ok}},
    EFFET     => q{$x->set('ok','y'); 1},
  });
  $e->loadRules($dir);
  $e->loop();
  ok($f1->ok,  'Test 5 - CONDITION+EXCEPTION: matching non-frozen frame gets effect');
  ok(!$f2->ok, 'Test 5b - CONDITION+EXCEPTION: non-matching frame skipped');
  ok(!$f3->ok, 'Test 5c - CONDITION+EXCEPTION: frozen frame skipped');
}

# -----------------------------------------------------------------------
# Test 6 : EFFET multiple — plusieurs instructions exécutées dans l'ordre
# -----------------------------------------------------------------------
{
  my $e   = make_engine();
  my $f1  = Chorus::Frame->new(color => 'blue');
  my $dir = rule_dir(rule01 => {
    REGLE     => 'multi-effet',
    CHERCHER  => { x => { attribut => 'color' } },
    EXCEPTION => q{$x->{done}},
    EFFET     => [ q{$x->set('step1','y')}, q{$x->set('done','y'); 1} ],
  });
  $e->loadRules($dir);
  $e->loop();
  ok($f1->step1, 'Test 6 - multi-EFFET: first effect applied');
  ok($f1->done,  'Test 6b - multi-EFFET: second effect applied');
}

done_testing();
