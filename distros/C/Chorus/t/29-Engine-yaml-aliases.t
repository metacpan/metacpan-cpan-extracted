#!perl -T

# Tests for English-keyword aliases in the YAML DSL:
#   RULE     => REGLE
#   FIND     => CHERCHER
#   ACTION   => EFFET
#   PREMISES => PREMISSES
#
# Each test mirrors the corresponding case in 24-Engine-codeRule.t
# but uses the English keys exclusively.

use strict;
use Test::More tests => 14;
use Chorus::Frame;
use Chorus::Engine;
use File::Temp qw(tempdir);
use YAML qw(DumpFile);

diag("Testing YAML English aliases (RULE/FIND/ACTION) - Chorus::Engine $Chorus::Engine::VERSION, Perl $], $^X");

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
# Test 1 : _ID generated from RULE (English alias for REGLE)
# -----------------------------------------------------------------------
{
    my $e   = make_engine();
    my $dir = rule_dir(rule01 => {
        RULE      => 'mark-all-en',
        FIND      => { x => { attribut => 'color' } },
        EXCEPTION => q{$x->{tagged}},
        ACTION    => q{$x->set('tagged','y'); 1},
    });
    $e->loadRules($dir);
    is($e->{_RULES}[0]->_ID, 'mark-all-en', 'Test 1 - RULE alias: _ID set from RULE');
}

# -----------------------------------------------------------------------
# Test 2 : ACTION applied to all frames in scope
# -----------------------------------------------------------------------
{
    my $e   = make_engine();
    my $f1  = Chorus::Frame->new(color => 'blue');
    my $f2  = Chorus::Frame->new(color => 'red');
    my $dir = rule_dir(rule01 => {
        RULE      => 'tag-all-en',
        FIND      => { x => { attribut => 'color' } },
        EXCEPTION => q{$x->{tagged}},
        ACTION    => q{$x->set('tagged','y'); 1},
    });
    $e->loadRules($dir);
    $e->loop();
    ok($f1->tagged, 'Test 2 - ACTION applied to all frames in scope (f1)');
    ok($f2->tagged, 'Test 2b - ACTION applied to all frames in scope (f2)');
}

# -----------------------------------------------------------------------
# Test 3 : CONDITION — only matching frames get the ACTION
# -----------------------------------------------------------------------
{
    my $e   = make_engine();
    my $f1  = Chorus::Frame->new(color => 'blue');
    my $f2  = Chorus::Frame->new(color => 'red');
    my $dir = rule_dir(rule01 => {
        RULE      => 'only-blue-en',
        FIND      => { x => { attribut => 'color' } },
        CONDITION => q{$x->{color} eq 'blue'},
        EXCEPTION => q{$x->{is_blue}},
        ACTION    => q{$x->set('is_blue','y'); 1},
    });
    $e->loadRules($dir);
    $e->loop();
    ok($f1->is_blue,  'Test 3 - CONDITION: matching frame gets ACTION');
    ok(!$f2->is_blue, 'Test 3b - CONDITION: non-matching frame skipped');
}

# -----------------------------------------------------------------------
# Test 4 : EXCEPTION — frames matching the exception are skipped
# -----------------------------------------------------------------------
{
    my $e   = make_engine();
    my $f1  = Chorus::Frame->new(color => 'blue');
    my $f2  = Chorus::Frame->new(color => 'blue', frozen => 'y');
    my $dir = rule_dir(rule01 => {
        RULE      => 'skip-frozen-en',
        FIND      => { x => { attribut => 'color' } },
        EXCEPTION => q{$x->{frozen} or $x->{processed}},
        ACTION    => q{$x->set('processed','y'); 1},
    });
    $e->loadRules($dir);
    $e->loop();
    ok($f1->processed,  'Test 4 - EXCEPTION: non-frozen frame gets ACTION');
    ok(!$f2->processed, 'Test 4b - EXCEPTION: frozen frame is skipped');
}

# -----------------------------------------------------------------------
# Test 5 : CONDITION + EXCEPTION combined
# -----------------------------------------------------------------------
{
    my $e   = make_engine();
    my $f1  = Chorus::Frame->new(color => 'blue');
    my $f2  = Chorus::Frame->new(color => 'red');
    my $f3  = Chorus::Frame->new(color => 'blue', frozen => 'y');
    my $dir = rule_dir(rule01 => {
        RULE      => 'blue-not-frozen-en',
        FIND      => { x => { attribut => 'color' } },
        CONDITION => q{$x->{color} eq 'blue'},
        EXCEPTION => q{$x->{frozen} or $x->{ok}},
        ACTION    => q{$x->set('ok','y'); 1},
    });
    $e->loadRules($dir);
    $e->loop();
    ok($f1->ok,  'Test 5 - CONDITION+EXCEPTION: matching non-frozen frame gets ACTION');
    ok(!$f2->ok, 'Test 5b - CONDITION+EXCEPTION: non-matching frame skipped');
    ok(!$f3->ok, 'Test 5c - CONDITION+EXCEPTION: frozen frame skipped');
}

# -----------------------------------------------------------------------
# Test 6 : Multi-value ACTION (array)
# -----------------------------------------------------------------------
{
    my $e   = make_engine();
    my $f1  = Chorus::Frame->new(color => 'blue');
    my $dir = rule_dir(rule01 => {
        RULE      => 'multi-action-en',
        FIND      => { x => { attribut => 'color' } },
        EXCEPTION => q{$x->{done}},
        ACTION    => [ q{$x->set('step1','y')}, q{$x->set('done','y'); 1} ],
    });
    $e->loadRules($dir);
    $e->loop();
    ok($f1->step1, 'Test 6 - multi-ACTION: first action applied');
    ok($f1->done,  'Test 6b - multi-ACTION: second action applied');
}

# -----------------------------------------------------------------------
# Test 7 : PREMISES alias — _PREMISSES populated on the rule frame
# -----------------------------------------------------------------------
{
    my $e   = make_engine();
    my $dir = rule_dir(rule01 => {
        RULE      => 'with-premises',
        FIND      => { x => { attribut => 'color' } },
        PREMISES  => [ 'CAT_NOUN', 'GENDER' ],
        EXCEPTION => q{$x->{tagged}},
        ACTION    => q{$x->set('tagged','y'); 1},
    });
    $e->loadRules($dir);
    my $rule = $e->{_RULES}[0];
    ok($rule->{_PREMISSES}{CAT_NOUN}, 'Test 7 - PREMISES alias: CAT_NOUN in _PREMISSES');
    ok($rule->{_PREMISSES}{GENDER},   'Test 7b - PREMISES alias: GENDER in _PREMISSES');
}

done_testing();
