package Alien::YARA;

use strict;
use warnings;
use version;

our $VERSION   = qv('v0.0.6');
our $AUTHORITY = 'cpan:MANWAR';

use parent 'Alien::Base';

=encoding utf-8

=head1 NAME

Alien::YARA - Find or download and install the YARA malware analysis library

=head1 VERSION

Version v0.0.6

=head1 SYNOPSIS

In your C<Makefile.PL> or C<Build.PL>:

 use Alien::Build::MM;
 my $abmm = Alien::Build::MM->new;

 WriteMakefile($abmm->mm_args(
     ...
     PREREQ_PM => {
         'Alien::YARA' => '0.01',
     },
 ));

In your Perl module code:

 use Alien::YARA;
 use FFI::Platypus;

 my $ffi = FFI::Platypus->new( api => 2 );
 $ffi->lib( Alien::YARA->dynamic_libs );

 # Now attach your C functions
 $ffi->attach( 'yr_initialize' => [] => 'int' );

=head1 DESCRIPTION

This module acts as an encapsulation layer for the YARA C library (C<libyara>).
It checks your host system to see if YARA is already installed via native package
management (like C<apt>, C<homebrew>, or C<pkgconf>). If it cannot find a suitable
global version, it automatically downloads the official YARA source code,
compiles it, and isolates the binaries locally within your Perl library tree.

This makes bundling dependencies for FFI-based modules like L<YaraFFI> perfectly
cross-platform across Linux, macOS, and Windows.

=head1 METHODS

This class inherits all methods from L<Alien::Base>. The most critical ones for FFI usage are:

=head2 dist_dir

 my $dir = Alien::YARA->dist_dir;

Returns the local installation directory if a C<share> install was performed.

=head2 dynamic_libs

 my @libs = Alien::YARA->dynamic_libs;
 my $lib  = $libs[0];

Returns a list of paths to the shared objects or dynamic libraries (C<.so>, C<.dylib>, C<.dll>).
Pass this directly into your L<FFI::Platypus> instantiation.

=head2 cflags

 my $cflags = Alien::YARA->cflags;

Returns the compiler flags needed to compile an XS module against C<libyara>.

=head2 libs

 my $libs = Alien::YARA->libs;

Returns the linker flags needed to link an XS module against C<libyara>.

=head1 SEE ALSO

=over 4

=item * L<YaraFFI> - The primary FFI interface built on top of this module.

=item * L<Alien::Base> - The base framework powering this installer wrapper.

=item * L<Alien::Build> - The underlying tools used to configure, download, and build YARA.

=item * L<https://github.com/VirusTotal/yara> - The official YARA open-source repository.

=back

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Alien-YARA>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/Alien-YARA/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Alien-YARA

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/Alien-YARA/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Alien-YARA>

=item * Search MetaCPAN

L<https://metacpan.org/dist/Alien-YARA>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:
L<http://www.perlfoundation.org/artistic_license_2_0>
Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.
If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.
This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.
This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.
Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Alien::YARA
