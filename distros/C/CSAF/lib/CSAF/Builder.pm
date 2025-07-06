package CSAF::Builder;

use 5.010001;
use strict;
use warnings;
use utf8;

use Carp;
use CSAF::Validator;

use Moo;
extends 'CSAF::Base';

sub build {

    my ($self, $skip_validation) = @_;

    my $document        = $self->csaf->document->TO_CSAF;
    my $vulnerabilities = $self->csaf->vulnerabilities->TO_CSAF;
    my $product_tree    = $self->csaf->product_tree->TO_CSAF;

    my $csaf = {document => $document};

    if (@{$vulnerabilities}) {
        $csaf->{vulnerabilities} = $vulnerabilities;
    }

    if ($product_tree) {
        $csaf->{product_tree} = $product_tree;
    }

    unless ($skip_validation) {
        $self->csaf->validator->validate;
    }

    return $csaf;

}

sub TO_JSON { shift->build }

1;


__END__

=encoding utf-8

=head1 NAME

CSAF::Builder - Build the CSAF document

=head1 SYNOPSIS

    use CSAF::Builder;
    my $builder = CSAF::Builder->new( csaf => $csaf );

    my $html = $renderer->render;


=head1 DESCRIPTION

L<CSAF::Builder> build and validate the CSAF document and prepare it for publishing.

=head2 METHODS

L<CSAF::Builder> inherits all methods from L<CSAF::Base> and implements the following new ones.

=over

=item $builder->build ( [$skip_validation = 0] )

Build the CSAF document.

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
