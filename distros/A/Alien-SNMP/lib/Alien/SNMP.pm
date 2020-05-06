package Alien::SNMP;

use strict;
use warnings;
use 5.010001;
use parent qw(Alien::Base);

our $VERSION = '2.002000';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::SNMP - Alien package for the Net-SNMP library

=head1 VERSION

Version 2.001000

=cut

=head1 SYNOPSIS

 use Alien::SNMP;
 # then it's just like SNMP.pm
 
 say Alien::SNMP->bin_dir;
 # where the net-snmp apps (snmptranslate, etc) live

=head1 DESCRIPTION

L<Alien::SNMP> downloads and installs the Net-SNMP library and
associated perl modules.

The library is built with the following options:

=over

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

 my $bin_dir = Alien::SNMP->bin_dir;

Returns the location of the net-snmp apps (snmptranslate, etc).

=head2 cflags

 my $cflags = Alien::SNMP->cflags;

Returns the C compiler flags.

=head2 libs

 my $libs = Alien::SNMP->libs;

Returns the linker flags.

=head1 SEE ALSO

=over 4

=item L<Alien>

=item L<Alien::Base>

=item L<SNMP>

The Perl5 'SNMP' Extension Module for the Net-SNMP SNMP package.  Depends on
libnetsnmp and the corresponding version is installed along with the C
library.

=back

=head1 AUTHOR

Eric A. Miller, C<< <emiller at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Eric A. Miller.

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
