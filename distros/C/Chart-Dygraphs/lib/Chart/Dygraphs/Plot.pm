package Chart::Dygraphs::Plot;

use strict;
use warnings;
use utf8;

use Moose;

our $VERSION = '0.007';    # VERSION

# ABSTRACT: Collection of series plotted in the same plot

has 'options' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        return { showRangeSelector => 1 };
    }
);

has 'data' => ( is      => 'rw',
                isa     => 'ArrayRef',
                default => sub { [ [ 1, 1 ], [ 2, 4 ], [ 3, 9 ], [ 4, 16 ] ] }
);

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Dygraphs::Plot - Collection of series plotted in the same plot

=head1 VERSION

version 0.007

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Pablo Rodríguez González.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
