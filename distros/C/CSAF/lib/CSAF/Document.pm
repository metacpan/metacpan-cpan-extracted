package CSAF::Document;

use 5.010001;
use strict;
use warnings;
use utf8;

use CSAF::Type::Document;
use CSAF::Type::ProductTree;
use CSAF::Type::Vulnerabilities;

use Moo;
extends 'CSAF::Type::Base';

sub document {
    my ($self, %params) = @_;
    $self->{document} ||= CSAF::Type::Document->new(%params);
}

sub product_tree {
    my ($self, %params) = @_;
    $self->{product_tree} ||= CSAF::Type::ProductTree->new(%params);
}

sub vulnerabilities {
    my ($self, %params) = @_;
    $self->{vulnerabilities} ||= CSAF::Type::Vulnerabilities->new(%params);
}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Document - CSAF Document

=head1 SYNOPSIS

    use CSAF::Document;

    my $csaf = CSAF::Document->new;

    $csaf->document->title('Base CSAF Document');
    $csaf->document->category('csaf_security_advisory');
    $csaf->document->publisher(
        category  => 'vendor',
        name      => 'CSAF',
        namespace => 'https://csaf.io'
    );

    my $tracking = $csaf->document->tracking(
        id                   => 'CSAF:2024-001',
        status               => 'final',
        version              => '1.0.0',
        initial_release_date => 'now',
        current_release_date => 'now'
    );

    $tracking->revision_history->add(
        date    => 'now',
        summary => 'First release',
        number  => '1'
    );


=head1 DESCRIPTION

The Common Security Advisory Framework (CSAF) Version 2.0 is the definitive 
reference for the language which supports creation, update, and interoperable 
exchange of security advisories as structured information on products, 
vulnerabilities and the status of impact and remediation among interested 
parties.

L<https://docs.oasis-open.org/csaf/csaf/v2.0/os/csaf-v2.0-os.html>


=head2 CSAF PROPERTIES

=over

=item document

Return L<CSAF::Type::Document>.

=item product_tree

Return L<CSAF::Type::ProductTree>.

=item vulnerabilities

Return L<CSAF::Type::Vulnerabilities>.

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
