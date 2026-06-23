package DBIO::Oracle::Storage;
# ABSTRACT: Oracle Support for DBIO

use strict;
use warnings;

# Compose cross-cutting Storage behaviour via ISA (not Exporter import), so the
# role methods live in the MRO and their next::method calls resolve. Roles that
# override a DBIO::Storage::DBI method (LOBSupport::_prep_for_execute,
# Savepoints::_dbh_execute_for_fetch) come BEFORE DBIO::Storage::DBI so the
# override wins and chains forward to the base.
use base qw/
  DBIO::Oracle::Storage::LOBSupport
  DBIO::Oracle::Storage::AutoIncrement
  DBIO::Oracle::Storage::Savepoints
  DBIO::Oracle::Storage::FKDeferral
  DBIO::Oracle::Storage::ConnectSetup
  DBIO::Storage::DBI
/;
use mro 'c3';

__PACKAGE__->register_driver('Oracle' => __PACKAGE__);

use DBIO::Carp;
use Try::Tiny;
use namespace::clean;

__PACKAGE__->sql_quote_char ('"');
__PACKAGE__->sql_maker_class('DBIO::Oracle::SQLMaker');
__PACKAGE__->datetime_parser_type('DateTime::Format::Oracle');

use DBIO::Oracle::Type ();

sub __cache_queries_with_max_lob_parts { 2 }

sub dbio_deploy_class { 'DBIO::Oracle::Deploy' }
sub deploy_setup { }


sub _determine_supports_insert_returning {
  my $self = shift;
  # TODO find out which version supports the RETURNING syntax
  # 8i has it and earlier docs are a 404 on oracle.com
  return 1 if $self->_server_info->{normalized_dbms_version} >= 8.001;
  return 0;
}

__PACKAGE__->_use_insert_returning_bound (1);

sub deployment_statements {
  my $self = shift;;
  my ($schema, $type, $version, $dir, $sqltargs, @rest) = @_;
  $sqltargs ||= {};
  if (! exists $sqltargs->{producer_args}{oracle_version}
      and my $dver = $self->_server_info->{dbms_version}) {
    $sqltargs->{producer_args}{oracle_version} = $dver;
  }
  $self->next::method($schema, $type, $version, $dir, $sqltargs, @rest);
}

sub _ping {
  my $self = shift;
  my $dbh = $self->_dbh or return 0;
  local $dbh->{RaiseError} = 1;
  local $dbh->{PrintError} = 0;
  return try {
    $dbh->do('select 1 from dual');
    1;
  } catch { 0 };
}

sub _dbh_execute {
  my ($self, $sql, $bind) = @_[0,2,3];

  # Turn off sth caching for multi-part LOBs. See _prep_for_execute below
  local $self->{disable_sth_caching} = 1 if grep {
    ($_->[0]{_ora_lob_autosplit_part}||0) > (__cache_queries_with_max_lob_parts - 1)
  } @$bind;

  my $next = $self->next::can;

  # if we are already in a txn we can't retry anything
  return shift->$next(@_) if $self->transaction_depth;

  local $self->{_in_do_block};

  return DBIO::Storage::BlockRunner->new(
    storage => $self,
    wrap_txn => 0,
    retry_handler => sub {
      if ($_[0]->failed_attempt_count == 1
          and $_[0]->last_exception =~ /ORA-01003/
          and my $dbh = $_[0]->storage->_dbh) {
        delete $dbh->{CachedKids}{$sql};
        return 1;
      }
      return 0;
    },
  )->run($next, @_);
}


sub relname_to_table_alias {
  my $self = shift;
  my ($relname, $join_count) = @_;
  my $alias = $self->next::method(@_);
  return $self->sql_maker->_shorten_identifier($alias);
}


# Internal helpers for LOBSupport role (called by the composed subs).
# The LOB-type predicates live in DBIO::Oracle::Type as the single source;
# these thin wrappers preserve the $self->_is_lob_type calling convention.
sub _is_lob_type      { DBIO::Oracle::Type::is_lob_type(@_) }
sub _is_text_lob_type { DBIO::Oracle::Type::is_text_lob_type(@_) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Storage - Oracle Support for DBIO

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

  # In your result (table) classes
  use base 'DBIO::Core';
  __PACKAGE__->add_columns({ id => { sequence => 'mysequence', auto_nextval => 1 } });
  __PACKAGE__->set_primary_key('id');

  # Somewhere in your Code
  # add some data to a table with a hierarchical relationship
  $schema->resultset('Person')->create ({
        firstname => 'foo',
        lastname => 'bar',
        children => [
            {
                firstname => 'child1',
                lastname => 'bar',
                children => [
                    {
                        firstname => 'grandchild',
                        lastname => 'bar',
                    }
                ],
            },
            {
                firstname => 'child2',
                lastname => 'bar',
            },
        ],
    });

  # select from the hierarchical relationship
  my $rs = $schema->resultset('Person')->search({},
    {
      'start_with' => { 'firstname' => 'foo', 'lastname' => 'bar' },
      'connect_by' => { 'parentid' => { '-prior' => { -ident => 'personid' } },
      'order_siblings_by' => { -asc => 'name' },
    };
  );

  # this will select the whole tree starting from person "foo bar", creating
  # following query:
  # SELECT
  #     me.persionid me.firstname, me.lastname, me.parentid
  # FROM
  #     person me
  # START WITH
  #     firstname = 'foo' and lastname = 'bar'
  # CONNECT BY
  #     parentid = prior personid
  # ORDER SIBLINGS BY
  #     firstname ASC

=head1 DESCRIPTION

This class implements base Oracle support. The subclass
L<DBIO::Oracle::Storage::WhereJoins> is for C<(+)> joins in Oracle
versions before 9.0.

=head1 METHODS

=head2 relname_to_table_alias

L<DBIO> uses L<DBIO::Relationship> names as table aliases in queries.

Unfortunately, Oracle doesn't support identifiers over 30 chars in length, so
the L<DBIO::Relationship> name is shortened and appended with half of an
MD5 hash.

See L<DBIO::Storage::DBI/relname_to_table_alias>.

=head2 connect_by or connect_by_nocycle

=over 4

=item Value: \%connect_by

=back

A hashref of conditions used to specify the relationship between parent rows
and child rows of the hierarchy.

  connect_by => { parentid => 'prior personid' }

  # adds a connect by statement to the query:
  # SELECT
  #     me.persionid me.firstname, me.lastname, me.parentid
  # FROM
  #     person me
  # CONNECT BY
  #     parentid = prior persionid


  connect_by_nocycle => { parentid => 'prior personid' }

  # adds a connect by statement to the query:
  # SELECT
  #     me.persionid me.firstname, me.lastname, me.parentid
  # FROM
  #     person me
  # CONNECT BY NOCYCLE
  #     parentid = prior persionid

=head2 start_with

=over 4

=item Value: \%condition

=back

A hashref of conditions which specify the root row(s) of the hierarchy.

It uses the same syntax as L<DBIO::ResultSet/search>

  start_with => { firstname => 'Foo', lastname => 'Bar' }

  # SELECT
  #     me.persionid me.firstname, me.lastname, me.parentid
  # FROM
  #     person me
  # START WITH
  #     firstname = 'foo' and lastname = 'bar'
  # CONNECT BY
  #     parentid = prior persionid

=head2 order_siblings_by

=over 4

=item Value: ($order_siblings_by | \@order_siblings_by)

=back

Which column(s) to order the siblings by.

It uses the same syntax as L<DBIO::ResultSet/order_by>

  'order_siblings_by' => 'firstname ASC'

  # SELECT
  #     me.persionid me.firstname, me.lastname, me.parentid
  # FROM
  #     person me
  # CONNECT BY
  #     parentid = prior persionid
  # ORDER SIBLINGS BY
  #     firstname ASC

=head1 ATTRIBUTES

Following additional attributes can be used in resultsets.

=head1 SEE ALSO

=over

=item * L<DBIO::Oracle> - Oracle schema component

=item * L<DBIO::Oracle::SQLMaker> - Oracle SQL dialect

=item * L<DBIO::Oracle::Storage::WhereJoins> - WHERE-clause join support for Oracle E<lt> 9

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
