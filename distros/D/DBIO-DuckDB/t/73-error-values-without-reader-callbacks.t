#!/usr/bin/env perl
# t/73-error-values-without-reader-callbacks.t -- the values bound to a
# refused statement stay out of the exception whether or not the storage's
# bind_param / fetch callbacks (the DBD::DuckDB <= 0.16 workarounds) are
# installed on the handle.
#
# WHY this matters: the masking of the engine's text goes through core's
# _mask_error_values hook, which is given the bound values by core itself. It
# must not depend on a driver-side record of the binds that only exists where
# the callbacks do; a newer DBD::DuckDB drops them, and the rule "an error
# message names no value" must hold there too. The forms: a value in a
# sentence the masker knows, a value only core's net can find (the name of a
# sequence taken from a bind), and a value outside ASCII. Every form runs on a
# handle without the callbacks and on one with them.

use strict;
use warnings;
use utf8;
use Test::More;
use DBIO::DuckDB::Test;
use DBIO::DuckDB::Storage;

my @forms = (
  [ 'value in a sentence', 'INSERT INTO p (id, nn) VALUES (?, ?)',
    [ 1, 'geheim42' ], 'geheim42', qr/Could not convert string '\*\*\*' to INT32/ ],
  [ 'value outside any sentence (sequence name)', 'SELECT nextval(?)',
    [ 'folge_geheim7' ], 'folge_geheim7', qr/Catalog Error/ ],
  [ 'non-ASCII value in a sentence', 'INSERT INTO p (id, nn) VALUES (?, ?)',
    [ 2, 'Grüße-geheim' ], 'Grüße-geheim', qr/Could not convert string/ ],
  [ 'non-ASCII value outside any sentence', 'SELECT nextval(?)',
    [ 'Größe_geheim9' ], 'Größe_geheim9', qr/Catalog Error/ ],
);

for my $with_callbacks (0, 1) {
  my $tag = $with_callbacks ? 'callbacks installed' : 'no callbacks';
  my $schema = do {
    no warnings 'redefine';
    my $orig = \&DBIO::DuckDB::Storage::_duckdb_text_callbacks;
    local *DBIO::DuckDB::Storage::_duckdb_text_callbacks = $with_callbacks ? $orig : sub { };
    my $s = DBIO::DuckDB::Test->init_schema(no_populate => 1);
    $s->storage->dbh;
    $s;
  };
  my $storage = $schema->storage;
  my $dbh     = $storage->dbh;

  is !!$dbh->{private_dbio_duckdb_text_callbacks}, !!$with_callbacks,
    "$tag: the handle is as the case wants it";

  $dbh->do(q{CREATE TABLE p (id INTEGER PRIMARY KEY, nn INTEGER, name VARCHAR)});

  my $refused = sub {
    my ($sql, @binds) = @_;
    my $ok = eval {
      $storage->_dbh_execute($storage->_get_dbh, $sql, [ map { [ {}, $_ ] } @binds ]);
      1;
    };
    return $ok ? undef : "$@";
  };

  for my $f (@forms) {
    my ($name, $sql, $binds, $marker, $stays) = @$f;
    $name = "$tag, $name";
    my $e = $refused->($sql, @$binds);
    ok defined $e, "$name: refused" or next;
    my $text  = "$e";
    my $bytes = $text;
    utf8::encode($bytes);
    my $marker_bytes = $marker;
    utf8::encode($marker_bytes);
    unlike $text, qr/\Q$marker\E/, "$name: the value is not in the exception";
    unlike $bytes, qr/\Q$marker_bytes\E/, "$name: nor its UTF-8 bytes";
    unlike $text, qr/\Q$marker_bytes\E/, "$name: nor its UTF-8 bytes in a text that holds bytes";
    like $text, $stays, "$name: what the caller needs stays";
    like $text, qr/\[for Statement "\Q$sql\E" with \d+ bind values?\]/, "$name: core's appendix stays";
  }
}

done_testing;
