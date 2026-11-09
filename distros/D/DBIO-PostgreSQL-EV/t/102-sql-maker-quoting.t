use strict;
use warnings;

use Test::More;

use DBIO::Schema;
use DBIO::PostgreSQL::Storage;
use DBIO::PostgreSQL::EV::Storage;

# OFFLINE test, karr k88 (from dbio-postgresql k121, maintainer's decision
# 2026-10-16): the ev transport quotes as the connection says.
#
# CLAIM: one connect_info, one quoting -- the SQL maker of the ev transport
# quotes exactly as the sync maker of the same connection does, because it
# takes quote_char and name_sep from it. Until now the transport wrote
# quote_char '"' and name_sep '.' whatever the connection said: an explicit
# quote_char/name_sep was not used on the async path, and where the sync maker
# writes identifiers unquoted the async one quoted them. What stays:
# limit_dialect LimitOffset, and a backend built without an owning sync
# storage quotes with " and . (the defaults of DBIO::PostgreSQL::Storage).
#
# Every case compares the two makers of one connection, which holds against
# any dbio-postgresql. The SQL each one writes is asserted as well; for
# `quote_names => 0` alone and an empty `quote_char` alone that is the sync
# maker's rule since dbio-postgresql karr k121 (bf640c4: quoting turned off
# stays off) -- against an older one the sync maker quotes there, and those
# expectations are skipped, the comparison is not.
#
# No connection is opened: the pool is lazy, the makers are built from the
# stored connect info.

{
  package DBIO::Test::K88EvQuote;
  $INC{'DBIO/Test/K88EvQuote.pm'} = 1;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

# Does the installed sync storage leave quoting off where it was turned off?
my $sync_off = do {
  my $s = DBIO::PostgreSQL::Storage->new('DBIO::Schema');
  $s->connect_info([ 'dbi:Pg:dbname=x', 'u', 'p', { quote_names => 0 } ]);
  !$s->sql_maker->_quote_chars;
};

sub sql_of {
  my ($sm, $sep) = @_;
  my ($sql) = $sm->select("Sch${sep}Tbl", ["Tbl${sep}Col"], { "Tbl${sep}Col" => 1 }, undef, 5);
  return $sql;
}

# name, connect attributes, SQL both write, quote_char, name_sep, needs k121
for my $case (
  [ 'nothing said'            => {},                   'SELECT "Tbl"."Col" FROM "Sch"."Tbl" WHERE ( "Tbl"."Col" = ? ) LIMIT ?', '"', '.', 0 ],
  [ 'quote_names => 1'        => { quote_names => 1 }, 'SELECT "Tbl"."Col" FROM "Sch"."Tbl" WHERE ( "Tbl"."Col" = ? ) LIMIT ?', '"', '.', 0 ],
  [ 'quote_names => 0 alone'  => { quote_names => 0 }, 'SELECT Tbl.Col FROM Sch.Tbl WHERE ( Tbl.Col = ? ) LIMIT ?',             undef, '.', 1 ],
  [ q{quote_char => '' alone} => { quote_char => '' }, 'SELECT Tbl.Col FROM Sch.Tbl WHERE ( Tbl.Col = ? ) LIMIT ?',             undef, '.', 1 ],
  [ q{quote_names => 0, quote_char => ''}
                              => { quote_names => 0, quote_char => '' },
                                                       'SELECT Tbl.Col FROM Sch.Tbl WHERE ( Tbl.Col = ? ) LIMIT ?',             undef, '.', 0 ],
  [ 'an explicit quote_char and name_sep'
                              => { quote_char => '`', name_sep => '@' },
                                                       'SELECT `Tbl`@`Col` FROM `Sch`@`Tbl` WHERE ( `Tbl`@`Col` = ? ) LIMIT ?', '`', '@', 0 ],
) {
  my ($name, $attrs, $want_sql, $want_qc, $want_sep, $needs_k121) = @$case;

  my $schema = DBIO::Test::K88EvQuote->connect(
    'dbi:Pg:dbname=x', 'u', 'p', { async => 'ev', %$attrs },
  );
  my $storage = $schema->storage;
  my $async   = $storage->async;
  isa_ok $async, 'DBIO::PostgreSQL::EV::Storage', "$name: the backend";

  my %maker = (sync => $storage->sql_maker, ev => $async->sql_maker);

  is sql_of($maker{ev}, $want_sep), sql_of($maker{sync}, $want_sep),
    "$name: the ev maker writes what the sync maker of the connection writes";
  is $maker{ev}{name_sep}, $maker{sync}{name_sep}, "$name: ... with its name_sep";
  is $maker{ev}{limit_dialect}, 'LimitOffset', "$name: ... and keeps limit_dialect LimitOffset";

  SKIP: {
    skip "$name: the sync maker quotes here -- needs dbio-postgresql with karr k121 (bf640c4)", 4
      if $needs_k121 && !$sync_off;
    for my $side (qw(sync ev)) {
      my $sm = $maker{$side};
      is sql_of($sm, $want_sep), $want_sql, "$name: $side maker writes $want_sql";
      if (defined $want_qc) {
        is $sm->{quote_char}, $want_qc, "$name: $side quote_char is $want_qc";
      }
      else {
        ok !$sm->_quote_chars, "$name: $side maker has no quote chars";
      }
    }
  }
}

# A backend without an owning sync storage: built on its own, as
# DBIO::PostgreSQL::EV::Storage->new(undef) plus connect_info. Core takes the
# quoting options out of the connect info a backend is given, so there is no
# connection to follow: " and ., the defaults of DBIO::PostgreSQL::Storage.
{
  my $alone = DBIO::PostgreSQL::EV::Storage->new(undef);
  $alone->connect_info([ 'dbi:Pg:dbname=x', 'u', 'p', { quote_names => 0, quote_char => '`' } ]);
  ok !$alone->_owner_storage, 'a backend built on its own has no owning sync storage';
  my $sm = $alone->sql_maker;
  is sql_of($sm, '.'), 'SELECT "Tbl"."Col" FROM "Sch"."Tbl" WHERE ( "Tbl"."Col" = ? ) LIMIT ?',
    '... and quotes with " and ., whatever its connect info said';
  is $sm->{limit_dialect}, 'LimitOffset', '... with limit_dialect LimitOffset';
}

done_testing;
