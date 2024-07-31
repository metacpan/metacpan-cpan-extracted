package CVSS::v3;

use feature ':5.10';
use strict;
use utf8;
use warnings;

use List::Util qw(min);
use POSIX      qw(floor round);
use Carp       ();

use base 'CVSS::Base';
use CVSS::Constants;

our $VERSION = '1.00';
$VERSION =~ tr/_//d;    ## no critic

use constant DEBUG => $ENV{CVSS_DEBUG};

my $WEIGHTS = CVSS::Constants->CVSS3_WEIGHTS;

sub ATTRIBUTES          { CVSS::Constants->CVSS3_ATTRIBUTES }
sub SEVERITY            { CVSS::Constants->CVSS3_SEVERITY }
sub NOT_DEFINED_VALUE   { CVSS::Constants->CVSS3_NOT_DEFINED_VALUE }
sub VECTOR_STRING_REGEX { CVSS::Constants->CVSS3_VECTOR_STRING_REGEX }
sub METRIC_GROUPS       { CVSS::Constants->CVSS3_METRIC_GROUPS }
sub METRIC_NAMES        { CVSS::Constants->CVSS3_METRIC_NAMES }

sub weight {

    my ($self, $metric) = @_;

    # Modified Base Score weight
    if ($metric =~ /M(AV|AC|PR|UI|S|C|I|A)/) {

        if ($metric eq 'MPR') {

            DEBUG and say STDERR '-- MPR depends on the value of Scope (MS)';

            my $ms_value  = $self->M('MS');
            my $mpr_value = $self->M('MPR');

            $ms_value  = $self->M('S')  if ($ms_value eq 'X');
            $mpr_value = $self->M('PR') if ($mpr_value eq 'X');

            my $weight = $WEIGHTS->{MPR}{$ms_value}{$mpr_value};

            DEBUG and say STDERR "-- Weight : $metric:$mpr_value = $weight (MS:$ms_value)";

            return $weight;

        }

        my $value = $self->M($metric);
        $value = $self->M($1) if ($value eq 'X');

        my $weight = $WEIGHTS->{$metric}{$value};

        DEBUG and say STDERR "-- Weight : $metric:$value = $weight";

        return $weight;

    }


    # PR depends on the value of Scope (S).
    if ($metric eq 'PR') {

        DEBUG and say STDERR '-- PR depends on the value of Scope (S)';

        my $s_value  = $self->M('S');
        my $pr_value = $self->M('PR');
        my $weight   = $WEIGHTS->{PR}{$s_value}{$pr_value};

        DEBUG and say STDERR "-- Weight : $metric:$pr_value = $weight (S:$s_value)";

        return $weight;

    }

    my $value  = $self->M($metric);
    my $weight = $WEIGHTS->{$metric}{$value};

    DEBUG and say STDERR "-- Weight : $metric:$value = $weight";

    return $weight;

}

sub W { weight(@_) }


sub temporal_score    { shift->{scores}->{temporal} }
sub temporal_severity { $_[0]->score_to_severity($_[0]->temporal_score) }

sub environmental_score    { shift->{scores}->{environmental} }
sub environmental_severity { $_[0]->score_to_severity($_[0]->environmental_score) }

# JSON-style alias
sub temporalScore    { shift->temporal_score }
sub temporalSeverity { shift->temporal_severity }

sub environmentalScore    { shift->environmental_score }
sub environmentalSeverity { shift->environmental_severity }


sub calculate_score {

    my ($self) = @_;

    if (%{$self->metrics}) {
        for (@{$self->METRIC_GROUPS->{base}}) {
            Carp::croak sprintf('Missing base metric (%s)', $_) unless ($self->metrics->{$_});
        }
    }

    # Set NOT_DEFINED
    $self->metrics->{E}  //= 'X';
    $self->metrics->{RL} //= 'X';
    $self->metrics->{RC} //= 'X';

    $self->metrics->{CR}  //= 'X';
    $self->metrics->{IR}  //= 'X';
    $self->metrics->{AR}  //= 'X';
    $self->metrics->{MAV} //= 'X';
    $self->metrics->{MAC} //= 'X';
    $self->metrics->{MPR} //= 'X';
    $self->metrics->{MUI} //= 'X';
    $self->metrics->{MS}  //= 'X';
    $self->metrics->{MC}  //= 'X';
    $self->metrics->{MI}  //= 'X';
    $self->metrics->{MA}  //= 'X';


    # Base Metrics Equations

    # The Base Score formula depends on sub-formulas for Impact Sub-Score (ISS),
    # Impact, and Exploitability, all of which are defined below:

    # ISS = 1 - [ (1 - Confidentiality) × (1 - Integrity) × (1 - Availability) ]

    # Impact =
    #   If Scope is Unchanged   6.42 × ISS
    #   If Scope is Changed     7.52 × (ISS - 0.029) - 3.25 × (ISS - 0.02) ** 15

    # Exploitability =  8.22 × AttackVector × AttackComplexity ×
    #                   PrivilegesRequired × UserInteraction

    # BaseScore =
    #   If Impact \<= 0         0, else
    #   If Scope is Unchanged   Roundup (Minimum [(Impact + Exploitability), 10])
    #   If Scope is Changed     Roundup (Minimum [1.08 × (Impact + Exploitability), 10])

    my $iss            = (1 - ((1 - $self->W('C')) * (1 - $self->W('I')) * (1 - $self->W('A'))));
    my $impact         = 0;
    my $exploitability = 8.22 * $self->W('AV') * $self->W('AC') * $self->W('PR') * $self->W('UI');
    my $base_score     = 0;

    if ($self->M('S') eq 'U') {
        $impact = $self->W('S') * $iss;
    }
    else {
        $impact = $self->W('S') * ($iss - 0.029) - 3.25 * ($iss - 0.02)**15;
    }

    if ($impact <= 0) {
        $base_score = 0;
    }
    elsif ($self->M('S') eq 'U') {
        $base_score = round_up(min(($impact + $exploitability), 10));
    }
    else {
        $base_score = round_up(min((1.08 * ($impact + $exploitability)), 10));
    }

    DEBUG and say STDERR "-- Impact Sub-Score (ISS): $iss";
    DEBUG and say STDERR "-- Impact: $impact";
    DEBUG and say STDERR "-- Exploitability: $exploitability";
    DEBUG and say STDERR "-- BaseScore: $base_score";

    $self->{scores}->{base}           = $base_score;
    $self->{scores}->{exploitability} = round_up($exploitability);
    $self->{scores}->{impact}         = round_up($impact);

    if ($self->metric_group_is_set('temporal')) {

        # Temporal Metrics Equations

        # TemporalScore =     Roundup (BaseScore × ExploitCodeMaturity × RemediationLevel × ReportConfidence)

        my $temporal_score = round_up($base_score * $self->W('E') * $self->W('RL') * $self->W('RC'));

        DEBUG and say STDERR "-- TemporalScore: $temporal_score";

        $self->{scores}->{temporal} = $temporal_score;

    }


    if ($self->metric_group_is_set('environmental')) {

        # Environmental Metrics Equations

        # The Environmental Score formula depends on sub-formulas for Modified Impact
        # Sub-Score (MISS), ModifiedImpact, and ModifiedExploitability, all of which
        # are defined below:

        # MISS =  Minimum ( 1 - [
        #   (1 - ConfidentialityRequirement × ModifiedConfidentiality) ×
        #   (1 - IntegrityRequirement × ModifiedIntegrity) ×
        #   (1 - AvailabilityRequirement × ModifiedAvailability)
        # ], 0.915)

        # ModifiedImpact =
        #   If ModifiedScope is Unchanged   6.42 × MISS
        #   If ModifiedScope is Changed     7.52 × (MISS - 0.029) - 3.25 × (MISS × 0.9731 - 0.02) ** 13
        #                   CVSS v3.0  -->  7.52 × (MISS - 0.029) - 3.25 × (MISS - 0.02) ** 15

        # ModifiedExploitability =    8.22 × ModifiedAttackVector ×
        #                                    ModifiedAttackComplexity ×
        #                                    ModifiedPrivilegesRequired ×
        #                                    ModifiedUserInteraction

        # EnvironmentalScore =
        #   If ModifiedImpact \<= 0         0, else
        #   If ModifiedScope is Unchanged   Roundup ( Roundup [Minimum (
        #                                       [ModifiedImpact + ModifiedExploitability], 10) ] ×
        #                                       ExploitCodeMaturity × RemediationLevel × ReportConfidence)

        #   If ModifiedScope is Changed     Roundup ( Roundup [Minimum (1.08 ×
        #                                       [ModifiedImpact + ModifiedExploitability], 10) ] ×
        #                                       ExploitCodeMaturity × RemediationLevel × ReportConfidence)

        my $modified_impact         = 0;
        my $environmental_score     = 0;
        my $modified_exploitability = 8.22 * $self->W('MAV') * $self->W('MAC') * $self->W('MPR') * $self->W('MUI');

        my $miss = min(
            (
                1 - (
                      (1 - $self->W('MC') * $self->W('CR'))
                    * (1 - $self->W('MI') * $self->W('IR'))
                        * (1 - $self->W('MA') * $self->W('AR'))
                )
            ),
            0.915
        );

        DEBUG and say STDERR "-- Modified Impact Sub-Score (MISS): $miss";

        if ($self->M('MS') eq 'U' || ($self->M('MS') eq 'X' && $self->M('S') eq 'U')) {
            $modified_impact = $self->W('MS') * $miss;
        }
        else {
            if ($self->version == 3.0) {
                $modified_impact = $self->W('MS') * ($miss - 0.029) - 3.25 * (($miss - 0.02)**15);
            }
            elsif ($self->version == 3.1) {
                $modified_impact = $self->W('MS') * ($miss - 0.029) - 3.25 * (($miss * 0.9731 - 0.02)**13);
            }
        }


        if ($modified_impact <= 0) {
            $environmental_score = 0;
        }
        elsif ($self->M('MS') eq 'U' || ($self->M('MS') eq 'X' && $self->M('S') eq 'U')) {
            $environmental_score
                = round_up(round_up(min(($modified_impact + $modified_exploitability), 10))
                    * $self->W('E')
                    * $self->W('RL')
                    * $self->W('RC'));
        }
        else {
            $environmental_score
                = round_up(round_up(min(1.08 * ($modified_impact + $modified_exploitability), 10))
                    * $self->W('E')
                    * $self->W('RL')
                    * $self->W('RC'));
        }

        DEBUG and say STDERR "-- ModifiedImpact: $modified_impact";
        DEBUG and say STDERR "-- ModifiedExploitability: $modified_exploitability";
        DEBUG and say STDERR "-- EnvironmentalScore: $environmental_score";

        $self->{scores}->{modified_impact} = round_up($modified_impact);
        $self->{scores}->{environmental}   = $environmental_score;


    }

    return 1;

}

sub round_up {

    my ($input) = @_;

    my $int_input = round($input * 100_000);

    if ($int_input % 10_000 == 0) {
        return $int_input / 100_000;
    }
    else {
        return (floor($int_input / 10_000) + 1) / 10;
    }

}

sub to_xml {

    my ($self) = @_;

    my $metric_value_names = $self->METRIC_NAMES;

    $self->calculate_score unless ($self->base_score);

    my $version                = $self->version;
    my $metrics                = $self->metrics;
    my $base_score             = $self->base_score;
    my $base_severity          = $self->base_severity;
    my $temporal_score         = $self->temporal_score;
    my $temporal_severity      = $self->temporal_severity;
    my $environmental_score    = $self->environmental_score;
    my $environmental_severity = $self->environmental_severity;

    my $xml_metrics = <<"XML";
  <base_metrics>
    <attack-vector>$metric_value_names->{AV}->{values}->{$metrics->{AV}}</attack-vector>
    <attack-complexity>$metric_value_names->{AC}->{values}->{$metrics->{AC}}</attack-complexity>
    <privileges-required>$metric_value_names->{PR}->{values}->{$metrics->{PR}}</privileges-required>
    <user-interaction>$metric_value_names->{UI}->{values}->{$metrics->{UI}}</user-interaction>
    <scope>$metric_value_names->{S}->{values}->{$metrics->{S}}</scope>
    <confidentiality-impact>$metric_value_names->{C}->{values}->{$metrics->{C}}</confidentiality-impact>
    <integrity-impact>$metric_value_names->{I}->{values}->{$metrics->{I}}</integrity-impact>
    <availability-impact>$metric_value_names->{A}->{values}->{$metrics->{A}}</availability-impact>
    <base-score>$base_score</base-score>
    <base-severity>$base_severity</base-severity>
  </base_metrics>
XML

    if ($self->metric_group_is_set('temporal')) {
        $xml_metrics .= <<"XML";
  <temporal_metrics>
    <exploit-code-maturity>$metric_value_names->{E}->{values}->{$metrics->{E} || 'X'}</exploit-code-maturity>
    <remediation-level>$metric_value_names->{RL}->{values}->{$metrics->{RL} || 'X'}</remediation-level>
    <report-confidence>$metric_value_names->{RC}->{values}->{$metrics->{RC} || 'X'}</report-confidence>
    <temporal-score>$temporal_score</temporal-score>
    <temporal-severity>$temporal_severity</temporal-severity>
  </temporal_metrics>
XML
    }

    if ($self->metric_group_is_set('environmental')) {
        $xml_metrics .= <<"XML";
  <environmental_metrics>
    <confidentiality-requirement>$metric_value_names->{CR}->{values}->{$metrics->{CR} || 'X'}</confidentiality-requirement>
    <integrity-requirement>$metric_value_names->{IR}->{values}->{$metrics->{IR} || 'X'}</integrity-requirement>
    <availability-requirement>$metric_value_names->{AR}->{values}->{$metrics->{AR} || 'X'}</availability-requirement>
    <modified-attack-vector>$metric_value_names->{MAV}->{values}->{$metrics->{MAV} || 'X'}</modified-attack-vector>
    <modified-attack-complexity>$metric_value_names->{MAC}->{values}->{$metrics->{MAC} || 'X'}</modified-attack-complexity>
    <modified-privileges-required>$metric_value_names->{MPR}->{values}->{$metrics->{MPR} || 'X'}</modified-privileges-required>
    <modified-user-interaction>$metric_value_names->{MUI}->{values}->{$metrics->{MUI} || 'X'}</modified-user-interaction>
    <modified-scope>$metric_value_names->{MS}->{$metrics->{values}->{MS} || 'X'}</modified-scope>
    <modified-confidentiality-impact>$metric_value_names->{MC}->{values}->{$metrics->{MC} || 'X'}</modified-confidentiality-impact>
    <modified-integrity-impact>$metric_value_names->{MI}->{values}->{$metrics->{MI} || 'X'}</modified-integrity-impact>
    <modified-availability-impact>$metric_value_names->{MA}->{values}->{$metrics->{MA} || 'X'}</modified-availability-impact>
    <environmental-score>$environmental_score</environmental-score>
    <environmental-severity>$environmental_severity</environmental-severity>
  </environmental_metrics>
XML
    }

    my $xml = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>
<cvssv$version xmlns="https://www.first.org/cvss/cvss-v$version.xsd"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="https://www.first.org/cvss/cvss-v$version.xsd https://www.first.org/cvss/cvss-v$version.xsd"
  >

$xml_metrics
</cvssv$version>
XML

    return $xml;

}

1;

1;
__END__

=pod

=head1 NAME

CVSS::v3 - Parse and calculate CVSS v3 scores

=head1 SYNOPSIS

    use CVSS::v3;
    my $cvss = CVSS::v3->from_vector_string('CVSS:3.1/AV:A/AC:L/PR:L/UI:R/S:U/C:H/I:H/A:H');

    say $cvss->AV; # A
    say $cvss->attackVector; # ADJACENT_NETWORK

=head1 DESCRIPTION


=head2 METHODS

L<CVSS::v3> inherits all methods from L<CVSS::Base> and implements the following new ones.

=head3 SCORES

=over

=item $cvss->temporal_score

Return the temporal score (0 - 10).

=item $cvss->temporal_severity

Return the temporal severity (LOW, MEDIUM, HIGH or CRITICAL).

=item $cvss->environmental_score

Return the environmental score (0 - 10).

=item $cvss->environmental_severity

Return the environmental severity (LOW, MEDIUM, HIGH or CRITICAL).

=back

=head3 BASE METRICS

=over

=item $cvss->AV | $cvss->attackVector

=item $cvss->AC | $cvss->attackComplexity

=item $cvss->PR | $cvss->privilegesRequired

=item $cvss->UI | $cvss->userInteraction

=item $cvss->S | $cvss->scope

=item $cvss->C | $cvss->confidentialityImpact

=item $cvss->I | $cvss->integrityImpact

=item $cvss->A | $cvss->availabilityImpact

=back

=head3 TEMPORAL METRICS

=over

=item $cvss->E | $cvss->exploitCodeMaturity

=item $cvss->RL | $cvss->remediationLevel

=item $cvss->RC | $cvss->reportConfidence

=back

=head3 ENVIROMENTAL METRICS

=over

=item $cvss->CR | $cvss->confidentialityRequirement

=item $cvss->IR | $cvss->integrityRequirement

=item $cvss->AR | $cvss->availabilityRequirement

=item $cvss->MAV | $cvss->modifiedAttackVector

=item $cvss->MAC | $cvss->modifiedAttackComplexity

=item $cvss->MPR | $cvss->modifiedPrivilegesRequired

=item $cvss->MUI | $cvss->modifiedUserInteraction

=item $cvss->MS | $cvss->modifiedScope

=item $cvss->MC | $cvss->modifiedConfidentialityImpact

=item $cvss->MI | $cvss->modifiedIntegrityImpact

=item $cvss->MA | $cvss->modifiedAvailabilityImpact

=back

=head1 SEE ALSO

L<CVSS>, L<CVSS::v2>, L<CVSS::v4>

=over 4

=item [FIRST] CVSS Data Representations (L<https://www.first.org/cvss/data-representations>)

=item [FIRST] CVSS v3.1 Specification (L<https://www.first.org/cvss/v3.1/specification-document>)

=item [FIRST] CVSS v3.0 Specification (L<https://www.first.org/cvss/v3.0/specification-document>)

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-CVSS/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-CVSS>

    git clone https://github.com/giterlizzi/perl-CVSS.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023-2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
