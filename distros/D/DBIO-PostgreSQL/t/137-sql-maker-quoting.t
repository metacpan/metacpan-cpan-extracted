use strict;
use warnings;

use Test::More;

use DBIO::Schema;
use DBIO::PostgreSQL::Storage;

# OFFLINE test, karr k121 point U5: identifier quoting that a connection turned
# off stays off on DBIO::PostgreSQL::Storage.
#
# CLAIM: the SQL maker of this storage is the core's, as it comes. Core quotes
# by default, and a connection that says it does not want quoting -- either
# `quote_names => 0` or an empty `quote_char` -- gets none. The storage used
# to fill a missing quote_char back in (`$sm->{quote_char} //= '"'`), which
# made both of those quote regardless; only the pair
# { quote_names => 0, quote_char => '' } held. That was the old claim; this is
# its replacement, decided by the maintainer. What is NOT changed: nothing
# said -> quoted with " and . ; an explicit quote_char/name_sep is used as given.
#
# No connection is made: connect_info is stored, sql_maker is built from it.

sub maker_for {
  my ($attrs) = @_;
  my $storage = DBIO::PostgreSQL::Storage->new('DBIO::Schema');
  $storage->connect_info([ 'dbi:Pg:dbname=x', 'u', 'p', $attrs ]);
  return $storage->sql_maker;
}

sub select_sql {
  my ($sm) = @_;
  my ($sql) = $sm->select('Tbl', ['Col'], {});
  return $sql;
}

for my $case (
  [ 'nothing said'                          => {},                                     'SELECT "Col" FROM "Tbl"' ],
  [ 'quote_names => 1'                      => { quote_names => 1 },                   'SELECT "Col" FROM "Tbl"' ],
  [ 'quote_names => 0 alone'                => { quote_names => 0 },                   'SELECT Col FROM Tbl' ],
  [ q{quote_char => '' alone}               => { quote_char => '' },                   'SELECT Col FROM Tbl' ],
  [ q{quote_names => 0, quote_char => ''}   => { quote_names => 0, quote_char => '' }, 'SELECT Col FROM Tbl' ],
  [ 'an explicit quote_char is kept'        => { quote_char => '`', name_sep => '@' }, 'SELECT `Col` FROM `Tbl`' ],
) {
  my ($name, $attrs, $want) = @$case;
  is select_sql(maker_for($attrs)), $want, $name;
}

# the separator is the maker's own, quoting or not
{
  my $sm = maker_for({});
  is $sm->{name_sep}, '.', 'default name_sep is .';
  is $sm->{quote_char}, '"', 'default quote_char is "';
  my $off = maker_for({ quote_names => 0 });
  is $off->{name_sep}, '.', 'name_sep stays . with quoting off';
  ok !$off->_quote_chars, 'no quote chars with quote_names => 0';
}

# ---------------------------------------------------------------------------
# The future_io transport follows the same connection (karr k121, maintainer's
# decision 2026-10-16).
#
# CLAIM: one connect_info, one quoting -- the SQL maker of the future_io
# transport quotes exactly as the sync maker of the same connection does,
# because it takes quote_char and name_sep from it. Until now the transport
# wrote quote_char '"' and name_sep '.' whatever the connection said, so
# quote_names => 0 or an empty quote_char gave unquoted SQL on the sync path
# and quoted SQL on the async one, and an explicit quote_char/name_sep was
# not used there at all. What stays: limit_dialect LimitOffset, and the
# transport's own maker (no bindtype; t/41-upsert-on-conflict.t).
#
# Both makers come from one schema connected with async => 'future_io'; no
# connection is opened (the backend's pool is lazy).
# ---------------------------------------------------------------------------

SKIP: {
  skip 'DBIO::Async not installed (recommends only) -- future_io transport unavailable', 1
    unless eval { require DBIO::PostgreSQL::Storage::Async; 1 };

  {
    package DBIO::Test::K121AsyncQuote;
    $INC{'DBIO/Test/K121AsyncQuote.pm'} = 1;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('PostgreSQL');
  }

  # name, connect attributes, SQL of both makers, quote_char, name_sep
  for my $case (
    [ 'nothing said'            => {},                   'SELECT "Tbl"."Col" FROM "Sch"."Tbl"', '"', '.' ],
    [ 'quote_names => 1'        => { quote_names => 1 }, 'SELECT "Tbl"."Col" FROM "Sch"."Tbl"', '"', '.' ],
    [ 'quote_names => 0 alone'  => { quote_names => 0 }, 'SELECT Tbl.Col FROM Sch.Tbl',         undef, '.' ],
    [ q{quote_char => '' alone} => { quote_char => '' }, 'SELECT Tbl.Col FROM Sch.Tbl',         undef, '.' ],
    [ q{quote_names => 0, quote_char => ''}
                                => { quote_names => 0, quote_char => '' },
                                                         'SELECT Tbl.Col FROM Sch.Tbl',         undef, '.' ],
    [ 'an explicit quote_char and name_sep'
                                => { quote_char => '`', name_sep => '@' },
                                                         'SELECT `Tbl`@`Col` FROM `Sch`@`Tbl`', '`', '@' ],
  ) {
    my ($name, $attrs, $want_sql, $want_qc, $want_sep) = @$case;
    my $schema = DBIO::Test::K121AsyncQuote->connect(
      'dbi:Pg:dbname=x', 'u', 'p', { async => 'future_io', %$attrs },
    );
    my $storage = $schema->storage;
    my %maker = (
      sync      => $storage->sql_maker,
      future_io => $storage->_async_storage->sql_maker,
    );
    isa_ok $storage->_async_storage, 'DBIO::PostgreSQL::Storage::Async', "$name: the backend";

    for my $side (qw(sync future_io)) {
      my $sm = $maker{$side};
      my ($sql) = $sm->select('Sch.Tbl', ['Tbl.Col'], {});
      $sql = $sm->select('Sch@Tbl', ['Tbl@Col'], {}) if $want_sep eq '@';
      is $sql, $want_sql, "$name: $side maker writes $want_sql";
      if (defined $want_qc) {
        is $sm->{quote_char}, $want_qc, "$name: $side quote_char is $want_qc";
      }
      else {
        ok !$sm->_quote_chars, "$name: $side maker has no quote chars";
      }
      is $sm->{name_sep}, $want_sep, "$name: $side name_sep is $want_sep";
    }

    is $maker{future_io}{limit_dialect}, 'LimitOffset',
      "$name: the future_io maker keeps limit_dialect LimitOffset";
  }
}

done_testing;
