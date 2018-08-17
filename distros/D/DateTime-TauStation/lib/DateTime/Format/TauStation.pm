package DateTime::Format::TauStation;

use strict;
use vars qw ($VERSION);

use Carp;
use DateTime::TauStation;
use DateTime::Duration::TauStation;
use parent 'DateTime::Format::Builder';

$VERSION = '0.1';
$VERSION = eval $VERSION;

=head1 NAME

DateTime::Format::TauStation - Parse and format TauStation GCT datetimes

=head1 SYNOPSIS

  use DateTime::Format::TauStation;
  
  my $dt = DateTime::Format::TauStation->parse_datetime( '90.28/44:001 GCT' );
  
  # 90.28/44:001 GCT
  DateTime::Format::TauStation->format_datetime($dt);
  
  my $dur = DateTime::Format::TauStation->parse_duration( 'D/20:000 GCT' );
  
  # D/20:000 GCT
  DateTime::Format::TauStation->format_duration($dur);


=head1 DESCRIPTION

Parse and format GCT (Galactic Coordinated Time) strings for the online game
L<TauStation|https://taustation.space>.

=cut

my @gct_fields = qw( gct_cycle gct_day gct_segment gct_unit );

my $cycle   = qr! ( [0-9]+     ) !x;
my $day     = qr! ( [0-9]{1,2} ) !x;
my $segment = qr! ( [0-9]{1,2} ) !x;
my $unit    = qr! ( [0-9]{1,3} ) !x;

my $date    = qr! $cycle   \. $day  !x;
my $time    = qr! $segment :  $unit !x;

my $gct_datetime = qr! ^ $date / $time [ ] GCT $ !x;

my $gct_duration_cdsu = qr! D $date / $time [ ] GCT $ !x;
my $gct_duration_dsu  = qr! D  $day / $time [ ] GCT $ !x;
my $gct_duration_su   = qr! D       / $time [ ] GCT $ !x;

my $parse_datetime = {
    regex       => $gct_datetime,
    params      => [@gct_fields],
    constructor => sub {
        my ( $parser, %args ) = @_;
        my %gct = map { $_ => $args{$_} } @gct_fields;

        return DateTime::TauStation->new(%gct);
    },
};

my $duration_constructor = sub {
    my ( $parser, %args ) = @_;
    my %gct = map { $_ => $args{$_} }
        map { "${_}s" }
        @gct_fields;

    return DateTime::Duration::TauStation->new(%gct);
};

my @parse_duration = (
    {
        regex  => $gct_duration_cdsu,
        params => [qw( gct_cycles gct_days gct_segments gct_units )],
        constructor => $duration_constructor,
    },
    {
        regex  => $gct_duration_dsu,
        params => [qw( gct_days gct_segments gct_units )],
        constructor => $duration_constructor,
    },
    {
        regex  => $gct_duration_su,
        params => [qw( gct_segments gct_units )],
        constructor => $duration_constructor,
    },
);

DateTime::Format::Builder->create_class
(
    parsers => {
        parse_datetime => [$parse_datetime],
        parse_duration => \@parse_duration,
    },
);

=head1 METHODS

=head2 parse_datetime

Requires a full datetime string such as "0.1/02:003", where C<0> is the
C<cycle>, C<1> is the day, C<03> is the segment, and C<004> is the unit.

Returns a L<DateTime::TauStation> object.

=head2 parse_duration

Supports the following forms of duration strings: C<D4.3/02:001 GCT>,
C<D3/02:001 GCT> and C<D/02:001 GCT>.

Returns a L<DateTime::TauStation> object.

=head2 format_datetime

=cut

sub format_datetime {
    my ( $self, $dt ) = @_;

    my ( $cycles, $days, $segments, $units ) = @{ $dt->_return_gct };

    return sprintf "%.3d.%.2d/%.2d:%.3d GCT",
        $cycles,
        $days,
        $segments,
        $units;
}

=head2 format_duration

=head2 format_interval

Given a C<DateTime::Duration::TauStation> object, this method returns a GCT
formatted duration string.

=cut

sub format_duration {
    my ( $self, $dur ) = @_;

    my $seconds = $dur->delta_seconds;

    my ( $cycles, $days, $segments, $units ) =
        @{ DateTime::TauStation->new->_return_gct( undef, $seconds ) };

    if ( $cycles ) {
        return sprintf "D%d.%d/%.2d:%.3d GCT",
            $cycles,
            $days,
            $segments,
            $units;
    }
    elsif ( $days ) {
        return sprintf "D%d/%.2d:%.3d GCT",
            $days,
            $segments,
            $units;
    }
    else {
        return sprintf "D/%.2d:%.3d GCT",
            $segments,
            $units;
    }
}

*format_interval = \&format_duration;

1;

__END__

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

L<DateTime::TauStation>, L<DateTime::Duration::TauStation>

=cut
