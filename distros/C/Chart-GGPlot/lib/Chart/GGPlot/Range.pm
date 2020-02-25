package Chart::GGPlot::Range;

# ABSTRACT: The role for range

use Chart::GGPlot::Role qw(:pdl);
use namespace::autoclean;

our $VERSION = '0.0009'; # VERSION

use Types::PDL qw(Piddle PiddleFromAny);

use Chart::GGPlot::Types qw(:all);


has range => (
    is      => 'rw',
    isa     => Piddle->plus_coercions(PiddleFromAny),
    coerce  => 1,
    builder => '_build_range'
);

sub _build_range { null; }


method reset () {
    $self->range( $self->_build_range );
}


requires 'train';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Range - The role for range

=head1 VERSION

version 0.0009

=head1 DESCRIPTION

Mutable ranges have two methods (C<train> and C<reset>), and make
it possible to build up complete ranges with multiple passes.

=head1 ATTRIBUTES

=head2 range

For continuous range it has two elements to indicate the start
and end of the range. For discrete range the arrayref contains
the discrete items of the range.

=head1 METHODS

=head2 reset()

Resets the range.

=head2 train($piddle)

Train the range according to given data.

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
