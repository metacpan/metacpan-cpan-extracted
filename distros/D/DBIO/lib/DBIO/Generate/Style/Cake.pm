package DBIO::Generate::Style::Cake;
# ABSTRACT: DBIO::Cake DSL emitter for DBIO::Generate

use strict;
use warnings;
use Data::Dumper ();
use DBIO::Generate::Util ();
use namespace::clean;


sub emit {
  my ($class, $spec) = @_;

  my @lines;

  push @lines, "package " . DBIO::Generate::Util::assert_pkg($spec->{class}) . ";";
  push @lines, "# ABSTRACT: " . DBIO::Generate::Util::abstract_comment($spec->{moniker});
  push @lines, "";
  push @lines, "use DBIO::Cake;";
  push @lines, "";

  if (my @c = @{ $spec->{components} // [] }) {
    push @lines, "load_components " . join(', ', map { DBIO::Generate::Util::pl_str($_) } @c) . ";";
    push @lines, "";
  }

  if ($spec->{is_view}) {
    push @lines, "table_class 'DBIO::ResultSource::View';";
    push @lines, "table " . DBIO::Generate::Util::pl_str($spec->{table}) . ";";
    if (defined $spec->{view_definition}) {
      push @lines, "view_definition " . DBIO::Generate::Util::pl_str($spec->{view_definition}) . ";";
    }
  }
  else {
    push @lines, "table " . DBIO::Generate::Util::pl_str($spec->{table}) . ";";
  }
  push @lines, "";

  my %pk_set = map { $_ => 1 } @{ $spec->{pk} // [] };
  for my $col (@{ $spec->{column_order} // [] }) {
    my $info = $spec->{columns}{$col} // {};
    my $type_str = _cake_type($info);
    my $col_str  = DBIO::Generate::Util::pl_str($col);
    if ($pk_set{$col}) {
      push @lines, "primary_column $col_str => $type_str;";
    }
    elsif ($info->{is_nullable}) {
      push @lines, "nullable_column $col_str => $type_str;";
    }
    else {
      push @lines, "column $col_str => $type_str;";
    }
  }
  push @lines, "";

  for my $uq (@{ $spec->{uniq} // [] }) {
    my ($name, $cols) = @$uq;
    push @lines, "unique_constraint " . DBIO::Generate::Util::pl_str($name) . " => [" . join(', ', map { DBIO::Generate::Util::pl_str($_) } @$cols) . "];";
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
    push @lines, "$rel->{method} " . DBIO::Generate::Util::pl_str($rel_name) . ", " . DBIO::Generate::Util::pl_str($remote_class) . ", $cond_str;";
  }
  push @lines, "" if @{ $spec->{relationships} // [] };

  push @lines, "1;";

  return join("\n", @lines);
}

sub _cake_type {
  my ($info) = @_;
  my $dt   = $info->{data_type} // 'varchar';
  my $size = $info->{size};

  # SECURITY: data_type / size are DB-reported and must never be spliced raw.
  # The bareword DSL type-function form (e.g. `varchar(100)`) is only safe when
  # the type token is a plain identifier and the size is an integer. For the
  # common case that holds and we keep the readable DSL form; anything outside
  # it falls back to explicit, string-literal `data_type => '...'` option pairs,
  # which Cake's column() accepts identically and which cannot inject code.
  my $safe_size = !defined $size || $size =~ /\A-?[0-9]+\z/;
  if ($dt =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/ && $safe_size) {
    return defined $size ? "$dt($size)" : $dt;
  }

  my $type_str = "data_type => " . DBIO::Generate::Util::pl_str($dt);
  if (defined $size) {
    $type_str .= ", size => "
      . ($safe_size ? $size : DBIO::Generate::Util::pl_str($size));
  }
  return $type_str;
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

version 0.900002

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
