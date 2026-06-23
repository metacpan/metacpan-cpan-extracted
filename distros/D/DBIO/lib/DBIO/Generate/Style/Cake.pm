package DBIO::Generate::Style::Cake;
# ABSTRACT: DBIO::Cake DSL emitter for DBIO::Generate

use strict;
use warnings;
use Data::Dumper ();
use namespace::clean;


sub emit {
  my ($class, $spec) = @_;

  my @lines;

  push @lines, "package $spec->{class};";
  push @lines, "# ABSTRACT: $spec->{moniker}";
  push @lines, "";
  push @lines, "use DBIO::Cake;";
  push @lines, "";

  if (my @c = @{ $spec->{components} // [] }) {
    push @lines, "load_components " . join(', ', map { "'$_'" } @c) . ";";
    push @lines, "";
  }

  if ($spec->{is_view}) {
    push @lines, "table_class 'DBIO::ResultSource::View';";
    push @lines, "table '$spec->{table}';";
    if (defined $spec->{view_definition}) {
      (my $vdef = $spec->{view_definition}) =~ s/'/\\'/g;
      push @lines, "view_definition '$vdef';";
    }
  }
  else {
    push @lines, "table '$spec->{table}';";
  }
  push @lines, "";

  my %pk_set = map { $_ => 1 } @{ $spec->{pk} // [] };
  for my $col (@{ $spec->{column_order} // [] }) {
    my $info = $spec->{columns}{$col} // {};
    my $type_str = _cake_type($info);
    if ($pk_set{$col}) {
      push @lines, "primary_column $col => $type_str;";
    }
    elsif ($info->{is_nullable}) {
      push @lines, "nullable_column $col => $type_str;";
    }
    else {
      push @lines, "column $col => $type_str;";
    }
  }
  push @lines, "";

  for my $uq (@{ $spec->{uniq} // [] }) {
    my ($name, $cols) = @$uq;
    push @lines, "unique_constraint '$name' => [" . join(', ', map { "'$_'" } @$cols) . "];";
  }
  push @lines, "" if @{ $spec->{uniq} // [] };

  for my $stmt (@{ $spec->{extra_statements} // [] }) {
    my ($method, @args) = @$stmt;
    push @lines, "$method " . join(', ', map { _dump_val($_) } @args) . ";";
  }
  push @lines, "" if @{ $spec->{extra_statements} // [] };

  for my $rel (@{ $spec->{relationships} // [] }) {
    my ($rel_name, $remote_class, $cond, @rest) = @{ $rel->{args} };
    my $cond_str = _dump_inline($cond);
    push @lines, "$rel->{method} '$rel_name', '$remote_class', $cond_str;";
  }
  push @lines, "" if @{ $spec->{relationships} // [] };

  push @lines, "1;";

  return join("\n", @lines);
}

sub _cake_type {
  my ($info) = @_;
  my $dt   = $info->{data_type} // 'varchar';
  my $size = $info->{size};
  return defined $size ? "$dt($size)" : $dt;
}

sub _dump_inline {
  my ($val) = @_;
  local $Data::Dumper::Indent   = 0;
  local $Data::Dumper::Terse    = 1;
  local $Data::Dumper::Sortkeys = 1;
  return Data::Dumper::Dumper($val);
}

sub _dump_val { _dump_inline($_[1]) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Generate::Style::Cake - DBIO::Cake DSL emitter for DBIO::Generate

=head1 VERSION

version 0.900000

=head1 METHODS

=head2 emit

    my $code = DBIO::Generate::Style::Cake->emit($spec);

Same $spec as L<DBIO::Generate::Style::Vanilla/emit>. Returns DBIO::Cake DSL source.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
