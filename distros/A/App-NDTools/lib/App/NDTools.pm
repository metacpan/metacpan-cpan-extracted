package App::NDTools;

use strict;
use warnings;

=head1 NAME

App::NDTools - command line tools for nested structures

=begin html

<a href="https://travis-ci.org/mr-mixas/NDTools"><img src="https://travis-ci.org/mr-mixas/NDTools.svg?branch=master" alt="CI"></a>
<a href='https://coveralls.io/github/mr-mixas/NDTools?branch=master'><img src='https://coveralls.io/repos/github/mr-mixas/NDTools/badge.svg?branch=master' alt='Coverage Status'/></a>
<a href="https://badge.fury.io/pl/App-NDTools"><img src="https://badge.fury.io/pl/App-NDTools.svg" alt="CPAN version"></a>

=end html

=head1 VERSION

Version 0.5.3

=cut

our $VERSION = "0.5.3";

=head1 DESCRIPTION

Diff, patch, process and query nested structures with ease.

=head1 TOOLS

=over 4

=item B<L<nddiff>>

Human friendly (colored, brief) and machine readable (JSON) diff.

=item B<L<ndpatch>>

Apply diff to the structure.

=item B<L<ndproc>>

Process structure using rules and modules.

=item B<L<ndquery>>

Examine structure with ease.

=back

=head1 INSTALL

From CPAN:

    cpanm App::NDTools

Build and install deb package:

    git clone https://github.com/mr-mixas/NDTools.git
    cd NDTools
    vim dist/debian/changelog # change sign for last version
    make -C dist deb
    sudo dpkg -i ndtools_*.deb

Play without installation:

    git clone https://github.com/mr-mixas/NDTools.git
    cd NDTools
    source ./SOURCEME # install depends to the current directory and set ENV

=head1 AUTHOR

Michael Samoglyadov, C<< <mixas at cpan.org> >>

=head1 BUGS

Report bugs to L<https://github.com/mr-mixas/NDTools/issues>

=head1 SEE ALSO

L<jq|https://stedolan.github.io/jq/>

L<Struct::Diff>, L<Struct::Path>, L<Struct::Path::PerlStyle>

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2018 Michael Samoglyadov

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see L<http://www.gnu.org/licenses/>.

=cut
