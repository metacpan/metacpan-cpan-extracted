package CSAF::Type::FullProductName;

use 5.010001;
use strict;
use warnings;
use utf8;

use CSAF::Type::ProductIdentificationHelper;

use Moo;
extends 'CSAF::Type::Base';

has name                          => (is => 'rw', required => 1);
has product_id                    => (is => 'rw', required => 1, trigger => 1);
has product_identification_helper => (is => 'rw', trigger  => 1);

sub _trigger_product_id {
    $CSAF::CACHE->{products}->{$_[0]->product_id} = $_[0]->name;
}

sub _trigger_product_identification_helper {
    my ($self) = @_;
    $self->{product_identification_helper}
        = CSAF::Type::ProductIdentificationHelper->new($self->product_identification_helper);
}

sub TO_CSAF {

    my $self = shift;

    my $output = {name => $self->name, product_id => $self->product_id};

    if (my $product_identification_helper = $self->{product_identification_helper}) {
        $output->{product_identification_helper} = $product_identification_helper;
    }

    return $output;

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Type::FullProductName

=head1 SYNOPSIS

    use CSAF::Type::FullProductName;
    my $type = CSAF::Type::FullProductName->new( );


=head1 DESCRIPTION



=head2 METHODS

L<CSAF::Type::FullProductName> inherits all methods from L<CSAF::Type::Base> and implements the following new ones.

=over

=item $type->has_product_identification_helper

=item $type->name

=item $type->product_id

=item $type->product_identification_helper

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
