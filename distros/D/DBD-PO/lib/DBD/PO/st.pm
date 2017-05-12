package DBD::PO::st; ## no critic (Capitalization)

use strict;
use warnings;

our $VERSION = '1.00';

use DBD::File;
use parent qw(-norequire DBD::File::st);

our $imp_data_size = 0; ## no critic (PackageVars)

1;

__END__

=head1 NAME

DBD::PO::st - statement class for DBD::PO

$Id: st.pm 339 2009-03-01 11:53:16Z steffenw $

$HeadURL: https://dbd-po.svn.sourceforge.net/svnroot/dbd-po/trunk/DBD-PO/lib/DBD/PO/st.pm $

=head1 VERSION

1.00

=head1 SYNOPSIS

do not use

=head1 DESCRIPTION

statement class for DBD::PO

=head1 SUBROUTINES/METHODS

none

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

parent

L<DBD::File>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

not known

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut