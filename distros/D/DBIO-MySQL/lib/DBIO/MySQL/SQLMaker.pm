package DBIO::MySQL::SQLMaker;
# ABSTRACT: MySQL-specific SQL generation for DBIO

use warnings;
use strict;

use base qw( DBIO::SQLMaker );

use Text::Balanced ();



sub apply_limit {
    my ( $self, $sql, $rs_attrs, $rows, $offset ) = @_;
    $sql .= $self->_parse_rs_attrs( $rs_attrs ) . " LIMIT ";
    if ($offset) {
      $sql .= '?, ';
      push @{$self->{limit_bind}}, [ $self->__offset_bindtype => $offset ];
    }
    $sql .= '?';
    push @{$self->{limit_bind}}, [ $self->__rows_bindtype => $rows ];

    return $sql;
}

#
# MySQL does not understand the standard INSERT INTO $table DEFAULT VALUES
# Adjust SQL here instead
#
sub insert {
  my $self = shift;

  if (! $_[1] or (ref $_[1] eq 'HASH' and !keys %{$_[1]} ) ) {
    my $table = $self->_quote($_[0]);
    return "INSERT INTO ${table} () VALUES ()"
  }

  return $self->next::method (@_);
}


# Allow STRAIGHT_JOIN's
sub _generate_join_clause {
    my ($self, $join_type) = @_;

    if( $join_type && $join_type =~ /^STRAIGHT\z/i ) {
        return ' STRAIGHT_JOIN '
    }

    return $self->next::method($join_type);
}

sub _wrap_self_referencing_subquery {
  my ($self, $sql, $target_name) = @_;

  return $sql unless $target_name;

  my $re = qr/ (?<!DELETE) [\s\)] (?: FROM | JOIN ) \s (?: \` \Q$target_name\E \` | \Q$target_name\E ) [\s\(] /xi;

  return $sql unless $sql =~ $re;

  my $new_sql;
  while (1) {

    my ($prefix, $parenthesized);

    ($parenthesized, $sql, $prefix) = do {
      # idiotic design - writes to $@ but *DOES NOT* throw exceptions
      local $@;
      Text::Balanced::extract_bracketed( $sql, '()', qr/[^\(]*/ );
    };

    # this is how an error is indicated, in addition to crapping in $@
    last unless $parenthesized;

    if ($parenthesized =~ $re) {
      # is this a select subquery?
      if ( $parenthesized =~ /^ \( \s* SELECT \s+ /xi ) {
        $parenthesized = "( SELECT * FROM $parenthesized `_forced_double_subquery` )";
      }
      # then drill down until we find it (if at all)
      else {
        $parenthesized =~ s/^ \( (.+) \) $/$1/x;
        $parenthesized = join ' ', '(', $self->_wrap_self_referencing_subquery( $parenthesized, $target_name ), ')';
      }
    }

    $new_sql .= $prefix . $parenthesized;
  }

  return $new_sql . $sql;
}

sub update {
  my $self = shift;
  my ($target, $source, $attributes) = @_;

  my ($sql, @bind) = $self->next::method(@_);

  # Extract target table name for self-referencing detection
  my $target_name = $self->_extract_target_name($target);

  $sql = $self->_wrap_self_referencing_subquery($sql, $target_name) if $target_name;

  return ($sql, @bind);
}

sub delete {
  my $self = shift;
  my ($target, $source, $attributes) = @_;

  my ($sql, @bind) = $self->next::method(@_);

  # Extract target table name for self-referencing detection
  my $target_name = $self->_extract_target_name($target);

  $sql = $self->_wrap_self_referencing_subquery($sql, $target_name) if $target_name;

  return ($sql, @bind);
}

sub _extract_target_name {
  my ($self, $target) = @_;

  return unless defined $target;

  if (ref $target eq 'SCALAR') {
    if ($$target =~ /^ (?:
        \` ( [^`]+ ) \` #`
      | ( [\w\-]+ )
    ) $/x
    ) {
      return (defined $1) ? $1 : $2;
    }
    return; # complex scalar ref, can't deal
  }

  # For HASH refs (simple result source) or plain strings, return as-is
  return ref $target ? undef : $target;
}


#
# Support for MySQL lock clause syntax according to specification
# including updates introduced in MySQL 8.0.1)
# FOR UPDATE | FOR SHARE [OF tbl_name [, tbl_name] ...] [NOWAIT | SKIP LOCKED]
#

my $lock_types = {
  update => 'FOR UPDATE',
  share => 'FOR SHARE',
};

my $lock_modifiers = {
  nowait => 'NOWAIT',
  skip_locked => 'SKIP LOCKED'
};

sub _lock_select {
  my ($self, $type) = @_;

  # Handle hash-based configuration to support new featureset
  if (ref $type eq 'HASH') {
    my $lock_type = $type->{type};
    my $tables = $type->{of};
    my $modifier = $type->{modifier};

    my $lock_clause = $lock_types->{$lock_type}
      || $self->throw_exception("Unknown SELECT .. FOR type '$lock_type' requested");

    # Add OF clause if tables are specified
    if ($tables) {
      my @table_list = ref $tables eq 'ARRAY' ? @$tables : ($tables);
      if (@table_list) {
        my $quoted_tables = join(', ',
          map { $self->_quote($_) } @table_list
        );
        $lock_clause .= " OF $quoted_tables";
      }
    }

    # Add modifier if specified
    if ($modifier) {
      my $mod_sql = $lock_modifiers->{$modifier}
        || $self->throw_exception("Unknown lock modifier '$modifier' requested");
      $lock_clause .= " $mod_sql";
    }

    return " $lock_clause";
  }

  # Handle simple string types (for backward compatibility)
  my $sql = $lock_types->{$type}
    || $self->throw_exception("Unknown SELECT .. FOR type '$type' requested");

  return " $sql";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::SQLMaker - MySQL-specific SQL generation for DBIO

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

  # Used automatically by DBIO::MySQL::Storage — no manual setup needed.

=head1 DESCRIPTION

MySQL-specific SQL generation layer for L<DBIO>. Extends L<DBIO::SQLMaker>
with the following MySQL adaptations:

=over 4

=item *

C<INSERT> with no columns emits C<INSERT INTO t () VALUES ()> instead of
the standard C<INSERT INTO t DEFAULT VALUES>, which MySQL does not support.

=item *

Supports C<STRAIGHT_JOIN> as a join type hint via the C<join_type> result
source attribute.

=item *

C<UPDATE> and C<DELETE> statements that reference the modification target
table in a subquery are automatically wrapped in a double subquery to work
around MySQL's restriction against self-referencing in DML.

=item *

Implements MySQL's C<SELECT ... FOR UPDATE / FOR SHARE> locking syntax,
including the C<OF tbl_name>, C<NOWAIT>, and C<SKIP LOCKED> clauses
introduced in MySQL 8.0.1.

=back

=head1 METHODS

=head2 apply_limit

Uses MySQL's C<LIMIT [offset,] rows> syntax instead of the standard
C<LIMIT rows OFFSET offset>.

=head2 insert

Overrides the standard C<INSERT> to emit C<INSERT INTO t () VALUES ()> for
rows with no column values, satisfying MySQL's syntax requirements.

=head2 update

=head2 delete

Overrides the base C<update> and C<delete> methods. When the modification
target table is referenced in a subquery within the same statement (a pattern
MySQL rejects), the affected subquery is automatically re-wrapped in an
additional C<SELECT * FROM (...) `_forced_double_subquery`> layer to satisfy
MySQL's parser.

=head2 _lock_select

Generates the locking clause appended to C<SELECT> statements. Accepts
either a plain string (C<'update'>, C<'share'>) or a hashref
for fine-grained control:

  $rs->search({}, { for => { type => 'update', of => ['tbl'], modifier => 'nowait' } });

Valid C<type> values: C<update>, C<share>.
Valid C<modifier> values: C<nowait>, C<skip_locked>.
The C<of> key takes a table name or arrayref of table names.

=seealso

=over 4

=item * L<DBIO::MySQL::Storage> - Storage class that uses this SQL maker

=item * L<DBIO::MySQL> - Schema component entry point

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
