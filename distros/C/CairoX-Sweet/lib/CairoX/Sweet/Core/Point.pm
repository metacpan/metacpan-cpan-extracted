use 5.10.0;
use strict;
use warnings;

package CairoX::Sweet::Core::Point;

# ABSTRACT: Defines a point
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0200';

use CairoX::Sweet::Elk;
use Types::Standard -types;

has x => (
    is => 'rw',
    isa => Num,
    required => 1,
);
has y => (
    is => 'rw',
    isa => Num,
    required => 1,
);

sub out {
    my $self = shift;
    return ($self->x, $self->y);
}
sub move {
    my $self = shift;
    my %params = @_;
    my $x = $params{'x'} || 0;
    my $y = $params{'y'} || 0;
    $self->x($self->x + $x);
    $self->y($self->y + $y);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CairoX::Sweet::Core::Point - Defines a point

=head1 VERSION

Version 0.0200, released 2016-08-22.

=head1 SOURCE

L<https://github.com/Csson/p5-CairoX-Sweet>

=head1 HOMEPAGE

L<https://metacpan.org/release/CairoX-Sweet>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
