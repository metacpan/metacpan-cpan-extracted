package Chorus::Sample::Diagnosis;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.00';

=head1 NAME

Chorus::Sample::Diagnosis - Medical diagnosis illustrating _NEEDED (deep), _LOCK_UNTIL_STABLE, and replay_all()

=head1 DESCRIPTION

A simplified medical diagnosis pipeline with two agents and a patient frame
whose symptom slots are intentionally incomplete.

  Patient frame slots
  -------------------
  temperature      : numeric value in °C  (may be absent → inferred from skin_temp)
  skin_temp        : 'hot' | 'normal' | 'cold'  (proxy when thermometer unavailable)
  cough            : 1/0
  sore_throat      : 1/0
  fatigue          : 1/0
  rash             : 1/0

  Derived slots (set by the pipeline)
  ------------------------------------
  fever_grade      : 'none' | 'low' | 'high'   (computed from temperature)
  hypothesis       : the current diagnostic hypothesis
  confidence       : 0..1

Mechanisms illustrated:
  _NEEDED (2 levels)    temperature → infer from skin_temp (backward chaining).
                        fever_grade → infer from temperature (second _NEEDED level).
  _LOCK_UNTIL_STABLE    Agent 2 (Diagnose) is blocked while Agent 1 (Collect)
                        is still making progress.
  replay_all()          When Diagnose finds a hypothesis that unlocks new
                        symptom checks, it calls replay_all() so Collect
                        can complete the missing slots before Diagnose
                        re-evaluates.
  solved()              Called when confidence > 0.8.

=cut

use FindBin qw($Bin);
use Chorus::Frame;
use Chorus::Engine;
use Chorus::Expert;

# ---------------------------------------------------------------------------
# Patient — temperature deliberately absent (must be inferred)
# ---------------------------------------------------------------------------

my $patient = Chorus::Frame->new(
    id         => 'patient-01',

    # skin_temp is available; temperature is not — triggers _NEEDED
    skin_temp  => 'hot',
    # temperature intentionally missing

    cough      => 1,
    sore_throat => 1,
    fatigue    => 1,
    rash       => 0,

    # temperature: inferred from skin_temp via _NEEDED (level 1)
    temperature => {
        _NEEDED => sub {
            my $st = $SELF->skin_temp;
            return 39.5 if defined $st && $st eq 'hot';
            return 36.6 if defined $st && $st eq 'normal';
            return 35.5 if defined $st && $st eq 'cold';
            return undef;
        },
    },

    # fever_grade: inferred from temperature via _NEEDED (level 2)
    fever_grade => {
        _NEEDED => sub {
            my $t = $SELF->temperature;   # may itself trigger level-1 _NEEDED
            return undef unless defined $t;
            return 'high' if $t >= 39.0;
            return 'low'  if $t >= 37.5;
            return 'none';
        },
    },
);

# ---------------------------------------------------------------------------
# Agent 1 — Collect
# Ensures derived slots are materialised on the patient frame.
# Rules load from YAML; each rule sets one derived slot if absent.
# Tagged _LOCK_UNTIL_STABLE: Agent 2 is skipped while this agent succeeds.
# ---------------------------------------------------------------------------

my $agent_collect = Chorus::Engine->new( _IDENT => 'Collect' );
$agent_collect->{_LOCK_UNTIL_STABLE} = 'Y';
$agent_collect->loadRules("$Bin/rules/diagnosis/collect");

# ---------------------------------------------------------------------------
# Agent 2 — Diagnose
# Reads materialised slots and builds a hypothesis + confidence score.
# When a hypothesis is found that implies new symptoms should be checked,
# it calls replay_all() to let Agent 1 complete them first.
# Calls solved() when confidence > 0.8.
# ---------------------------------------------------------------------------

my $agent_diagnose = Chorus::Engine->new( _IDENT => 'Diagnose' );

# Make $agent_diagnose visible inside YAML EFFET blocks (injected into main::).
# YAML rules are eval'd in the package where loadRules() is called;
# the typeglob injection makes the reference available to all rule closures.
{
    no strict 'refs';
    *{'main::agent_diagnose'} = \$agent_diagnose;
}

$agent_diagnose->loadRules("$Bin/rules/diagnosis/diagnose");

# Termination rule (pure Perl — needs $agent reference in closure)
$agent_diagnose->addrule(
    _ID    => 'terminate-on-confidence',
    _SCOPE => { p => sub { [ fmatch(slot => 'confidence') ] } },
    _APPLY => sub {
        my %opts  = @_;
        my $p     = $opts{p};
        my $conf  = $p->confidence // 0;
        return unless $conf > 0.8;
        $agent_diagnose->solved();
        return 1;
    },
);

# ---------------------------------------------------------------------------
# Expert pipeline
# ---------------------------------------------------------------------------

my $xprt = Chorus::Expert->new();
$xprt->{_MAX_ITER} = 200;
$xprt->register($agent_collect, $agent_diagnose);

my $result = $xprt->process();

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

print "\nDiagnosis report\n";
print '-' x 50 . "\n";
printf "  temperature  : %.1f °C  (inferred via _NEEDED from skin_temp='%s')\n",
    $patient->temperature_value // 0,
    $patient->skin_temp   // '?';
printf "  fever_grade  : %s\n",   $patient->fever_grade_value // '(unknown)';
printf "  cough        : %s\n",   $patient->cough        ? 'yes' : 'no';
printf "  sore_throat  : %s\n",   $patient->sore_throat  ? 'yes' : 'no';
printf "  fatigue      : %s\n",   $patient->fatigue      ? 'yes' : 'no';
printf "  rash         : %s\n",   $patient->rash         ? 'yes' : 'no';
print '-' x 50 . "\n";
printf "  hypothesis   : %s\n",   $patient->hypothesis   // '(none)';
printf "  confidence   : %.2f\n", $patient->confidence   // 0;
printf "  pipeline     : %s\n",   $result ? 'SOLVED' : 'FAILED/TIMEOUT';
