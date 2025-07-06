package CSAF::Util::CVSS;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT_OK = (qw[decode_cvss_vector_string]);

my $CVSS2_METRIC_LABEL = {
    AV  => 'accessVector',
    AC  => 'accessComplexity',
    Au  => 'authentication',
    C   => 'confidentialityImpact',
    I   => 'integrityImpact',
    A   => 'availabilityImpact',
    E   => 'exploitability',
    RL  => 'remediationLevel',
    RC  => 'reportConfidence',
    CDP => 'collateralDamagePotential',
    TD  => 'targetDistribution',
    CR  => 'confidentialityRequirement',
    IR  => 'integrityRequirement',
    AR  => 'availabilityRequirement'
};

my $CVSS3_METRIC_LABEL = {
    A  => 'availabilityImpact',
    AC => 'attackComplexity',
    AV => 'attackVector',
    C  => 'confidentialityImpact',
    E  => 'exploitCodeMaturity',
    I  => 'integrityImpact',
    PR => 'privilegesRequired',
    RC => 'reportConfidence',
    RL => 'remediationLevel',
    S  => 'scope',
    UI => 'userInteraction',

    MA  => 'modifiedAvailabilityImpact',
    MAC => 'modifiedAttackComplexity',
    MAV => 'modifiedAttackVector',
    MC  => 'modifiedConfidentialityImpact',
    MI  => 'modifiedIntegrityImpact',
    MPR => 'modifiedPrivilegesRequired',
    MS  => 'modifiedScope',
    MUI => 'modifiedUserInteraction',
};


my $CVSS2_METRIC_VALUES = {
    AV => {N  => 'NETWORK',      A   => 'ADJACENT_NETWORK', L => 'LOCAL'},
    AC => {H  => 'HIGH',         M   => 'MEDIUM',           L => 'LOW'},
    Au => {M  => 'MULTIPLE',     S   => 'SINGLE',           N => 'NONE'},
    C  => {N  => 'NONE',         P   => 'PARTIAL',          C => 'COMPLETE'},
    I  => {N  => 'NONE',         P   => 'PARTIAL',          C => 'COMPLETE'},
    A  => {N  => 'NONE',         P   => 'PARTIAL',          C => 'COMPLETE'},
    E  => {U  => 'UNPROVEN',     POC => 'PROOF_OF_CONCEPT', F => 'FUNCTIONAL', H => 'HIGH',        ND => 'NOT_DEFINED'},
    RL => {OF => 'OFFICIAL_FIX', TF  => 'TEMPORARY_FIX',    W => 'WORKAROUND', U => 'UNAVAILABLE', ND => 'NOT_DEFINED'},
    RC => {UC => 'UNCONFIRMED',  UR  => 'UNCORROBORATED',   C => 'CONFIRMED',  ND => 'NOT_DEFINED'},
    CDP => {N => 'NONE', L => 'LOW',    LM => 'LOW_MEDIUM', MH => 'MEDIUM_HIGH', H => 'HIGH', ND => 'NOT_DEFINED'},
    TD  => {N => 'NONE', L => 'LOW',    M  => 'MEDIUM',     H  => 'HIGH', ND => 'NOT_DEFINED'},
    CR  => {L => 'LOW',  M => 'MEDIUM', H  => 'HIGH',       ND => 'NOT_DEFINED'},
    IR  => {L => 'LOW',  M => 'MEDIUM', H  => 'HIGH',       ND => 'NOT_DEFINED'},
    AR  => {L => 'LOW',  M => 'MEDIUM', H  => 'HIGH',       ND => 'NOT_DEFINED'},
};

my $CVSS3_METRIC_VALUES = {
    AV => {N => 'NETWORK',     A => 'ADJACENT_NETWORK', L => 'LOCAL', P => 'PHYSICAL'},
    AC => {L => 'LOW',         H => 'HIGH'},
    PR => {N => 'NONE',        L => 'LOW', H => 'HIGH'},
    UI => {N => 'NONE',        R => 'REQUIRED'},
    S  => {U => 'UNCHANGED',   C => 'CHANGED'},
    C  => {N => 'NONE',        L => 'LOW',          H => 'HIGH'},
    I  => {N => 'NONE',        L => 'LOW',          H => 'HIGH'},
    A  => {N => 'NONE',        L => 'LOW',          H => 'HIGH'},
    E  => {X => 'NOT_DEFINED', U => 'UNPROVEN',     P => 'PROOF_OF_CONCEPT', F => 'FUNCTIONAL', H => 'HIGH'},
    RL => {X => 'NOT_DEFINED', O => 'OFFICIAL_FIX', T => 'TEMPORARY_FIX',    W => 'WORKAROUND', U => 'UNAVAILABLE'},
    RC => {X => 'NOT_DEFINED', U => 'UNKNOWN',      R => 'REASONABLE',       C => 'CONFIRMED'},

    MA  => {X => 'NOT_DEFINED', N => 'NONE',      L => 'LOW', H => 'HIGH'},
    MAC => {X => 'NOT_DEFINED', L => 'LOW',       H => 'HIGH'},
    MAV => {X => 'NOT_DEFINED', N => 'NETWORK',   A => 'ADJACENT_NETWORK', L => 'LOCAL', P => 'PHYSICAL'},
    MC  => {X => 'NOT_DEFINED', N => 'NONE',      L => 'LOW', H => 'HIGH'},
    MI  => {X => 'NOT_DEFINED', N => 'NONE',      L => 'LOW', H => 'HIGH'},
    MPR => {X => 'NOT_DEFINED', N => 'NONE',      L => 'LOW', H => 'HIGH'},
    MS  => {X => 'NOT_DEFINED', U => 'UNCHANGED', C => 'CHANGED'},
    MUI => {X => 'NOT_DEFINED', N => 'NONE',      R => 'REQUIRED'},
};


sub decode_cvss_vector_string {

    my $vector_string = shift;
    my $decoded       = {};

    if ($vector_string =~ /^CVSS:3[.][0-1]\/(.*)/) {

        my %cvss = split /[:\/]/, $1;

        foreach my $metric (keys %cvss) {

            if (defined $CVSS3_METRIC_LABEL->{$metric}) {

                my $value = $cvss{$metric};
                my $label = $CVSS3_METRIC_LABEL->{$metric};

                $decoded->{$label} = $CVSS3_METRIC_VALUES->{$metric}->{$value} || $value;

            }
        }

    }
    else {

        my %cvss = split /[:\/]/, $vector_string;

        foreach my $metric (keys %cvss) {

            if (defined $CVSS2_METRIC_LABEL->{$metric}) {

                my $value = $cvss{$metric};
                my $label = $CVSS2_METRIC_LABEL->{$metric};

                $decoded->{$label} = $CVSS2_METRIC_VALUES->{$metric}->{$value} || $value;

            }
        }

    }

    return $decoded;

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Util::CVSS - CVSS utility for CSAF

=head1 SYNOPSIS

    use CSAF::Util::CVSS qw(decode_cvss_vector_string);

    say Dumper(decode_cvss_vector_string('CVSS:3.1/AV:L/AC:L/PR:N/UI:R/S:U/C:H/I:N/A:L/E:F/RL:O/RC:C'));

=head1 DESCRIPTION

CVSS utility for L<CSAF>.

=head2 FUNCTIONS

=over

=item decode_cvss_vector_string

Decode the provided CVSS (v2.0 or v3.x) vector string.

    my $decoded = decode_cvss_vector_string('CVSS:3.1/AV:L/AC:L/PR:N/UI:R/S:U/C:H/I:N/A:L/E:F/RL:O/RC:C');

    say $decoded->{attackVector}; # LOCAL

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-CSAF/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-CSAF>

    git clone https://github.com/giterlizzi/perl-CSAF.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023-2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
