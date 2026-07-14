package DBIO::SQLMaker;
# ABSTRACT: An SQL::Abstract-based SQL maker class

use strict;
use warnings;

our $CONTRACT_VERSION = '1.1';

use base qw(
  DBIO::SQLMaker::ClassicExtensions
  SQL::Abstract
);

sub contract_version { $CONTRACT_VERSION }

# NOTE THE LACK OF mro SPECIFICATION
# This is deliberate to ensure things will continue to work
# with ( usually ) untagged custom darkpan subclasses

sub new {
  my $self = shift;
  my %opts = (ref $_[0] eq 'HASH') ? %{$_[0]} : @_;

  # Reproduce the SQL::Abstract behaviour it only wires up for classes that
  # ->isa('DBIx::Class::SQLMaker'). The DBIO rename of the SQLMaker hierarchy
  # no longer trips that gate, so without this, select() emitted a bare
  # 'WHERE cond' instead of the canonical 'WHERE ( cond )' that DBIx::Class
  # produced. Routing select's WHERE through where() restores the parens, and
  # disabling the old special-op system makes every DBIO driver express its
  # operators through the new expand_op mechanism (see DBIO::PostgreSQL and
  # DBIO::Oracle SQLMakers) -- the two go together.
  $opts{warn_once_on_nest}      = 1;
  $opts{disable_old_special_ops} = 1;
  $opts{render_clause}{'select.where'} ||= sub {
    my ($sql, @bind) = $_[0]->where($_[2]);
    s/\A\s+//, s/\s+\Z// for $sql;
    # where() wraps its result in a single 'WHERE ( ... )' layer. When the
    # top-level WHERE node is an -and/-or, SQL::Abstract's _render_op_andor
    # has already wrapped the condition in its own '( ... )', so where()'s
    # wrapper produces a redundant second layer: 'WHERE ( ( ... ) )'. Collapse
    # that one redundant layer back to the canonical 'WHERE ( ... )'. Only the
    # outer pair added by where() is touched; the already-wrapped condition and
    # every nested group are left exactly as rendered (see ADR 0004 / karr #26).
    $sql = "$1 " . __unwrap_redundant_paren($2)
      if $sql =~ /\A(WHERE)\s+(\(.*\))\z/si;
    return [ $sql, @bind ];
  };

  return $self->next::method(\%opts);
}

# Given the 'WHERE ( <inner> )' block that where() added (passed in with its
# own surrounding parens), return the canonical single-layer 'inner'. If the
# content between where()'s parens is itself exactly one balanced parenthesised
# group spanning the whole content (the -and/-or case), the redundant pair is
# dropped; otherwise the block is returned unchanged. Balance counting (not a
# naive ^\( .. \)$ match) is required so a content like '( a ) OR ( b )' -- two
# sibling groups -- is NOT mistaken for one wrapping layer.
sub __unwrap_redundant_paren {
  my ($block) = @_;
  # $block always looks like '( <content> )' here.
  my $content = $block;
  $content =~ s/\A\(\s*//;
  $content =~ s/\s*\)\z//;
  return $block unless $content =~ /\A\(/;    # nothing to unwrap

  # Walk $content; find the position that closes the leading '('. If it is the
  # final character, the leading '(' and trailing ')' are a single matched pair
  # spanning everything, i.e. a redundant wrapping layer -> drop it.
  my $depth = 0;
  my @chars = split //, $content;
  for my $i (0 .. $#chars) {
    my $c = $chars[$i];
    $depth++ if $c eq '(';
    $depth-- if $c eq ')';
    if ($depth == 0) {
      return $i == $#chars ? $content : $block;
    }
  }
  return $block;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLMaker - An SQL::Abstract-based SQL maker class

=head1 VERSION

version 0.900002

=head1 DESCRIPTION

This module serves as a mere "nexus class" providing
L<SQL::Abstract>-based SQL generation functionality to L<DBIO> itself, and
to a number of database-engine-specific subclasses. This indirection is
explicitly maintained in order to allow swapping out the core of SQL
generation within DBIO on per-C<$schema> basis without major architectural
changes. It is guaranteed by design and tests that this fast-switching
will continue being maintained indefinitely.

=head2 Implementation switching

See L<DBIO::Storage::DBI/connect_call_rebase_sqlmaker>

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
