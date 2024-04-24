package CSAF::Type::CVSS2;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;

extends 'CSAF::Type::Base';

has version      => (is => 'ro', default => '2.0');
has vectorString => (is => 'ro');
has baseScore    => (is => 'ro', coerce => sub { ($_[0] + 0) });

has [qw(
    accessVector
    accessComplexity
    authentication
    confidentialityImpact
    integrityImpact
    availabilityImpact
    exploitability
    remediationLevel
    reportConfidence
    collateralDamagePotential
    targetDistribution
    confidentialityRequirement
    integrityRequirement
    availabilityRequirement
)] => (is => 'rw', coerce => sub { uc $_[0] });

has ['temporalScore', 'environmentalScore'] => (is => 'rw', coerce => sub { ($_[0] + 0) });


sub TO_CSAF {

    my $self = shift;

    my $output = {version => $self->version, vectorString => $self->vectorString, baseScore => $self->baseScore};

    my @attributes = qw(
        accessVector
        accessComplexity
        authentication
        confidentialityImpact
        integrityImpact
        availabilityImpact
        exploitability
        remediationLevel
        reportConfidence
        temporalScore
        collateralDamagePotential
        targetDistribution
        confidentialityRequirement
        integrityRequirement
        availabilityRequirement
        environmentalScore
    );

    for my $attribute (@attributes) {
        $output->{$attribute} = $self->$attribute if ($self->$attribute);
    }

    return $output;

}

sub TO_JSON { shift->TO_CSAF }

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Type::CVSS2

=head1 SYNOPSIS

    use CSAF::Type::CVSS2;
    my $type = CSAF::Type::CVSS2->new( );


=head1 DESCRIPTION

Common Vulnerability Scoring System (CVSS) version 2.0.


=head2 METHODS

L<CSAF::Type::CVSS2> inherits all methods from L<CSAF::Type::Base> and implements the following new ones.

=over

=item $type->accessComplexity

=item $type->accessVector

=item $type->authentication

=item $type->availabilityImpact

=item $type->availabilityRequirement

=item $type->baseScore

=item $type->collateralDamagePotential

=item $type->confidentialityImpact

=item $type->confidentialityRequirement

=item $type->environmentalScore

=item $type->exploitability

=item $type->integrityImpact

=item $type->integrityRequirement

=item $type->remediationLevel

=item $type->reportConfidence

=item $type->targetDistribution

=item $type->temporalScore

=item $type->vectorString

=item $type->version

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

This software is copyright (c) 2023-2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
