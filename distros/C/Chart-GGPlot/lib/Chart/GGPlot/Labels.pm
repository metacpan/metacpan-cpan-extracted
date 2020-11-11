package Chart::GGPlot::Labels;

# ABSTRACT: Axis, legend, and plot labels

use Chart::GGPlot::Setup;
use namespace::autoclean;

our $VERSION = '0.0011'; # VERSION

use parent qw(Chart::GGPlot::Aes);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Labels - Axis, legend, and plot labels

=head1 VERSION

version 0.0011

=head1 DESCRIPTION

This class inherits L<Chart::GGPlot::Aes>.
Now it actually does nothing more than its parent class, but is just for
having its own type which is used by L<Chart::GGPlot::Plot>. 

=head1 SEE ALSO

L<Chart::GGPlot::Labels::Functions>, L<Chart::GGPlot::Aes>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2020 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
