package DBIO::MySQL::Adapter;
# ABSTRACT: MySQL base->native type resolver

use strict;
use warnings;
use Carp qw/croak/;
use base 'DBIO::Adapter::Base';

my %NATIVE = (
  integer   => 'BIGINT',
  text      => 'LONGTEXT',
  boolean   => 'TINYINT(1)',
  double    => 'DOUBLE',
  blob      => 'LONGBLOB',
  timestamp => 'DATETIME',
);

# Native types whose information_schema row reports character_set_name and
# collation_name as NULL (binary, numeric, datetime families). Text families
# (CHAR, VARCHAR, LONGTEXT, …) get a server-assigned charset and we do not
# preserve that on round-trip -- see DBIO::MySQL::Diff ESCALATION NOTE.
my %NO_CHARSET = map { $_ => 1 } qw(
  bigint tinyint double decimal longblob datetime
);

sub to_native {
  my ($self, $col) = @_;
  my $b = $col->{base_type};
  return 'CHAR(' . ($col->{size} // 255) . ')' if $b eq 'char';
  if ($b eq 'numeric') {
    my ($p, $s) = @{$col}{qw/precision scale/};
    return (defined $p && defined $s) ? "DECIMAL($p,$s)" : 'DECIMAL';
  }
  return $NATIVE{$b} // croak "no MySQL native type for base '$b'";
}

# True when the given native type (e.g. "BIGINT", "DECIMAL(10,2)", "DATETIME")
# is from a family whose information_schema row never carries a character
# set / collation. Used by Diff::target_from_compiled to leave those fields
# undef on the target side of the comparison.
sub no_charset_for {
  my ($self, $native) = @_;
  my $lc = lc $native;
  $lc =~ s/\(.*//;   # strip "(10,2)" parameters
  return exists $NO_CHARSET{$lc} ? 1 : 0;
}

# capabilities inherited from DBIO::Adapter::Base: supports_alter_column_type => 1

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Adapter - MySQL base->native type resolver

=head1 VERSION

version 0.900000

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
