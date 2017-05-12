use 5.10.0;
use strict;
use warnings;

package CairoX::Sweet::Core::LineTo;

# ABSTRACT: Draw a line_to
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0200';

use CairoX::Sweet::Elk;
use CairoX::Sweet::Core::Point;
use Types::CairoX::Sweet -types;
use Types::Standard qw/Bool/;

with 'CairoX::Sweet::Role::PathCommand';

has point => (
    is => 'ro',
    isa => Point,
    required => 1,
);
has is_relative => (
    is => 'ro',
    isa => Bool,
    required => 1,
);

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my $x = shift;
    my $y = shift;

    my %options = @_;
    my $is_relative = $options{'is_relative'} || 0;

    my $point = CairoX::Sweet::Core::Point->new(x => $x, y => $y);
    $self->$orig(is_relative => $is_relative, point => $point);
};
sub out {
    my $self = shift;
    return $self->point->out;
}
sub method {
    my $self = shift;
    return $self->is_relative ? 'rel_line_to' : 'line_to';
}
sub location {
    my $self = shift;
    return $self->point;
}
sub move_location {
    my $self = shift;
    my %params = @_;
    my $x = $params{'x'} || 0;
    my $y = $params{'y'} || 0;
    $self->point->move(x => $x, y => $y);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CairoX::Sweet::Core::LineTo - Draw a line_to

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
