#!perl -T

# ============================================================================
# 26-Frame-reset.t — Chorus::Frame::_reset()
#
# Vérifie que _reset() vide complètement les registres globaux (%FMAP,
# %REPOSITORY, %INSTANCES) et remet $getMode à N.
# Cela garantit l'isolation entre tests qui partagent le même processus.
# ============================================================================

use strict;
use Test::More tests => 5;
use Chorus::Frame;

diag("Testing Chorus::Frame::_reset $Chorus::Frame::VERSION, Perl $], $^X");

# -----------------------------------------------------------------------
# Test 1 : un frame créé avant _reset() n'est plus visible par fmatch()
# -----------------------------------------------------------------------
{
  my $f = Chorus::Frame->new(sentinel => 'y');
  my @before = fmatch(slot => 'sentinel');
  ok(scalar(@before) >= 1, 'Test 1 - frame with sentinel visible before _reset()');
}

Chorus::Frame::_reset();

{
  my @after = fmatch(slot => 'sentinel');
  is(scalar(@after), 0, 'Test 2 - frame with sentinel no longer visible after _reset()');
}

# -----------------------------------------------------------------------
# Test 3 : un frame créé après _reset() est bien enregistré
# -----------------------------------------------------------------------
{
  my $f = Chorus::Frame->new(fresh => 'y');
  my @found = fmatch(slot => 'fresh');
  is(scalar(@found), 1, 'Test 3 - frame created after _reset() is registered');
}

# -----------------------------------------------------------------------
# Test 4 : _reset() remet le mode d'héritage à N
# -----------------------------------------------------------------------
{
  Chorus::Frame::setMode('Z');
  Chorus::Frame::_reset();

  # En mode N : $f1 fournit _DEFAULT pour 'x', $f2 hérite → get retourne
  # la valeur _DEFAULT de f1 (mode N remonte vers le parent)
  my $f1 = Chorus::Frame->new(x => { _DEFAULT => 'from-parent' });
  my $f2 = Chorus::Frame->new(_ISA => $f1);
  is($f2->get('x'), 'from-parent', 'Test 4 - _reset() restores getMode to N');
}

# -----------------------------------------------------------------------
# Test 5 : _reset() vide la pile $SELF / @Heap
# -----------------------------------------------------------------------
{
  Chorus::Frame::_reset();

  # Après _reset(), $SELF doit être undef (pas de contexte en cours)
  ok(!defined($Chorus::Frame::SELF), 'Test 5 - _reset() clears $SELF context');
}

done_testing();
