package CXC::Astro::Regions::CFITSIO::Types;

# ABSTRACT: Types for CFITSIO Regions

use v5.20;
use warnings;

our $VERSION = '0.03';

use Types::Standard        qw( Enum Bool Num Str StrMatch );
use Types::Common::Numeric qw( PositiveNum );

use Type::Utils -all;
use Regexp::Common qw( number );
use Type::Library
  -base,
  -extends => [ 'Types::Common::Numeric', 'Types::Common::String', 'Types::Standard' ],
  -declare => qw(
  Angle
  Length
  PositionAsNum
  Vertex
  XPosition
  YPosition
  );

use CXC::Types::Astro::Coords 'Sexagesimal';

declare PositionAsNum,
  as StrMatch [qr{\A (?: $RE{num}{real} [d]?) \z}x];


declare XPosition, as PositionAsNum | Sexagesimal [ -ra,  -sep ];
declare YPosition, as PositionAsNum | Sexagesimal [ -dec, -sep ];
declare Vertex,    as Tuple [ XPosition, YPosition ];

declare Length, as StrMatch [qr/\A$RE{num}{real} (['"dp])?\z/x];

declare Angle, as Num;

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

CXC::Astro::Regions::CFITSIO::Types - Types for CFITSIO Regions

=head1 VERSION

version 0.03

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
