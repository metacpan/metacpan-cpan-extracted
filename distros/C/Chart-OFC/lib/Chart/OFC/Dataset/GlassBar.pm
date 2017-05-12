package Chart::OFC::Dataset::GlassBar;
$Chart::OFC::Dataset::GlassBar::VERSION = '0.12';
use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use Chart::OFC::Types;

extends 'Chart::OFC::Dataset::OutlinedBar';

sub type
{
    return 'bar_glass';
}

no Moose;

__PACKAGE__->meta()->make_immutable();

1;


=pod

=for Pod::Coverage type

=head1 SYNOPSIS

    my @numbers = (1, 2, 3);
    my $bars    = Chart::OFC::Dataset::GlassBar->new(
        values     => \@numbers,
        opacity    => 60,
        fill_color => 'purple',
        label      => 'Daily Sales in $',
        text_size  => 12,
    );

=head1 DESCRIPTION

This class contains values to be charted as bars on a grid chart. The
bars are filled with the specified color and have a separate outline
color.

=head1 ATTRIBUTES

This class is a subclass of C<Chart::OFC::Dataset::OutlinedBar> and accepts
all of that class's attributes. It has no attributes of its own.

=head1 ROLES

This class does the C<Chart::OFC::Role::OFCDataLines> role.

=cut
