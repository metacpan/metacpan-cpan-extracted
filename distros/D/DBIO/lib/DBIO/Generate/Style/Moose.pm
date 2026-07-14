package DBIO::Generate::Style::Moose;
# ABSTRACT: Moose-style emitter for DBIO::Generate

use strict;
use warnings;
use Data::Dumper ();
use DBIO::Generate::Util ();
use namespace::clean;

# IMPORTANT: This module writes "use Moose" as text. It does NOT load Moose
# at runtime. Moose is only required if you load the *generated* class.


sub emit {
  my ($class, $spec) = @_;

  my @lines;

  push @lines, "package " . DBIO::Generate::Util::assert_pkg($spec->{class}) . ";";
  push @lines, "# ABSTRACT: " . DBIO::Generate::Util::abstract_comment($spec->{moniker});
  push @lines, "";
  push @lines, "use Moose;";
  push @lines, "use MooseX::NonMoose;";
  push @lines, "use MooseX::MarkAsMethods autoclean => 1;";
  push @lines, "";

  my $base = $spec->{result_base_class} // 'DBIO::Core';
  push @lines, "extends " . DBIO::Generate::Util::pl_str($base) . ";";
  push @lines, "";

  if (my @c = @{ $spec->{components} // [] }) {
    push @lines, "__PACKAGE__->load_components(" . join(', ', map { DBIO::Generate::Util::pl_str($_) } @c) . ");";
    push @lines, "";
  }

  if ($spec->{is_view}) {
    push @lines, "__PACKAGE__->table_class('DBIO::ResultSource::View');";
    push @lines, "__PACKAGE__->table(" . DBIO::Generate::Util::pl_str($spec->{table}) . ");";
    push @lines, "__PACKAGE__->result_source_instance->view_definition(" . DBIO::Generate::Util::pl_str($spec->{view_definition}) . ");"
      if defined $spec->{view_definition};
  }
  else {
    push @lines, "__PACKAGE__->table(" . DBIO::Generate::Util::pl_str($spec->{table}) . ");";
  }
  push @lines, "";

  push @lines, "__PACKAGE__->add_columns(";
  for my $col (@{ $spec->{column_order} // [] }) {
    my $info = $spec->{columns}{$col} // {};
    push @lines, "  " . DBIO::Generate::Util::pl_str($col) . " => " . _dump_inline($info) . ",";
  }
  push @lines, ");";
  push @lines, "";

  if (my @pk = @{ $spec->{pk} // [] }) {
    push @lines, "__PACKAGE__->set_primary_key(" . join(', ', map { DBIO::Generate::Util::pl_str($_) } @pk) . ");";
    push @lines, "";
  }

  for my $uq (@{ $spec->{uniq} // [] }) {
    my ($name, $cols) = @$uq;
    push @lines, "__PACKAGE__->add_unique_constraint(" . DBIO::Generate::Util::pl_str($name) . ", [" . join(', ', map { DBIO::Generate::Util::pl_str($_) } @$cols) . "]);";
  }
  push @lines, "" if @{ $spec->{uniq} // [] };

  for my $stmt (@{ $spec->{extra_statements} // [] }) {
    my ($method, @args) = @$stmt;
    push @lines, "__PACKAGE__->$method(" . join(', ', map { _dump_val($_) } @args) . ");";
  }
  push @lines, "" if @{ $spec->{extra_statements} // [] };

  for my $rel (@{ $spec->{relationships} // [] }) {
    my ($rel_name, $remote_class, $cond, @rest) = @{ $rel->{args} };
    my $cond_str = _dump_inline($cond);
    my $rest_str = @rest ? ', ' . join(', ', map { _dump_inline($_) } @rest ) : '';
    push @lines, "__PACKAGE__->$rel->{method}(";
    push @lines, "  " . DBIO::Generate::Util::pl_str($rel_name) . ",";
    push @lines, "  " . DBIO::Generate::Util::pl_str($remote_class) . ",";
    push @lines, "  $cond_str$rest_str,";
    push @lines, ");";
    push @lines, "";
  }

  push @lines, "__PACKAGE__->meta->make_immutable;";
  push @lines, "";
  push @lines, "1;";

  return join("\n", @lines);
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

DBIO::Generate::Style::Moose - Moose-style emitter for DBIO::Generate

=head1 VERSION

version 0.900002

=head1 METHODS

=head2 emit

Same spec as L<DBIO::Generate::Style::Vanilla/emit>. Emits C<use Moose> +
C<extends> style. No Moose dependency at generation time.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
