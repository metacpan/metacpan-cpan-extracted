package Bundle::DBD::DB2;

$VERSION = '1.85';

1;

__END__

=head1 NAME

Bundle::DBD::DB2 - A bundle to install all DBD::DB2 related modules

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::DBD::DB2'>

=head1 CONTENTS

Bundle::DBI  - Bundle for DBI by TIMB (Tim Bunce)

DBD::DB2     - DBD::DB2 by DB2PERL

=head1 DESCRIPTION

This bundle includes all the modules used by the Perl Database
Interface (DBI) driver for DB2 (DBD::DB2), assuming the
use of DBI version 1.21 or later, created by Tim Bunce.

If you've not previously used the CPAN module to install any
bundles, you will be interrogated during its setup phase.
But when you've done it once, it remembers what you told it.
You could start by running:

    C<perl -MCPAN -e 'install Bundle::CPAN'>

=head1 SEE ALSO

Bundle::DBI

=head1 AUTHOR

DB2PERL E<lt>F<db2perl@ca.ibm.com>E<gt>

=head1 THANKS

This bundle was created by ripping off Bundle::libnet created by
Graham Barr E<lt>F<gbarr@ti.com>E<gt>, and radically simplified
with some information from Jochen Wiedmann E<lt>F<joe@ispsoft.de>E<gt>.
The template was then included in the DBI::DBD documentation by
Jonathan Leffler E<lt>F<jleffler@informix.com>E<gt>.

=cut
