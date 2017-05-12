package DBIx::PgLink::Accessor::Table;

# wish I can use SQL::Interpolate or real ORM, but DBIx::PgLink::Local is not real DBI :(

use Carp;
use Moose;
use MooseX::Method;
use Data::Dumper;
use DBIx::PgLink::Local;
use DBIx::PgLink::Logger;
use DBIx::PgLink::Types;
use DBIx::PgLink::Accessor::TableColumns;

our $VERSION = '0.01';


extends 'DBIx::PgLink::Accessor::BaseAccessor';

with 'DBIx::PgLink::Accessor::HasColumns';

has '+columns_class' => (default=>'DBIx::PgLink::Accessor::TableColumns');

with 'DBIx::PgLink::Accessor::HasQueries';



# class method, enumerates remote TABLEs/VIEWs and create accessor for each
sub _implement_build_accessors {
  my ($class, $p) = @_;

  my $objects = $p->{connector}->adapter->table_info_arrayref(
    $p->{remote_catalog},
    $p->{remote_schema},
    $p->{remote_object},
    $p->{remote_object_type},
  ) or return 0;

  my $cnt = 0;
  for my $obj (@{$objects}) {

    my $local_object = $p->{object_name_mapping}->{$obj->{TABLE_NAME}}
                    || $obj->{TABLE_NAME};

    my $accessor = $class->new_from_remote_metadata({
      %{$p},
      %{$obj},
      local_object => $local_object,
    });

    $cnt += $accessor->build;
  }
  return $cnt;
};


# constructor
sub new_from_remote_metadata {
  my ($class, $meta) = @_;
  my $connector = delete $meta->{connector};
  return $class->new(
    %{$meta},
    connector          => $connector,
    remote_catalog     => $meta->{TABLE_CAT},
    remote_schema      => $meta->{TABLE_SCHEM},
    remote_object      => $meta->{TABLE_NAME},
    remote_object_type => $meta->{TABLE_TYPE},
    table_info         => $meta,
  );
}


# -------------------------------------------------------

has 'table_info' => ( is=>'ro', isa=>'HashRef' ); # passed by build_accessors

# NAMES

my %name_attr = (is=>'ro', isa=>'Str', lazy=>1);

# name without schema or quoting
has 'function'           => (%name_attr, default=>sub{ $_[0]->local_object . '$' });
  # $-suffix to prevent collision with remote function accessor
has 'view'               => (%name_attr, default=>sub{ $_[0]->local_object });
has 'rowtype'            => (%name_attr, default=>sub{ $_[0]->local_object . '_rowtype' });
has 'shadow_table'       => (%name_attr, default=>sub{ $_[0]->local_object . '_shadow' });
has 'shadow_row_trigger' => (%name_attr, default=>sub{ $_[0]->local_object . '_trg_row' });
has 'shadow_bs_trigger'  => (%name_attr, default=>sub{ $_[0]->local_object . '_trg_bs' });
has 'shadow_as_trigger'  => (%name_attr, default=>sub{ $_[0]->local_object . '_trg_as' });
has 'insert_rule'        => (%name_attr, default=>sub{ $_[0]->local_object . '_insert' });
has 'update_rule'        => (%name_attr, default=>sub{ $_[0]->local_object . '_update' });
has 'delete_rule'        => (%name_attr, default=>sub{ $_[0]->local_object . '_delete' });

# full qualified, double-quoted name
has 'view_quoted'         => (%name_attr, default=>sub{ $_[0]->QLIS($_[0]->view) } );
has 'rowtype_quoted'      => (%name_attr, default=>sub{ $_[0]->QLIS($_[0]->rowtype) } );
has 'function_quoted'     => (%name_attr, default=>sub{ $_[0]->QLIS($_[0]->function) } );
has 'shadow_table_quoted' => (%name_attr, default=>sub{ $_[0]->QLIS($_[0]->shadow_table) } );

# function signature (with args)
has 'function3_quoted_sign' => (%name_attr, default=>sub{ $_[0]->function_quoted . '(TEXT,TEXT[],TEXT[])' });
has 'function0_quoted_sign' => (%name_attr, default=>sub{ $_[0]->function_quoted . '()' });

# rule and trigger don't need schema
has 'shadow_row_trigger_quoted' => (%name_attr, default=>sub{ $_[0]->QLI($_[0]->shadow_row_trigger) } );
has 'shadow_bs_trigger_quoted'  => (%name_attr, default=>sub{ $_[0]->QLI($_[0]->shadow_bs_trigger) } );
has 'shadow_as_trigger_quoted'  => (%name_attr, default=>sub{ $_[0]->QLI($_[0]->shadow_as_trigger) } );
has 'insert_rule_quoted'        => (%name_attr, default=>sub{ $_[0]->QLI($_[0]->insert_rule) } );
has 'update_rule_quoted'        => (%name_attr, default=>sub{ $_[0]->QLI($_[0]->update_rule) } );
has 'delete_rule_quoted'        => (%name_attr, default=>sub{ $_[0]->QLI($_[0]->delete_rule) } );

# additional functions (query filter)
has 'function_set_filter' => (%name_attr, default=>sub{ $_[0]->local_object . '_set_filter' });
has 'function_reset_filter' => (%name_attr, default=>sub{ $_[0]->local_object . '_reset_filter' });

has 'function_set_filter_quoted_sign' => (%name_attr, 
  default=>sub{ $_[0]->QLIS($_[0]->function_set_filter) . '(TEXT,TEXT[],TEXT[])' });
has 'function_reset_filter_quoted_sign' => (%name_attr, 
  default=>sub{ $_[0]->QLIS($_[0]->function_reset_filter) . '()' });


sub create_metadata {
  my $self = shift;

  $self->columns->require_quoted_names;

  die "Cannot detect columns of ".$self->remote_object_quoted 
    unless @{$self->columns->metadata};

  $self->create_query( $self->_select_query );
  $self->create_query( $self->_insert_query );
  $self->create_query( $self->_update_query );
  $self->create_query( $self->_delete_query );
}


sub _select_query {
  my $self = shift;

  my @columns = $self->columns->metadata;

  return {
    query_text  => <<END_OF_SQL,
SELECT *
FROM @{[ $self->remote_object_quoted ]}
END_OF_SQL
    action      => 'S',
    params      => [],
  };
}


sub _insert_query {
  my $self = shift;

  my @columns = grep { $_->{insertable} } $self->columns->metadata;
  my @params = map { { column_name => $_->{new_column_name}, meta => $_ } } @columns;

  return {
    query_text  => <<END_OF_SQL,
INSERT INTO @{[ $self->remote_object_quoted ]} (
  @{[ join ", ", map { $_->{remote_column_quoted} } @columns ]}
) VALUES (
  @{[ join ", ", map { "?" } @columns ]}
)
END_OF_SQL
    action      => 'I',
    params      => \@params,
  };
}


sub _update_query {
  my $self = shift;

  my @columns = grep { $_->{updatable} } $self->columns->metadata;
  my @params = map { { column_name => $_->{new_column_name}, meta => $_ } } @columns;
  my $where = $self->_where_clause(\@params);

  return {
    query_text  => <<END_OF_SQL,
UPDATE @{[ $self->remote_object_quoted ]} SET
  @{[ join ",\n  ", map { "$_->{remote_column_quoted} = ?" } @columns ]}
WHERE $where
END_OF_SQL
    action      => 'U',
    params      => \@params,
  };
}


sub _delete_query {
  my $self = shift;

  my @params = ();
  my $where = $self->_where_clause(\@params);

  return {
    query_text  => <<END_OF_SQL,
DELETE FROM @{[ $self->remote_object_quoted ]}
WHERE $where
END_OF_SQL
    action      => 'D',
    params      => \@params,
  };

}


sub _where_clause {
  my ($self, $params) = @_;

  my @where;
  for my $f (grep { $_->{searchable} } $self->columns->metadata) {
    if ($f->{nullable}) {
      push @where, "($f->{remote_column_quoted} = ? OR ($f->{remote_column_quoted} IS NULL AND ? IS NULL))";
      push @{$params},
        ({ column_name => $f->{old_column_name}, meta => $f }) x 2;
    } else {
      push @where, "$f->{remote_column_quoted} = ?";
      push @{$params},
        { column_name => $f->{old_column_name}, meta => $f };
    }
  }
  return join("\n  AND ", @where);
};



sub create_local_objects {
  my $self = shift;

  $self->create_rowtype; # by HasColumns role
  $self->create_functions;
  $self->create_view;
  $self->create_shadow_table;
  $self->create_rules;

  return 1;
};


sub drop_local_objects {
  my $self = shift;

  for my $obj (
    ['VIEW',      $self->view_quoted],         # cascade to rules
    ['TABLE',     $self->shadow_table_quoted], # cascade to triggers
    ['FUNCTION',  $self->function0_quoted_sign],
    ['FUNCTION',  $self->function3_quoted_sign],
    ['FUNCTION',  $self->function_set_filter_quoted_sign],
    ['FUNCTION',  $self->function_reset_filter_quoted_sign],
    ['TYPE',      $self->rowtype_quoted],
  ) {
    pg_dbh->do("DROP $obj->[0] IF EXISTS $obj->[1]");
  }
};


sub _create_function {
  my ($self, $name, $query, $purpose) = @_;

  pg_dbh->do($query, {types=>[]});

  pg_dbh->do(<<END_OF_SQL);
REVOKE ALL ON FUNCTION $name FROM public;
END_OF_SQL

  $self->create_comment(
    type    => "FUNCTION",
    name    => $name,
    comment => $purpose . " for remote " . $self->remote_object_type . " " . $self->remote_object_quoted,
  );
  trace_msg('INFO', "Created function $name")
    if trace_level >= 1;
}


sub create_functions {
  my $self = shift;

  # (where,param_values,param_types)
  $self->_create_function($self->function3_quoted_sign, <<END_OF_SQL, 'SELECT function');
CREATE OR REPLACE FUNCTION @{[ $self->function3_quoted_sign ]}
RETURNS SETOF @{[ $self->rowtype_quoted ]}
SECURITY DEFINER
LANGUAGE plperlu
AS \$method_body\$
  use DBIx::PgLink;
  DBIx::PgLink->connect(
    @{[ $self->perl_quote($self->conn_name) ]}
  )->remote_accessor_query(
    object_id    => @{[ $self->object_id ]},
    where        => \$_[0],
    defined \$_[1] ? (param_values => \$_[1]) : (),
    defined \$_[2] ? (param_types  => \$_[2]) : (),
  );
\$method_body\$
END_OF_SQL

  # ()
  $self->_create_function($self->function0_quoted_sign, <<END_OF_SQL, 'SELECT function');
CREATE OR REPLACE FUNCTION @{[ $self->function0_quoted_sign ]}
RETURNS SETOF @{[ $self->rowtype_quoted ]}
SECURITY DEFINER
LANGUAGE sql
AS \$method_body\$
  SELECT * FROM @{[ $self->function_quoted ]}(''::text, NULL::text[], NULL::text[])
\$method_body\$
END_OF_SQL


  # set query filter
  $self->_create_function($self->function_set_filter_quoted_sign, <<END_OF_SQL, 'Set query filter');
CREATE OR REPLACE FUNCTION @{[ $self->function_set_filter_quoted_sign ]}
RETURNS void
SECURITY DEFINER
LANGUAGE plperlu
AS \$method_body\$
  use DBIx::PgLink;
  DBIx::PgLink->connect(
    @{[ $self->perl_quote($self->conn_name) ]}
  )->set_query_session_filter(
    object_id    => @{[ $self->object_id ]},
    where        => \$_[0],
    defined \$_[1] ? (param_values => \$_[1]) : (),
    defined \$_[2] ? (param_types  => \$_[2]) : (),
  );
\$method_body\$
END_OF_SQL

  # reset query filter
  $self->_create_function($self->function_reset_filter_quoted_sign, <<END_OF_SQL, 'Reset query filter');
CREATE OR REPLACE FUNCTION @{[ $self->function_reset_filter_quoted_sign ]}
RETURNS void
SECURITY DEFINER
LANGUAGE plperlu
AS \$method_body\$
  use DBIx::PgLink;
  DBIx::PgLink->connect(
    @{[ $self->perl_quote($self->conn_name) ]}
  )->reset_query_session_filter(
    object_id    => @{[ $self->object_id ]},
  );
\$method_body\$
END_OF_SQL

}


sub create_view {
  my $self = shift;

  pg_dbh->do(<<END_OF_SQL);
CREATE VIEW @{[ $self->view_quoted ]} AS
SELECT * FROM @{[ $self->function_quoted ]}()
END_OF_SQL
  $self->create_comment(
    type    => "VIEW",
    name    => $self->view_quoted,
    comment => "Access for remote table " . $self->remote_object_quoted,
  );
  trace_msg('INFO', "Created view " . $self->view_quoted)
    if trace_level >= 1;
}


sub create_shadow_table {
  my $self = shift;

  pg_dbh->do(<<END_OF_SQL);
CREATE TABLE @{[ $self->shadow_table_quoted ]} (
  action CHAR(1) NOT NULL CHECK (action in ('I','U','D')),
  @{[ join ",\n", map { "$_->{old_column_quoted} $_->{local_type}" } $self->columns->metadata ]},
  @{[ join ",\n", map { "$_->{new_column_quoted} $_->{local_type}" } $self->columns->metadata ]}
)
END_OF_SQL
  $self->create_comment(
    type    => "TABLE",
    name    => $self->shadow_table_quoted,
    comment => "Shadow table for modification of remote " . $self->remote_object_type . " " . $self->remote_object_quoted,
  );
  trace_msg('INFO', "Created table " . $self->shadow_table_quoted)
    if trace_level >= 2;

  my $conn_name_literal = pg_dbh->quote($self->conn_name);

  # row trigger
  pg_dbh->do(<<END_OF_SQL);
CREATE TRIGGER @{[ $self->shadow_row_trigger_quoted ]}
  BEFORE INSERT ON @{[ $self->shadow_table_quoted ]}
  FOR EACH ROW
  EXECUTE PROCEDURE dbix_pglink.shadow_row_trigger_func($conn_name_literal, $self->{object_id})
END_OF_SQL
  trace_msg('INFO', "Created row trigger on " . $self->shadow_table_quoted)
    if trace_level >= 2;

  # before statement trigger
  pg_dbh->do(<<END_OF_SQL);
CREATE TRIGGER @{[ $self->shadow_bs_trigger_quoted ]}
  BEFORE INSERT ON @{[ $self->shadow_table_quoted ]}
  FOR EACH STATEMENT
  EXECUTE PROCEDURE dbix_pglink.shadow_stmt_trigger_func($conn_name_literal, $self->{object_id})
END_OF_SQL
  trace_msg('INFO', "Created before statement trigger on " . $self->shadow_table_quoted)
    if trace_level >= 2;

  # after statement trigger
  pg_dbh->do(<<END_OF_SQL);
CREATE TRIGGER @{[ $self->shadow_as_trigger_quoted ]}
  AFTER INSERT ON @{[ $self->shadow_table_quoted ]}
  FOR EACH STATEMENT
  EXECUTE PROCEDURE dbix_pglink.shadow_stmt_trigger_func($conn_name_literal, $self->{object_id})
END_OF_SQL
  trace_msg('INFO', "Created after statement trigger on " . $self->shadow_table_quoted)
    if trace_level >= 2;

}


sub create_rules {
  my $self = shift;

  my $nulls = join(", ", map {'NULL'} $self->columns->metadata);

  pg_dbh->do(<<END_OF_SQL);
CREATE RULE @{[ $self->insert_rule_quoted ]}  AS
ON INSERT TO @{[ $self->view_quoted ]} DO INSTEAD
INSERT INTO @{[ $self->shadow_table_quoted ]} VALUES ('I', $nulls, NEW.*)
END_OF_SQL
  trace_msg('INFO', "Created rule " . $self->insert_rule_quoted)
    if trace_level >= 2;

  pg_dbh->do(<<END_OF_SQL);
CREATE RULE @{[ $self->update_rule_quoted ]} AS
ON UPDATE TO @{[ $self->view_quoted ]} DO INSTEAD
INSERT INTO @{[ $self->shadow_table_quoted ]} VALUES ('U', OLD.*, NEW.*)
END_OF_SQL
  trace_msg('INFO', "Created rule " . $self->update_rule_quoted)
    if trace_level >= 2;

  pg_dbh->do(<<END_OF_SQL);
CREATE RULE @{[ $self->delete_rule_quoted ]} AS
ON DELETE TO @{[ $self->view_quoted ]} DO INSTEAD
INSERT INTO @{[ $self->shadow_table_quoted ]} VALUES ('D', OLD.*, $nulls)
END_OF_SQL
  trace_msg('INFO', "Created rule " . $self->delete_rule_quoted)
    if trace_level >= 2;

}



# ----------------------------------------------------------


method update_statistics => named (
  execution_cost => { isa => 'Num', required => 1 },
) => sub {
  my ($self, $p) = @_;

  croak 'Per-function cost settings available starting from PostgreSQL 8.3'
    if pg_dbh->pg_server_version < 80300;

  my $cnt = 0;

  my $adapter = $self->connector->adapter;

  $self->create_names;

  trace_msg('INFO', "counting rows of " . $self->remote_object_quoted . " at " . $self->conn_name)
    if trace_level >= 1;

  my $rows = $adapter->get_number_of_rows(
    $self->remote_catalog,
    $self->remote_schema,
    $self->remote_object,
    $self->remote_object_type
  );
  if (!defined $rows) {
    trace_msg('WARNING', "Cannot get row count of " . $self->remote_object_type
      . " " . $self->remote_object_quoted . " at " . $self->conn_name);
    return;
  }

  pg_dbh->do(<<END_OF_SQL);
ALTER FUNCTION @{[ $self->function_quoted_sign ]}
COST $p->{execution_cost}
ROWS $rows
END_OF_SQL

};


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

DBIx::PgLink::Accessor::Table - accessor for table/view

=head1 DESCRIPTION

Enumerate tables/views in remote database.

Creates set of local database object that supports DML operations on remote table
as if it is local table.

Enumerate existing accessors in local database.

=head2 List of local objects

=over

=item 1.

Composite type

Represent row of remote table. Field types are mapped to PostgreSQL types.

=item 2.

Set of functions

PL/Perl function execute SELECT query on remote table and fetch data to PostgreSQL.
One function has no parameters and fetch all data, others accept WHERE clause, 
optional parameter values list and optional parameter types list.

Name of function suffixed with "$" to minimize name clash with remote function accessor.

=item 3.

View

Wraps function that fetch all data.

=item 4.

Insert, update and delete rules on view

Translate any modification of view to insert into shadow table.

=item 5.

Shadow table

Proxy object. Contains no real data.

=item 6.

Trigger on shadow table

Fire PL/Perl function on every row inserted to shadow table.
That function transfer data modification to remote table.

=back

For each object C<build> method creates 4 queries - for SELECT, INSERT, UPDATE and DELETE.
Queries are stored in I<dbix_pglink.queries> table.
You can manually change it or modify I<dbix_pglink.columns>
metadata table and call I<dbix_pglink.rebuild_accessors()> function.

Columns marked with I<searchable> attrribute in I<dbix_pglink.columns> used in
WHERE condition of UPDATE and DELETE statements to locate changed row.
If remote table has primary key, it used as search key.
All columns are supposed searchable if no primary key exists
or driver can't recognize primary key.


Remote modification statements are executed in transaction,
started in statement BEFORE-trigger
and commited in statement AFTER-trigger.

=head1 METHODS

=over

=item C<update_statistics>

  $accessor->update_statistics(
    execution_cost => 220
  );

Counts number of rows for each corresponding remote table
and assign row count and estimated execution cost
to local PL/Perl function.

Requires local PostgreSQL server version 8.3 or later.

=back

=head1 CAVEATS

=over

=item *

All rows are fetched for any SELECT, UPDATE or DELETE operation

Currently there is no way to supply dynamic condition to view/function.
To limit number of fetched rows you can manually add static condition to function call in view.

This is a major flaw both in I<dbi_link> project and I<DBIx::PgLink>.

B<Do not issue SELECT, UPDATE, DELETE on large tables (i.e. more than 10_000 rows on fast network)>

For SELECT use accessor function with WHERE clause as argument,
for UPDATE and DELETE use I<dbix_pglink.remote_do> function.

INSERT query is relatively fast (but ~2x-times slower than plain DBI).

=item *

Remote transaction stalls, if error occured at local database

You need explicitly call SELECT dbix_pglink.rollback() at exception handler in your application code.

=back

=head1 SEE ALSO

L<DBIx::PgLink::Accessor::BaseAccessor>

=head1 AUTHOR

Alexey Sharafutdinov E<lt>alexey.s.v.br@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
