package Chart::Clicker::Positioned;
$Chart::Clicker::Positioned::VERSION = '2.90';
use Moose::Role;

# ABSTRACT: Role for components that care about position.

use Moose::Util::TypeConstraints;

enum 'Chart::Clicker::Position' => [qw(left right top bottom)];


has 'position' => (
    is => 'rw',
    isa => 'Chart::Clicker::Position'
);


sub is_left {
    my ($self) = @_;

    return $self->position eq 'left';
}


sub is_right {
    my ($self) = @_;

    return $self->position eq 'right';
}


sub is_top {
    my ($self) = @_;

    return $self->position eq 'top';
}


sub is_bottom {
    my ($self) = @_;

    return $self->position eq 'bottom';
}

no Moose;
1;

__END__

=pod

=head1 NAME

Chart::Clicker::Positioned - Role for components that care about position.

=head1 VERSION

version 2.90

=head1 SYNOPSIS

    package My::Component;
    use Moose;

    extends 'Chart::Clicker::Drawing::Component';

    with 'Chart::Clicker::Positioned';

    1;

=head1 DESCRIPTION

Some components draw differently depending on which 'side' they are
positioned.  If an Axis is on the left, it will put the numbers left and the
bar on the right.  If positioned on the other side then those two piece are
reversed.

=head1 ATTRIBUTES

=head2 position

The 'side' on which this component is positioned.

=head1 METHODS

=head2 is_left

Returns true if the component is positioned left.

=head2 is_right

Returns true if the component is positioned right.

=head2 is_top

Returns true if the component is positioned top.

=head2 is_bottom

Returns true if the component is positioned bottom.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Cory G Watson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
