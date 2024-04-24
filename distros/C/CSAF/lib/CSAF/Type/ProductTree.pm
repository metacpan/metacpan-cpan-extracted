package CSAF::Type::ProductTree;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;
extends 'CSAF::Type::Base';

use CSAF::Type::Branches;
use CSAF::Type::FullProductNames;
use CSAF::Type::ProductGroups;
use CSAF::Type::Relationships;


sub branches {
    my ($self, %params) = @_;
    $self->{branches} ||= CSAF::Type::Branches->new(%params);
}

sub full_product_names {
    my ($self, %params) = @_;
    $self->{full_product_names} ||= CSAF::Type::FullProductNames->new(%params);
}

sub product_groups {
    my ($self, %params) = @_;
    $self->{product_groups} ||= CSAF::Type::ProductGroups->new(%params);
}

sub relationships {
    my ($self, %params) = @_;
    $self->{relationships} ||= CSAF::Type::Relationships->new(%params);
}

sub TO_CSAF {

    my $self = shift;

    my $output = {};

    if (@{$self->branches->items}) {
        $output->{branches} = $self->branches->TO_CSAF;
    }

    if (@{$self->relationships->items}) {
        $output->{relationships} = $self->relationships->TO_CSAF;
    }

    if (@{$self->full_product_names->items}) {
        $output->{full_product_names} = $self->full_product_names->TO_CSAF;
    }

    return if not keys %{$output};

    return $output;

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Type::ProductTree

=head1 SYNOPSIS

    use CSAF::Type::ProductTree;
    my $type = CSAF::Type::ProductTree->new( );


=head1 DESCRIPTION



=head2 METHODS

L<CSAF::Type::ProductTree> inherits all methods from L<CSAF::Type::Base> and implements the following new ones.

=over

=item $type->branches

=item $type->full_product_names

=item $type->product_groups

=item $type->relationships

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
