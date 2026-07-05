#!perl -T

# Tests for Copy-on-Write (CoW) behaviour introduced via _PARENT_KEY
#
# Design:
#   - Each sub-frame created inline in the constructor receives a _PARENT_KEY
#     equal to its immediate parent's _KEY.
#   - When _setN traverses a multi-level path (followWay truthy) and encounters
#     a sub-frame it does not own (_PARENT_KEY != $this->{_KEY}), it creates a
#     local shadow frame inheriting the shared one via _ISA and writes there.
#   - The original (shared) frame is left untouched.
#   - Single-level set (followWay empty) is NOT subject to CoW — the existing
#     behaviour (_setValue / _setSlot directly on the crossed Frame) is preserved,
#     so that procedural hooks (_BEFORE / _AFTER) still fire correctly.

use strict;
use Test::More tests => 13;
use Chorus::Frame;

diag("Testing Chorus::Frame Copy-on-Write (_PARENT_KEY) $Chorus::Frame::VERSION, Perl $], $^X");

# -----------------------------------------------------------------------
# Test 1 : sous-frame inline reçoit _PARENT_KEY au constructeur
# -----------------------------------------------------------------------
{
  my $f = Chorus::Frame->new(
    body => { color => 'blue' }
  );
  ok(
    defined($f->{body}{_PARENT_KEY}) && $f->{body}{_PARENT_KEY} eq $f->{_KEY},
    'Test 1 - inline sub-frame gets _PARENT_KEY == parent _KEY'
  );
}

# -----------------------------------------------------------------------
# Test 2 : set multi-niveaux via frame partagé → shadow CoW créé
# -----------------------------------------------------------------------
{
  my $parent = Chorus::Frame->new(body => { color => 'blue' });
  my $child  = Chorus::Frame->new(_ISA => $parent);

  $child->set('body color', 'red');

  isnt(
    $child->{body},
    $parent->{body},
    'Test 2 - set on shared sub-frame creates a local shadow (different ref)'
  );
}

# -----------------------------------------------------------------------
# Test 3 : le parent n'est pas muté
# -----------------------------------------------------------------------
{
  my $parent = Chorus::Frame->new(body => { color => 'blue' });
  my $child  = Chorus::Frame->new(_ISA => $parent);

  $child->set('body color', 'red');

  is(
    $parent->get('body color'),
    'blue',
    'Test 3 - parent sub-frame is NOT mutated after child CoW set'
  );
}

# -----------------------------------------------------------------------
# Test 4 : le child voit la nouvelle valeur après CoW
# -----------------------------------------------------------------------
{
  my $parent = Chorus::Frame->new(body => { color => 'blue' });
  my $child  = Chorus::Frame->new(_ISA => $parent);

  $child->set('body color', 'red');

  is(
    $child->get('body color'),
    'red',
    'Test 4 - child sees the new value after CoW set'
  );
}

# -----------------------------------------------------------------------
# Test 5 : le shadow hérite des slots non modifiés via _ISA
# -----------------------------------------------------------------------
{
  my $parent = Chorus::Frame->new(body => { color => 'blue', size => 'large' });
  my $child  = Chorus::Frame->new(_ISA => $parent);

  $child->set('body color', 'red');

  is(
    $child->get('body size'),
    'large',
    'Test 5 - shadow inherits unmodified slots from parent via _ISA'
  );
}

# -----------------------------------------------------------------------
# Test 6 : set simple (un seul niveau) ne crée pas de shadow — modifie localement
# -----------------------------------------------------------------------
{
  my $parent = Chorus::Frame->new(color => 'blue');
  my $child  = Chorus::Frame->new(_ISA => $parent);

  $child->set('color', 'red');

  is($child->get('color'), 'red', 'Test 6 - single-level set works on child');
  is($parent->get('color'), 'blue', 'Test 6b - single-level set does not touch parent');
}

# -----------------------------------------------------------------------
# Test 7 : _AFTER toujours déclenché sur set d'un sous-frame (followWay vide)
# -----------------------------------------------------------------------
{
  my $fired = 0;
  my $f = Chorus::Frame->new(
    body => {
      _AFTER => sub { $fired = 1 },
    }
  );

  $f->set('body', 'trigger');
  ok($fired, 'Test 7 - _AFTER still fires when followWay is empty (no CoW short-circuit)');
}

# -----------------------------------------------------------------------
# Test 8 : set multi-niveaux sur frame propre (même _PARENT_KEY) → pas de shadow
# -----------------------------------------------------------------------
{
  my $f = Chorus::Frame->new(body => { color => 'blue' });

  my $body_before = $f->{body};
  $f->set('body color', 'green');
  my $body_after = $f->{body};

  is($body_before, $body_after, 'Test 8 - no shadow created when sub-frame is already owned');
  is($f->get('body color'), 'green', 'Test 8b - owned sub-frame is mutated in place');
}

# -----------------------------------------------------------------------
# Test 9 : set simple (followWay vide) sur frame partagé → shadow CoW
#           (le vrai défaut architectural — corrigé par suppression de la garde)
# -----------------------------------------------------------------------
{
  my $shared = Chorus::Frame->new(_DEFAULT => 'blue');
  my $f1     = Chorus::Frame->new(color => $shared);
  my $f2     = Chorus::Frame->new(color => $shared);

  $f2->set('color', 'red');

  isnt($f2->{color}, $shared,  'Test 9  - single-level set on shared frame creates shadow');
  is($f1->get('color'), 'blue', 'Test 9b - f1 not mutated after f2 single-level CoW set');
  is($f2->get('color'), 'red',  'Test 9c - f2 sees the new value');
}

done_testing();
