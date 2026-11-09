package DBIO::ClickHouse::Test::Schema::Probe;
# ABSTRACT: Test result class -- one column per branch of the DDL type map

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Core';


__PACKAGE__->table('dbio_test_probe');

__PACKAGE__->add_columns(
  # the key
  id => { data_type => 'integer', is_nullable => 0 },

  # integers, by width, signed and unsigned
  i8  => { data_type => 'tinyint',  is_nullable => 0 },
  i16 => { data_type => 'smallint', is_nullable => 0 },
  i64 => { data_type => 'bigint',   is_nullable => 0 },
  u32 => { data_type => 'integer', extra => { unsigned => 1 }, is_nullable => 0 },
  u64 => { data_type => 'bigint',  extra => { unsigned => 1 }, is_nullable => 0 },

  # floats and fixed point
  f32    => { data_type => 'real',             is_nullable => 0 },
  f64    => { data_type => 'double precision', is_nullable => 0 },
  dec    => { data_type => 'decimal', size => [10, 2], is_nullable => 0 },
  amount => { data_type => 'money',   is_nullable => 0 },

  # the string family, all of which collapse onto String
  s_var  => { data_type => 'varchar', size => 255, is_nullable => 0 },
  s_text => { data_type => 'text',    is_nullable => 0 },
  s_blob => { data_type => 'blob',    is_nullable => 0 },
  s_json => { data_type => 'json',    is_nullable => 0 },

  # the two opt-in string encodings
  s_fixed => { data_type => 'char', size => 3, is_nullable => 0,
               extra => { fixed_string => 1 } },
  s_low   => { data_type => 'varchar', size => 32, is_nullable => 0,
               extra => { low_cardinality => 1 } },

  # LowCardinality nests OUTSIDE Nullable
  s_low_null => { data_type => 'varchar', size => 32, is_nullable => 1,
                  extra => { low_cardinality => 1 } },

  # misc scalars
  flag => { data_type => 'boolean', is_nullable => 0 },
  guid => { data_type => 'uuid',    is_nullable => 0 },
  ip   => { data_type => 'IPv4',    is_nullable => 0 },

  # temporal: portable spelling vs exact native spelling
  d_wide   => { data_type => 'date',        is_nullable => 0 },
  d_narrow => { data_type => 'Date',        is_nullable => 0 },
  ts_ms    => { data_type => 'datetime',    is_nullable => 0 },
  ts_sec   => { data_type => 'DateTime',    is_nullable => 0 },
  ts_utc   => { data_type => 'timestamptz', is_nullable => 0 },
  t_str    => { data_type => 'time',        is_nullable => 0 },

  # enum, with a member that needs escaping
  state => { data_type => 'enum', is_nullable => 0,
             extra => { list => ['draft', 'live', q{it's}] } },

  # arrays are never wrapped in Nullable()
  tags => { data_type => 'text[]',    is_nullable => 1 },
  nums => { data_type => 'integer[]', is_nullable => 0 },

  # nullability and the two default shapes
  note    => { data_type => 'varchar', size => 64, is_nullable => 1 },
  title   => { data_type => 'varchar', size => 64, is_nullable => 0,
               default_value => 'untitled' },
  counter => { data_type => 'bigint', is_nullable => 0, default_value => \'0' }
);

__PACKAGE__->set_primary_key('id');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::Test::Schema::Probe - Test result class -- one column per branch of the DDL type map

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

One column for every branch L<DBIO::ClickHouse::DDL/Type mapping> can take.
This table exists so that B<deploying> L<DBIO::ClickHouse::Test::Schema> is
itself the answer to "does the server accept every type this driver can emit",
without a single assertion being written: a rejected type is a failed
C<CREATE TABLE>, and a type the catalog reports back differently is a phantom
diff in C<t/30-deploy.t>.

The columns, and the decision each one carries:

=over 4

=item * B<the integer widths> -- the map is width-preserving rather than
one-size-fits-all C<Int64>, and C<< extra => { unsigned => 1 } >> selects the
C<UInt*> counterpart.

=item * B<C<flag>> -- C<boolean> maps to C<Bool>, B<not> C<UInt8>. C<Bool> is
an alias for C<UInt8> inside the engine, so the whole mapping only holds if the
catalog reports the alias back. C<t/18-types-live.t> asserts exactly that.

=item * B<C<d_wide> / C<d_narrow>> -- portable C<date> maps to C<Date32>
(1900-2299) while the exact native spelling C<'Date'> reaches the two-byte type
that starts at 1970. Both must exist for the escape hatch to be reachable.

=item * B<C<ts_ms> / C<ts_sec> / C<ts_utc>> -- the same rule for
C<DateTime64(3)> vs native C<DateTime>, plus the timezone-in-the-type form.

=item * B<C<state>> -- an enum member containing an apostrophe, so the
C<\'> escaping L<DBIO::ClickHouse::DDL::Emit/quote_string> emits is executed by
the server rather than only pinned offline.

=item * B<C<s_fixed>> -- C<FixedString(N)> is opt-in and pads with zero
B<bytes>, which is the reason it is never inferred from C<char(N)>.

=item * B<C<title> / C<counter>> -- a scalar C<default_value> renders as a
quoted literal, a SCALAR ref verbatim; both have to survive the round trip
through C<system.columns.default_expression>.

=back

C<JSON> is deliberately B<not> here. It is the one type in the map whose
availability depends on the server version and on an experimental setting, so a
server that rejects it would take the entire schema -- and therefore every live
test file -- down with it. It is probed on its own table in
C<t/18-types-live.t> instead.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
