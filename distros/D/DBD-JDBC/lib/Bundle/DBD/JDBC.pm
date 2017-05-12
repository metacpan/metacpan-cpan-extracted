package Bundle::DBD::JDBC;

$VERSION = '0.71';

1;

__END__

=head1 NAME

Bundle::DBD::JDBC - A bundle to install all DBD::JDBC related modules

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::DBD::JDBC'>

=head1 CONTENTS

Bundle::DBI  - Bundle for DBI by TIMB (Tim Bunce)

Convert::BER - Convert::BER by GBARR (Graham Barr)

DBD::JDBC  - DBD::JDBC by VIZDOM (Gennis Emerson)

=head1 DESCRIPTION

This bundle includes all the modules used by the Perl Database
Interface (DBI) driver for Driver (DBD::JDBC), assuming the
use of DBI version 1.47 or later, created by Tim Bunce.

If you've not previously used the CPAN module to install any
bundles, you will be interrogated during its setup phase.
But when you've done it once, it remembers what you told it.
You could start by running:

  C<perl -MCPAN -e 'install Bundle::CPAN'>

=head1 SEE ALSO

Bundle::DBI

=head1 AUTHOR

Gennis Emerson E<lt>F<gemerson@vizdom.com>E<gt>

=head1 THANKS

This bundle is based on the template included in the DBI::DBD
documentation by Jonathan Leffler
E<lt>F<jleffler@informix.com>E<gt>.

=cut
