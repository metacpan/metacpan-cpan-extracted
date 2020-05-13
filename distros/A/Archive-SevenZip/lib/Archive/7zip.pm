package Archive::7zip;
use strict;

use Archive::SevenZip;

our $VERSION= '0.12';

*Archive::7zip:: = \*Archive::SevenZip::;

=head1 NAME

Archive::7zip - Read/write 7z , zip , ISO9960 and other archives

=head1 DESCRIPTION

This is an alias for L<Archive::SevenZip>.

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/archive-sevenzip>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Archive-SevenZip>
or via mail to L<archive-sevenzip-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2015-2019 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
