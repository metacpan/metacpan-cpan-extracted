package CSAF::Type;

use 5.010001;
use strict;
use warnings;
use utf8;

use Carp;

use constant TYPE_CLASSES => {
    acknowledgment                => 'CSAF::Type::Acknowledgment',
    acknowledgments               => 'CSAF::Type::Acknowledgments',
    aggregate_severity            => 'CSAF::Type::AggregateSeverity',
    branch                        => 'CSAF::Type::Branch',
    branches                      => 'CSAF::Type::Branches',
    cvss_v2                       => 'CSAF::Type::CVSS2',
    cvss_v3                       => 'CSAF::Type::CVSS3',
    cwe                           => 'CSAF::Type::CWE',
    distribution                  => 'CSAF::Type::Distribution',
    document                      => 'CSAF::Type::Document',
    engine                        => 'CSAF::Type::Engine',
    file_hash                     => 'CSAF::Type::FileHash',
    file_hashes                   => 'CSAF::Type::FileHashes',
    flag                          => 'CSAF::Type::Flag',
    flags                         => 'CSAF::Type::Flags',
    full_product_name             => 'CSAF::Type::FullProductName',
    full_product_names            => 'CSAF::Type::FullProductNames',
    generator                     => 'CSAF::Type::Generator',
    generic_uri                   => 'CSAF::Type::GenericURI',
    generic_uris                  => 'CSAF::Type::GenericURIs',
    hash                          => 'CSAF::Type::Hash',
    hashes                        => 'CSAF::Type::Hashes',
    id                            => 'CSAF::Type::ID',
    ids                           => 'CSAF::Type::IDs',
    note                          => 'CSAF::Type::Note',
    notes                         => 'CSAF::Type::Notes',
    product                       => 'CSAF::Type::Product',
    product_group                 => 'CSAF::Type::ProductGroup',
    product_groups                => 'CSAF::Type::ProductGroups',
    product_identification_helper => 'CSAF::Type::ProductIdentificationHelper',
    product_status                => 'CSAF::Type::ProductStatus',
    product_tree                  => 'CSAF::Type::ProductTree',
    publisher                     => 'CSAF::Type::Publisher',
    reference                     => 'CSAF::Type::Reference',
    references                    => 'CSAF::Type::References',
    relationship                  => 'CSAF::Type::Relationship',
    relationships                 => 'CSAF::Type::Relationships',
    remediation                   => 'CSAF::Type::Remediation',
    remediations                  => 'CSAF::Type::Remediations',
    restart_required              => 'CSAF::Type::RestartRequired',
    revision                      => 'CSAF::Type::Revision',
    revision_history              => 'CSAF::Type::RevisionHistory',
    score                         => 'CSAF::Type::Score',
    scores                        => 'CSAF::Type::Scores',
    threat                        => 'CSAF::Type::Threat',
    threats                       => 'CSAF::Type::Threats',
    tlp                           => 'CSAF::Type::TLP',
    tracking                      => 'CSAF::Type::Tracking',
    vulnerabilities               => 'CSAF::Type::Vulnerabilities',
    vulnerability                 => 'CSAF::Type::Vulnerability',
};


sub new {

    my ($self, %params) = @_;

    my $name  = delete $params{name};
    my $value = delete $params{value};

    return _build(lc $name, $value);

}

sub name {
    my ($self, $name, $value) = @_;
    return _build(lc $name, $value);
}

sub _build {

    my ($name, $value) = @_;

    my $class = TYPE_CLASSES->{$name} or Carp::croak 'Unknown CSAF type';

    if ($class->can('new') or eval "require $class; 1") {
        local $Carp::Internal{caller()} = 1;
        return $class->new($value);
    }

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Type - Wrapper for all CSAF document types

=head1 SYNOPSIS

    use CSAF::Type;

    CSAF::Type->name(
        reference => {
            url      => 'https://www.cve.org/CVERecord?id=CVE-2022-43634',
            summary  => 'CVE-2022-43634',
            category => 'external'
        }
    );


    CSAF::Type->new(
        name  => 'reference',
        value => {
            url      => 'https://www.cve.org/CVERecord?id=CVE-2022-43634',
            summary  => 'CVE-2022-43634',
            category => 'external'
        }
    );



=head1 DESCRIPTION



=head2 METHODS

=over

=item new ( name => $name, value => $value )

Load and return the B<CSAF::Type::*> class provided in B<name>.

    CSAF::Type->new(
        name  => 'reference',
        value => {
            url      => 'https://www.cve.org/CVERecord?id=CVE-2022-43634',
            summary  => 'CVE-2022-43634',
            category => 'external'
        }
    );

=item name ( $type => $value )

Load and return the B<CSAF::Type::*> class.

    CSAF::Type->name(
        reference => {
            url      => 'https://www.cve.org/CVERecord?id=CVE-2022-43634',
            summary  => 'CVE-2022-43634',
            category => 'external'
        }
    );


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
