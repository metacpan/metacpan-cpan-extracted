#!perl -T

# ============================================================================
# 25-Expert-construction.t — Système expert de vérification de poutres en bois
#
# Illustre un pipeline Chorus::Expert à 3 agents spécialisés, dont les règles
# métier sont définies en YAML et chargées via loadRules() :
#
#   Agent 1 — Matériaux  : lit la classe de bois et affecte la résistance
#                          de calcul en flexion fm_d (MPa) selon EC5 Tab.1
#
#   Agent 2 — Charges    : calcule la contrainte de flexion sigma_m (MPa)
#                          à partir de la charge, de la portée et du module W
#                          sigma_m = M_max / W  avec  M_max = q·L²/8
#
#   Agent 3 — Vérif EC5  : compare sigma_m à fm_d et pose le statut
#                          CONFORME ou NON_CONFORME (réf. EC5 §6.1.6)
#
# La règle de terminaison (solved) est injectée en Perl pur — c'est le seul
# rôle de l'agent de contrôle : déclarer le problème résolu quand tous les
# éléments ont un statut.
#
# Règles YAML : t/rules/Expert-construction/
#   materiaux/    R01-affecter-fm_d.yml
#   charges/      R01-calculer-sigma_m.yml
#   verification/ R01-verifier-EC5-6.1.6.yml
#
# Unités utilisées : q en N/mm, L en mm, W en mm³, sigma_m et fm_d en MPa
# ============================================================================

use strict;
use Test::More tests => 11;
use FindBin qw($RealBin);

use Chorus::Frame;
use Chorus::Engine;
use Chorus::Expert;

diag("Testing Expert 3-agents construction pipeline, Perl $], $^X");

my $RULES = "$RealBin/rules/Expert-construction";

# ---------------------------------------------------------------------------
# Données de test — 2 poutres rectangulaires en bois
#
#   Poutre P1 : C24, q=0.015 N/mm, L=3000 mm, b=60 mm, h=160 mm
#     W = b·h²/6 = 60·160²/6 = 256 000 mm³
#     M_max = q·L²/8 = 0.015·9_000_000/8 = 16 875 N·mm
#     sigma_m = 16 875 / 256 000 ≈ 0.066 MPa  <<  fm_d(C24)=16.0  -> CONFORME
#
#   Poutre P2 : C16, q=0.500 N/mm, L=5000 mm, b=60 mm, h=120 mm
#     W = 60·120²/6 = 144 000 mm³
#     M_max = 0.500·25_000_000/8 = 1 562 500 N·mm
#     sigma_m = 1_562_500 / 144_000 ≈ 10.85 MPa  >  fm_d(C16)=10.0  -> NON_CONFORME
# ---------------------------------------------------------------------------

my $P1 = Chorus::Frame->new(
    id           => 'P1',
    classe_bois  => 'C24',
    q_lineique   => 0.015,   # N/mm
    portee       => 3000,    # mm
    largeur      => 60,      # mm
    hauteur      => 160,     # mm
);

my $P2 = Chorus::Frame->new(
    id           => 'P2',
    classe_bois  => 'C16',
    q_lineique   => 0.500,   # N/mm
    portee       => 5000,    # mm
    largeur      => 60,      # mm
    hauteur      => 120,     # mm
);

# ---------------------------------------------------------------------------
# Agent 1 — Matériaux
# Règle YAML : lit classe_bois, affecte fm_d (résistance caract. en flexion)
# Valeurs issues de EN 338 / EC5 Table 1 (valeurs caractéristiques, MPa)
# ---------------------------------------------------------------------------

my $agent_mat = Chorus::Engine->new();
$agent_mat->loadRules("$RULES/materiaux");

# ---------------------------------------------------------------------------
# Agent 2 — Charges
# Règle YAML : calcule sigma_m à partir de fm_d (posé par l'agent précédent)
# Pré-requis implicite : fm_d doit exister (l'agent 1 tourne en premier)
# ---------------------------------------------------------------------------

my $agent_chg = Chorus::Engine->new();
$agent_chg->loadRules("$RULES/charges");

# ---------------------------------------------------------------------------
# Agent 3 — Vérification EC5 §6.1.6
# Règle YAML : compare sigma_m à fm_d et pose le statut
# ---------------------------------------------------------------------------

my $agent_ver = Chorus::Engine->new();
$agent_ver->loadRules("$RULES/verification");

# ---------------------------------------------------------------------------
# Agent de contrôle — terminaison (règle Perl pur)
# Déclare le problème résolu quand toutes les poutres ont un statut
# ---------------------------------------------------------------------------

my $agent_ctrl = Chorus::Engine->new();
$agent_ctrl->addrule(
    _SCOPE => { p => sub { [ fmatch(slot => 'classe_bois') ] } },
    _APPLY => sub {
        my @poutres = fmatch(slot => 'classe_bois');
        return unless @poutres && (grep { defined $_->{statut} } @poutres) == scalar(@poutres);
        $agent_ctrl->solved();
        return 1;
    },
);

# ---------------------------------------------------------------------------
# Pipeline Expert — 3 agents métier + 1 agent de contrôle
# ---------------------------------------------------------------------------

my $xprt = Chorus::Expert->new();
$xprt->register($agent_mat, $agent_chg, $agent_ver, $agent_ctrl);
my $result = $xprt->process();

# ---------------------------------------------------------------------------
# Assertions
# ---------------------------------------------------------------------------

# --- Agent 1 : Matériaux ---

cmp_ok($P1->fm_d, '==', 16.0,
    'Test 1 - Agent Materiaux : fm_d(C24) = 16.0 MPa');

cmp_ok($P2->fm_d, '==', 10.0,
    'Test 2 - Agent Materiaux : fm_d(C16) = 10.0 MPa');

# --- Agent 2 : Charges ---

# P1 : W=256000, M=16875  → sigma_m ≈ 0.0659
my $sigma_P1_expected = (0.015 * 3000**2 / 8) / (60 * 160**2 / 6);
cmp_ok(abs($P1->sigma_m - $sigma_P1_expected), '<', 1e-6,
    'Test 3 - Agent Charges : sigma_m(P1) calcul correct');

# P2 : W=144000, M=1562500 → sigma_m ≈ 10.85
my $sigma_P2_expected = (0.500 * 5000**2 / 8) / (60 * 120**2 / 6);
cmp_ok(abs($P2->sigma_m - $sigma_P2_expected), '<', 1e-6,
    'Test 4 - Agent Charges : sigma_m(P2) calcul correct');

# --- Agent 3 : Vérification EC5 ---

is($P1->statut, 'CONFORME',
    'Test 5 - Agent Verif : P1 (sigma_m << fm_d) est CONFORME');

ok(!defined($P1->ref_norme),
    'Test 6 - Agent Verif : P1 CONFORME -> pas de ref_norme');

is($P2->statut, 'NON_CONFORME',
    'Test 7 - Agent Verif : P2 (sigma_m > fm_d) est NON_CONFORME');

is($P2->ref_norme, 'EC5-6.1.6',
    'Test 8 - Agent Verif : P2 NON_CONFORME -> ref EC5-6.1.6 posee');

# --- Pipeline Expert ---

ok(defined $result && $result,
    'Test 9 - Expert->process() retourne 1 (solved)');

# Tous les statuts sont posés
my @avec_statut = grep { defined $_->{statut} } fmatch(slot => 'classe_bois');
is(scalar(@avec_statut), 2,
    'Test 10 - Les 2 poutres ont un statut apres pipeline');

# Les statuts sont distincts (un CONFORME, un NON_CONFORME)
my %statuts = map { $_->{statut} => 1 } @avec_statut;
is(scalar(keys %statuts), 2,
    'Test 11 - Les 2 statuts distincts sont representes (CONFORME + NON_CONFORME)');

done_testing();
