package DBIO::DB2::Storage;
# ABSTRACT: IBM DB2 support for DBIO

use strict;
use warnings;

use base qw/DBIO::Storage::DBI/;
use mro 'c3';

__PACKAGE__->register_driver('DB2' => __PACKAGE__);

__PACKAGE__->datetime_parser_type('DateTime::Format::DB2');
__PACKAGE__->sql_quote_char ('"');
__PACKAGE__->sql_maker_class('DBIO::DB2::SQLMaker');

sub sqlt_type { 'DB2' }


# lazy-default kind of thing
sub sql_name_sep {
  my $self = shift;

  my $v = $self->next::method(@_);

  if (! defined $v and ! @_) {
    $v = $self->next::method($self->_dbh_get_info('SQL_QUALIFIER_NAME_SEPARATOR') || '.');
  }

  return $v;
}


sub dbio_deploy_class { 'DBIO::DB2::Deploy' };

sub _dbh_last_insert_id {
  my ($self, $dbh, $source, $col) = @_;

  my $name_sep = $self->sql_name_sep;

  my $sth = $dbh->prepare_cached(
    # An older equivalent of 'VALUES(IDENTITY_VAL_LOCAL())', for compat
    # with ancient DB2 versions. Should work on modern DB2's as well:
    # http://publib.boulder.ibm.com/infocenter/db2luw/v8/topic/com.ibm.db2.udb.doc/admin/r0002369.htm?resultof=%22%73%79%73%64%75%6d%6d%79%31%22%20
    "SELECT IDENTITY_VAL_LOCAL() FROM sysibm${name_sep}sysdummy1",
    {},
    3
  );
  $sth->execute();

  my @res = $sth->fetchrow_array();

  return @res ? $res[0] : undef;
}

sub deploy_setup { }



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::Storage - IBM DB2 support for DBIO

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Storage driver for IBM DB2 databases. Handles autoincrement column retrieval
via C<IDENTITY_VAL_LOCAL()>, queries the server name separator from L<DBI>,
and sets the datetime parser to L<DateTime::Format::DB2>.

Uses L<DBIO::DB2::SQLMaker> for SQL generation with DB2-specific LIMIT/OFFSET
support (C<ROW_NUMBER() OVER()> for OFFSET, C<FETCH FIRST n ROWS ONLY> otherwise).

=head1 METHODS

=head2 sql_name_sep

Returns the name separator character used by this DB2 server (e.g. C<.>),
queried from the server via C<SQL_QUALIFIER_NAME_SEPARATOR> on first access.

=head2 deploy_setup

No-op stub for DB2. Present for API compatibility with other drivers
that need to allocate resources before a deploy operation.

=head1 SEE ALSO

=over

=item * L<DBIO::DB2> - DB2 schema component

=item * L<DBIO::Storage::DBI> - Base DBI storage class

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
