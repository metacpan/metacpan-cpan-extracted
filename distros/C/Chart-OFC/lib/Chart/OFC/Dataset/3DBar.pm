# critic is on drugs, I guess
package Chart::OFC::Dataset::3DBar; ## no critic RequireFilenameMatchesPackage
$Chart::OFC::Dataset::3DBar::VERSION = '0.12';
use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use Chart::OFC::Types;

extends 'Chart::OFC::Dataset::Bar';

sub type
{
    return 'bar_3d';
}

no Moose;

__PACKAGE__->meta()->make_immutable();

1;


# ABSTRACT: A dataset represented as 3D bars

__END__

=pod

=head1 NAME

Chart::OFC::Dataset::3DBar - A dataset represented as 3D bars

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    my @numbers = (1, 2, 3);
    my $bars    = Chart::OFC::Dataset::3DBar->new(
        values     => \@numbers,
        opacity    => 60,
        fill_color => 'purple',
        label      => 'Daily Sales in $',
        text_size  => 12,
    );

=head1 DESCRIPTION

This class contains values to be charted as bars on a grid chart. The
bars are filled with the specified color and have a 3D look.

=for Pod::Coverage type

=head1 ATTRIBUTES

This class is a subclass of C<Chart::OFC::Dataset::Bar> and accepts
all of that class's attributes. It has no attributes of its own.

=head1 ROLES

This class does the C<Chart::OFC::Role::OFCDataLines> role.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
