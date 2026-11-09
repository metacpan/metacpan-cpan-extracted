package DBIO::PostgreSQL::Diff::Policy;
# ABSTRACT: Diff operations for PostgreSQL Row Level Security policies

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::PostgreSQL::Diff::NoStatement ();
use DBIO::PostgreSQL::Introspect ();
use DBIO::PostgreSQL::Util qw(quote_ident quote_qualified quote_role);

__PACKAGE__->mk_diff_accessors(qw(
  table_key schema_name table_name policy_name policy_info
));








# The schema_name / table_name pair of an operation, from the entries filed
# under the table key.
sub _table_names {
  my ($table_key, @entries) = @_;
  my ($table_name, $schema_name) = reverse
    DBIO::PostgreSQL::Introspect->key_names($table_key, table_name => @entries);
  return (schema_name => $schema_name, table_name => $table_name);
}

sub diff {
  my ($class, $source_pol, $target_pol, $source_tables, $target_tables) = @_;
  my @ops;

  # RLS enable/disable changes on tables
  for my $key (sort keys %$target_tables) {
    # A table that is created in this diff starts without row level security.
    my $src = $source_tables->{$key} // {};
    my $tgt = $target_tables->{$key};

    if (!$src->{rls_enabled} && $tgt->{rls_enabled}) {
      push @ops, $class->new(
        action    => 'enable_rls',
        table_key => $key,
        _table_names($key, $tgt, $src),
      );
    }
    elsif ($src->{rls_enabled} && !$tgt->{rls_enabled}) {
      push @ops, $class->new(
        action    => 'disable_rls',
        table_key => $key,
        _table_names($key, $tgt, $src),
      );
    }
  }

  # Policy diffs
  for my $table_key (sort keys %$target_pol) {
    my $src_pols = $source_pol->{$table_key} // {};
    my $tgt_pols = $target_pol->{$table_key};

    for my $name (sort keys %$tgt_pols) {
      if (!exists $src_pols->{$name}) {
        push @ops, $class->new(
          action      => 'create',
          table_key   => $table_key,
          _table_names($table_key, $tgt_pols->{$name}, $target_tables->{$table_key}),
          policy_name => $name,
          policy_info => $tgt_pols->{$name},
        );
      }
    }
  }

  for my $table_key (sort keys %$source_pol) {
    my $src_pols = $source_pol->{$table_key};
    my $tgt_pols = $target_pol->{$table_key} // {};

    for my $name (sort keys %$src_pols) {
      next if exists $tgt_pols->{$name};
      push @ops, $class->new(
        action      => 'drop',
        table_key   => $table_key,
        _table_names($table_key, $src_pols->{$name}, $source_tables->{$table_key}),
        policy_name => $name,
        policy_info => $src_pols->{$name},
      );
    }
  }

  return @ops;
}


sub as_sql {
  my ($self) = @_;
  my $table = quote_qualified(
    DBIO::PostgreSQL::Introspect->key_names($self->table_key, table_name => $self));

  if ($self->action eq 'enable_rls') {
    return sprintf 'ALTER TABLE %s ENABLE ROW LEVEL SECURITY;', $table;
  }
  elsif ($self->action eq 'disable_rls') {
    return sprintf 'ALTER TABLE %s DISABLE ROW LEVEL SECURITY;', $table;
  }
  elsif ($self->action eq 'create') {
    my $info = $self->policy_info;
    my $sql = sprintf 'CREATE POLICY %s ON %s', quote_ident($self->policy_name), $table;
    $sql .= ' AS RESTRICTIVE' if defined $info->{permissive} && !$info->{permissive};
    $sql .= sprintf ' FOR %s', $info->{command} if $info->{command} && $info->{command} ne 'ALL';
    if ($info->{roles} && @{ $info->{roles} }) {
      $sql .= sprintf ' TO %s', join(', ', map { quote_role($_) } @{ $info->{roles} });
    }
    $sql .= sprintf ' USING (%s)', $info->{using_expr} if $info->{using_expr};
    $sql .= sprintf ' WITH CHECK (%s)', $info->{check_expr} if $info->{check_expr};
    return "$sql;";
  }
  elsif ($self->action eq 'drop') {
    return sprintf 'DROP POLICY %s ON %s;', quote_ident($self->policy_name), $table;
  }
  DBIO::PostgreSQL::Diff::NoStatement->throw(
    $self,
    ( defined $self->policy_name ? 'policy ' . $self->policy_name . ' on ' : 'table ' )
      . ($self->table_key // ''),
  );
}


sub summary {
  my ($self) = @_;
  if ($self->action =~ /rls/) {
    return sprintf '  %s: RLS on %s', $self->action, $self->table_key;
  }
  my $prefix = $self->action eq 'create' ? '+' : '-';
  return sprintf '  %spolicy: %s on %s', $prefix, $self->policy_name, $self->table_key;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff::Policy - Diff operations for PostgreSQL Row Level Security policies

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a Row Level Security diff operation: C<CREATE POLICY>, C<DROP
POLICY>, C<ENABLE ROW LEVEL SECURITY>, or C<DISABLE ROW LEVEL SECURITY>. RLS
enable/disable changes on tables are detected by comparing the C<rls_enabled>
flag from table introspection.

=head1 ATTRIBUTES

=head2 table_key

The C<schema.table> key identifying the table. It is where the model files
the table, and what L</summary> prints; it is not SQL.

=head2 schema_name

The schema of that table.

=head2 table_name

The name of that table. L</as_sql> writes the table from C<schema_name> and
C<table_name>, each quoted for itself -- the key cannot be taken apart again,
a schema or a table may have a dot in its name. L</diff> takes both from the
policy entry or the C<tables> sections. An operation built by hand without
them falls back to the key (L<DBIO::PostgreSQL::Introspect/key_names>).

=head2 policy_name

The policy name (not set for C<enable_rls> / C<disable_rls> operations).

=head2 policy_info

Policy metadata hashref (C<command>, C<permissive>, C<using_expr>,
C<check_expr>, C<roles>).

=head1 METHODS

=head2 diff

    my @ops = DBIO::PostgreSQL::Diff::Policy->diff(
        $source_pol, $target_pol, $source_tables, $target_tables,
    );

Compares RLS state and policy sets. Detects RLS enable/disable changes on
existing tables, new policies, and dropped policies.

A table that only the target has, with row level security enabled, gets its
C<ENABLE ROW LEVEL SECURITY> here as well, ahead of its policies:
L<DBIO::PostgreSQL::Diff::Table> creates the table and no more, and policies
on a table without row level security apply to nobody.

=head2 as_sql

Returns the SQL for this operation: C<ALTER TABLE ... ENABLE/DISABLE ROW LEVEL
SECURITY>, C<CREATE POLICY ...>, or C<DROP POLICY ... ON ...>.

C<CREATE POLICY> writes what the policy's entry holds: C<AS RESTRICTIVE> when
C<permissive> is defined and false, C<FOR> the command unless it is C<ALL>,
C<TO> the C<roles>, C<USING> and C<WITH CHECK>. A policy without C<roles> --
the catalog has none for a policy that is for everybody -- gets no C<TO>,
which is C<PUBLIC>.

Policy and table are identifiers by the server's rule
(L<DBIO::PostgreSQL::Util/quote_ident>), and so is every role
(L<DBIO::PostgreSQL::Util/quote_role>, which leaves C<PUBLIC> and the other
key words that stand for a role as they are). The C<USING> and C<WITH CHECK>
expressions come from the catalog (C<pg_get_expr>) and are written as given.

For an C<action> this class does not know it dies
(L<DBIO::PostgreSQL::Diff::NoStatement/throw>).

=head2 summary

Returns a one-line description such as C<+policy: users_own_data on auth.users>
or C<enable_rls on auth.users>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
