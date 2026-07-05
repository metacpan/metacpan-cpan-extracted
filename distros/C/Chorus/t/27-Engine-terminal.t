#!perl -T

# Tests for YAML DSL field TERMINAL: solved / failed
#
# TERMINAL is a declarative field on a rule. When the rule fires (returns true),
# the engine calls solved() or failed() automatically — without Perl code in _APPLY.
#
# This covers the case described in DEBUG-01.txt §7:
#   "impossible d'exprimer solved()/failed() en YAML pur"

use strict;
use Test::More tests => 8;
use Chorus::Frame;
use Chorus::Engine;
use File::Temp qw(tempdir);
use YAML qw(DumpFile);

diag("Testing Chorus::Engine TERMINAL field in YAML rules, Perl $], $^X");

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
# Test 1-3 : TERMINAL: solved
# Une règle YAML qui pose un flag sur un frame et déclare TERMINAL: solved
# -> le pipeline doit se terminer avec BOARD->{SOLVED}
# -----------------------------------------------------------------------
{
    Chorus::Frame::_reset();

    my $e  = make_engine();
    my $f1 = Chorus::Frame->new(status => 'ready');
    my $dir = rule_dir(rule01 => {
        REGLE    => 'mark-done',
        CHERCHER => { x => { attribut => 'status' } },
        EXCEPTION => q{$x->{done}},
        EFFET    => q{$x->set('done', 'y'); 1},
        TERMINAL => 'solved',
    });
    $e->loadRules($dir);
    $e->loop();

    ok($f1->done, 'Test 1 - TERMINAL:solved — effet appliqué sur le frame');
    ok($e->BOARD->{SOLVED}, 'Test 2 - TERMINAL:solved — BOARD->{SOLVED} posé');
    ok(!$e->BOARD->{FAILED}, 'Test 3 - TERMINAL:solved — BOARD->{FAILED} absent');
}

# -----------------------------------------------------------------------
# Test 4-6 : TERMINAL: failed
# Une règle YAML qui détecte une condition d'erreur et déclare TERMINAL: failed
# -> le pipeline doit se terminer avec BOARD->{FAILED}
# -----------------------------------------------------------------------
{
    Chorus::Frame::_reset();

    my $e  = make_engine();
    my $f1 = Chorus::Frame->new(error => 'overflow');
    my $dir = rule_dir(rule01 => {
        REGLE    => 'detect-error',
        CHERCHER => { x => { attribut => 'error' } },
        EXCEPTION => q{$x->{flagged}},
        EFFET    => q{$x->set('flagged', 'y'); 1},
        TERMINAL => 'failed',
    });
    $e->loadRules($dir);
    $e->loop();

    ok($f1->flagged, 'Test 4 - TERMINAL:failed — effet appliqué sur le frame');
    ok($e->BOARD->{FAILED}, 'Test 5 - TERMINAL:failed — BOARD->{FAILED} posé');
    ok(!$e->BOARD->{SOLVED}, 'Test 6 - TERMINAL:failed — BOARD->{SOLVED} absent');
}

# -----------------------------------------------------------------------
# Test 7 : Sans TERMINAL — pas de solved automatique
# Une règle sans TERMINAL ne doit pas modifier BOARD
# -----------------------------------------------------------------------
{
    Chorus::Frame::_reset();

    my $e  = make_engine();
    my $f1 = Chorus::Frame->new(color => 'blue');
    my $dir = rule_dir(rule01 => {
        REGLE    => 'no-terminal',
        CHERCHER => { x => { attribut => 'color' } },
        EXCEPTION => q{$x->{tagged}},
        EFFET    => q{$x->set('tagged', 'y'); 1},
        # pas de TERMINAL
    });
    $e->loadRules($dir);
    $e->loop();

    ok(!$e->BOARD->{SOLVED} && !$e->BOARD->{FAILED},
        'Test 7 - sans TERMINAL — BOARD reste vide');
}

# -----------------------------------------------------------------------
# Test 8 : TERMINAL ne se déclenche pas si la règle ne retourne pas vrai
# -----------------------------------------------------------------------
{
    Chorus::Frame::_reset();

    my $e  = make_engine();
    # frame sans le slot attendu → scope vide → _APPLY jamais appelé
    my $f1 = Chorus::Frame->new(other => 'x');
    my $dir = rule_dir(rule01 => {
        REGLE    => 'no-match',
        CHERCHER => { x => { attribut => 'color' } },   # 'color' absent
        EFFET    => q{$x->set('done', 'y'); 1},
        TERMINAL => 'solved',
    });
    $e->loadRules($dir);
    $e->loop();

    ok(!$e->BOARD->{SOLVED},
        'Test 8 - TERMINAL pas déclenché si règle ne s\'applique pas');
}

done_testing();
