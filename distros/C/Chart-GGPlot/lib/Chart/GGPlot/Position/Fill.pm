package Chart::GGPlot::Position::Fill;

# ABSTRACT: Position for "fill"

use Chart::GGPlot::Class;
use namespace::autoclean;

our $VERSION = '0.002000'; # VERSION

extends qw(Chart::GGPlot::Position::Stack);

sub fill { true }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Position::Fill - Position for "fill"

=head1 VERSION

version 0.002000

=head1 DESCRIPTION

This class inherits L<Chart::GGPlot::Position::Stack>. Compared to "stack",
this class standardises each stack to have constant height.

=head1 SEE ALSO

L<Chart::GGPlot::Position>,
L<Chart::GGPlot::Position::Stack>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2021 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
