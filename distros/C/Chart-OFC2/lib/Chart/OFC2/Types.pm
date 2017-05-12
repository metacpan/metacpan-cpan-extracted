package Chart::OFC2::Types;

use strict;
use warnings;

use MooseX::Types
    -declare => [qw(
        PositiveInt
        ChartOFC2Labels
    )];

use Chart::OFC2::Labels;
use MooseX::Types::Moose qw( Int HashRef ArrayRef );

subtype PositiveInt,
    as Int,
    where { $_ > 0 };

class_type ChartOFC2Labels, { class => 'Chart::OFC2::Labels' };

coerce ChartOFC2Labels,
    from HashRef,
    via { Chart::OFC2::Labels->new($_) };
coerce ChartOFC2Labels,
    from ArrayRef,
    via { Chart::OFC2::Labels->new({'labels' => $_}) };

1;

=head1 NAME

Chart::OFC2::Types - constrainted types and coercions for Chart::OFC2

=head1 SYNOPSIS

package Chart::OFC2::Demo;

use Moose;
use Chart::OFC2::Types qw( PositiveInt ChartOFC2Labels );

has 'attribute1' => ( is => 'rw', isa => PositiveInt, );
has 'attribute2' => ( is => 'rw', isa => ChartOFC2Labels, coerce => 1 );

1;

use Chart::OFC2::Demo;
my $demo = Chart::OFC2::Demo->new({
    attribute1 => 4,
    attribute2 => {
        labels => [ "Jan", "Feb", "Mar", "Apr", "May" ]
    }
});

=head1 TYPES

=over 4

=item PositiveInt

An integer greater than 0

=item ChartOFC2Labels

subtype of Chart::OFC2::Labels

Coerces from HashRef via L<Chart::OFC2::Labels/new>

=back

=head1 AUTHOR

Jeff Tam

=cut
