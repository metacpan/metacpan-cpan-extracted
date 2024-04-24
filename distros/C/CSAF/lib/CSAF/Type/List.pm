package CSAF::Type::List;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;
use Carp;

extends 'CSAF::Util::List';

has item_class => (is => 'ro', required => 1);

sub each {

    my ($self, $callback) = @_;

    return @{$self->items} unless $callback;

    my $idx = 0;
    $_->$callback($idx++) for @{$self->items};

    return $self;

}

sub item {

    my ($self, %params) = @_;

    my $item_class = $self->item_class;

    if ($item_class->can('new') or eval "require $item_class; 1") {

        my $item = $item_class->new(%params);
        push @{$self->items}, $item;

        return $item;
    }

    Carp::croak "Failed to load item class '$item_class': $@" if ($@);

}

sub TO_JSON { shift->TO_CSAF }

sub TO_CSAF {

    my $self   = shift;
    my $output = [];

    foreach my $item (@{$self->items}) {
        push @{$output}, ((ref($item) =~ /^CSAF::Type/) ? $item->TO_CSAF : $item);
    }

    return $output;

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Type::List

=head1 SYNOPSIS

    use CSAF::Type::List;
    my $type = CSAF::Type::List->new( item_class=> 'CSAF::Type::Vulnerability' );


=head1 DESCRIPTION

L<CSAF::Type::List> is a base collection class.


=head2 METHODS

L<CSAF::Type::List> inherits all methods from L<CSAF::Util::List> and implements the following new ones.

=over

=item $type->item_class

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
