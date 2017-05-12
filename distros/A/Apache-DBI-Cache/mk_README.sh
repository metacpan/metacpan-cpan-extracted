#!/bin/bash

perl -pe '/^=head1 DESCRIPTION/ and print <STDIN>' lib/Apache/DBI/Cache.pod >README.pod <<EOF
=head1 INSTALLATION

This installs 2 modules C<Apache::DBI::Cache> und C<Apache::DBI::Cache::mysql>.

 perl Makefile.PL
 make
 make test
 make install

=head2 Testing

=head3 MySQL

Since Apache::DBI::Cache::mysql depends on MySQL you need 2 databases on the
same DB server listening on port 3306 to test it. Nothing will be written to
them. Only connections are established and the C<SHOW PROCESSLIST> command
is executed.

The connection parameters are passed to the test as environment variables.
If you do not want to test it leave them empty and the plugin test
(C<t/100mysql>) is silently skipped.

These environment variables are used:

=over 4

=item B<MYSQL1>, B<MYSQL2>

the 2 database names

=item B<MYSQL_HOST>

the database host. If omitted C<localhost> is used.

=item B<MYSQL_USER>, B<MYSQL_PASSWD>

you credentials.

=back

My C<make test> command looks like:

 MYSQL1=dbitest1 MYSQL2=dbitest2 make test

=head3 BerkeleyDB

If C<BerkeleyDB> is not available a few tests are skipped.

=head1 DEPENDENCIES

B<BerkeleyDB> is used if installed to make DBI handle statistics visible
for the whole Apache process group instead of a single process.

DBI 1.37

perl 5.8.0

EOF

perldoc -tU README.pod >README
