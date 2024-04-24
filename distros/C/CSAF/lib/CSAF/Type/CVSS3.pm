package CSAF::Type::CVSS3;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;
use Carp;

extends 'CSAF::Type::Base';


# TODO      Parse vector string and set single metrics

has version => (
    is      => 'ro',
    default => '3.1',
    isa     => sub { Carp::croak "CVSS3 version must be 3.0 or 3.1" unless ($_[0] eq '3.0' || $_[0] eq '3.1') }
);

has vectorString => (is => 'rw', coerce => sub { uc $_[0] });
has baseScore    => (is => 'rw', coerce => sub { ($_[0] + 0) });
has baseSeverity => (is => 'rw', coerce => sub { uc $_[0] });

has [qw(
    attackVector
    attackComplexity
    privilegesRequired
    userInteraction
    scope
    confidentialityImpact
    integrityImpact
    availabilityImpact
    exploitCodeMaturity
    remediationLevel
    reportConfidence
    temporalScore
    temporalSeverity
    confidentialityRequirement
    integrityRequirement
    availabilityRequirement
    modifiedAttackVector
    modifiedAttackComplexity
    modifiedPrivilegesRequired
    modifiedUserInteraction
    modifiedScope
    modifiedConfidentialityImpact
    modifiedIntegrityImpact
    modifiedAvailabilityImpact
    environmentalScore
    environmentalSeverity
)] => (is => 'rw', coerce => sub { uc $_[0] });

sub TO_CSAF {

    my $self = shift;

    my $output = {
        version      => $self->version,
        vectorString => $self->vectorString,
        baseScore    => $self->baseScore,
        baseSeverity => $self->baseSeverity
    };


    my @attributes = qw(
        attackVector
        attackComplexity
        privilegesRequired
        userInteraction
        scope
        confidentialityImpact
        integrityImpact
        availabilityImpact
        exploitCodeMaturity
        remediationLevel
        reportConfidence
        temporalScore
        temporalSeverity
        confidentialityRequirement
        integrityRequirement
        availabilityRequirement
        modifiedAttackVector
        modifiedAttackComplexity
        modifiedPrivilegesRequired
        modifiedUserInteraction
        modifiedScope
        modifiedConfidentialityImpact
        modifiedIntegrityImpact
        modifiedAvailabilityImpact
        environmentalScore
        environmentalSeverity
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

CSAF::Type::CVSS3

=head1 SYNOPSIS

    use CSAF::Type::CVSS3;
    my $type = CSAF::Type::CVSS3->new( );


=head1 DESCRIPTION

Common Vulnerability Scoring System (CVSS) version 3.0 and 3.1.


=head2 METHODS

L<CSAF::Type::CVSS3> inherits all methods from L<CSAF::Type::Base> and implements the following new ones.

=over

=item $type->attackComplexity

=item $type->attackVector

=item $type->availabilityImpact

=item $type->availabilityRequirement

=item $type->baseScore

=item $type->baseSeverity

=item $type->carp

=item $type->confess

=item $type->confidentialityImpact

=item $type->confidentialityRequirement

=item $type->croak

=item $type->environmentalScore

=item $type->environmentalSeverity

=item $type->exploitCodeMaturity

=item $type->integrityImpact

=item $type->integrityRequirement

=item $type->modifiedAttackComplexity

=item $type->modifiedAttackVector

=item $type->modifiedAvailabilityImpact

=item $type->modifiedConfidentialityImpact

=item $type->modifiedIntegrityImpact

=item $type->modifiedPrivilegesRequired

=item $type->modifiedScope

=item $type->modifiedUserInteraction

=item $type->privilegesRequired

=item $type->remediationLevel

=item $type->reportConfidence

=item $type->scope

=item $type->temporalScore

=item $type->temporalSeverity

=item $type->userInteraction

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
