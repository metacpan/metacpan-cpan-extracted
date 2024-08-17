package CVSS::v2;

use feature ':5.10';
use strict;
use utf8;
use warnings;

use Carp       ();
use List::Util qw(min);

use base 'CVSS::Base';
use CVSS::Constants ();

our $VERSION = '1.13';
$VERSION =~ tr/_//d;    ## no critic

use constant DEBUG => $ENV{CVSS_DEBUG};

my $WEIGHTS = CVSS::Constants->CVSS2_WEIGHTS;

sub ATTRIBUTES          { CVSS::Constants->CVSS2_ATTRIBUTES }
sub SCORE_SEVERITY      { CVSS::Constants->CVSS2_SCORE_SEVERITY }
sub NOT_DEFINED_VALUE   { CVSS::Constants->CVSS2_NOT_DEFINED_VALUE }
sub VECTOR_STRING_REGEX { CVSS::Constants->CVSS2_VECTOR_STRING_REGEX }
sub METRIC_GROUPS       { CVSS::Constants->CVSS2_METRIC_GROUPS }
sub METRIC_NAMES        { CVSS::Constants->CVSS2_METRIC_NAMES }
sub METRIC_VALUES       { CVSS::Constants->CVSS2_METRIC_VALUES }

sub version {'2.0'}

sub weight {

    my ($self, $metric) = @_;

    my $value  = $self->M($metric);
    my $weight = $WEIGHTS->{$metric}{$value};

    DEBUG and say STDERR "-- Weight : $metric:$value = $weight";
    return $weight;

}

sub W { weight(@_) }

sub calculate_score {

    my ($self, $args) = @_;

    if (%{$self->metrics}) {
        for (@{$self->METRIC_GROUPS->{base}}) {
            Carp::croak sprintf('Missing base metric (%s)', $_) unless ($self->metrics->{$_});
        }
    }

    # Set NOT_DEFINED
    $self->metrics->{E}  //= 'ND';
    $self->metrics->{RL} //= 'ND';
    $self->metrics->{RC} //= 'ND';

    $self->metrics->{TD} //= 'ND';
    $self->metrics->{CR} //= 'ND';
    $self->metrics->{IR} //= 'ND';
    $self->metrics->{AR} //= 'ND';

    # Base Equation

    # BaseScore = round_to_1_decimal(((0.6*Impact)+(0.4*Exploitability)-1.5)*f(Impact))
    # Impact = 10.41*(1-(1-ConfImpact)*(1-IntegImpact)*(1-AvailImpact))
    # Exploitability = 20* AccessVector*AccessComplexity*Authentication
    # f(impact)= 0 if Impact=0, 1.176 otherwise

    my $impact         = (10.41 * (1 - (1 - $self->W('C')) * (1 - $self->W('I')) * (1 - $self->W('A'))));
    my $exploitability = (20 * $self->W('AV') * $self->W('AC') * $self->W('Au'));
    my $f_impact       = ($impact == 0 ? 0 : 1.176);
    my $base_score     = sprintf('%.1f', (((0.6 * $impact) + (0.4 * $exploitability) - 1.5) * $f_impact));

    DEBUG and say STDERR "-- Impact: $impact";
    DEBUG and say STDERR "-- f(Impact): $f_impact";
    DEBUG and say STDERR "-- Exploitability: $exploitability";
    DEBUG and say STDERR "-- BaseScore: $base_score";

    $self->{scores}->{impact}         = sprintf('%.1f', $impact);
    $self->{scores}->{base}           = $base_score;
    $self->{scores}->{exploitability} = sprintf('%.1f', $exploitability);

    if ($self->metric_group_is_set('temporal')) {

        # Temporal Equation

        # TemporalScore = round_to_1_decimal(BaseScore * Exploitability * RemediationLevel * ReportConfidence)

        my $temporal_score = sprintf('%.1f', ($base_score * $self->W('E') * $self->W('RL') * $self->W('RC')));

        DEBUG and say STDERR "-- TemporalScore: $temporal_score";

        $self->{scores}->{temporal} = $temporal_score;

    }

    if ($self->M('CDP')) {

        # Environmental Equation

        # EnvironmentalScore = round_to_1_decimal((AdjustedTemporal+
        #                      (10-AdjustedTemporal)*CollateralDamagePotential)*TargetDistribution)

        # AdjustedTemporal = TemporalScore recomputed with the BaseScore's Impact sub-
        #                    equation replaced with the AdjustedImpact equation

        # AdjustedImpact = min(10,10.41*(1-(1-ConfImpact*ConfReq)*(1-IntegImpact*IntegReq)
        #                  *(1-AvailImpact*AvailReq)))

        # AdjustedTemporal = quickRound(AdjustedBaseScore * Exploitability * RemediationLevel * ReportConfidence)
        # AdjustedBaseScore = quickRound((0.6 * AdjustedImpact + 0.4 * Exploitability - 1.5) * f(Impact))

        my $adj_impact = min(
            10,
            10.41 * (
                      1 - (1 - $self->W('C') * $self->W('CR'))
                    * (1 - $self->W('I') * $self->W('IR'))
                    * (1 - $self->W('A') * $self->W('AR'))
            )
        );

        $adj_impact = 10 if ($adj_impact > 10);

        my $adj_base_score = ((0.6 * $adj_impact + 0.4 * $exploitability - 1.5) * $f_impact);
        my $adj_temporal   = ($adj_base_score * $self->W('E') * $self->W('RL') * $self->W('RC'));

        my $environmental_score
            = sprintf('%.1f', (($adj_temporal + (10 - $adj_temporal) * $self->W('CDP')) * $self->W('TD')));

        DEBUG and say STDERR "-- AdjustedImpact: $adj_impact";
        DEBUG and say STDERR "-- AdjustedTemporal: $adj_temporal";
        DEBUG and say STDERR "-- EnvironmentalScore: $environmental_score";

        $self->{scores}->{environmental}   = $environmental_score;
        $self->{scores}->{modified_impact} = sprintf('%.1f', $adj_impact);

    }

    return 1;

}

1;
__END__

=pod

=head1 NAME

CVSS::v2 - Parse and calculate CVSS v2.0 scores

=head1 SYNOPSIS

    use CVSS::v2;
    my $cvss = CVSS::v2->from_vector_string('AV:N/AC:L/Au:N/C:N/I:N/A:C');

    say $cvss->AV; # N
    say $cvss->accessVector; # NETWORK


=head1 DESCRIPTION


=head2 METHODS

L<CVSS::v2> inherits all methods from L<CVSS::Base> and implements the following new ones.

=over

=item $cvss-weight ( $metric )

Return the weight of provided metric.

=item $cvss->W ( $metric )

Alias of C<weight>.

=back

=head3 BASE METRICS

=over

=item $cvss->AV | $cvss->accessVector

=item $cvss->AC | $cvss->accessComplexity

=item $cvss->Au | $cvss->authentication

=item $cvss->C | $cvss->confidentialityImpact

=item $cvss->I | $cvss->integrityImpact

=item $cvss->A | $cvss->availabilityImpact

=back


=head3 TEMPORAL METRICS

=over

=item $cvss->E | $cvss->exploitability

=item $cvss->RL | $cvss->remediationLevel

=item $cvss->RC | $cvss->reportConfidence

=back


=head3 ENVIRONMENTAL METRICS

=over

=item $cvss->CDP | $cvss->collateralDamagePotential

=item $cvss->TD | $cvss->targetDistribution

=item $cvss->CR | $cvss->confidentialityRequirement

=item $cvss->IR | $cvss->integrityRequirement

=item $cvss->AR | $cvss->availabilityRequirement

=back


=head1 SEE ALSO

L<CVSS>, L<CVSS::v3>, L<CVSS::v4>

=over 4

=item [FIRST] CVSS Data Representations (L<https://www.first.org/cvss/data-representations>)

=item [FIRST] CVSS v2.0 Complete Guide (L<https://www.first.org/cvss/v2/guide>)

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
