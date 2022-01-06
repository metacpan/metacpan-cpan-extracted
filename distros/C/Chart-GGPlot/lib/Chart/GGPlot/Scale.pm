package Chart::GGPlot::Scale;

# ABSTRACT: The role for scale

use Chart::GGPlot::Role qw(:pdl);
use namespace::autoclean;

our $VERSION = '0.002000'; # VERSION

use PDL::Primitive qw(which);
use Types::PDL qw(Piddle PiddleFromAny);
use Types::Standard qw(Any ArrayRef CodeRef Maybe Str InstanceOf ConsumerOf);
use Type::Params;

use Chart::GGPlot::Trans;
use Chart::GGPlot::Types qw(:all);
use Chart::GGPlot::Util qw(:all);


has aesthetics => (
    is       => 'ro',
    isa      => ArrayRef->plus_coercions(ArrayRefFromAny),
    coerce   => 1,
    required => 1,
);
has scale_name => ( is => 'ro', isa => Str, required => 1 );
has palette => ( is => 'rw', isa => Maybe [CodeRef] );
has range => ( is => 'rw', isa => Piddle, default => sub { null; } );

has limits => (
    is      => 'rw',
    default => sub { null; },
);

has na_value => ( is => 'rw', default => "nan" );
has expand   => ( is => 'rw', default => undef );
has name     => ( is => 'rw', default => undef );
has breaks   => ( is => 'rw', default => undef );
has labels =>
  ( is => 'rw', isa => Maybe [ Piddle | CodeRef ], default => undef );
has guide    => ( is => 'ro', default => "legend" );
has position => ( is => 'rw', isa     => PositionEnum, default => "left" );
has trans    => ( is => 'rw', isa     => InstanceOf ["Chart::GGPlot::Trans"] );

requires 'train';    # Train an individual scale from a vector of data.
requires 'transform';

requires 'get_breaks_minor';
requires 'get_labels';
requires 'break_info';
requires 'dimension';
requires 'get_breaks';

#requires 'clone';


method train_df ($df) {
    return if $df->isempty;

    my $aesthetics = $self->aesthetics->intersect($df->names);
    for my $aesthetic (@$aesthetics) {
        $self->train( $df->at($aesthetic) );
    }
}


method reset () {
    $self->range->reset;
}

method isempty () {
    return ( $self->range->range->isempty and $self->limits->isempty );
}


method transform_df ($df) {
    return if $df->isempty;

    my $aesthetics = $self->aesthetics->intersect( $df->names );
    my @transformed =
      map {
        my $col_raw = $df->at($_);
        (
            $_ => $self->transform($col_raw),
            ( !$df->exists("${_}_raw") ? ( "${_}_raw" => $col_raw ) : () )
        );
      } @$aesthetics;
    return \@transformed;
}


method map_df ( $df, $i = undef ) {
    return if ( $df->isempty );

    my $aesthetics = $self->aesthetics->intersect($df->names);
    return if ( $aesthetics->isempty );

    my @mapped = map {
        my $col_raw = defined $i ? $df->at($_)->select_rows($i) : $df->at($_);
        (
            $_ => $self->map_to_limits($col_raw),
            ( !$df->exists("${_}_raw") ? ( "${_}_raw" => $col_raw ) : () ),
        );
    } ( $aesthetics->flatten );
    return \@mapped;
}

requires 'map_to_limits';

method get_limits () {
    return pdl( [ 0, 1 ] ) if $self->isempty;

    if ( !$self->limits->isempty ) {
        my $limits = $self->limits->copy;
        return ifelse( $limits->isgood, $limits, $self->range->range );
    }
    else {
        return $self->range->range;
    }
}

# Here to make it possible for scales to modify the default titles
method make_title ($title) { $title; }
method make_sec_title ($title) { $title; }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Scale - The role for scale

=head1 VERSION

version 0.002000

=head1 DESCRIPTION

This module is a Moose role for "scale".

For users of Chart::GGPlot you would mostly want to look at
L<Chart::GGPlot::Scale::Functions> instead.

=head1 ATTRIBUTES

=head2 aesthetics

The name of the aesthetics that this scale works with.

=head2 scale_name

The name of the scale.

=head2 palette

A palette function that when called with a single integer
argument (the number of levels in the scale) returns the values that
they should take.

=head2 limits

A numeric vector of length two providing limits of the scale.

=head2 name

Used as axis or legend title. If C<undef>, the default, it's taken from
the first mapping used for that aesthetic. If C<null> or C<[]>, the legend
title will be omitted.

=head2 breaks

One of

=over 4

=item *

C<null> or C<[]> for no breaks.

=item *

C<undef> for default breaks computed by the tranformation object.

=item *

a numeric vector of positions.

=item *

a function that takes the limits as input and returns breaks.

=back

=head2 labels

One of

=over 4

=item *

C<null> or C<[]> for no labels.

=item *

C<undef> for default labels computed by the tranformation object.

=item *

a string vector of labels (must be same of length as C<breaks>).

=item *

a function that takes the breaks as input and returns labels.

=back

=head2 na_value

Missing values will be replaced with this value.

=head2 trans

Either the name of a transformation object, or the object itself.
Built-in transformations include "asn", "atanh", "exp", "identity",
"identity", "log", "log10", "log1p", etc. 
See L<Chart::GGPlot::Trans> for details. 

=head2 guide

A function used to create a guide or its name.

=head2 position

The position of the axis. Possible values are
C<"left">, C<"right">, C<"top">, C<"bottom">.

=head1 METHODS

=head2 train_df($df)

Train scale from a dataframe.
Adjust range of the scale according to column data.

=head2 reset()

Reset scale, untrain ranges.

=head2 transform_df

Returns an associative arrayref of transformed variables and their values.

=head2 map_df($df, $i=null)

This calls C<map_to_limits()> on each of the scale's aesthetics. 
Returns an associative arrayref which maps aesthetics to processed column
data.

=head2 map_to_limits($p, $limits=$self->get_limits)

Maps a piddle of data to the scale's limits.
Returns a piddle of processed column data.

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2021 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
