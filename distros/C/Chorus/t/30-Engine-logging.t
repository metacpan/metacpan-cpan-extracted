#!perl -T

# Tests for the rule-firing log system:
#   _LOG  on the engine  → callback or STDERR on every rule fire
#   _TRACE on a rule     → STDERR for that rule only (even without _LOG)
#   _CYCLE               → incremented by loop() after each productive pass
#   TRACE: 1 in YAML     → same as _TRACE => 1 via loadRules()

use strict;
use Test::More tests => 11;
use Chorus::Frame;
use Chorus::Engine;
use File::Temp qw(tempdir);
use YAML qw(DumpFile);

diag("Testing Chorus::Engine logging (_LOG/_TRACE/_CYCLE) $Chorus::Engine::VERSION, Perl $], $^X");

Chorus::Frame::_reset();

sub make_engine {
    my $e = Chorus::Engine->new(@_);
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
# Test 1-2 : _LOG callback — called when rule fires, not when it doesn't
# -----------------------------------------------------------------------
{
    Chorus::Frame::_reset();
    my @fired;
    my $e = make_engine();
    $e->set('_LOG', sub {
        my ($engine, $rule_id, $opts) = @_;
        push @fired, $rule_id;
    });

    my $f1 = Chorus::Frame->new(color => 'blue');
    my $f2 = Chorus::Frame->new(color => 'red');

    $e->addrule(
        _ID    => 'tag-blue',
        _SCOPE => { x => sub { [ fmatch(slot => 'color') ] } },
        _APPLY => sub {
            my %opts = @_;
            return unless ($opts{x}{color} // '') eq 'blue';
            return if $opts{x}{tagged};
            $opts{x}->set('tagged', 'y');
            return 1;
        },
    );
    $e->loop();

    is(scalar @fired, 1, 'Test 1 - _LOG callback called exactly once (only blue fires)');
    is($fired[0], 'tag-blue', 'Test 2 - _LOG callback receives correct rule_id');
}

# -----------------------------------------------------------------------
# Test 3 : _LOG callback receives scope opts (frame reference)
# -----------------------------------------------------------------------
{
    Chorus::Frame::_reset();
    my $captured_frame;
    my $e = make_engine();
    $e->set('_LOG', sub {
        my ($engine, $rule_id, $opts) = @_;
        $captured_frame = $opts->{x};
    });

    my $f = Chorus::Frame->new(color => 'blue', id => 'test-frame');
    $e->addrule(
        _ID    => 'capture',
        _SCOPE => { x => sub { [ fmatch(slot => 'color') ] } },
        _APPLY => sub {
            my %opts = @_;
            return if $opts{x}{done};
            $opts{x}->set('done', 'y');
            return 1;
        },
    );
    $e->loop();

    is($captured_frame, $f, 'Test 3 - _LOG callback receives correct scope frame');
}

# -----------------------------------------------------------------------
# Test 4-5 : _LOG disabled — no callback when _LOG is undef/0
# -----------------------------------------------------------------------
{
    Chorus::Frame::_reset();
    my @fired;
    my $e = make_engine();
    # _LOG NOT set

    my $f = Chorus::Frame->new(color => 'blue');
    $e->addrule(
        _ID    => 'no-log',
        _SCOPE => { x => sub { [ fmatch(slot => 'color') ] } },
        _APPLY => sub {
            my %opts = @_;
            return if $opts{x}{done};
            $opts{x}->set('done', 'y');
            return 1;
        },
    );
    $e->loop();

    is(scalar @fired, 0, 'Test 4 - no _LOG set → callback never called');
    ok($f->done, 'Test 5 - rule still fires normally without _LOG');
}

# -----------------------------------------------------------------------
# Test 6-7 : _CYCLE incremented by loop()
# -----------------------------------------------------------------------
{
    Chorus::Frame::_reset();
    my $e = make_engine();

    # 3 frames each needing one rule fire → 3 cycles
    my $f1 = Chorus::Frame->new(val => 1);
    my $f2 = Chorus::Frame->new(val => 2);
    my $f3 = Chorus::Frame->new(val => 3);

    $e->addrule(
        _ID    => 'mark',
        _SCOPE => { x => sub { [ grep { !$_->{done} } fmatch(slot => 'val') ] } },
        _APPLY => sub {
            my %opts = @_;
            $opts{x}->set('done', 'y');
            return 1;
        },
    );

    is($e->{_CYCLE}, undef, 'Test 6 - _CYCLE undef before loop()');
    $e->loop();
    ok($e->{_CYCLE} >= 1, 'Test 7 - _CYCLE >= 1 after loop() with productive passes');
}

# -----------------------------------------------------------------------
# Test 8-9 : _TRACE on a single rule via addrule()
# -----------------------------------------------------------------------
{
    Chorus::Frame::_reset();
    my @log_calls;
    my $e = make_engine();
    # _LOG NOT set — only _TRACE on one rule

    my $f = Chorus::Frame->new(color => 'blue');

    # Capture STDERR to detect _TRACE output
    my $stderr_output = '';
    {
        local *STDERR;
        open STDERR, '>', \$stderr_output or die;

        $e->addrule(
            _ID    => 'traced-rule',
            _TRACE => 1,
            _SCOPE => { x => sub { [ fmatch(slot => 'color') ] } },
            _APPLY => sub {
                my %opts = @_;
                return if $opts{x}{done};
                $opts{x}->set('done', 'y');
                return 1;
            },
        );
        $e->loop();
    }

    ok($f->done, 'Test 8 - _TRACE rule still fires normally');
    like($stderr_output, qr/traced-rule.*fired|fired.*traced-rule/i,
        'Test 9 - _TRACE produces STDERR output containing rule id');
}

# -----------------------------------------------------------------------
# Test 10-11 : TRACE: 1 in YAML → _TRACE on compiled rule
# -----------------------------------------------------------------------
{
    Chorus::Frame::_reset();
    my $e = make_engine();

    my $f = Chorus::Frame->new(color => 'blue');

    my $stderr_output = '';
    {
        local *STDERR;
        open STDERR, '>', \$stderr_output or die;

        my $dir = rule_dir(rule01 => {
            RULE      => 'yaml-traced',
            FIND      => { x => { attribut => 'color' } },
            TRACE     => 1,
            EXCEPTION => q{$x->{done}},
            ACTION    => q{$x->set('done','y'); 1},
        });
        $e->loadRules($dir);
        $e->loop();
    }

    ok($f->done, 'Test 10 - YAML TRACE:1 rule fires normally');
    like($stderr_output, qr/yaml-traced.*fired|fired.*yaml-traced/i,
        'Test 11 - YAML TRACE:1 produces STDERR output containing rule id');
}

done_testing();
