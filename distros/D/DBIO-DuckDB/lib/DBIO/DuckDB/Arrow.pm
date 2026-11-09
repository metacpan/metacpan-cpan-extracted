package DBIO::DuckDB::Arrow;
# ABSTRACT: Read a DuckDB result through libduckdb's Arrow interface

use strict;
use warnings;

our $VERSION = '0.900004';

use Config;
use Try::Tiny;
use Math::BigInt ();
use FFI::Platypus 2.00 ();
use FFI::Platypus::Memory ();
use FFI::Platypus::Buffer ();
use FFI::CheckLib ();
use DBD::DuckDB::FFI ();
use DBIO::DuckDB::Util ();

# Arrow C data interface, 64 bit: struct ArrowSchema is 9 words, struct
# ArrowArray 10. The 'Q' templates and the 72 and 80 byte sizes below assume
# 8 byte pointers, hence the check.
die "DBIO::DuckDB::Arrow needs a perl with 64 bit pointers\n" if $Config{ptrsize} != 8;
my $SCHEMA_BYTES = 72;
my $ARRAY_BYTES  = 80;

# DuckDB's type ids (duckdb.h, duckdb_type) the decoder tells apart or refuses.
my %TYPE_NAME = (
  0  => 'INVALID',  28 => 'UNION',  29 => 'BIT', 30 => 'TIME WITH TIME ZONE',
  34 => 'ANY',      35 => 'BIGNUM', 40 => 'GEOMETRY', 41 => 'VARIANT',
);
my $TYPE_UHUGEINT = 32;
my $TYPE_LIST     = 24;
my $TYPE_STRUCT   = 25;
my $TYPE_MAP      = 26;
my $TYPE_ARRAY    = 33;
my %NESTED = map { $_ => 1 } $TYPE_LIST, $TYPE_STRUCT, $TYPE_MAP, $TYPE_ARRAY;

# Arrow format => [ bytes, pack template ] of the fixed width numbers.
my %NUMBER = (
  c => [ 1, 'c'  ], s => [ 2, 's<' ], i => [ 4, 'l<' ], l => [ 8, 'q<' ],
  C => [ 1, 'C'  ], S => [ 2, 'S<' ], I => [ 4, 'L<' ], L => [ 8, 'Q<' ],
  f => [ 4, 'f<' ], g => [ 8, 'd<' ],
);

# timestamp unit => [ units per second, digits of the fraction ]
my %UNIT = (
  s => [ 1, 0 ], m => [ 1_000, 3 ], u => [ 1_000_000, 6 ], n => [ 1_000_000_000, 9 ],
);

my $TWO64 = Math::BigInt->new(2)->bpow(64);

my $FFI = FFI::Platypus->new(
  api => 2,
  lib => FFI::CheckLib::find_lib_or_die(
    lib   => 'duckdb',
    alien => ($ENV{DUCKDB_NO_ALIEN} ? undef : 'Alien::DuckDB'),
  ),
);
# DBD::DuckDB::FFI binds the arrays of this call as single pointers.
$FFI->attach(
  [ duckdb_to_arrow_schema => '_to_arrow_schema' ] =>
    [ 'opaque', 'opaque[]', 'string[]', 'uint64', 'opaque' ] => 'opaque',
);

my %RELEASE;
sub _release {
  my ($struct, $release_at) = @_;
  my $fn = unpack 'Q', FFI::Platypus::Buffer::buffer_to_scalar($struct + $release_at, 8);
  return unless $fn;
  ($RELEASE{$fn} ||= $FFI->function($fn => ['opaque'] => 'void'))->call($struct);
  return;
}

sub _read { FFI::Platypus::Buffer::buffer_to_scalar($_[0], $_[1]) }

sub _string {
  my $ptr = shift;
  return $ptr ? $FFI->cast('opaque', 'string', $ptr) : undef;
}

sub _error {
  my ($err) = @_;
  return unless $err;
  my $message;
  if (DBD::DuckDB::FFI::duckdb_error_data_has_error($err)) {
    $message = DBD::DuckDB::FFI::duckdb_error_data_message($err);
  }
  DBD::DuckDB::FFI::duckdb_destroy_error_data(\$err);
  return $message;
}

# ---- DuckDB's logical types, as a tree of ids ---------------------------

sub _type_tree {
  my ($lt) = @_;
  my $id = DBD::DuckDB::FFI::duckdb_get_type_id($lt);
  my @kids;
  my $child = sub {
    my $t = shift;
    push @kids, _type_tree($t);
    DBD::DuckDB::FFI::duckdb_destroy_logical_type(\$t);
  };
  if ($id == $TYPE_LIST) {
    $child->(DBD::DuckDB::FFI::duckdb_list_type_child_type($lt));
  }
  elsif ($id == $TYPE_ARRAY) {
    $child->(DBD::DuckDB::FFI::duckdb_array_type_child_type($lt));
  }
  elsif ($id == $TYPE_MAP) {
    $child->(DBD::DuckDB::FFI::duckdb_map_type_key_type($lt));
    $child->(DBD::DuckDB::FFI::duckdb_map_type_value_type($lt));
  }
  elsif ($id == $TYPE_STRUCT) {
    $child->(DBD::DuckDB::FFI::duckdb_struct_type_child_type($lt, $_))
      for 0 .. DBD::DuckDB::FFI::duckdb_struct_type_child_count($lt) - 1;
  }
  return { id => $id, kids => \@kids };
}

# ---- the plan: one decoder per column, made once from schema and types ----

sub _refuse {
  my ($column, $format, $type) = @_;
  die sprintf "column '%s' has Arrow format '%s'%s, which cannot be decoded\n",
    $column, $format, defined $type ? " (DuckDB type $type)" : '';
}

sub _plan {
  my ($schema, $node, $column) = @_;

  my ($format_at, $name_at, undef, undef, $n_children, $children, $dictionary)
    = unpack 'Q Q Q q q Q Q', _read($schema, 56);
  my $format = _string($format_at);
  my $id     = $node ? $node->{id} : -1;

  _refuse($column, $format, $TYPE_NAME{$id}) if $TYPE_NAME{$id};

  my @kid_schemas = $n_children ? unpack("Q$n_children", _read($children, 8 * $n_children)) : ();
  my @kid_nodes   = $node ? @{ $node->{kids} } : ();
  my $plan = { format => $format };

  if ($dictionary) {
    # DuckDB's ENUM: small integers indexing a dictionary of text.
    _refuse($column, $format) unless $NUMBER{$format} and $format =~ /\A[cCsSiI]\z/;
    my $index = _number_decoder($format);
    my $dict  = _plan($dictionary, undef, $column);
    _refuse($column, $dict->{format}) unless $dict->{format} eq 'u';
    $plan->{decode} = sub {
      my ($array) = @_;
      my (undef, undef, undef, undef, undef, undef, undef, $dict_array) = unpack 'q q q q q Q Q Q', _read($array, 64);
      my $values = $dict->{decode}->($dict_array);
      return [ map { defined $_ ? $values->[$_] : undef } @{ $index->($array) } ];
    };
  }
  elsif ($NUMBER{$format}) {
    $plan->{decode} = _number_decoder($format);
  }
  elsif ($format eq 'b') {
    $plan->{decode} = sub {
      my ($len, $off, $buffers) = _array_head($_[0]);
      return [] unless $len;
      my $bits = unpack 'b*', _read($buffers->[1] + ($off >> 3), (($off & 7) + $len + 7) >> 3);
      return [ map { $_ ? !!1 : !!0 } split //, substr($bits, $off & 7, $len) ];
    };
  }
  elsif ($format eq 'u' or $format eq 'z') {
    my $text = $format eq 'u';
    $plan->{decode} = sub {
      my ($len, $off, $buffers) = _array_head($_[0]);
      return [] unless $len;
      my @o = unpack 'l<' . ($len + 1), _read($buffers->[1] + 4 * $off, 4 * ($len + 1));
      my $data = $o[-1] > $o[0] ? _read($buffers->[2] + $o[0], $o[-1] - $o[0]) : '';
      my $base = $o[0];
      my @v    = map { substr $data, $o[$_] - $base, $o[$_ + 1] - $o[$_] } 0 .. $len - 1;
      if ($text) { utf8::decode($_) for @v }
      return \@v;
    };
  }
  elsif ($format =~ /\Ad:(\d+),(\d+)(?:,(\d+))?\z/) {
    my ($scale, $bits) = ($2, $3 // 128);
    _refuse($column, $format) unless $bits == 128;
    my $unsigned = $id == $TYPE_UHUGEINT;
    $plan->{decode} = sub {
      my ($len, $off, $buffers) = _array_head($_[0]);
      return [] unless $len;
      my @w = unpack 'q<*', _read($buffers->[1] + 16 * $off, 16 * $len);
      return [ map { _decimal($w[2 * $_], $w[2 * $_ + 1], $scale, $unsigned) } 0 .. $len - 1 ];
    };
  }
  elsif ($format eq 'tdD') {
    $plan->{decode} = sub {
      my ($len, $off, $buffers) = _array_head($_[0]);
      return [] unless $len;
      return [ map { _infinite($_, 2147483647) // _date($_) } unpack 'l<' . $len, _read($buffers->[1] + 4 * $off, 4 * $len) ];
    };
  }
  elsif ($format eq 'ttu') {
    $plan->{decode} = sub {
      my ($len, $off, $buffers) = _array_head($_[0]);
      return [] unless $len;
      return [ map { _time($_) } unpack 'q<' . $len, _read($buffers->[1] + 8 * $off, 8 * $len) ];
    };
  }
  elsif ($format =~ /\Ats([smun]):(.*)\z/s) {
    my ($per_second, $digits) = @{ $UNIT{$1} };
    my $zoned = length $2;
    $plan->{decode} = sub {
      my ($len, $off, $buffers) = _array_head($_[0]);
      return [] unless $len;
      return [ map { _infinite($_, 9223372036854775807) // _timestamp($_, $per_second, $digits, $zoned) }
        unpack 'q<' . $len, _read($buffers->[1] + 8 * $off, 8 * $len) ];
    };
  }
  elsif ($format eq 'tin') {
    $plan->{decode} = sub {
      my ($len, $off, $buffers) = _array_head($_[0]);
      return [] unless $len;
      my @w = unpack 'l< l< q<' x $len, _read($buffers->[1] + 16 * $off, 16 * $len);
      return [ map { _interval(@w[3 * $_ .. 3 * $_ + 2]) } 0 .. $len - 1 ];
    };
  }
  elsif ($format eq '+l' or $format =~ /\A\+w:\d+\z/) {
    my ($fixed) = $format =~ /\A\+w:(\d+)\z/;
    my $kid   = _plan($kid_schemas[0], $kid_nodes[0], $column);
    $plan->{decode} = sub {
      my ($len, $off, $buffers, $kids) = _array_head($_[0]);
      return [] unless $len;
      my $values = $kid->{decode}->($kids->[0]);
      if (defined $fixed) {
        return [ map { my $at = ($off + $_) * $fixed; [ @$values[$at .. $at + $fixed - 1] ] } 0 .. $len - 1 ];
      }
      my @o = unpack 'l<' . ($len + 1), _read($buffers->[1] + 4 * $off, 4 * ($len + 1));
      return [ map { [ @$values[$o[$_] .. $o[$_ + 1] - 1] ] } 0 .. $len - 1 ];
    };
  }
  elsif ($format eq '+s') {
    my @kids  = map { _plan($kid_schemas[$_], $kid_nodes[$_], $column) } 0 .. $#kid_schemas;
    my @names = map { _string((unpack 'Q Q', _read($_, 16))[1]) } @kid_schemas;
    $plan->{decode} = sub {
      my ($len, $off, undef, $kids) = _array_head($_[0]);
      return [] unless $len;
      my @col = map { $kids[$_]{decode}->($kids->[$_]) } 0 .. $#kids;
      return [ map { my $i = $off + $_; +{ map { $names[$_] => $col[$_][$i] } 0 .. $#kids } } 0 .. $len - 1 ];
    };
  }
  elsif ($format eq '+m') {
    my (undef, undef, undef, undef, $n_entry, $entry_children)
      = unpack 'Q Q Q q q Q', _read($kid_schemas[0], 48);
    my @entry = unpack "Q$n_entry", _read($entry_children, 8 * $n_entry);
    my $key   = _plan($entry[0], $kid_nodes[0], $column);
    my $value = _plan($entry[1], $kid_nodes[1], $column);
    # a hash key is text; a nested key has none
    die sprintf "column '%s' has Arrow format '%s' with a key of Arrow format '%s', which cannot be decoded\n",
      $column, $format, $key->{format}
      if $kid_nodes[0] and $NESTED{ $kid_nodes[0]{id} };
    $plan->{decode} = sub {
      my ($len, $off, $buffers, $kids) = _array_head($_[0]);
      return [] unless $len;
      # the entries are a struct array of their own: its offset and validity count
      my (undef, $entry_off, undef, $entry_kids) = _array_head($kids->[0]);
      my @pair   = @$entry_kids;
      my $keys   = $key->{decode}->($pair[0]);
      my $values = $value->{decode}->($pair[1]);
      my $valid  = _validity($kids->[0]);
      my @o = unpack 'l<' . ($len + 1), _read($buffers->[1] + 4 * $off, 4 * ($len + 1));
      return [ map {
        +{ map { $keys->[$entry_off + $_] => $values->[$entry_off + $_] }
           grep { !$valid or $valid->[$_] } $o[$_] .. $o[$_ + 1] - 1 }
      } 0 .. $len - 1 ];
    };
  }
  else {
    _refuse($column, $format, $TYPE_NAME{$id});
  }

  # Arrow's validity bitmap, read only when the block has NULLs.
  my $values = $plan->{decode};
  $plan->{decode} = sub {
    my $out = $values->($_[0]);
    my $valid = _validity($_[0]);
    if ($valid) {
      $out->[$_] = undef for grep { !$valid->[$_] } 0 .. $#$valid;
    }
    return $out;
  };

  return $plan;
}

# One flag per value, from the validity bitmap; undef when the block has no
# NULLs (the bitmap is not read then).
sub _validity {
  my ($len, $off, $buffers, undef, $nulls) = _array_head($_[0]);
  return unless $nulls and $buffers->[0] and $len;
  my $bits = unpack 'b*', _read($buffers->[0] + ($off >> 3), (($off & 7) + $len + 7) >> 3);
  return [ split //, substr($bits, $off & 7, $len) ];
}

# ($length, $offset, \@buffers, \@children, $null_count, ...) of an ArrowArray.
sub _array_head_raw {
  return unpack 'q q q q q Q Q', _read($_[0], 56);
}

sub _array_head {
  my ($len, $nulls, $off, $n_buffers, $n_children, $buffers, $children) = _array_head_raw($_[0]);
  my @b = $n_buffers  ? unpack("Q$n_buffers",  _read($buffers,  8 * $n_buffers))  : ();
  my @c = $n_children ? unpack("Q$n_children", _read($children, 8 * $n_children)) : ();
  return ($len, $off, \@b, \@c, $nulls);
}

sub _number_decoder {
  my ($format) = @_;
  my ($size, $template) = @{ $NUMBER{$format} };
  return sub {
    my ($len, $off, $buffers) = _array_head($_[0]);
    return [] unless $len;
    return [ unpack $template . $len, _read($buffers->[1] + $size * $off, $size * $len) ];
  };
}

# ---- values -------------------------------------------------------------

# 128 bit two's complement, little-endian (as two signed words), to a decimal
# string with $scale digits behind the point.
sub _decimal {
  my ($lo, $hi, $scale, $unsigned) = @_;
  my $digits;
  my $negative = 0;
  if (!$unsigned and $hi == 0 and $lo >= 0) {
    $digits = "$lo";
  }
  elsif (!$unsigned and $hi == -1 and $lo < 0 and $lo > -9223372036854775807 - 1) {
    $digits   = -$lo;
    $negative = 1;
  }
  else {
    my $lo_u = Math::BigInt->new($lo);
    $lo_u->badd($TWO64) if $lo < 0;
    my $v = Math::BigInt->new($hi);
    $v->badd($TWO64) if $unsigned and $hi < 0;
    $v->bmul($TWO64)->badd($lo_u);
    $negative = $v->is_neg;
    $digits   = $v->babs->bstr;
  }
  if ($scale) {
    $digits = ('0' x ($scale - length($digits) + 1)) . $digits if length($digits) <= $scale;
    substr($digits, -$scale, 0) = '.';
  }
  return $negative ? "-$digits" : $digits;
}

# Days since 1970-01-01 to YYYY-MM-DD (proleptic Gregorian).
sub _civil {
  my ($days) = @_;
  use integer;
  my $z   = $days + 719468;
  my $era = ($z >= 0 ? $z : $z - 146096) / 146097;
  my $doe = $z - $era * 146097;
  my $yoe = ($doe - $doe / 1460 + $doe / 36524 - $doe / 146096) / 365;
  my $doy = $doe - (365 * $yoe + $yoe / 4 - $yoe / 100);
  my $mp  = (5 * $doy + 2) / 153;
  my $d   = $doy - (153 * $mp + 2) / 5 + 1;
  my $m   = $mp < 10 ? $mp + 3 : $mp - 9;
  my $y   = $yoe + $era * 400 + ($m <= 2 ? 1 : 0);
  return ($y, $m, $d);
}

# DuckDB writes +infinity as the largest value of the storage type and
# -infinity as the smallest plus one; its text for them is the word.
sub _infinite {
  my ($v, $max) = @_;
  return $v == $max ? 'infinity' : $v == -$max ? '-infinity' : undef;
}

# DuckDB's text: years up to 0 are written as 1 - year with " (BC)".
sub _date {
  my ($y, $m, $d) = _civil($_[0]);
  return $y > 0 ? sprintf('%04d-%02d-%02d', $y, $m, $d) : sprintf('%04d-%02d-%02d (BC)', 1 - $y, $m, $d);
}

# floor division and remainder, for epochs before 1970
sub _divmod {
  my ($n, $d) = @_;
  use integer;
  my $q = $n / $d;
  my $r = $n - $q * $d;
  if ($r < 0) { $q--; $r += $d }
  return ($q, $r);
}

sub _clock {
  my ($seconds) = @_;
  return sprintf '%02d:%02d:%02d', int($seconds / 3600), int(($seconds % 3600) / 60), $seconds % 60;
}

# TIME: microseconds since midnight; DuckDB's text has the fraction without
# trailing zeros, and none when it is zero.
sub _time {
  my ($micros) = @_;
  my ($s, $f) = _divmod($micros, 1_000_000);
  my $fraction = $f ? sprintf('.%06d', $f) : '';
  $fraction =~ s/0+\z//;
  return _clock($s) . $fraction;
}

sub _timestamp {
  my ($v, $per_second, $digits, $zoned) = @_;
  my ($s, $f)    = _divmod($v, $per_second);
  my ($days, $t) = _divmod($s, 86400);
  my $fraction = $f ? sprintf(".%0${digits}d", $f) : '';
  # DuckDB's own text: the fraction has no trailing zeros
  $fraction =~ s/0+\z//;
  return _date($days) . ' ' . _clock($t) . $fraction . ($zoned ? '+00' : '');
}

# DuckDB's own text form of an INTERVAL: months and days, then the time.
sub _interval {
  my ($months, $days, $nanos) = @_;
  my @part;
  my ($years, $mon) = (int($months / 12), $months % 12);
  $mon -= 12 if $months < 0 and $mon > 0;
  my $unit = sub { push @part, "$_[0] $_[1]" . (abs($_[0]) == 1 ? '' : 's') if $_[0] };
  $unit->($years, 'year');
  $unit->($mon,   'month');
  $unit->($days,  'day');
  if ($nanos) {
    my $micros = int($nanos / 1000);
    my $sign   = $micros < 0 ? '-' : '';
    $micros = abs $micros;
    my ($s, $f) = (int($micros / 1_000_000), $micros % 1_000_000);
    my $fraction = $f ? sprintf('.%06d', $f) : '';
    $fraction =~ s/0+\z//;
    push @part, $sign . sprintf('%02d:%02d:%02d', int($s / 3600), int(($s % 3600) / 60), $s % 60) . $fraction;
  }
  return @part ? join(' ', @part) : '00:00:00';
}

# ---- the fetch ----------------------------------------------------------


sub fetch {
  my ($class, $dbh, $sql, $binds, $mask) = @_;
  $mask //= sub { $_[0] };

  my $sth;
  my @cleanup;
  my $result = try {
    $sth = $dbh->prepare($sql);
    $sth->execute(@{ $binds // [] });

    my $res   = $sth->{duckdb_res};
    my @types = @{ $sth->{duckdb_col_logical_types} // [] };
    my @names = @{ $sth->{NAME} };
    my $n     = @names;

    my @trees = map { _type_tree($_) } @types;

    my $options = DBD::DuckDB::FFI::duckdb_result_get_arrow_options($res);
    push @cleanup, sub { DBD::DuckDB::FFI::duckdb_destroy_arrow_options(\$options) };

    my $schema = FFI::Platypus::Memory::calloc(1, $SCHEMA_BYTES);
    push @cleanup, sub { FFI::Platypus::Memory::free($schema) };
    my $failure = _error(_to_arrow_schema($options, \@types, \@names, $n, $schema));
    die $mask->($failure) . "\n" if defined $failure;
    push @cleanup, sub { _release($schema, 56) };

    my (undef, undef, undef, undef, undef, $children) = unpack 'Q Q Q q q Q', _read($schema, 48);
    my @column_schemas = $n ? unpack("Q$n", _read($children, 8 * $n)) : ();

    my @plans = map { _plan($column_schemas[$_], $trees[$_], $names[$_]) } 0 .. $n - 1;

    my @columns = map { [] } 1 .. $n;
    my $rows    = 0;
    while (my $chunk = DBD::DuckDB::FFI::duckdb_fetch_chunk($res)) {
      my $array = FFI::Platypus::Memory::calloc(1, $ARRAY_BYTES);
      try {
        my $failure = _error(DBD::DuckDB::FFI::duckdb_data_chunk_to_arrow($options, $chunk, $array));
        die $mask->($failure) . "\n" if defined $failure;
        my ($len, $off, undef, $kids) = _array_head($array);
        for my $c (0 .. $n - 1) {
          push @{ $columns[$c] }, @{ $plans[$c]{decode}->($kids->[$c]) };
        }
        $rows += $len;
      }
      catch { die $_ }
      finally {
        _release($array, 64);
        FFI::Platypus::Memory::free($array);
        my $c = $chunk;
        DBD::DuckDB::FFI::duckdb_destroy_data_chunk(\$c);
      };
    }

    +{
      names   => \@names,
      formats => [ map { $_->{format} } @plans ],
      columns => \@columns,
      rows    => $rows,
    };
  }
  catch { die $_ }
  finally {
    for my $step (reverse @cleanup) { eval { $step->(); 1 } }
    eval { $sth->finish } if $sth;
  };

  return $result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::Arrow - Read a DuckDB result through libduckdb's Arrow interface

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The decoder behind L<DBIO::DuckDB::Storage/duckdb_arrow_fetch>; call that
method, not this module. It prepares and executes the statement on the DBI
handle, converts the result block by block with libduckdb's
C<duckdb_to_arrow_schema> and C<duckdb_data_chunk_to_arrow> and decodes the
Arrow buffers of each column in one C<unpack> per buffer. DuckDB's type ids
decide what Arrow's formats cannot (UHUGEINT against HUGEINT, BIT and BIGNUM
against BLOB, TIME WITH TIME ZONE against TIME). Every pointer libduckdb hands
out is released on every way out.

=head1 METHODS

=head2 fetch

    my $t = DBIO::DuckDB::Arrow->fetch($dbh, $sql, \@binds, \&mask);

Returns C<< { names, formats, columns, rows } >> as described at
L<DBIO::DuckDB::Storage/duckdb_arrow_fetch>; dies with a message naming the
column and the Arrow format for a type it cannot render. The optional
C<\&mask> is called with the text libduckdb reports for a failed conversion
and answers the text to die with; the storage hands in its
C<_mask_error_values>. Without it the text is used as it is.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
