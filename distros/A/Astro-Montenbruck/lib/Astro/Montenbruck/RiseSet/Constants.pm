package Astro::Montenbruck::RiseSet::Constants;

use strict;
use warnings;

our @ISA = qw/Exporter/;
our $VERSION   = 0.01;

use Readonly;

my @events   = qw/$EVT_RISE $EVT_SET $EVT_TRANSIT @RS_EVENTS/;
my @states   = qw/$STATE_CIRCUMPOLAR $STATE_NEVER_RISES/;
my @twilight = qw/$TWILIGHT_CIVIL $TWILIGHT_ASTRO $TWILIGHT_NAUTICAL/;
my @alts     = qw/$H0_SUN $H0_MOO $H0_PLA %H0_TWL/;

our %EXPORT_TAGS = (
    events    => \@events,
    states    => \@states,
    twilight  => \@twilight,
    altitudes => \@alts,
    all       => [ @events, @states, @twilight, @alts ]
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

Readonly our $EVT_RISE         => 'rise';
Readonly our $EVT_SET          => 'set';
Readonly our $EVT_TRANSIT      => 'transit';
Readonly::Array our @RS_EVENTS => ( $EVT_RISE, $EVT_TRANSIT, $EVT_SET );

Readonly our $STATE_CIRCUMPOLAR => 'circumpolar';
Readonly our $STATE_NEVER_RISES => 'never rises';

Readonly our $TWILIGHT_CIVIL    => 'civil';
Readonly our $TWILIGHT_ASTRO    => 'astronomical';
Readonly our $TWILIGHT_NAUTICAL => 'nautical';

Readonly our $H0_SUN       => -50 / 60;
Readonly our $H0_MOO       =>   8 / 60;
Readonly our $H0_PLA       => -34 / 60;
Readonly::Hash our %H0_TWL => (
    $TWILIGHT_CIVIL    => -6,
    $TWILIGHT_ASTRO    => -18,
    $TWILIGHT_NAUTICAL => -12
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::RiseSet::Constants — rise/set constants

=head1 SYNOPSIS

use Astro::Montenbruck::RiseSet::Constants qw/:all/;

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

Constants used across rise/set modules.

=head1 EXPORT

=head2 CONSTANTS

=head3 EVENTS

=over

=item * C<$EVT_RISE> — rise

=item * C<$EVT_SET> — set

=item * C<$EVT_TRANSIT> — transit (upper culmination)

=item * C<@RS_EVENTS> — array containing all the constants above

=back

=head3 STATES

=over

=item * C<$STATE_CIRCUMPOLAR> — always above the horizon

=item * C<$STATE_NEVER_RISES> — always below the horizon

=back

=head3 TYPES OF TWILIGHT

=over

=item * C<$TWILIGHT_CIVIL> — civil

=item * C<$TWILIGHT_ASTRO> — astronomical

=item * C<$TWILIGHT_NAUTICAL> — nautical

=back

=head3 STANDARD ALTITUDES

=over

=item * C<$H0_SUN> — Sun

=item * C<$H0_MOO> — Moon

=item * C<$H0_PLA> — Planets and stars

=item * C<%H0_TWL> — For twilight types. Keys are L</TYPES OF TWILIGHT>

=back

=head2 TAGS

=over

=item * C<:events> — C<$EVT_RISE>, C<$EVT_SET>, C<$EVT_TRANSIT>, C<@RS_EVENTS>

=item * C<:states> — C<$STATE_CIRCUMPOLAR>, C<$STATE_NEVER_RISES>

=item * C<:twilight> — C<$TWILIGHT_CIVIL>, C<$TWILIGHT_ASTRO>, C<$TWILIGHT_NAUTICAL>

=item * C<:altitudes> — C<$H0_SUN>, C<$H0_MOO>, C<$H0_PLA>, C<%H0_TWL>

=item * C<:all> — all of the above

=back

=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2019 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
