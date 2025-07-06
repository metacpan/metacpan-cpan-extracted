package CSAF::Type::Branch;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;
use CSAF::Type::Branches;
use CSAF::Type::Product;

extends 'CSAF::Type::Base';

has category => (is => 'rw', required => 1);
has name => (is => 'rw', required => 1, coerce => sub { ref($_[0]) eq 'URI::VersionRange' ? $_[0]->to_string : $_[0] });
has product => (is => 'rw', predicate => 1, coerce => sub { CSAF::Type::Product->new(shift) });


sub branches {
    my $self = shift;
    $self->{branches} ||= CSAF::Type::Branches->new(@_);
}

sub TO_CSAF {

    my $self = shift;

    my $output = {category => $self->category, name => $self->name};

    if (@{$self->branches->items}) {
        $output->{branches} = $self->branches;
    }

    $output->{product} = $self->product if ($self->product);

    return $output;

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Type::Branch

=head1 SYNOPSIS

    use CSAF::Type::Branch;
    my $type = CSAF::Type::Branch->new( );


=head1 DESCRIPTION



=head2 METHODS

L<CSAF::Type::Branch> inherits all methods from L<CSAF::Type::Base> and implements the following new ones.

=over

=item $type->branches

=item $type->category

=item $type->has_product

=item $type->name

=item $type->product

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
