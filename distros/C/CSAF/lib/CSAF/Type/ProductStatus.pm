package CSAF::Type::ProductStatus;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;
use Carp;

extends 'CSAF::Type::Base';

my @ATTRIBUTES = qw(
    first_affected first_fixed fixed known_affected known_not_affected
    last_affected recommended under_investigation
);

has [@ATTRIBUTES] => (
    is  => 'rw',
    isa => sub {
        Carp::croak 'must be an array of products' if (ref $_[0] ne 'ARRAY');
    },
    default => sub { [] }
);

sub TO_CSAF {

    my $self = shift;

    my $output = {};

    for my $attribute (@ATTRIBUTES) {
        $output->{$attribute} = $self->$attribute if (@{$self->$attribute});
    }

    return if (!keys %{$output});

    return $output;

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Type::ProductStatus

=head1 SYNOPSIS

    use CSAF::Type::ProductStatus;
    my $type = CSAF::Type::ProductStatus->new( );


=head1 DESCRIPTION



=head2 METHODS

L<CSAF::Type::ProductStatus> inherits all methods from L<CSAF::Type::Base> and implements the following new ones.

=over

=item $type->first_affected

=item $type->first_fixed

=item $type->fixed

=item $type->known_affected

=item $type->known_not_affected

=item $type->last_affected

=item $type->recommended

=item $type->under_investigation

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
