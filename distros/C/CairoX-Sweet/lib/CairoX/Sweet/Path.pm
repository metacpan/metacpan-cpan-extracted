use 5.10.0;
use strict;
use warnings;

package CairoX::Sweet::Path;

# ABSTRACT: Handles a path
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0200';

use CairoX::Sweet::Elk;
use Type::Utils qw/enum/;
use CairoX::Sweet::Core::LineTo;
use Types::CairoX::Sweet -types;
use Types::Standard qw/Maybe Num ArrayRef/;

has move => (
    is => 'rw',
    isa => Maybe[MoveTo],
    predicate => 1,
    coerce => 1,
);
has start => (
    is => 'rw',
    isa => Maybe[MoveTo],
    predicate => 1,
    coerce => 1,
);
has color => (
    is => 'rw',
    isa => Maybe[Color],
    coerce => 1,
    predicate => 1,
);
has background_color => (
    is => 'rw',
    isa => Maybe[Color],
    coerce => 1,
    predicate => 1,
);
has width => (
    is => 'rw',
    isa => Maybe[Num],
    predicate => 1,
);
has cap => (
    is => 'rw',
    isa => enum([qw/butt round square/]),
    default => 'butt',
);
has join => (
    is => 'rw',
    isa => enum([qw/miter round bevel/]),
    default => 'miter',
);
has commands => (
    is => 'rw',
    isa => ArrayRef,
    traits => ['Array'],
    handles => {
        add_command => 'push',
        all_commands => 'elements',
        get_command => 'get',
        count_commands => 'count',
    },
);
around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    if(exists $args{'start'}) {
        $args{'start'} = CairoX::Sweet::Core::MoveTo->new(@{ $args{'start'} }, is_relative => 0);
    }
    elsif(exists $args{'move'}) {
        $args{'move'} = CairoX::Sweet::Core::MoveTo->new(@{ $args{'move'} }, is_relative => 1);
    }
    $self->$orig(%args);
};
sub BUILD {
    my $self = shift;

    if($self->has_start) {
        $self->add_command($self->start);
    }
    elsif($self->has_move) {
        $self->add_command($self->move);
    }
}
around qw/color background_color/ => sub {
    my $orig = shift;
    my $self = shift;

    if(scalar @_ == 3) {
        $self->$orig(\@_);
    }
    else {
        $self->$orig(@_);
    }
};
sub purge {
    my $self = shift;
    $self->commands([]);
}

sub _add_move {
    my $self = shift;
    my $is_relative = shift;
    my @values = @_;

    while(scalar @values >= 2) {
        $self->add_command(CairoX::Sweet::Core::MoveTo->new(splice(@values, 0, 2), is_relative => $is_relative));
    }
    return $self;
}
sub add_start {
    my $self = shift;
    return $self->_add_move(0, @_);
}
sub add_move {
    my $self = shift;
    return $self->_add_move(1, @_);
}

sub _add_line_helper {
    my $self = shift;
    my $is_relative = shift;

    while(scalar @_ >= 2) {
        $self->add_command(CairoX::Sweet::Core::LineTo->new(splice(@_, 0, 2), is_relative => $is_relative));
    }
    return $self;
}
sub add_line {
    my $self = shift;
    return $self->_add_line_helper(0, @_);
}
sub add_relative_line {
    my $self = shift;
    return $self->_add_line_helper(1, @_);
}

sub add_curve {
    my $self = shift;

    while(scalar @_ >= 6) {
        $self->add_command(CairoX::Sweet::Core::CurveTo->new(splice(@_, 0,6), is_relative => 0));
    }
    return $self;
}
sub add_relative_curve {
    my $self = shift;

    while(scalar @_ >= 6) {
        $self->add_command(CairoX::Sweet::Core::CurveTo->new(splice(@_, 0, 6), is_relative => 1));
    }
    return $self;
}

sub move_path {
    my $self = shift;
    my %params = @_;
    my $x = $params{'x'} || 0;
    my $y = $params{'y'} || 0;

    foreach my $command ($self->all_commands) {
        $command->move_location(x => $x, y => $y);
    }
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

CairoX::Sweet::Path - Handles a path

=head1 VERSION

Version 0.0200, released 2016-08-22.

=head1 SYNOPSIS

    use CairoX::Sweet;

    my $c = CairoX::Sweet->new(500, 500, '#ffffff');
    my $path = CairoX::Sweet::Path->new(start => [35, 50], color => '#8855bb', width => 10, cap => 'round', join => 'round');

    $path->add_relative_line(qw/
        20 -5
        10 0
        30 -20
        -50 0
    /);
    $c->add_path($path, close => 1);

=head1 ATTRIBUTES

=head2 move => [x, y]

Array reference of two numbers. Optional, can't be used together with C<start>.

Sets the starting position of the path to C<x> and C<y> points from the current position.

    $path = CairoX::Sweet::Path->new(move => [35, 50], ...);

=head2 start = [x, y]

Array reference of two numbers. Optional, can't be used together with C<move>.

Sets the starting position of the path to C<x> and C<y> points from the [0, 0] point.

    $path = CairoX::Sweet::Path->new(start => [135, 150], ...);

=head2 color => Color

A color. Optional. See L<CairoX::Sweet::background_color|CairoX::Sweet/"background_color"> for more information on colors.

Sets the pen color. B<stroke> will always be called on the path, if C<color> isn't set then the current color is used.

    $path = CairoX::Sweet::Path->new(color => '#8855bb', ...);

=head2 background_color => Color

A color. Optional. See L<CairoX::Sweet::background_color|CairoX::Sweet/"background_color"> for more information on colors.

Sets the background color. If C<background_color> is given, B<fill> will be called on the path.

    $path = CairoX::Sweet::Path->new(background_color => [240, 245, 240], ...);

=head2 width => x

A number. Optional. Sets the pen width.

    $path = CairoX::Sweet::Path->new(width => 10, ...);

=head2 cap => cap_type

One of C<butt>, C<round> or C<square>.

=head2 join => join_type

One of C<miter>, C<round> or C<bevel>.

=head1 METHODS

=head2 add_line(x1, y1, x2, y2, ...)

The argument must be a list with an even number of items. The positions are absolute. Uses B<line_to> in L<Cairo>.

    $path->add_line(qw/
        20 30
        30 40
        30 80
        40 80
    /);

Note that the line starts at the current position, usually set by C<move> or C<start> in the constructor.

Pushes a line onto the path. Note that any number of calls to the add_*_line, add_*_curve, add_start and add_move can be made. They will be combined into one path in the end.

=head2 add_relative_line(x1, y1, x2, y2, ...)

The argument must be a list a number of items. Similar to C<add_line()> except that the positions are relative to the previous current position. Uses B<line_rel_to> in L<Cairo>.

=head2 add_curve(bezier_1ax, bezier_1ay, bezier_1bx, bezier_1by, x1, y1, ...)

The argument must be a list a number of items divisible by six. The positions are absolute. Uses B<curve_to> in L<Cairo>.

    $path->add_curve(qw/
        441 157  461 149  457 135
        454 119  434 113  421 109
        422 105  423 101  424  97
        424  87  416  83  408  84
    /);

=head2 add_relative_curve(bezier_1ax, bezier_1ay, bezier_1bx, bezier_1by, x1, y1, ...)

The argument must be a list a number of items divisible by six. Similar to C<add_curve()> except that the positions are relative to the previous current position. Uses B<curve_rel_to> in L<Cairo>.

=head2 add_move(x, y)

Moves the current position C<x>/C<y> points from the current position.

=head2 add_start(x, y)

Moves the current position to C<x>/C<y> from the 0/0 point.

=head2 move_path(x => 30, y => 30)

Moves all points in the path C<x> and C<y> points from their current positions. This means you can do this:

    my $c = CairoX::Sweet->new(220, 130, background_color => '#ffffff');
    my $path = CairoX::Sweet::Path->new(start => [25, 50], color => '#8855bb', width => 10, join => 'miter');

    $path->add_line(qw/
         45 95
         55 95
    /);
    $path->add_curve(qw/
         70 110   90 90  100 100
        110  90  110 90  120  90
        130  80  130 80  140 105
        155 120  170 80  185  75
    /);
    $path->add_line(qw/
        185 45
        150 10
        135 20
    /);
    $c->add_path($path, close => 1);

    $path->color('#bb99cc');
    $path->join('round');
    $path->cap('round');
    $path->move_path(x => 12, y => 12);
    $c->add_path($path);

    $c->surface->write_to_png('image.png');

Which produces:

=for HTML <p><img src="https://raw.githubusercontent.com/Csson/p5-CairoX-Sweet/master/static/images/move_path.png" /></p>

=head2 purge()

Empties lines and curves.

=head1 SEE ALSO

=over 4

=item *

L<CairoX::Sweet::Path>

=item *

L<Cairo>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-CairoX-Sweet>

=head1 HOMEPAGE

L<https://metacpan.org/release/CairoX-Sweet>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
