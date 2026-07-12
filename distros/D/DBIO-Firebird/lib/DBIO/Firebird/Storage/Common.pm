package DBIO::Firebird::Storage::Common;
# ABSTRACT: Shared Firebird / InterBase storage logic

use strict;
use warnings;
use base qw/DBIO::Storage::DBI/;
use mro 'c3';


__PACKAGE__->_use_insert_returning (1);
__PACKAGE__->sql_quote_char ('"');
__PACKAGE__->sql_maker_class ('DBIO::Firebird::SQLMaker');

sub sqlt_type {
  return 'Firebird';
}


sub _sequence_fetch {
  my ($self, $nextval, $sequence) = @_;

  $self->throw_exception("Can only fetch 'nextval' for a sequence")
    if $nextval !~ /^nextval$/i;

  $self->throw_exception('No sequence to fetch') unless $sequence;

  my ($val) = $self->_get_dbh->selectrow_array(sprintf
    'SELECT GEN_ID(%s, 1) FROM rdb$database',
    $self->sql_maker->_quote($sequence)
  );

  return $val;
}

sub _dbh_get_autoinc_seq {
  my ($self, $dbh, $source, $col) = @_;

  my $table_name = $source->from;
  $table_name    = $$table_name if ref $table_name;
  $table_name    = $self->sql_maker->quote_char ? $table_name : uc($table_name);

  local $dbh->{LongReadLen} = 100000;
  local $dbh->{LongTruncOk} = 1;

  my $sth = $dbh->prepare(<<'EOF');
SELECT t.rdb$trigger_source
FROM rdb$triggers t
WHERE t.rdb$relation_name = ?
AND t.rdb$system_flag = 0 -- user defined
AND t.rdb$trigger_type = 1 -- BEFORE INSERT
EOF
  $sth->execute($table_name);

  while (my ($trigger) = $sth->fetchrow_array) {
    my @trig_cols = map
      { /^"([^"]+)/ ? $1 : uc($_) }
      $trigger =~ /new\.("?\w+"?)/ig
    ;

    my ($quoted, $generator) = $trigger =~
/(?:gen_id\s* \( \s* |next \s* value \s* for \s*)(")?(\w+)/ix;

    if ($generator) {
      $generator = uc $generator unless $quoted;

      return $generator
        if grep {
          $self->sql_maker->quote_char ? ($_ eq $col) : (uc($_) eq uc($col))
        } @trig_cols;
    }
  }

  return undef;
}

sub _exec_svp_begin {
  my ($self, $name) = @_;

  $self->_dbh->do("SAVEPOINT $name");
}

sub _exec_svp_release {
  my ($self, $name) = @_;

  $self->_dbh->do("RELEASE SAVEPOINT $name");
}

sub _exec_svp_rollback {
  my ($self, $name) = @_;

  $self->_dbh->do("ROLLBACK TO SAVEPOINT $name")
}

# http://www.firebirdfaq.org/faq223/
sub _get_server_version {
  my $self = shift;

  return $self->_get_dbh->selectrow_array(q{
SELECT rdb$get_context('SYSTEM', 'ENGINE_VERSION') FROM rdb$database
  });
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird::Storage::Common - Shared Firebird / InterBase storage logic

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

This class contains the shared logic for both Firebird and InterBase drivers.
It extends L<DBIO::Storage::DBI> directly to avoid unnecessary inheritance depth.

=head1 METHODS

=head2 sqlt_type

Returns C<Firebird>, identifying this storage to L<SQL::Translator>.

=head1 CAVEATS

=over 4

=item *

C<last_insert_id> support by default only works for Firebird versions 2 or
greater, L<auto_nextval|DBIO::ResultSource/auto_nextval> however should
work with earlier versions.

=back

=head1 SEE ALSO

=over

=item * L<DBIO::Firebird> - Firebird schema component

=item * L<DBIO::Firebird::Storage> - Firebird driver via L<DBD::Firebird>

=item * L<DBIO::Firebird::Storage::InterBase> - InterBase driver

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
