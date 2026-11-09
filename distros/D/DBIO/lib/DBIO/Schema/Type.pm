package DBIO::Schema::Type;
# ABSTRACT: portable base-type vocabulary for multi-engine schemas

use strict;
use warnings;

our $VERSION = '0.900004';

use Carp qw/croak/;
use namespace::clean;

our @BASE_TYPES = qw/integer text char boolean numeric double blob timestamp/;
my %IS_BASE = map { $_ => 1 } @BASE_TYPES;

our %ALIAS = (
  (map { $_ => 'integer' } qw/int integer bigint smallint tinyint serial bigserial/),
  (map { $_ => 'text'    } qw/text varchar string clob mediumtext longtext/),
  (map { $_ => 'char'    } qw/char character/),
  (map { $_ => 'boolean' } qw/boolean bool/),
  (map { $_ => 'numeric' } qw/numeric decimal/),
  'double' => 'double', 'double precision' => 'double', real => 'double', float => 'double',
  (map { $_ => 'blob'    } qw/blob bytea binary varbinary/),
  (map { $_ => 'timestamp' } qw/timestamp datetime timestamptz/),
);


sub base_types   { @BASE_TYPES }


sub is_base_type { $IS_BASE{ $_[0] // '' } ? 1 : 0 }


sub normalize {
  my ($type) = @_;
  croak "undef data_type" unless defined $type;
  my $key = lc $type;
  $key =~ s/\(.*\)\s*$//;        # strip parameters: varchar(255) -> varchar
  $key =~ s/^\s+|\s+$//g;
  $key =~ s/\s+/ /g;
  my $base = $ALIAS{$key}
    or croak "unknown data_type '$type' (not in portable base-type vocabulary)";
  return $base;
}


sub canonical_column {
  my ($name, $info) = @_;
  my $base = normalize($info->{data_type});
  my %col = (
    column_name    => $name,
    base_type      => $base,
    not_null       => ($info->{is_nullable} ? 0 : 1),
    default        => $info->{default_value},
    auto_increment => ($info->{is_auto_increment} ? 1 : 0),
  );
  if ($base eq 'char') {
    my ($width) = _size_parts($name, $base, $info->{size});
    $col{size} = $width;
  }
  elsif ($base eq 'numeric') {
    my @parts = _size_parts($name, $base, $info->{size});
    @col{qw/precision scale/} = @parts[0, 1] if @parts;
  }
  elsif ($base eq 'timestamp') {
    # defined, not true: 0 is a precision (whole seconds).
    my ($fractional) = _size_parts($name, $base, $info->{size});
    $col{size} = $fractional if defined $fractional;
  }
  return \%col;
}

# The form of size, read once for every base type that consumes it.
# A scalar is the single value the form names (width for char, precision for
# numeric, fractional seconds for timestamp); an arrayref names them in order
# and anything past the last meaningful element is dropped; an empty arrayref
# names nothing and counts as absent. That is the reading the drivers already
# established on their own alias names. Any other reference form means nothing
# in any of these readings and would reach a driver as a stringified address
# -- CHAR(ARRAY(0x...)) -- so it is refused here rather than passed on. Only
# the form is checked, never the content.
sub _size_parts {
  my ($name, $base, $size) = @_;
  return ()      unless defined $size;
  my $ref = ref $size;
  return ($size) unless $ref;
  return (@$size) if $ref eq 'ARRAY';
  croak "size for column '$name' (base type '$base') must be a scalar or "
      . "an arrayref, got a $ref reference";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Schema::Type - portable base-type vocabulary for multi-engine schemas

=head1 VERSION

version 0.900004

=head1 METHODS

=head2 base_types

    my @types = DBIO::Schema::Type::base_types;

Returns the list of portable base-type names (C<integer>, C<text>, C<char>,
C<boolean>, C<numeric>, C<double>, C<blob>, C<timestamp>) that every engine
alias in C<%ALIAS> normalizes down to.

=head2 is_base_type

    if (DBIO::Schema::Type::is_base_type($name)) { ... }

Returns true if C<$name> is already one of L</base_types> (not an alias that
still needs L</normalize>).

=head2 normalize

    my $base = DBIO::Schema::Type::normalize($data_type);

Normalizes an engine-specific C<data_type> string (e.g. C<varchar(255)>,
C<INT>) down to its portable L</base_types> name. Strips a trailing
C<(...)> parameter list and lower-cases before the alias lookup. C<croak>s on
an C<undef> type or one not present in C<%ALIAS>.

=head2 canonical_column

    my $col = DBIO::Schema::Type::canonical_column($name, $info);

Builds a canonical column hashref from a column name and a
C<table_columns_info>-shaped C<$info> hashref (see
L<DBIO::Introspect::Base/table_columns_info>): C<column_name>, C<base_type> (via
L</normalize>), C<not_null>, C<default> and C<auto_increment>, plus the size
of the three base types that carry one:

  char       size               the width
  numeric    precision, scale   scale undefined when the size names one value
  timestamp  size               the fractional-seconds precision

A C<timestamp> has its C<size> key only when a precision was declared -- C<0>
is one -- and a C<numeric> its two keys only when its size names a value. A
C<char> always has the key, undefined when no width was declared. The other
five base types carry no size: one declared on a column that normalizes to
C<integer>, C<text>, C<boolean>, C<double> or C<blob> is not read and not
passed on.

The form of C<size> in C<$info> is read once and is the same form every base
type consumes: a scalar names the single value the base type means (width for
C<char>, precision for C<numeric>, fractional seconds for C<timestamp>); an
arrayref names them in order and any element past the last meaningful one is
dropped; an empty arrayref names nothing and counts as absent. The drivers
already settled on this reading on their own alias-named paths; centralising
the form here means every driver stops repeating the same three-branch
`ref()` check, and a ref (a list passed where the form wants a scalar) becomes
a clear caller bug rather than a silent mangling into C<CHAR(ARRAY(0x...))> on
the SQL side.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
