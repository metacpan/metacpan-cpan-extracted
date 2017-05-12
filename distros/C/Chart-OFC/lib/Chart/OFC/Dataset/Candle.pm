package Chart::OFC::Dataset::Candle;
$Chart::OFC::Dataset::Candle::VERSION = '0.12';
use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use Chart::OFC::Types;

extends 'Chart::OFC::Dataset::HighLowClose';

sub type
{
    return 'candle';
}

no Moose;

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A dataset represented as a candle for each value

__END__

=pod

=head1 NAME

Chart::OFC::Dataset::Candle - A dataset represented as a candle for each value

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    my @numbers = ( [ 1, 2, 3 ], [ 3, 2, 1 ] );
    my $candle = Chart::OFC::Dataset::Candle->new(
        values    => \@numbers,
        width     => 5,
        color     => 'purple',
        label     => 'Daily Sales in $',
        text_size => 12,
        opacity   => 80,
    );

=head1 DESCRIPTION

This class contains values to be charted as candle points on a grid chart.

=for Pod::Coverage type

=head1 ATTRIBUTES

This class has several attributes which may be passed to the C<new()>
method.

It is a subclass of C<Chart::OFC::Dataset::HighLowClose> and accepts all of
that class's attributes. It has no attributes of its own.

=head1 ROLES

This class does the C<Chart::OFC::Role::OFCDataLines> role.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
