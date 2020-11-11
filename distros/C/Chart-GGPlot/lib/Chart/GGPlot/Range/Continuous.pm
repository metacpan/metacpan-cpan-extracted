package Chart::GGPlot::Range::Continuous;

# ABSTRACT: Continuous range

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;

our $VERSION = '0.0011'; # VERSION

with qw(Chart::GGPlot::Range);

use Types::PDL -types;

use Chart::GGPlot::Util qw(is_discrete range_);

method train ($p) {
    return $self->range if $p->isnull;

    if (is_discrete($p)) {
        die("Discrete value supplied to continuous scale");
    }
    my $range = range_( $self->range->glue(0, $p) );
    $self->range($range);

    return $self->range;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Range::Continuous - Continuous range

=head1 VERSION

version 0.0011

=head1 SEE ALSO

L<Chart::GGPlot::Range>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2020 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
