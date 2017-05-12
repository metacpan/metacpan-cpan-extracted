use 5.10.0;
use strict;
use warnings;

# PODCLASSNAME

package CairoX::Sweet::Color;

our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0200';

use CairoX::Sweet::Elk;
use Types::CairoX::Sweet -types;

foreach my $color (qw/red green blue/) {
    has $color => (
        is => 'ro',
        isa => NumUpToOne,
        required => 1,
    );
}
has opacity => (
    is => 'ro',
    default => 1,
    isa => NumUpToOne,
);

sub color {
    my $self = shift;
    return ($self->red, $self->green, $self->blue);
}
sub color_with_opacity {
    my $self = shift;
    return ($self->red, $self->green, $self->blue, $self->opacity);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CairoX::Sweet::Color

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
