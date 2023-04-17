package Astro::FITS::CFITSIO::FileName::Types;

# ABSTRACT: Types for Astro::FITS::CFITSIO::FileName

use v5.26;
use warnings;

our $VERSION = '0.08';

use Type::Library -base;
use Types::Standard 'Str', 'HashRef';
use Type::Tiny::Class;

require Astro::FITS::CFITSIO::FileName;    # prevent import loop, just in case.









__PACKAGE__->add_type(
    Type::Tiny::Class->new(
        name  => 'FitsFileName',
        class => 'Astro::FITS::CFITSIO::FileName',
    )->plus_constructors( Str, 'new', HashRef, 'new', ),
);

#
# This file is part of Astro-FITS-CFITSIO-FileName
#
# This software is Copyright (c) 2021 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory FitsFileName

=head1 NAME

Astro::FITS::CFITSIO::FileName::Types - Types for Astro::FITS::CFITSIO::FileName

=head1 VERSION

version 0.08

=head1 DESCRIPTION

This is a L<Type::Tiny> library.

=head1 TYPES

=head2 FitsFileName

This is a class type for L<Astro::FITS::CFITSIO::FileName>.  It has
coercions from L<Types::Standard/Str> and L<Types::Standard/HashRef> to
a L<Astro::FITS::CFITSIO::FileName> object.

=head1 INTERNALS

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-astro-fits-cfitsio-filename@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-FITS-CFITSIO-FileName>

=head2 Source

Source is available at

  https://gitlab.com/djerius/astro-fits-cfitsio-filename

and may be cloned from

  https://gitlab.com/djerius/astro-fits-cfitsio-filename.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Astro::FITS::CFITSIO::FileName|Astro::FITS::CFITSIO::FileName>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
