package DBIO::Firebird::Introspect::Columns;
# ABSTRACT: Introspect Firebird columns via rdb$fields / rdb$relation_fields

use strict;
use warnings;

use DBIO::Firebird::Type qw(sql_type_from_rdb);



sub fetch {
  my ($class, $dbh, $tables) = @_;
  my %columns;

  my $sth = $dbh->prepare(q{
    SELECT rf.rdb$relation_name, rf.rdb$field_name, rf.rdb$field_position,
           rf.rdb$null_flag,
           f.rdb$field_type, f.rdb$field_sub_type, f.rdb$field_scale,
           f.rdb$field_precision, f.rdb$character_set_id, f.rdb$character_length,
           rf.rdb$default_source
    FROM rdb$relation_fields rf
    JOIN rdb$fields f ON rf.rdb$field_source = f.rdb$field_name
    WHERE rf.rdb$system_flag = 0
    ORDER BY rf.rdb$relation_name, rf.rdb$field_position
  });
  $sth->execute;

  while (my $row = $sth->fetchrow_hashref) {
    my $table = $row->{'rdb$relation_name'};
    $table =~ s/\s+$//;
    next unless exists $tables->{$table};

    my $name = $row->{'rdb$field_name'};
    $name =~ s/\s+$//;

    my $type = sql_type_from_rdb($row->{'rdb$field_type'}, $row->{'rdb$field_sub_type'});

    my $size;
    if ($type =~ /^(?:char|varchar)/) {
      $size = $row->{'rdb$character_length'};
    } elsif ($type =~ /^(?:numeric|decimal)/ && defined $row->{'rdb$field_precision'}) {
      # rdb$field_scale is stored as a negative number of fractional digits.
      $size = [$row->{'rdb$field_precision'}, abs($row->{'rdb$field_scale'} // 0)];
    }

    my $default;
    if (my $src = $row->{'rdb$default_source'}) {
      $src =~ s/^\s+|\s+$//g;
      if (my ($def) = $src =~ /^DEFAULT \s+(\S+)/ix) {
        $default = $def;
      }
    }

    push @{ $columns{$table} }, {
      column_name   => $name,
      data_type     => $type,
      not_null      => $row->{'rdb$null_flag'} ? 1 : 0,
      default_value => $default,
      is_pk         => 0,
      pk_position   => 0,
      size          => $size,
    };
  }

  # Primary-key membership
  my $pk_sth = $dbh->prepare(q{
    SELECT rc.rdb$relation_name, iseg.rdb$field_name, iseg.rdb$field_position
    FROM rdb$relation_constraints rc
    JOIN rdb$index_segments iseg ON rc.rdb$index_name = iseg.rdb$index_name
    WHERE rc.rdb$constraint_type = 'PRIMARY KEY'
    ORDER BY rc.rdb$relation_name, iseg.rdb$field_position
  });
  $pk_sth->execute;

  while (my $row = $pk_sth->fetchrow_hashref) {
    my $table = $row->{'rdb$relation_name'};
    $table =~ s/\s+$//;
    my $col = $row->{'rdb$field_name'};
    $col =~ s/\s+$//;
    my $list = $columns{$table} or next;
    for my $c (@$list) {
      if ($c->{column_name} eq $col) {
        $c->{is_pk}       = 1;
        # rdb$field_position is 0-based; keep it raw so composite-PK ordering
        # (table_pk_info sorts on it) stays correct. (`|| 1` collapsed pos 0
        # and 1 to the same value.)
        $c->{pk_position} = $row->{'rdb$field_position'};
        last;
      }
    }
  }

  return \%columns;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird::Introspect::Columns - Introspect Firebird columns via rdb$fields / rdb$relation_fields

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Fetches column metadata via C<rdb$relation_fields> joined against
C<rdb$fields>. Primary-key information is derived from
C<rdb$index_segments> joined against C<rdb$relation_constraints>.

=head1 METHODS

=head2 fetch

    my $columns = DBIO::Firebird::Introspect::Columns->fetch($dbh, $tables);

Given the tables hashref from L<DBIO::Firebird::Introspect::Tables>,
returns a hashref keyed by table name. Each value is an arrayref of
column hashrefs in ordinal position order with keys:
C<column_name>, C<data_type>, C<not_null>, C<default_value>,
C<is_pk>, C<pk_position>, C<size>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
