package DBIO::PostgreSQL::Diff::Policy;
# ABSTRACT: Diff operations for PostgreSQL Row Level Security policies

use strict;
use warnings;

use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(table_key policy_name policy_info));






sub diff {
  my ($class, $source_pol, $target_pol, $source_tables, $target_tables) = @_;
  my @ops;

  # RLS enable/disable changes on tables
  for my $key (sort keys %$target_tables) {
    next unless exists $source_tables->{$key};
    my $src = $source_tables->{$key};
    my $tgt = $target_tables->{$key};

    if (!$src->{rls_enabled} && $tgt->{rls_enabled}) {
      push @ops, $class->new(
        action    => 'enable_rls',
        table_key => $key,
      );
    }
    elsif ($src->{rls_enabled} && !$tgt->{rls_enabled}) {
      push @ops, $class->new(
        action    => 'disable_rls',
        table_key => $key,
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
        policy_name => $name,
        policy_info => $src_pols->{$name},
      );
    }
  }

  return @ops;
}


sub as_sql {
  my ($self) = @_;

  if ($self->action eq 'enable_rls') {
    return sprintf 'ALTER TABLE %s ENABLE ROW LEVEL SECURITY;', $self->table_key;
  }
  elsif ($self->action eq 'disable_rls') {
    return sprintf 'ALTER TABLE %s DISABLE ROW LEVEL SECURITY;', $self->table_key;
  }
  elsif ($self->action eq 'create') {
    my $info = $self->policy_info;
    my $sql = sprintf 'CREATE POLICY %s ON %s', $self->policy_name, $self->table_key;
    $sql .= sprintf ' FOR %s', $info->{command} if $info->{command} && $info->{command} ne 'ALL';
    $sql .= sprintf ' USING (%s)', $info->{using_expr} if $info->{using_expr};
    $sql .= sprintf ' WITH CHECK (%s)', $info->{check_expr} if $info->{check_expr};
    return "$sql;";
  }
  elsif ($self->action eq 'drop') {
    return sprintf 'DROP POLICY %s ON %s;', $self->policy_name, $self->table_key;
  }
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

version 0.900001

=head1 DESCRIPTION

Represents a Row Level Security diff operation: C<CREATE POLICY>, C<DROP
POLICY>, C<ENABLE ROW LEVEL SECURITY>, or C<DISABLE ROW LEVEL SECURITY>. RLS
enable/disable changes on tables are detected by comparing the C<rls_enabled>
flag from table introspection.

=head1 ATTRIBUTES

=head2 table_key

The C<schema.table> key identifying the table.

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

=head2 as_sql

Returns the SQL for this operation: C<ALTER TABLE ... ENABLE/DISABLE ROW LEVEL
SECURITY>, C<CREATE POLICY ...>, or C<DROP POLICY ... ON ...>.

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
