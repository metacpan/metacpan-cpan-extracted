package Chart::GGPlot::Class;

# ABSTRACT: For creating classes in Chart::GGPlot

use strict;
use warnings;

our $VERSION = '0.002002'; # VERSION

use Chart::GGPlot::Setup ();

sub import {
    my ( $class, @tags ) = @_;
    Chart::GGPlot::Setup->_import( scalar(caller), qw(:class), @tags );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Class - For creating classes in Chart::GGPlot

=head1 VERSION

version 0.002002

=head1 SYNOPSIS

    use Chart::GGPlot::Class;

=head1 DESCRIPTION

C<use Chart::GGPlot::Class ...;> is equivalent of 

    use Chart::GGPlot::Setup qw(:class), ...;

=head1 SEE ALSO

L<Chart::GGPlot::Setup>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
