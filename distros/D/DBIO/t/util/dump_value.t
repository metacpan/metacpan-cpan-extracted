use strict;
use warnings;
use Test::More;

use DBIO::Util qw(dump_value);

# ADR 0027: this is the ONE legitimate place that pins dump_value's exact byte
# form. dump_value adopts upstream DBIx::Class::_Util::dump_value's
# Useqq(1) + Quotekeys(0) form (bare keys, double-quoted values) on top of the
# existing Indent=1 / Terse=1 / Sortkeys=1. A later "simplify back to single
# quotes" must break HERE, not in scattered driver/consumer tests.

# --- canonical bare-key / double-quoted form for a representative hash --------
{
  my $out = dump_value({ id => 42, name => 'pop_art_1' });

  like $out, qr/\bid => 42\b/,
    'numeric value is unquoted, key is bare (no quotes)';
  like $out, qr/\bname => "pop_art_1"/,
    'string value is double-quoted, key is bare (no quotes)';

  unlike $out, qr/'/,
    'no single quotes anywhere (Useqq + Quotekeys off)';
  unlike $out, qr/["']id["']\s*=>/,
    'hash key "id" is not quoted (Quotekeys off)';
  unlike $out, qr/["']name["']\s*=>/,
    'hash key "name" is not quoted (Quotekeys off)';
}

# --- Sortkeys ordering is honoured (keys come out sorted) --------------------
{
  my $out = dump_value({ zebra => 1, alpha => 2, mango => 3 });

  my $alpha = index $out, 'alpha';
  my $mango = index $out, 'mango';
  my $zebra = index $out, 'zebra';

  ok $alpha >= 0 && $mango >= 0 && $zebra >= 0, 'all keys present in dump';
  ok $alpha < $mango && $mango < $zebra,
    'Sortkeys: keys emitted in sorted order (alpha < mango < zebra)';
}

# --- nested structure (hash containing an arrayref) renders in same form -----
{
  my $out = dump_value({ tags => [ 'red', 'blue' ], count => 2 });

  like $out, qr/\bcount => 2\b/, 'nested: numeric scalar unquoted, bare key';
  like $out, qr/\btags => \[/,   'nested: arrayref key is bare';
  like $out, qr/"red"/,          'nested: array element double-quoted';
  like $out, qr/"blue"/,         'nested: array element double-quoted';
  unlike $out, qr/'/,            'nested: no single quotes anywhere';
}

# --- round-trip: Terse=1 emits a bare evaluatable literal --------------------
{
  for my $struct (
    { id => 42, name => 'pop_art_1' },
    { tags => [ 'red', 'blue' ], count => 2, meta => { nested => 'deep' } },
    [ 1, 'two', { three => 3 } ],
  ) {
    my $dumped = dump_value($struct);
    my $back = eval $dumped;  ## no critic
    is $@, '', 'dump_value output evals cleanly (Terse bare literal)';
    is_deeply $back, $struct,
      'round-trip: eval(dump_value($x)) is_deeply $x';
  }
}

done_testing;
