package Apache::Session::Browseable;

our $VERSION = '1.3.17';

print STDERR "Use a sub module of Apache::Session::Browseable such as Apache::Session::Browseable::File";

1;
__END__

=head1 NAME

Apache::Session::Browseable - Add index and search methods to Apache::Session

=head1 DESCRIPTION

Apache::Session::browseable provides some class methods to manipulate all
sessions and add the capability to index some fields to make research faster.

It has been written to increase performances of LemonLDAP::NG. Read the
chosen module documentation carefully to set the indexes.

=head1 AVAILABLE MODULES

=head2 SQL databases

=head3 PostgreSQL

=over

=item L<Apache::Session::Browseable::Postgres>

=item L<Apache::Session::Browseable::PgHstore>: uses "hstore" field

=item L<Apache::Session::Browseable::PgJSON>: uses "json/jsonb" field

=item L<Apache::Session::Browseable::Patroni>: uses "json/jsonb" field and
manage connection using Patroni API to find master node of PostgreSQL cluster

=back

=head3 MySQL or MariaDB

=over

=item L<Apache::Session::Browseable::MySQL>: for MySQL and MariaDB

=item L<Apache::Session::Browseable::MySQLJSON>: for MySQL only, uses "json" field

=back

=head3 Other

=over

=item L<Apache::Session::Browseable::Informix>

=item L<Apache::Session::Browseable::Oracle>

=item L<Apache::Session::Browseable::SQLite>

=back

=head2 NoSQL

=over

=item L<Apache::Session::Browseable::Redis>

=item L<Apache::Session::Browseable::Cassandra>

=back

=head1 SEE ALSO

L<Apache::Session>, L<http://lemonldap-ng.org>,
L<https://lemonldap-ng.org/documentation/2.0/performances#performance_test>

=head1 COPYRIGHT AND LICENSE

=encoding utf8

Copyright (C):

=over

=item 2009-2025 by Xavier Guimard

=item 2013-2025 by Clément Oudot

=item 2019-2025 by Maxime Besson

=item 2013-2025 by Worteks

=item 2023-2025 by Linagora

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
