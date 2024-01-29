package CXC::Astro::Regions::DS9::Types;

# ABSTRACT: Types for DS9 Regions

use v5.20;
use warnings;

our $VERSION = '0.02';

use Types::Standard        qw( Enum Bool Num  );
use Types::Common::Numeric qw( PositiveNum );
use Type::Utils -all;
use Regexp::Common qw( number );
use Type::Library
  -base,
  -extends => [ 'Types::Common::Numeric', 'Types::Common::String', 'Types::Standard' ],
  -declare => qw(
  Angle
  CoordSys
  Length
  LengthPair
  OneZero
  PointType
  RulerCoords
  Vertex
  XPos
  YPos
  );

declare OneZero, as Enum [ 1, 0 ];
coerce OneZero, from Bool->coercibles, via { to_Bool( $_ ) ? q{1} : q{0} };

my $PosNum = qr{ (?: $RE{num}{real} [drpi]?) }x;

# these are unsophisticated, and don't take into account the allowed
# ranges for [DH]/M/S
my $PosXMS = qr/(?: $RE{num}{int}:$RE{num}{int}:$RE{num}{real})/x;
my $PosHMS = qr/(?: $RE{num}{int}h$RE{num}{int}m$RE{num}{real}s)/x;
my $PosDMS = qr/(?: $RE{num}{int}d$RE{num}{int}m$RE{num}{real}s)/x;

my $XPosRE = qr/^(?: $PosNum|$PosXMS|$PosHMS )$/x;
my $YPosRE = qr/^(?: $PosNum|$PosXMS|$PosDMS )$/x;

declare XPos,   as StrMatch [$XPosRE];
declare YPos,   as StrMatch [$YPosRE];
declare Vertex, as Tuple [ XPos, YPos ];

my $SizeRE = qr/$RE{num}{real} ["'drpi]?/x;

declare Length,     as StrMatch [$SizeRE];
declare LengthPair, as Tuple [ Length, Length ];

declare Angle, as Num;

## no critic (RegularExpressions::ProhibitEnumeratedClasses)
declare CoordSys,
  as StrMatch->of( qr/wcs[a-z]/i ) | Enum->of(
    \1,    # use Type::Tiny::Enum::closest_match
    'amplifier',
    'detector',
    'ecliptic',
    'fk4',
    'fk5',
    'galactic',
    'icrs',
    'image',
    'linear',
    'physical',
  ),
  coercion => 1;

declare PointType, as Enum [
    \1,    # use Type::Tiny::Enum::closest_match
    qw( circle box diamond cross x arrow boxcircle ),
  ],
  coercion => 1;

declare RulerCoords, as Enum [
    \1,    # use Type::Tiny::Enum::closest_match
    qw( pixels degrees arcmin arcsec ),
  ],
  coercion => 1;

1;

#
# This file is part of CXC-Astro-Regions
#
# This software is Copyright (c) 2023 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

CXC::Astro::Regions::DS9::Types - Types for DS9 Regions

=head1 VERSION

version 0.02

=head1 INTERNALS

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-astro-regions@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Astro-Regions>

=head2 Source

Source is available at

  https://gitlab.com/djerius/cxc-astro-regions

and may be cloned from

  https://gitlab.com/djerius/cxc-astro-regions.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<CXC::Astro::Regions|CXC::Astro::Regions>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
