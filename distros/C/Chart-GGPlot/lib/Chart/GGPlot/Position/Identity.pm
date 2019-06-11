package Chart::GGPlot::Position::Identity;

# ABSTRACT: Position class that does not adjust position

use Chart::GGPlot::Class;
use namespace::autoclean;

our $VERSION = '0.0005'; # VERSION

with qw(Chart::GGPlot::Position);

method compute_layer($data, $params, $scales) {
    return $data;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Position::Identity - Position class that does not adjust position

=head1 VERSION

version 0.0005

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
