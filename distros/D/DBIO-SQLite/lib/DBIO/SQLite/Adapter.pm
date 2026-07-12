package DBIO::SQLite::Adapter;
# ABSTRACT: SQLite base->native type resolver

use strict;
use warnings;
use Carp qw/croak/;
use base 'DBIO::Adapter::Base';

my %NATIVE = (
  integer   => 'INTEGER',
  text      => 'TEXT',
  boolean   => 'BOOLEAN',
  double    => 'REAL',
  blob      => 'BLOB',
  timestamp => 'TEXT',
);

sub to_native {
  my ($self, $col) = @_;
  my $b = $col->{base_type};
  return 'CHAR(' . ($col->{size} // 255) . ')' if $b eq 'char';
  if ($b eq 'numeric') {
    my ($p, $s) = @{$col}{qw/precision scale/};
    return (defined $p && defined $s) ? "NUMERIC($p,$s)" : 'NUMERIC';
  }
  return $NATIVE{$b} // croak "no SQLite native type for base '$b'";
}

sub capabilities { return { supports_alter_column_type => 0 } }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Adapter - SQLite base->native type resolver

=head1 VERSION

version 0.900001

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
