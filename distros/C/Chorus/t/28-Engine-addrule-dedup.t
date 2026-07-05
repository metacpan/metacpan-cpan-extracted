#!perl -T

# Tests for addrule() duplicate _ID detection (DEBUG-01 §10)
#
# When two YAML files (or two addrule() calls) declare the same REGLE:/
# _ID, the second must be silently skipped with a warning — the rule
# must not fire twice per cycle.

use strict;
use Test::More;
use Test::Warn;
use Chorus::Frame;
use Chorus::Engine;
use File::Temp qw(tempdir);
use YAML qw(DumpFile);

diag("Testing Chorus::Engine::addrule duplicate _ID detection, Perl $], $^X");

sub make_engine {
    my $e = Chorus::Engine->new();
    $e->set('BOARD', Chorus::Frame->new());
    return $e;
}

# -----------------------------------------------------------------------
# Test 1-2 : addrule() direct — doublon détecté, warning émis
# -----------------------------------------------------------------------
{
    Chorus::Frame::_reset();

    my $e = make_engine();
    $e->addrule(_ID => 'my-rule', _SCOPE => {}, _APPLY => sub { });
    is(scalar @{$e->{_RULES}}, 1, 'Test 1 - première règle chargée');

    warning_like {
        $e->addrule(_ID => 'my-rule', _SCOPE => {}, _APPLY => sub { });
    } qr/duplicate rule _ID 'my-rule'/, 'Test 2 - doublon via addrule() émet un warning';
}

# -----------------------------------------------------------------------
# Test 3 : après doublon, _RULES ne contient toujours qu'une règle
# -----------------------------------------------------------------------
{
    Chorus::Frame::_reset();

    my $e = make_engine();
    $e->addrule(_ID => 'my-rule', _SCOPE => {}, _APPLY => sub { });

    warning_like {
        $e->addrule(_ID => 'my-rule', _SCOPE => {}, _APPLY => sub { });
    } qr/duplicate rule _ID 'my-rule'/, 'Test 3 - warning confirmé (deuxième appel)';

    is(scalar @{$e->{_RULES}}, 1,
        'Test 4 - _RULES contient 1 seule règle après doublon');
}

# -----------------------------------------------------------------------
# Test 4-5 : règles sans _ID ou avec _ID distincts — pas de dédup
# -----------------------------------------------------------------------
{
    Chorus::Frame::_reset();

    my $e = make_engine();
    $e->addrule(_SCOPE => {}, _APPLY => sub { });
    $e->addrule(_SCOPE => {}, _APPLY => sub { });
    is(scalar @{$e->{_RULES}}, 2, 'Test 5 - deux règles sans _ID coexistent');

    $e->addrule(_ID => 'rule-a', _SCOPE => {}, _APPLY => sub { });
    $e->addrule(_ID => 'rule-b', _SCOPE => {}, _APPLY => sub { });
    is(scalar @{$e->{_RULES}}, 4, 'Test 6 - deux règles avec _ID distincts coexistent');
}

# -----------------------------------------------------------------------
# Test 6-7 : doublon via loadRules() — deux fichiers YAML même REGLE
# La règle ne doit s'appliquer qu'une fois par frame
# -----------------------------------------------------------------------
{
    Chorus::Frame::_reset();

    my $e  = make_engine();
    my $f1 = Chorus::Frame->new(color => 'blue');

    my $dir = tempdir(CLEANUP => 1);
    DumpFile("$dir/R01-tag.yml", {
        REGLE     => 'tag-frame',
        CHERCHER  => { x => { attribut => 'color' } },
        EXCEPTION => q{$x->{count}},
        EFFET     => q{$x->set('count', ($x->{count} || 0) + 1); 1},
    });
    DumpFile("$dir/R02-tag-dup.yml", {
        REGLE     => 'tag-frame',       # même _ID !
        CHERCHER  => { x => { attribut => 'color' } },
        EXCEPTION => q{$x->{count}},
        EFFET     => q{$x->set('count', ($x->{count} || 0) + 1); 1},
    });

    warnings_like {
        $e->loadRules($dir);
    } [qr/duplicate rule _ID 'tag-frame'/],
        'Test 7 - loadRules() émet un warning pour le doublon YAML';

    $e->loop();

    is($f1->count, 1,
        "Test 8 - règle dupliquée en YAML ne s'applique qu'une fois (count=1)");
}

done_testing();
