package DBIO::MSSQL::Storage;
# ABSTRACT: Base Class for Microsoft SQL Server support in DBIO

use strict;
use warnings;

use base qw/
  DBIO::Storage::DBI::UniqueIdentifier
  DBIO::Storage::DBI::IdentityInsert
/;
use mro 'c3';

use Context::Preserve 'preserve_context';
use Scope::Guard ();
use SQL::Abstract::Util 'is_literal_value';
use Try::Tiny;
use namespace::clean;

__PACKAGE__->mk_group_accessors(simple => qw/
  _identity _identity_method _no_scope_identity_query
/);

__PACKAGE__->sql_maker_class('DBIO::MSSQL::SQLMaker');

__PACKAGE__->register_driver('MSSQL' => __PACKAGE__);

__PACKAGE__->sql_quote_char([qw/[ ]/]);

__PACKAGE__->datetime_parser_type (
  'DBIO::MSSQL::Storage::DateTime::Format'
);

__PACKAGE__->new_guid('NEWID()');

sub dbio_deploy_class { 'DBIO::MSSQL::Deploy' }

sub deploy_setup { }


sub _prep_for_execute {
  my $self = shift;
  my ($op, $ident, $args) = @_;

# cast MONEY values properly
  if ($op eq 'insert' || $op eq 'update') {
    my $fields = $args->[0];

    my $colinfo = $ident->columns_info([keys %$fields]);

    for my $col (keys %$fields) {
      # $ident is a result source object with INSERT/UPDATE ops
      if (
        $colinfo->{$col}{data_type}
          &&
        $colinfo->{$col}{data_type} =~ /^money\z/i
      ) {
        if(
          length ref $fields->{$col}
            and
          my $lit = is_literal_value( $fields->{$col} )
        ) {
          # We are being fed a literal value
          # Generally there is not much we can do about it, *except*
          # in the unambiguous case of a lone bind parameter
          $fields->{$col} = \[ 'CAST(? AS MONEY)', @{$lit}[ 1 .. $#$lit ] ]
            if $lit->[0] eq '?';
        }
        # nonliteral - wrap away
        else {
          $fields->{$col} = \['CAST(? AS MONEY)', [ $col => $fields->{$col} ]];
        }
      }
    }
  }

  # UNIQUEIDENTIFIER columns that look like is_auto_increment are
  # actually populated by NEWID() (see DBIO::Storage::DBI::UniqueIdentifier
  # _prefetch_autovalues) - they are NOT real IDENTITY columns. Suppress
  # the SET IDENTITY_INSERT wrapper the parent IdentityInsert would emit
  # for any autoinc column with a value, otherwise MSSQL complains that
  # the table has no IDENTITY property.
  my $suppress_identity_insert = 0;
  if ($op eq 'insert' and $self->_autoinc_supplied_for_op) {
    my $colinfo = $ident->columns_info;
    my $is_guid_autoinc = 0;
    for my $col (keys %$colinfo) {
      next unless $colinfo->{$col}{is_auto_increment};
      my $dt = $colinfo->{$col}{data_type} || '';
      if ($dt =~ /^(?:uniqueidentifier(?:str)?|guid)\z/i) {
        $is_guid_autoinc = 1;
        last;
      }
    }
    $suppress_identity_insert = 1 if $is_guid_autoinc;
  }

  my ($sql, $bind);
  if ($suppress_identity_insert) {
    local $self->{_autoinc_supplied_for_op} = 0;
    ($sql, $bind) = $self->next::method(@_);
  }
  else {
    ($sql, $bind) = $self->next::method(@_);
  }

  # SELECT SCOPE_IDENTITY only works within a statement scope. We
  # must try to always use this particular idiom first, as it is the
  # only one that guarantees retrieving the correct id under high
  # concurrency. When this fails we will fall back to whatever secondary
  # retrieval method is specified in _identity_method, but at this
  # point we don't have many guarantees we will get what we expected.
  # http://msdn.microsoft.com/en-us/library/ms190315.aspx
  # http://davidhayden.com/blog/dave/archive/2006/01/17/2736.aspx
  if (
    $self->_perform_autoinc_retrieval
      and
    not $self->_no_scope_identity_query
      and
    not $suppress_identity_insert
  ) {
    $sql .= "\nSELECT SCOPE_IDENTITY()";
  }

  return ($sql, $bind);
}

sub _execute {
  my $self = shift;

  # always list ctx - we need the $sth
  my ($rv, $sth, @bind) = $self->next::method(@_);

  if ($self->_perform_autoinc_retrieval) {

    # attempt to bring back the result of SELECT SCOPE_IDENTITY() we tacked
    # on in _prep_for_execute above
    my $identity;

    # we didn't even try on ftds
    unless ($self->_no_scope_identity_query) {
      ($identity) = try { $sth->fetchrow_array };
      $sth->finish;
    }

    # SCOPE_IDENTITY failed, but we can do something else
    if ( (! $identity) && $self->_identity_method) {
      ($identity) = $self->_dbh->selectrow_array(
        'select ' . $self->_identity_method
      );
    }

    $self->_identity($identity);
  }

  return wantarray ? ($rv, $sth, @bind) : $rv;
}

sub last_insert_id { shift->_identity }


#
# MSSQL is retarded wrt ordered subselects. One needs to add a TOP
# to *all* subqueries, but one also *can't* use TOP 100 PERCENT
# http://sqladvice.com/forums/permalink/18496/22931/ShowThread.aspx#22931
#
sub _select_args_to_query {
  #my ($self, $ident, $select, $cond, $attrs) = @_;
  my $self = shift;
  my $attrs = $_[3];

  my $sql_bind = $self->next::method (@_);

  # see if this is an ordered subquery
  if (
    $$sql_bind->[0] !~ /^ \s* \( \s* SELECT \s+ TOP \s+ \d+ \s+ /xi
      and
    scalar $self->_extract_order_criteria ($attrs->{order_by})
  ) {
    $self->throw_exception(
      'An ordered subselect encountered - this is not safe! Please see "Ordered Subselects" in DBIO::MSSQL::Storage'
    ) unless $attrs->{unsafe_subselect_ok};

    $$sql_bind->[0] =~ s/^ \s* \( \s* SELECT (?=\s) / '(SELECT TOP ' . $self->sql_maker->__max_int /exi;
  }

  $sql_bind;
}


# savepoint syntax is the same as in Sybase ASE

sub _exec_svp_begin {
  my ($self, $name) = @_;

  $self->_dbh->do("SAVE TRANSACTION $name");
}

# A new SAVE TRANSACTION with the same name releases the previous one.
sub _exec_svp_release { 1 }

sub _exec_svp_rollback {
  my ($self, $name) = @_;

  $self->_dbh->do("ROLLBACK TRANSACTION $name");
}

sub sqlt_type { 'SQLServer' }


sub _random_function { 'NEWID()' }

# TODO: MSSQL needs a SQLMaker with apply_limit that uses RowNumberOver
# (>= 2005/v9) or Top (older) based on server version.

sub _ping {
  my $self = shift;

  my $dbh = $self->_dbh or return 0;

  local $dbh->{RaiseError} = 1;
  local $dbh->{PrintError} = 0;

  return try {
    $dbh->do('select 1');
    1;
  } catch {
    0;
  };
}

sub with_deferred_fk_checks {
    my ( $self, $sub ) = @_;

    my $txn_scope_guard = $self->txn_scope_guard;

    $self->_do_query(
        'EXEC sp_msforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT ALL"');

    my $sg = Scope::Guard->new(
        sub {
            $self->_do_query(
                'EXEC sp_msforeachtable "ALTER TABLE ? CHECK CONSTRAINT ALL"'
            );
        } );

    return preserve_context { $sub->() } after => sub {
        # explicitly check constraints because MSSQL does not check when
        # re-enabling them
        $self->_do_query(
            'EXEC sp_msforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL"'
        );
        $txn_scope_guard->commit;
        $sg->dismiss;
    };
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Storage - Base Class for Microsoft SQL Server support in DBIO

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Storage driver for Microsoft SQL Server databases. Handles identity column
(autoincrement) retrieval via C<SCOPE_IDENTITY()>, proper C<MONEY> column
casting on insert/update, ordered subselect safety checks, savepoint support,
deferred foreign key checks via C<sp_msforeachtable>, and datetime parsing.

The limit dialect (C<RowNumberOver> or C<Top>) is detected automatically from
the server version. Uses L<DBIO::MSSQL::SQLMaker> for SQL generation.

=head1 METHODS

=head2 last_insert_id

Returns the last identity value inserted, as retrieved by C<SCOPE_IDENTITY()>
or the fallback C<_identity_method>.

=head2 sqlt_type

Returns C<SQLServer>, identifying this storage to L<SQL::Translator>.

=head2 with_deferred_fk_checks

    $storage->with_deferred_fk_checks(sub { ... });

Runs the supplied coderef with all foreign key constraints disabled via
C<sp_msforeachtable>. Constraints are re-enabled and explicitly verified
afterwards, and the transaction is committed.

=head1 SEE ALSO

=over

=item * L<DBIO::MSSQL> - MSSQL schema component

=item * L<DBIO::MSSQL::SQLMaker> - MSSQL SQL dialect

=item * L<DBIO::MSSQL::Storage::Sybase> - MSSQL via L<DBD::Sybase>

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
