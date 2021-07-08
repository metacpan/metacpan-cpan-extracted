package Alien::SNMP::MIBDEV;

use strict;
use warnings;
use 5.010001;
use parent qw(Alien::Base);

our $VERSION = '2.020000';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::SNMP::MIBDEV - Alien package for the Net-SNMP library

=head1 VERSION

Version 2.020000

=cut

=head1 SYNOPSIS

 use Alien::SNMP::MIBDEV;
 # then it's just like SNMP.pm
 
 say Alien::SNMP::MIBDEV->bin_dir;
 # where the net-snmp apps (snmptranslate, etc) live

=head1 DESCRIPTION

L<Alien::SNMP::MIBDEV> is mainly used for netdisco-mibs development where
standard settings do not suffice. It's not intended for other purposes.

L<Alien::SNMP::MIBDEV> downloads and installs the Net-SNMP 5.8 library and
associated perl modules.

This is based on L<Alien::SNMP::MAXTC>.

Compared to the standard module MAX_IMPORTS has been raised to 512.

The library is built with the following options:

=over

=item MAX_IMPORTS set to 512

=item C<--with-pic>

=item C<--disable-agent>

=item C<--disable-manuals>

=item C<--disable-scripts>

=item C<--disable-mibs>

=item C<--enable-ipv6>

=item C<--with-mibs="">

=item C<--with-perl-modules>

=item C<--disable-embedded-perl>

=item C<--with-defaults>

=back

=head1 METHODS

=head2 bin_dir

 my $bin_dir = Alien::SNMP::MIBDEV->bin_dir;

Returns the location of the net-snmp apps (snmptranslate, etc).

=head2 cflags

 my $cflags = Alien::SNMP::MIBDEV->cflags;

Returns the C compiler flags.

=head2 libs

 my $libs = Alien::SNMP::MIBDEV->libs;

Returns the linker flags.

=head1 SEE ALSO

=over 4

=item L<Alien>

=item L<Alien::Base>

=item L<Alien::SNMP>

=item L<Alien::SNMP::MAXTC>

=item L<SNMP>

The Perl5 'SNMP' Extension Module for the Net-SNMP SNMP package.  Depends on
libnetsnmp and the corresponding version is installed along with the C
library.

=back

=head1 AUTHOR

Eric A. Miller, C<< <emiller at cpan.org> >>

Oliver Gorwits

Nick Nauwelaerts

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Eric A. Miller.

Copyright 2020 Oliver Gorwits.

Copyright 2021 Nick Nauwelaerts.

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

* Neither the name of Eric A. Miller's Organization
nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
