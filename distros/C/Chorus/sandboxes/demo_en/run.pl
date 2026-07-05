#!/usr/bin/env perl
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../../lib";   # Chorus::Engine, Frame, Expert, Collection
use lib "$Bin/lib";                 # CobIntro::*

use CobIntro::Feed   qw(load_projet);
use CobIntro::Expert;

my $fichier = shift @ARGV
    or die "Usage: perl run.pl <fichier-projet.json>\n";
-f $fichier or die "File not found: $fichier\n";

# Feed — project data → Chorus Frames
my @elements = load_projet($fichier);
printf "Feed: %d element(s) loaded\n\n", scalar @elements;

# Calibrate _MAX_CYCLES to actual project volume
# Heuristic: N_elements × 16_rules × 4_agents × 10 (safety margin)
my $max_cycles = scalar(@elements) * 16 * 4 * 10;
$max_cycles = 10_000 if $max_cycles < 10_000;  # safety minimum

# Pipeline
my ($ok) = CobIntro::Expert->run(
    base_dir   => $Bin,
    input      => { elements => \@elements },
    max_cycles => $max_cycles,
    max_iter   => $max_cycles * 2,
);

# Result slots to display (set by agents in the pipeline)
my @slots_resultat_display = qw(
    qualified rejection_reason
    frame_ok domain_note
    thermal_ok
    fire_ok fire_note
    compliance_status compliance_note
);

print "=" x 62 . "\n";
print "  COMPLIANCE REPORT — CobIntro\n";
print "=" x 62 . "\n\n";

my $n_conforme     = 0;
my $n_non_conforme = 0;
my $n_non_traite   = 0;

for my $e (@elements) {
    my $id   = $e->{id}           // '?';
    my $type = $e->{type_element} // '?';
    my $stat = $e->{compliance_status} // '(unprocessed)';

    if    ($stat eq 'COMPLIANT')     { $n_conforme++ }
    elsif ($stat eq 'NON-COMPLIANT') { $n_non_conforme++ }
    else                             { $n_non_traite++ }

    my $flag = $stat eq 'COMPLIANT'     ? '✅'
             : $stat eq 'NON-COMPLIANT' ? '❌'
             : '⚠️ ';

    printf "  %s  [%s — %s]\n", $flag, $id, $type;

    for my $slot (@slots_resultat_display) {
        next unless defined $e->{$slot};
        next if $slot eq 'compliance_note';
        printf "       %-28s : %s\n", $slot, $e->{$slot};
    }
    if (defined $e->{compliance_note}) {
        printf "       %-28s : %s\n", '→ compliance_note', $e->{compliance_note};
    }
    print "\n";
}

# ── Block 1: Compliance rate ──────────────────────────────────────────────
my $n_total = scalar @elements;
my $taux    = $n_total ? int(0.5 + 100 * $n_conforme / $n_total) : 0;
my $bar_ok  = int($taux / 5);
my $bar_ko  = 20 - $bar_ok;
my $barre   = '█' x $bar_ok . '░' x $bar_ko;

print "─" x 62 . "\n";
printf "  Compliant      : %d / %d  (%d%%)\n", $n_conforme,     $n_total, $taux;
printf "  Non-compliant  : %d / %d\n",          $n_non_conforme, $n_total;
printf "  Unprocessed    : %d / %d\n",           $n_non_traite,   $n_total;
printf "  [%s]  %d%%\n", $barre, $taux;
printf "  Pipeline       : %s\n", $ok ? 'SOLVED ✅' : 'FAILED/TIMEOUT ❌';
print "─" x 62 . "\n";

# ── Block 2: Validation process — traversal by agent ──────────────────────
{
    # [ label, targeting_slot, result_slot, ok_value, ko_value ]
    my @pipeline_def = (
        [ 'Qualification', 'needs_qualify',    'qualified',         'YES',       'NO'          ],
        [ 'Domain',        'needs_domain',      'frame_ok',          'YES',       'NO'          ],
        [ 'Fire',          'needs_fire',        'fire_ok',           'YES',       'NO'          ],
        [ 'Compliance',    'needs_compliance',  'compliance_status', 'COMPLIANT', 'NON-COMPLIANT' ],
    );

    print "\n  Validation process — traversal by agent\n";
    print "  " . "─" x 58 . "\n";
    printf "  %-16s  %7s  %6s  %6s  %5s\n", 'Agent', 'Targeted', 'OK', 'KO', 'NA';
    print "  " . "─" x 58 . "\n";

    for my $def (@pipeline_def) {
        my ($label, $slot_cible, $slot_res, $ok_val, $ko_val) = @$def;
        # Since targeting slots are deleted after processing, count via result slot
        my @with_res = grep { defined $_->{$slot_res} } @elements;
        my $n_res    = scalar @with_res;
        my ($n_ok, $n_ko) = (0, 0);
        for my $e (@with_res) {
            my $res = $e->{$slot_res} // '';
            if    ($res eq $ok_val) { $n_ok++ }
            elsif ($res eq $ko_val) { $n_ko++ }
        }
        printf "  %-16s  %7d  %6s  %6s  %5s\n",
            $label, $n_res,
            $n_ok ? $n_ok : '-',
            $n_ko ? $n_ko : '-',
            '-';
    }
    print "  " . "─" x 58 . "\n";
}

# ── Block 3: Distribution by element type ─────────────────────────────────
{
    my (%ok_par_type, %ko_par_type, %tous_types);
    for my $e (@elements) {
        my $type = $e->{type_element} // '?';
        $tous_types{$type}++;
        my $stat = $e->{compliance_status} // '';
        if    ($stat eq 'COMPLIANT')     { $ok_par_type{$type}++ }
        elsif ($stat eq 'NON-COMPLIANT') { $ko_par_type{$type}++ }
    }
    print "\n  Distribution by element type\n";
    print "  " . "─" x 46 . "\n";
    printf "  %-30s  %5s  %5s\n", 'Type', '✅', '❌';
    print "  " . "─" x 46 . "\n";
    for my $t (sort keys %tous_types) {
        printf "  %-30s  %5d  %5d\n",
            $t,
            $ok_par_type{$t} // 0,
            $ko_par_type{$t} // 0;
    }
    print "  " . "─" x 46 . "\n";
}

# ── Block 4: Non-conformity summary ───────────────────────────────────────
{
    my @nc = grep { ($_{compliance_status} // '') eq 'NON-COMPLIANT' } @elements;
    @nc    = grep { ($_ ->{compliance_status} // '') eq 'NON-COMPLIANT' } @elements;
    if (@nc) {
        print "\n  Non-conformity summary\n";
        print "  " . "─" x 58 . "\n";
        for my $e (@nc) {
            my $id   = $e->{id}           // '?';
            my $type = $e->{type_element} // '?';
            my $note = $e->{compliance_note} // '(reason not specified)';
            printf "  ❌  %-22s [%s]\n      %s\n\n", $id, $type, $note;
        }
        print "  " . "─" x 58 . "\n";
    }
}
