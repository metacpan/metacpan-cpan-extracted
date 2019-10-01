package Bundle::Maintainer::MHASCH;

use strict;
use warnings;

our $VERSION = '0.002';

1;

__END__

=head1 NAME

Bundle::Maintainer::MHASCH - CPAN Modules maintained by Martin Becker (MHASCH).

=head1 VERSION

This documentation refers to version 0.002 of Bundle::Maintainer::MHASCH.

=head1 SYNOPSIS

  perl -MCPAN -e "install Bundle::Maintainer::MHASCH"

=head1 CONTENTS

Date::Gregorian

Math::DifferenceSet::Planar

Math::Logic::Ternary

Math::ModInt

Math::Polynomial

Math::Polynomial::ModInt

Math::Polynomial::Multivariate

=head1 DESCRIPTION

Bundles are special modules with no functionality other than a POD
section "CONTENTS".  Other modules mentioned there will be installed by
CPAN clients when instructed to install the Bundle.  Thus bundles can
be used to group modules from different distributions in order to make
it easy to install them all at once.

However, this mechanism is very specific to CPAN and not quite flexible.
To resolve complex or platform-dependent or configurable dependencies,
ordinary modules with their metadata and various configuration directives
have much more powerful capabilities than bundles with just a static list
of modules to be installed.  To provide modern meta-modules to pull in
a set of other modules it is now generally recommended to populate the
Task:: namespace.

Exceptions might be simple shopping lists like one person's favourites
or one person's liabilities.  An advantage bundles have over tasks is
that they will always pull latest releases without any need to update
version requirements.

To keep things intuitive and namespaces clean, we recommend naming
personal favourite bundles Bundle::User::E<lt>CPAN-IDE<gt> and lists
of modules one has to care for Bundle::Maintainer::E<lt>CPAN-IDE<gt>.
Note that these may but don't have to be published on CPAN.  Either way,
there most certainly will be no risk of name clashes.  Bundles related to
some task or concept can go on to use the rest of the Bundle:: and Task::
namespaces.

This particular bundle, Bundle::Maintainer::MHASCH, consequently, is
a list of main modules of CPAN distributions currently maintained by
Martin Becker (MHASCH), only without itself and other bundles and tasks.
Modules this author only contributes to but is not responsible to maintain
are also omitted.

=head1 SEE ALSO

=over 4

=item *

L<Distributions by Martin Becker (MHASCH)|https://metacpan.org/author/MHASCH>

=back

=head1 BUGS AND LIMITATIONS

Please submit bug reports and suggestions via the CPAN RT,
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bundle-Maintainer-MHASCH>.

=head1 AUTHOR

Martin Becker, E<lt>mhasch I<at> cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2019 by Martin Becker.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
