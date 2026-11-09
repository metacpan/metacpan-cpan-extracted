package DBIO::MySQL::SQLMaker::MariaDB;
# ABSTRACT: Deprecated alias of DBIO::MySQL::SQLMaker

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::MySQL::SQLMaker';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::SQLMaker::MariaDB - Deprecated alias of DBIO::MySQL::SQLMaker

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

B<Deprecated. This class adds nothing and exists only so that an explicit
C<< sql_maker_class => 'DBIO::MySQL::SQLMaker::MariaDB' >> in existing
configuration keeps working.> Use L<DBIO::MySQL::SQLMaker>; a connection made
through either of this dist's schema components already does.

It used to exist for one thing: MariaDB has no C<FOR SHARE>, so it overrode
C<_lock_select> to spell C<< for => 'share' >> as C<LOCK IN SHARE MODE>, and
L<DBIO::MySQL::Storage::MariaDB> selected it as its C<sql_maker_class>.

That put an B<engine> question on a B<DBD> class, and got two of the four
DBD/engine combinations wrong (this dist's ADR 0003). L<DBD::MariaDB> connects
to MySQL servers, where the override then produced C<LOCK IN SHARE MODE OF `t`
NOWAIT> -- rejected, because on MySQL the legacy spelling is exactly the one
that carries neither C<OF> nor a modifier. And L<DBD::mysql> connects to
MariaDB servers, which do not reach this class: a schema declares its driver,
and one that loads the MySQL component keeps L<DBIO::MySQL::Storage>. They
were handed the C<FOR SHARE> that MariaDB has in no version.

The decision now belongs to the server: L<DBIO::MySQL::Storage/_lock_dialect>
reads the product and version and hands the answer to
L<DBIO::MySQL::SQLMaker/_lock_select>, which renders it. So this subclass
overrides nothing -- and a configuration still naming it inherits the correct,
server-keyed behaviour instead of the old fixed one.

=head1 SEE ALSO

=pod

=over 4

=item * L<DBIO::MySQL::SQLMaker> - the class this one is now an empty alias of

=item * L<DBIO::MySQL::Storage> - decides the lock dialect from the server

=item * L<DBIO::MySQL::Storage::MariaDB> - the DBD::MariaDB binding, and nothing else

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
