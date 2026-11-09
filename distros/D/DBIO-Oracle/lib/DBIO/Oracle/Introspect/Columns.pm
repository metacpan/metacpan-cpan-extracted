package DBIO::Oracle::Introspect::Columns;
# ABSTRACT: Introspect Oracle columns

use strict;
use warnings;

our $VERSION = '0.900004';

use Try::Tiny;
use DBIO::Oracle::Type;


# One identifier of a trigger body: quoted ($1, a doubled quote inside is one
# quote) or bare ($2, folded to upper case by the server).
my $IDENT = qr/"((?:[^"]|"")+)"|([A-Za-z][\w\$#]*)/;

# The name as the server has it, from the two captures of $IDENT.
sub _ident {
  my ($quoted, $bare) = @_;
  return uc $bare if defined $bare;
  return undef unless defined $quoted;
  (my $name = $quoted) =~ s/""/"/g;
  return $name;
}


sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;

  my %columns;
  my @table_names = sort keys %$tables;

  # data_default and trigger_body are LONG columns. Set before the statements
  # are prepared: that is when DBD::Oracle sizes the buffer for them.
  local $dbh->{LongReadLen} = 1_000_000;
  local $dbh->{LongTruncOk} = 0;

  # ADR 0008: DBD::Oracle is loaded where it is needed, not at load time
  require DBD::Oracle;

  # Old DBD::Oracle reports size in (UTF-16) bytes, not characters
  my $nchar_size_factor = $DBD::Oracle::VERSION >= 1.52 ? 1 : 2;

  # all_tab_columns.identity_column exists from 12c on; before that the
  # column is not selected at all (ORA-00904) and no column is an IDENTITY.
  my $has_identity = ( ($dbh->func('ora_server_version') || [0])->[0] >= 12 ) ? 1 : 0;
  my $identity_sel = $has_identity ? 'identity_column' : q{'NO' AS identity_column};

  for my $table_name (@table_names) {
    my @col_list;

    my $col_sth = $dbh->prepare_cached(qq{
      SELECT column_name, data_type, data_length, char_length, char_used,
             data_precision, data_scale, nullable, data_default, column_id, $identity_sel
      FROM all_tab_columns
      WHERE table_name = ? AND owner = ?
      ORDER BY column_id
    });
    $col_sth->execute($table_name, $schema);

    while (my $row = $col_sth->fetchrow_hashref('NAME_lc')) {
      my $col = DBIO::Oracle::Type::map_dbd_type_to_dbio(
        $row->{data_type},
        data_length    => $row->{data_length},
        char_length    => $row->{char_length},
        char_used      => $row->{char_used},
        data_precision => $row->{data_precision},
        data_scale     => $row->{data_scale},
        nchar_size_factor => $nchar_size_factor,
      );
      $col->{column_name} = $row->{column_name};
      $col->{not_null} = (uc($row->{nullable} // 'Y') eq 'N') ? 1 : 0;

      # GENERATED ... AS IDENTITY: Oracle keeps a sequence of its own for the
      # column and shows it as the expression default "ISEQ$$_n".nextval.
      # That is not a default of the column; the column is auto-increment
      # (karr k41).
      my $identity = uc($row->{identity_column} // 'NO') eq 'YES';
      $col->{is_auto_increment} = 1 if $identity;

      # Handle default value
      my $default = $identity ? undef : $row->{data_default};
      if (defined $default) {
        $default =~ s/^\s+|\s+\z//g;
        if (uc $default eq 'NULL') {
          # DEFAULT NULL is no default (karr k63): what the diff writes to
          # take a default away reads back as a column without one
        }
        elsif ($default =~ /^'((?:[^']|'')*)'\z/) {
          # A string literal: the inverse of DBIO::Oracle::Type::
          # render_default_value (karr k47). The apostrophe is doubled in the
          # literal; a quote in the middle that is not doubled ('a'||'b')
          # makes it an expression, which falls through to the scalar ref.
          ($col->{default_value} = $1) =~ s/''/'/g;
        }
        elsif ($default =~ /^(-?[\d.]+)\z/) {
          $col->{default_value} = $1;
        }
        elsif (lc($default) eq 'sysdate') {
          my $ts = 'current_timestamp';
          $col->{default_value} = \$ts;
        }
        elsif ($default ne '') {
          $col->{default_value} = \$default;
        }
      }

      push @col_list, $col;
    }
    $col_sth->finish;

    # Detect sequences from BEFORE INSERT triggers
    my $trig_sth = $dbh->prepare_cached(q{
      SELECT trigger_body
      FROM all_triggers
      WHERE table_name = ? AND table_owner = ?
        AND status = 'ENABLED'
        AND UPPER(trigger_type) LIKE '%BEFORE EACH ROW%'
        AND LOWER(triggering_event) LIKE '%insert%'
    });
    $trig_sth->execute($table_name, $schema);

    my %seq_for_col;
    while (my ($body) = $trig_sth->fetchrow_array) {
      # An identifier is quoted (kept as written, a doubled quote is one
      # quote) or bare (folded to upper case by the server). The model
      # spells the names as the server has them (karr k61).
      if (my @m = $body =~ /(?:$IDENT\s*\.\s*)?$IDENT\s*\.\s*nextval/i) {
        my $seq_schema = _ident(@m[0, 1]) // $schema;
        my $seq_name   = _ident(@m[2, 3]);
        # :new.id as a hand-written trigger has it, :new."id" as the install
        # DDL writes it (karr k42)
        if (my @c = $body =~ /:new\.$IDENT/i) {
          $seq_for_col{ _ident(@c) } = "$seq_schema.$seq_name";
        }
      }
    }
    $trig_sth->finish;

    # Attach sequence info to columns
    for my $col (@col_list) {
      if (my $seq = $seq_for_col{ $col->{column_name} }) {
        $col->{is_auto_increment} = 1;
        $col->{sequence} = $seq;
      }
    }

    $columns{$table_name} = \@col_list if @col_list;
  }

  return \%columns;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Introspect::Columns - Introspect Oracle columns

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches Oracle column metadata via C<all_tab_columns> and C<all_triggers>.
Handles Oracle-specific data types (NUMBER, CHAR, DATE, LOB, etc.) and
detects sequences via trigger inspection. A C<GENERATED ... AS IDENTITY>
column (C<all_tab_columns.identity_column>, Oracle 12c and later; older
servers are not asked) is reported as C<is_auto_increment> without a
C<default_value>: the C<"ISEQ$$_n".nextval> Oracle shows as its default is
the generator, not a default.

Two of the columns read are C<LONG>: C<all_tab_columns.data_default> and
C<all_triggers.trigger_body>. C<LongReadLen> is raised for the duration of
the fetch, as L<DBIO::Oracle::Introspect/view_definition> does for
C<all_views.text> -- with DBI's default of 80 bytes any longer default or
trigger body ends the fetch with C<ORA-24345>. The handle's own setting is
restored afterwards.

The sequence of an auto-increment column is recorded as C<schema.sequence>,
both spelled the way the server has them: a quoted name as
written, a bare one in upper case. The column is found by the same rule, so a
trigger on C<:new.id> feeds the column C<ID>, and one on C<:new."id"> the
column C<id>.

Every row is read by lower-case keys (C<fetchrow_hashref('NAME_lc')>);
DBD::Oracle reports column names in upper case.

=head1 METHODS

=head2 fetch

    my $columns = DBIO::Oracle::Introspect::Columns->fetch($dbh, $schema, $tables);

Given the tables hashref from L<DBIO::Oracle::Introspect::Tables>,
returns a hashref keyed by table name. Each value is an arrayref of
column hashrefs in C<column_id> order.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
