package DBIO::Oracle::SQLMaker::Joins;
# ABSTRACT: Pre-ANSI Joins-via-Where-Clause Syntax for Oracle

use warnings;
use strict;

use base qw( DBIO::Oracle::SQLMaker );


sub select {
  my ($self, $table, $fields, $where, $rs_attrs, @rest) = @_;

  if (ref($table) eq 'ARRAY') {
    $where = $self->_oracle_joins($where, @{ $table }[ 1 .. $#$table ]);
  }

  return $self->next::method($table, $fields, $where, $rs_attrs, @rest);
}

sub _recurse_from {
  my ($self, $from, @join) = @_;

  my @sqlf = $self->_from_chunk_to_sql($from);

  for (@join) {
    my ($to, $on) = @$_;

    if (ref $to eq 'ARRAY') {
      push (@sqlf, $self->_recurse_from(@{ $to }));
    }
    else {
      push (@sqlf, $self->_from_chunk_to_sql($to));
    }
  }

  return join q{, }, @sqlf;
}

sub _oracle_joins {
  my ($self, $where, @join) = @_;
  my $join_where = $self->_recurse_oracle_joins(@join);

  if (keys %$join_where) {
    if (!defined($where)) {
      $where = $join_where;
    } else {
      if (ref($where) eq 'ARRAY') {
        $where = { -or => $where };
      }
      $where = { -and => [ $join_where, $where ] };
    }
  }
  return $where;
}

sub _recurse_oracle_joins {
  my $self = shift;

  my @where;
  for my $j (@_) {
    my ($to, $on) = @{ $j };

    push @where, $self->_recurse_oracle_joins(@{ $to })
      if (ref $to eq 'ARRAY');

    my $join_opts  = ref $to eq 'ARRAY' ? $to->[0] : $to;
    my $left_join  = q{};
    my $right_join = q{};

    if (ref $join_opts eq 'HASH' and my $jt = $join_opts->{-join_type}) {
      $self->throw_exception("Can't handle full outer joins in Oracle 8 yet!\n")
        if $jt =~ /full/i;

      $left_join  = q{(+)} if $jt =~ /left/i
        && $jt !~ /inner/i;

      $right_join = q{(+)} if $jt =~ /right/i
        && $jt !~ /inner/i;
    }

    $on = $on->{-and}[0] if (
      ref $on eq 'HASH'
        and
      keys %$on == 1
        and
      ref $on->{-and} eq 'ARRAY'
        and
      @{$on->{-and}} == 1
    );

    push @where, map { \do {
        my ($sql) = $self->_recurse_where({
          $_ => ( length ref $on->{$_}
            ? $on->{$_}
            : { -ident => $on->{$_} }
          )
        });

        $sql =~ s/\s*\=/$left_join =/
          if $left_join;

        "$sql$right_join";
      }
    } sort keys %$on;
  }

  return { -and => \@where };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::SQLMaker::Joins - Pre-ANSI Joins-via-Where-Clause Syntax for Oracle

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

L<DBIO::Oracle::SQLMaker> subclass that generates Oracle's pre-ANSI
WHERE-clause join syntax (C<table1, table2 WHERE table1.id = table2.id>)
instead of standard C<JOIN ... ON> syntax.

This is used automatically by L<DBIO::Oracle::Storage::WhereJoins> for
Oracle databases older than version 9.0. Left and right outer joins are
supported via Oracle's C<(+)> syntax. Full outer joins are not supported.

=head1 SEE ALSO

=over

=item * L<DBIO::Oracle::Storage::WhereJoins> - Storage that uses this SQL maker

=item * L<DBIO::Oracle::SQLMaker> - Parent SQL maker with Oracle extensions

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
