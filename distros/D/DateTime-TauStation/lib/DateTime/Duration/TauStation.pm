package DateTime::Duration::TauStation;

use strict;
use vars qw ($VERSION);

use Carp;
use DateTime::TauStation;
use POSIX 'floor';
use parent 'DateTime::Duration';

$VERSION = '0.1';
$VERSION = eval $VERSION;

=head1 NAME

DateTime::Duration::TauStation - TauStation GCT duration objects.

=head1 SYNOPSIS

  use DateTime::TauStation;
  use DateTime::Format::TauStation;
  
  my $dur = DateTime::Format::TauStation->parse_duration( 'D/20:000 GCT' );
  
  my $dt = DateTime::TauStation->now->add_duration( $dur );
  
  print DateTime::Format::TauStation->format_datetime($dt);

=head1 DESCRIPTION

L<DateTime::Duration> subclass for GCT (Galactic Coordinated Time) datetimes
for the online game L<TauStation|https://taustation.space>.

=cut

my @gct_fields = qw( gct_cycle gct_day gct_segment gct_unit );

sub new {
    my ( $class, %args ) = @_;
    my $self;

    my %gct_args = map { $_ => $args{"${_}s"} }
        grep { exists $args{"${_}s"} }
        @gct_fields;

    if ( %gct_args ) {
        my $dt1 = DateTime::TauStation->catastrophe;

        # relative to catastrophe
        my $dt2 = DateTime::TauStation->new( %gct_args );

        my $diff = $dt2->epoch() - $dt1->epoch();

        $self = $class->SUPER::new(
            seconds => $diff,
        );
    }
    else {
        croak "constructor requires at least 1 of the arguments: @gct_fields";
    }

    return $self;
}

=head1 METHODS

=head2 gct_cycles

Returns the C<cycle> portion of a duration.

=cut

sub gct_cycles {
    my ( $self ) = @_;

    return DateTime::TauStation->catastrophe->add_duration( $self )->gct_cycle;
}

=head2 gct_days

Returns the C<day> portion of a duration.

=cut

sub gct_days {
    my ( $self ) = @_;

    return DateTime::TauStation->catastrophe->add_duration( $self )->gct_day;
}

=head2 gct_segments

Returns the C<segment> portion of a duration.

=cut

sub gct_segments {
    my ( $self ) = @_;

    return DateTime::TauStation->catastrophe->add_duration( $self )->gct_segment;
}

=head2 gct_units

Returns the C<unit> portion of a duration.

=cut

sub gct_units {
    my ( $self ) = @_;

    return DateTime::TauStation->catastrophe->add_duration( $self )->gct_unit;
}

=head1 Limitations

Currently does not support negative GCT (pre-catastrophe) dates or negative
durations.

=head1 AUTHOR

Carl Franks

=head1 COPYRIGHT

Copyright (c) 2018 Carl Franks.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with
this module.

=head1 SEE ALSO

L<DateTime::TauStation>, L<DateTime::Format::TauStation>

=cut
