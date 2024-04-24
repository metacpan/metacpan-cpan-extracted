package CSAF::Type::Relationship;

use 5.010001;
use strict;
use warnings;
use utf8;

use CSAF::Type::FullProductName;

use Moo;
extends 'CSAF::Type::Base';

has category                     => (is => 'rw', required => 1);
has product_reference            => (is => 'rw', required => 1);
has relates_to_product_reference => (is => 'rw', required => 1);

has full_product_name => (
    is     => 'rw',
    coerce => sub {
        (ref($_[0]) !~ /FullProductName/) ? CSAF::Type::FullProductName->new(shift) : $_[0];
    }
);

sub TO_CSAF {

    my $self = shift;

    my $output = {
        category                     => $self->category,
        full_product_name            => $self->full_product_name,
        product_reference            => $self->product_reference,
        relates_to_product_reference => $self->relates_to_product_reference,
    };

    return $output;

}


1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Type::Relationship

=head1 SYNOPSIS

    use CSAF::Type::Relationship;
    my $type = CSAF::Type::Relationship->new( );


=head1 DESCRIPTION



=head2 METHODS

L<CSAF::Type::Relationship> inherits all methods from L<CSAF::Type::Base> and implements the following new ones.

=over

=item $type->category

=item $type->full_product_name

=item $type->has_full_product_name

=item $type->product_reference

=item $type->relates_to_product_reference

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
