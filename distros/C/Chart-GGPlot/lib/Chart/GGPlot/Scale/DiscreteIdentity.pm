package Chart::GGPlot::Scale::DiscreteIdentity;

# ABSTRACT: Discrete identity scale

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;

our $VERSION = '0.0003'; # VERSION

use Chart::GGPlot::Util qw(:all);

extends qw(
  Chart::GGPlot::Scale::Discrete
);

method map_to_limits ( $p, $limits = $self->get_limits ) {
    if ($p->$_DOES('PDL::Factor')) {
        return $p->as_pdlsv;
    } else {
        return $p;
    }
}

method train ($p) {
    return if $self->guide eq 'none';
    $self->SUPER::train($p);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Scale::DiscreteIdentity - Discrete identity scale

=head1 VERSION

version 0.0003

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
