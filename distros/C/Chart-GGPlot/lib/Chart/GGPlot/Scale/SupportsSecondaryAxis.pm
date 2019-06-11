package Chart::GGPlot::Scale::SupportsSecondaryAxis;

# ABSTRACT: Role for scales that support secondary axis

use Chart::GGPlot::Role;
use namespace::autoclean;

our $VERSION = '0.0005'; # VERSION

use Types::Standard qw(InstanceOf Maybe);

has secondary_axis => (
    is      => 'ro',
    isa     => Maybe [ InstanceOf ['Chart::GGPlot::AxisSecondary'] ],
);

method sec_name () {
    return $self->secondary_axis->$_call_if_can('name');
}

method make_sec_title ($title) {
    if ( defined $self->secondary_axis ) {
        return $self->secondary_axis->make_title($title);
    } else {
        return $self->SUPER::make_sec_title($title);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Scale::SupportsSecondaryAxis - Role for scales that support secondary axis

=head1 VERSION

version 0.0005

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
