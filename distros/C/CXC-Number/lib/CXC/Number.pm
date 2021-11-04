package CXC::Number;

# ABSTRACT:  A namespace for modules which deal with numbers.

use strict;
use warnings;

our $VERSION = '0.06';

#
# This file is part of CXC-Number
#
# This software is Copyright (c) 2019 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

CXC::Number - A namespace for modules which deal with numbers.

=head1 VERSION

version 0.06

=head1 DESCRIPTION

The following are known:

=over

=item L<CXC::Number::Grid>

A representation of a grid of numbers, with the ability to join and
overlay grids.  Useful for binning data.

=item L<CXC::Number::Sequence>

A namespace and module for dealing with sequences of numbers, often
constructed so that they are useful for binning data.

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Number> or by email
to L<bug-cxc-number@rt.cpan.org|mailto:bug-cxc-number@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<CXC::Number::Grid|CXC::Number::Grid>

=item *

L<CXC::Number::Sequence|CXC::Number::Sequence>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
