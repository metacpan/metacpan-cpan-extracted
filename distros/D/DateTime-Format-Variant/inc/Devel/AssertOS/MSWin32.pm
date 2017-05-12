# $Id: MSWin32.pm,v 1.4 2008/11/05 22:52:34 drhyde Exp $

package #
Devel::AssertOS::MSWin32;

use Devel::CheckOS;

$VERSION = '1.2';

sub os_is { $^O eq 'MSWin32' ? 1 : 0; }

sub expn {
join("\n",
"The operating system is Microsoft Windows, and perl was built using",
"the Win32 API"
)
}

Devel::CheckOS::die_unsupported() unless(os_is());

=head1 COPYRIGHT and LICENCE

Copyright 2007 - 2008 David Cantrell

This software is free-as-in-speech software, and may be used, distributed, and modified under the terms of either the GNU General Public Licence version 2 or the Artistic Licence. It's up to you which one you use. The full text of the licences can be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=cut

1;
