package DPKG::Update;

use Getopt::Long;
use vars qw(
	    $VERSION
	    );

$VERSION='0.1';

=pod

=head1 NAME

DPKG::Update - compare installed dpkg with up-to-date distribution

=head1 SYNOPSIS

 use DPKG::Update;

 DPKG::Update::execute();

=head1 README

I<DPKG::Update> compares installed Debian packages on a Linux system
with an up-to-date distribution.  Updates are automatically performed.

=head1 DESCRIPTION

Currently, there are no options to B<DPKG::Update::execute>.

I<DPKG::Update> compares installed Debian packages on a Linux system
with an up-to-date distribution.

=cut

=pod

=head1 SEE ALSO

dpkg, dselect, apt-get

=head1 AUTHOR

The module packager is Scott Harrison,
Michigan State University, sharrison@users.sourceforge.net

=head1 LICENSE

DPKG::Update is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

DPKG::Update is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details:
http://www.gnu.org/licenses/gpl.html

=cut

sub execute {
    return `apt-get -u update`;
}

1;
