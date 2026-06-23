package DBIO::Sybase::Diff::Index;
# ABSTRACT: Diff Sybase ASE indexes

use strict;
use warnings;

use DBIO::Diff::Compare qw(changed_index_fields);


sub diff {
  my ($class, $source, $target) = @_;
  $source //= {};
  $target //= {};
  my @ops;

  for my $table (sort keys %$target) {
    my $s_idx = $source->{$table} // {};
    my $t_idx = $target->{$table} // {};

    for my $name (sort keys %$t_idx) {
      if (exists $s_idx->{$name}) {
        push @ops, DBIO::Sybase::Diff::Index::Alter->new(
          action => 'alter',
          table  => $table,
          from   => $s_idx->{$name},
          to     => $t_idx->{$name},
        ) if changed_index_fields($s_idx->{$name}, $t_idx->{$name});
      }
      else {
        push @ops, DBIO::Sybase::Diff::Index::Create->new(
          action => 'create',
          table  => $table,
          idx    => $t_idx->{$name},
        );
      }
    }

    for my $name (sort keys %$s_idx) {
      push @ops, DBIO::Sybase::Diff::Index::Drop->new(
        action => 'drop',
        table  => $table,
        idx    => $s_idx->{$name},
      ) unless exists $t_idx->{$name};
    }
  }

  return @ops;
}

package DBIO::Sybase::Diff::Index::Create;
use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(table idx));

sub as_sql {
  my $self = shift;
  my $cols = join(', ', @{$self->idx->{columns}});
  my $unique = $self->idx->{is_unique} ? 'UNIQUE ' : '';
  "CREATE ${unique}INDEX $self->{idx}{index_name} ON $self->{table} ($cols)";
}
sub summary {
  my $self = shift;
  "CREATE INDEX $self->{idx}{index_name} ON $self->{table}";
}

package DBIO::Sybase::Diff::Index::Alter;
use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(table from to));

sub as_sql {
  my $self = shift;
  my $tbl     = $self->table;
  my $cols    = join(', ', @{$self->to->{columns}});
  my $unique  = $self->to->{is_unique} ? 'UNIQUE ' : '';
  # DROP and CREATE since Sybase ASE does not support ALTER INDEX
  "DROP INDEX $tbl.$self->{from}{index_name}; CREATE ${unique}INDEX $self->{to}{index_name} ON $tbl ($cols)";
}
sub summary {
  my $self = shift;
  "ALTER INDEX $self->{to}{index_name} ON $self->{table}";
}

package DBIO::Sybase::Diff::Index::Drop;
use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(table idx));

sub as_sql {
  my $self = shift;
  "DROP INDEX $self->{table}.$self->{idx}{index_name}";
}
sub summary {
  my $self = shift;
  "DROP INDEX $self->{table}.$self->{idx}{index_name}";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Diff::Index - Diff Sybase ASE indexes

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Compares two index sets and generates index-level diff operations.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
