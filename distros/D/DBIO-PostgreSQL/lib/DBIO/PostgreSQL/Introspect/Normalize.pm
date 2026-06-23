package DBIO::PostgreSQL::Introspect::Normalize;
# ABSTRACT: Pure normalization helpers for PostgreSQL introspected metadata

use strict;
use warnings;



sub name {
  my ($class, $name, $preserve_case) = @_;
  return undef unless defined $name;
  return $preserve_case ? $name : lc $name;
}


sub data_type {
  my ($class, $info, $column, $enum_values) = @_;

  if ($column->{type_category} && $column->{type_category} eq 'e' && $column->{enum_type}) {
    my $qualified = $column->{type_schema} && $column->{type_schema} ne 'public'
      ? "$column->{type_schema}.$column->{enum_type}"
      : $column->{enum_type};

    $info->{data_type} = 'enum';
    $info->{extra}{list} = $class->array($enum_values)
      if $enum_values;
    $info->{extra}{custom_type_name} = $qualified;
    $info->{pg_enum_type} = $qualified;
    return;
  }

  my $type = lc($column->{data_type} || '');

  # Dispatch table: each entry is [pattern, callback]. The callback
  # mutates $info and returns 1 to claim the match, 0 to fall through.
  my @DISPATCH = (
    [qr/^(?:character varying|varchar)\((\d+)\)\z/, sub {
      $info->{data_type} = 'varchar';
      $info->{size} = 0 + $1;
    }],
    [qr/^character varying\z/, sub {
      $info->{data_type} = 'text';
      $info->{original}{data_type} = 'varchar';
    }],
    [qr/^(?:character|char)\((\d+)\)\z/, sub {
      $info->{data_type} = 'char';
      $info->{size} = 0 + $1;
    }],
    [qr/^(numeric|decimal)\((\d+),(\d+)\)\z/, sub {
      $info->{data_type} = $1;
      $info->{size} = [ 0 + $2, 0 + $3 ];
    }],
    [qr/^(?:bit varying|varbit)\((\d+)\)\z/, sub {
      $info->{data_type} = 'varbit';
      $info->{size} = 0 + $1;
    }],
    [qr/^bit\((\d+)\)\z/, sub {
      $info->{data_type} = 'bit';
      $info->{size} = 0 + $1;
    }],
    [qr/^(vector|halfvec|sparsevec)\((\d+)\)\z/, sub {
      $info->{data_type} = $1;
      $info->{size} = 0 + $2;
    }],
    [qr/^(timestamp|time)\((\d+)\) without time zone\z/, sub {
      $info->{data_type} = $1;
      $info->{size} = 0 + $2;
    }],
    [qr/^timestamp without time zone\z/, sub {
      $info->{data_type} = 'timestamp';
    }],
    [qr/^time without time zone\z/, sub {
      $info->{data_type} = 'time';
    }],
    [qr/^(interval|timestamp with time zone|time with time zone)\((\d+)\)\z/, sub {
      $info->{data_type} = $1;
      $info->{size} = 0 + $2;
    }],
  );

  for my $entry (@DISPATCH) {
    my ($re, $cb) = @$entry;
    if ($type =~ $re) {
      $cb->();
      return;
    }
  }

  # Fallback aliases (when no size-bearing match wins).
  $type =~ s/^character$/char/;
  $type =~ s/^character varying$/varchar/;
  $type =~ s/^bit varying$/varbit/;
  $info->{data_type} = $type;
}


sub default_value {
  my ($class, $info, $default, $is_primary_key) = @_;

  return unless defined $default;

  my $value = $default;
  $value =~ s/^\s+//;
  $value =~ s/\s+\z//;

  if ($value =~ /\bnextval\('([^']+)'::(?:text|regclass)\)/i) {
    $info->{is_auto_increment} = 1;
    $info->{sequence} = $1;
    $info->{retrieve_on_insert} = 1 if $is_primary_key;
    return;
  }

  if ($value =~ /^["'](.*?)['"](?:::[\w\s\."]+)?\z/) {
    $info->{default_value} = $1;
  }
  elsif ($value =~ /^\((-?\d.*?)\)(?:::[\w\s\."]+)?\z/) {
    $info->{default_value} = $1;
  }
  elsif ($value =~ /^(-?\d.*?)(?:::[\w\s\."]+)?\z/) {
    $info->{default_value} = $1;
  }
  elsif ($value =~ /^NULL:?/i) {
    my $null = 'null';
    $info->{default_value} = \$null;
  }
  else {
    my $literal = lc($value) eq 'now()' ? 'current_timestamp' : $value;
    $literal =~ s/\bCURRENT_TIMESTAMP\b/lc $&/ge;
    $info->{default_value} = \$literal;
  }

  if (!$info->{is_auto_increment} && $is_primary_key) {
    $info->{retrieve_on_insert} = 1;
  }

  my $type = $info->{data_type} || '';
  if ($type =~ /^bool/i && exists $info->{default_value} && !ref $info->{default_value}) {
    if ($info->{default_value} eq '0') {
      my $false = 'false';
      $info->{default_value} = \$false;
    }
    elsif ($info->{default_value} eq '1') {
      my $true = 'true';
      $info->{default_value} = \$true;
    }
  }
}


sub array {
  my ($class, $value) = @_;
  return undef if !defined $value;
  return $value if ref $value eq 'ARRAY';

  my $raw = $value;
  $raw =~ s/^\{|\}$//g;
  return [ grep { length $_ } split /,/, $raw ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Introspect::Normalize - Pure normalization helpers for PostgreSQL introspected metadata

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Leaf module that holds the pure-data normalization helpers used by
L<DBIO::PostgreSQL::Introspect> to translate raw C<pg_catalog> rows into
the canonical column-info shape consumed by L<DBIO::Generate>. None of
these subs talk to the database or hold state; they are class methods that
take scalars / hashrefs and return scalar / hashref results, so they are
trivially unit-testable in isolation.

The helpers are:

=over 4

=item * L</name> -- lowercase / preserve-case policy

=item * L</data_type> -- parses C<pg_catalog.format_type> into a
C<data_type>/C<size> pair, handling all the special forms
(C<varchar(n)>, C<numeric(p,s)>, C<interval(n)>, pgvector, etc.)

=item * L</default_value> -- normalises the C<pg_get_expr(adbin, adrelid)>
string into a scalar / SCALAR-ref suitable for round-tripping through
DBIO and detects the C<nextval(...)> sequence pattern

=item * L</array> -- decodes the C<{a,b,c}> form returned by DBD::Pg for
array columns into a Perl ArrayRef

=back

=head2 name

    my $normalised = DBIO::PostgreSQL::Introspect::Normalize->name(
        $name, $preserve_case,
    );

Returns the column / index / constraint name as a Perl string. When
C<$preserve_case> is false (the default) the name is lowercased to match
DBIx::Class convention. C<undef> stays C<undef>.

=head2 data_type

    DBIO::PostgreSQL::Introspect::Normalize->data_type(
        $info, $column, $enum_values,
    );

Mutates C<$info> in place to set C<data_type> and (where appropriate)
C<size> from the raw C<pg_catalog> row. Handles the size-bearing
variants (C<varchar(n)>, C<numeric(p,s)>, C<interval(n)>,
pgvector C<vector(n)>, etc.) and the size-stripped aliases (C<character
varying> B<-> C<text>). Enum columns are detected via C<type_category>
and the canonical C<schema.name> reference is recorded under
C<pg_enum_type> / C<extra/custom_type_name> / C<extra/list>. Pass the
already-fetched C<values> ArrayRef in C<$enum_values> when normalising a
column that references an enum (the caller has to look it up in the
model because that lookup is stateful and not the leaf module's job).

=head2 default_value

    DBIO::PostgreSQL::Introspect::Normalize->default_value(
        $info, $default_expr, $is_primary_key,
    );

Normalises the C<pg_get_expr(adbin, adrelid)> string returned by the
introspect query into either a Perl scalar, a SCALAR ref (for SQL
expressions like C<now()>), or C<nextval('schema.seq'::regclass)>
auto-increment metadata. Mutates C<$info> in place.

=head2 array

    my $arr = DBIO::PostgreSQL::Introspect::Normalize->array($value);

Decodes the C<{a,b,c}> string DBD::Pg returns for C<text[]> / C<integer[]>
columns into a Perl ArrayRef. Already-an-ArrayRef values pass through
unchanged. C<undef> returns C<undef>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
