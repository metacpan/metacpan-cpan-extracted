package CVSS::Base;

use feature ':5.10';
use strict;
use utf8;
use warnings;

use Carp ();

our $VERSION = '1.11';
$VERSION =~ tr/_//d;    ## no critic

use overload '""' => \&to_string, fallback => 1;

use constant DEBUG => $ENV{CVSS_DEBUG};

sub import {

    my $class = shift;

    my $ATTRIBUTES = $class->ATTRIBUTES;

    for my $method (keys %{$ATTRIBUTES}) {

        no strict 'refs';
        no warnings 'uninitialized';
        no warnings 'redefine';

        my $metric = $ATTRIBUTES->{$method};

        # Long method name
        *{"${class}::${method}"} = sub {
            @_ > 1 ? $_[0]->_metric_name_to_value($metric, $_[1]) : $_[0]->_metric_value_to_name($metric);
        };

        # Create metric alias
        *{"${class}::${metric}"} = sub { $_[0]->M($metric) };

    }

}

sub new {

    my ($class, %params) = @_;

    $params{metrics}       //= {};
    $params{scores}        //= {};
    $params{vector_string} //= undef;

    my $self = bless {%params}, $class;

    if (!$self->version =~ /(2.0|3.[0-1]|4.0)/) {
        Carp::croak 'Invalid CVSS version';
    }

    if ($self->{vector_string}) {

        DEBUG and say STDERR sprintf('-- Validate vector string: %s', $self->VECTOR_STRING_REGEX);

        if ($self->{vector_string} !~ $self->VECTOR_STRING_REGEX) {
            Carp::croak 'Invalid CVSS vector string';
        }

        $self->calculate_score;

    }

    return $self;

}

sub from_vector_string {

    my ($class, $vector_string) = @_;

    my %metrics = split /[\/:]/, $vector_string;
    my $version = delete $metrics{CVSS} || '2.0';

    DEBUG and say STDERR "-- Vector String: $vector_string";
    return $class->new(version => $version, metrics => \%metrics, vector_string => $vector_string);

}

sub ATTRIBUTES          { {} }
sub SEVERITY            { {} }
sub NOT_DEFINED_VALUE   { }
sub VECTOR_STRING_REGEX {qw{}}
sub METRIC_GROUPS       { {} }
sub METRIC_NAMES        { {} }


sub _metric_name_to_value {
    my ($self, $metric, $name) = @_;
    $name =~ s/\s/_/g;
    $self->metrics->{$metric} = $self->METRIC_NAMES->{$metric}->{names}->{$name};
    return $self;
}

sub _metric_value_to_name {
    my ($self, $metric) = @_;
    $self->METRIC_NAMES->{$metric}->{values}->{$self->metrics->{$metric}};
}

sub version       { shift->{version}       || Carp::croak 'Missing CVSS version' }
sub vector_string { $_[0]->{vector_string} || $_[0]->to_vector_string }
sub metrics       { shift->{metrics} }
sub scores        { shift->{scores} }


# Scores & severities
sub base_score    { shift->{scores}->{base} }
sub base_severity { $_[0]->score_to_severity($_[0]->base_score) }

# CVSS 2.0/3.x scores & severities
sub temporal_score         { shift->{scores}->{temporal} }
sub temporal_severity      { $_[0]->score_to_severity($_[0]->temporal_score) }
sub environmental_score    { shift->{scores}->{environmental} }
sub environmental_severity { $_[0]->score_to_severity($_[0]->environmental_score) }

# Extra 2.0/3.x scores
sub exploitability_score  { shift->{scores}->{exploitability} }
sub impact_score          { shift->{scores}->{impact} }
sub modified_impact_score { shift->{scores}->{modified_impact} }


# JSON-style alias
sub vectorString          { shift->vector_string }
sub baseScore             { shift->base_score }
sub baseSeverity          { shift->base_severity }
sub temporalScore         { shift->temporal_score }
sub temporalSeverity      { shift->temporal_severity }
sub environmentalScore    { shift->environmental_score }
sub environmentalSeverity { shift->environmental_severity }


sub metric_group_is_set {

    my ($self, $type) = @_;

    for (@{$self->METRIC_GROUPS->{$type}}) {
        return 1 if ($self->M($_) && $self->M($_) ne $self->NOT_DEFINED_VALUE);
    }

}

sub metric {
    my ($self, $metric) = @_;
    my $value = $self->M($metric);

    return $self->METRIC_NAMES->{$metric}->{values}->{$value};
}

sub M { $_[0]->metrics->{$_[1]} }

sub score_to_severity {

    my ($self, $score) = @_;

    return unless (!!$score);

    my $SEVERITY = $self->SEVERITY;

    foreach (keys %{$SEVERITY}) {
        my $range = $SEVERITY->{$_};
        if ($score >= $range->{min} && $score <= $range->{max}) {
            return $_;
        }
    }

    Carp::croak 'Unknown severity';

}

sub calculate_score { Carp::croak sprintf('%s->calculate_score() is not implemented in subclass', ref(shift)) }

sub to_xml { Carp::croak sprintf('%s->to_xml() is not implemented in subclass', ref(shift)) }

sub to_string { shift->to_vector_string }

sub to_vector_string {

    my ($self) = @_;

    my $metrics = $self->metrics;
    my @vectors = ();

    if ($self->version > 2.0) {
        push @vectors, sprintf('CVSS:%s', $self->version);
    }

    foreach my $metric (@{$self->METRIC_GROUPS->{base}}) {
        push @vectors, sprintf('%s:%s', $metric, $metrics->{$metric});
    }

    my @other_metrics = ();

    push @other_metrics, @{$self->METRIC_GROUPS->{threat}        || []};    # CVSS 4.0
    push @other_metrics, @{$self->METRIC_GROUPS->{temporal}      || []};    # CVSS 2.0-3.x
    push @other_metrics, @{$self->METRIC_GROUPS->{environmental} || []};    # CVSS 2.0-3.x-4.0
    push @other_metrics, @{$self->METRIC_GROUPS->{supplemental}  || []};    # CVSS 4.0

    foreach my $metric (@other_metrics) {
        if (defined $metrics->{$metric} && $metrics->{$metric} ne $self->NOT_DEFINED_VALUE) {
            push @vectors, sprintf('%s:%s', $metric, $metrics->{$metric});
        }
    }

    return join '/', @vectors;

}

sub TO_JSON {

    my ($self) = @_;

    # Required JSON fields:
    #   CVSS == v2.0: version, vectorString and baseScore
    #   CVSS >= v3.0: version, vectorString, baseScore and baseSeverity

    $self->calculate_score unless ($self->base_score);

    my $json = {
        version      => sprintf('%.1f', $self->version),
        vectorString => $self->vector_string,
        baseScore    => $self->base_score
    };

    if ($self->version > 2.0) {
        $json->{baseSeverity} = $self->base_severity;
    }

    my $metrics    = $self->metrics;
    my %attributes = reverse(%{$self->ATTRIBUTES});

    foreach my $metric (@{$self->METRIC_GROUPS->{base}}) {
        $json->{$attributes{$metric}} = $self->METRIC_NAMES->{$metric}->{values}->{$metrics->{$metric}};
    }

    my @other_metrics = ();

    push @other_metrics, @{$self->METRIC_GROUPS->{threat}        || []};    # CVSS 4.0
    push @other_metrics, @{$self->METRIC_GROUPS->{temporal}      || []};    # CVSS 2.0-3.x
    push @other_metrics, @{$self->METRIC_GROUPS->{environmental} || []};    # CVSS 2.0-3.x-4.0
    push @other_metrics, @{$self->METRIC_GROUPS->{supplemental}  || []};    # CVSS 4.0

    foreach my $metric (@other_metrics) {
        if ($metrics->{$metric} && $metrics->{$metric} ne $self->NOT_DEFINED_VALUE) {
            $json->{$attributes{$metric}} = $self->METRIC_NAMES->{$metric}->{values}->{$metrics->{$metric}};
        }
    }

    if ($self->version <= 3.1) {

        if ($self->metric_group_is_set('temporal')) {

            $json->{temporalScore} = $self->temporal_score;

            if ($self->version != 2.0) {
                $json->{temporalSeverity} = $self->temporal_severity;
            }

        }

        if ($self->metric_group_is_set('environmental')) {

            $json->{environmentalScore} = $self->environmental_score;

            if ($self->version != 2.0) {
                $json->{environmentalSeverity} = $self->environmental_severity;
            }

        }

    }

    # CVSS 4.0 ???

    # environmentalScore
    # environmentalSeverity
    # threatScore
    # threatSeverity

    return $json;

}

1;
__END__

=pod

=head1 NAME

CVSS::Base - Base class for CVSS


=head1 DESCRIPTION

These are base class for L<CVSS::v2>, L<CVSS::v3> and L<CVSS::v4> classes.

=head2 METHODS

=over 

=item $cvss->version

Return the CVSS version.

=item $cvss->vector_string

Return the CVSS vector string.

=item $cvss->metrics

Return the HASH of CVSS metrics.

=back


=head3 SCORE & SEVERITY

=over

=item $cvss->scores

Return the HASH of calculated score (base, impact, temporal, etc.).

    $scores = $cvss->scores;

    say Dumper($scores);

    # { "base"           => "7.4",
    #   "exploitability" => "1.6",
    #   "impact"         => "5.9" }

=item $cvss->calculate_score

Performs the calculation of the score in accordance with the CVSS specification.

=item score_to_severity ( $score )

Convert the score in severity

=item $cvss->base_score

Return the base score (0 - 10).

=item $cvss->base_severity

Return the base severity (LOW, MEDIUM, HIGH or CRITICAL).

=item $cvss->temporal_score

Return the temporal score (0 - 10) -- (CVSS 2.0/3.x)

=item $cvss->temporal_severity

Return the temporal severity (LOW, MEDIUM, HIGH or CRITICAL) -- (CVSS 2.0/3.x)

=item $cvss->environmental_score

Return the environmental score (0 - 10) -- (CVSS 2.0/3.x)

=item $cvss->environmental_severity

Return the environmental severity (LOW, MEDIUM, HIGH or CRITICAL) -- (CVSS 2.0/3.x)

=item $cvss->impact_score

Return the impact score (0 - 10) -- (CVSS 2.0/3.x)

=item $cvss->exploitability_score

Return the exploitability score (0 - 10) -- (CVSS 2.0/3.x)

=item $cvss->modified_impact_score

Return the modified impact score (0 - 10) -- (CVSS 2.0/3.x)

=back


=head3 METRICS

=over

=item $cvss->M ( $metric )

Return the metric value (short)

    say $cvss->M('AV'); # A

=item $cvss->metric ( $metric )

Return the metric value (long)

    say $cvss->metric('AV'); # ADJACENT_NETWORK

=item $cvss->metric_group_is_set ( $group )

=back

=head3 DATA REPRESENTATIONS

=over

=item $cvss->to_vector_string

Convert the L<CVSS> object in vector string

    say $cvss->to_vector_string; # CVSS:3.1/AV:A/AC:L/PR:L/UI:R/S:U/C:H/I:H/A:H

    # or

    say $cvss; # CVSS:3.1/AV:A/AC:L/PR:L/UI:R/S:U/C:H/I:H/A:H

=item $cvss->to_xml

Convert the L<CVSS> object in XML in according of CVSS XML Schema Definition.

=over

=item * https://nvd.nist.gov/schema/cvss-v2_0.2.xsd - XSD for CVSS v2.0

=item * https://www.first.org/cvss/cvss-v3.0.xsd - XSD for CVSS v3.0

=item * https://www.first.org/cvss/cvss-v3.1.xsd - XSD for CVSS v3.1

=item * https://www.first.org/cvss/cvss-v4.0.xsd - XSD for CVSS v4.0

=back

    say $cvss->to_xml;

    # <?xml version="1.0" encoding="UTF-8"?>
    # <cvssv3.1 xmlns="https://www.first.org/cvss/cvss-v3.1.xsd"
    #   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    #   xsi:schemaLocation="https://www.first.org/cvss/cvss-v3.1.xsd https://www.first.org/cvss/cvss-v3.1.xsd"
    #   >
    # 
    #   <base_metrics>
    #     <attack-vector>ADJACENT_NETWORK</attack-vector>
    #     <attack-complexity>LOW</attack-complexity>
    #     <privileges-required>LOW</privileges-required>
    #     <user-interaction>REQUIRED</user-interaction>
    #     <scope>UNCHANGED</scope>
    #     <confidentiality-impact>HIGH</confidentiality-impact>
    #     <integrity-impact>HIGH</integrity-impact>
    #     <availability-impact>HIGH</availability-impact>
    #     <base-score>7.4</base-score>
    #     <base-severity>HIGH</base-severity>
    #   </base_metrics>
    # 
    # </cvssv3.1>

=item $cvss->TO_JSON

Helper method for JSON modules (L<JSON>, L<JSON::PP>, L<JSON::XS>, L<Mojo::JSON>, etc).

Convert the L<CVSS> object in JSON format in according of CVSS JSON Schema.

=over

=item * https://www.first.org/cvss/cvss-v2.0.json - JSON Schema for CVSS v2.0.

=item * https://www.first.org/cvss/cvss-v3.0.json - JSON Schema for CVSS v3.0.

=item * https://www.first.org/cvss/cvss-v3.1.json - JSON Schema for CVSS v3.1.

=item * https://www.first.org/cvss/cvss-v4.0.json - JSON Schema for CVSS v4.0.

=back

    use Mojo::JSON qw(encode_json);

    say encode_json($cvss);

    # {
    #    "attackComplexity" : "LOW",
    #    "attackVector" : "ADJACENT_NETWORK",
    #    "availabilityImpact" : "HIGH",
    #    "baseScore" : 7.4,
    #    "baseSeverity" : "HIGH",
    #    "confidentialityImpact" : "HIGH",
    #    "integrityImpact" : "HIGH",
    #    "privilegesRequired" : "LOW",
    #    "scope" : "UNCHANGED",
    #    "userInteraction" : "REQUIRED",
    #    "vectorString" : "CVSS:3.1/AV:A/AC:L/PR:L/UI:R/S:U/C:H/I:H/A:H",
    #    "version" : "3.1"
    # }

=back

=head1 SEE ALSO

L<CVSS::v2>, L<CVSS::v3>, L<CVSS::v4>


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
