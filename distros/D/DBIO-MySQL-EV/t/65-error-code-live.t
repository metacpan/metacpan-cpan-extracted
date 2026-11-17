use strict;
use warnings;
use Test::More;

# LIVE (ADR 0075 of the core). The server words its errors in the language of
# the session (lc_messages), and the rules that take a value out of an
# English sentence do not read German or French. A value shorter than four
# characters is not found by the bound-value pass either, so under de_DE or
# fr_FR a `Doppelter Eintrag 'ab' fuer Schluessel ...` or a
# `Duplicata du champ 'ab' ...` left the value in the message. The error
# number of the server is the same in every language and EV::MariaDB holds it
# on the handle: the transport hands it to the masker, which masks by the
# code.
#
# This file puts its own sessions into German and into French (no matter
# what DBIO_TEST_SERVER_LANGUAGE says), makes the server refuse a SHORT value
# with a duplicate entry (1062) and an incorrect integer value (1366), and
# asks every way a server text reaches the caller: the pool (statements with
# binds and with a literal), a transaction's pinned connection, and the listen
# connection's statement runner. The table is fw_ev_code_<pid>, created here
# and dropped at the end. Gated like the other live tests: DBIO_TEST_MYSQL_DSN,
# _USER, _PASS.

use DBIO::MySQL::EV::TestHarness;

DBIO::MySQL::EV::TestHarness->skip_all_unless_live;

$SIG{ALRM} = sub { BAIL_OUT('t/65-error-code-live.t: alarm, a wait did not end') };
alarm 240;

{
  package T65L::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL', 'MySQL::EV');
}

my $T = "fw_ev_code_$$";

for my $locale (qw(de_DE fr_FR)) {
  my $h = DBIO::MySQL::EV::TestHarness->new(
    schema_class  => 'T65L::Schema',
    connect_attrs => {
      pool_size     => 1,
      # replayed after every reset of a borrow: the session stays in the language
      on_connect_do => ['SET NAMES utf8mb4', "SET SESSION lc_messages = '$locale'"],
    },
  );
  my $async = $h->async;

  my $run = sub {
    my ($sql, $bind) = @_;
    my @r = eval { $h->await($async->_query_async($sql, $bind || [])) };
    return $@ ? $@ : '';
  };

  $run->("DROP TABLE IF EXISTS $T");
  my $setup = $run->("CREATE TABLE $T (id INT NOT NULL PRIMARY KEY, i INT NULL, u VARCHAR(20) NULL, UNIQUE KEY fw_ev_code_u (u)) ENGINE=InnoDB");
  die "setup failed: $setup" if $setup;
  $run->("INSERT INTO $T (id, i, u) VALUES (1, 1, 'ab'), (2, 2, 'xy')");

  my ($lc) = map { $_->[0] } $h->await($async->_query_async('SELECT @@lc_messages', []));
  is $lc, $locale, "$locale: the session of the pool is in the language";

  # [ label, sql, binds, the value that must be gone, qr of what must stay ]
  my @cases = (
    [ 'duplicate entry, bound',   "INSERT INTO $T (id, u) VALUES (?, ?)", [11, 'ab'], q{'ab'}, qr/'\*\*\*'.*fw_ev_code_u/ ],
    [ 'duplicate entry, literal', "INSERT INTO $T (id, u) VALUES (12, 'xy')", [],      q{'xy'}, qr/'\*\*\*'.*fw_ev_code_u/ ],
    [ 'incorrect value, bound',   "INSERT INTO $T (id, i) VALUES (?, ?)", [13, 'ab'],  q{'ab'}, qr/'\*\*\*'.*\bi\b/ ],
    [ 'incorrect value, literal', "INSERT INTO $T (id, i) VALUES (14, 'xy')", [],      q{'xy'}, qr/'\*\*\*'.*\bi\b/ ],
  );

  for my $case (@cases) {
    my ($label, $sql, $bind, $gone, $keep) = @$case;

    my $err = $run->($sql, $bind);
    ok length "$err", "$locale: $label: the statement fails" or next;
    diag "$locale: $label: $err" if $ENV{DBIO_TEST_VERBOSE};
    ok index("$err", $gone) < 0, "$locale: $label: no $gone in the message";
    like "$err", $keep, "$locale: $label: the key or column stays, the value is masked";
    isa_ok $err, 'DBIO::Exception::Server', "$locale: $label: the exception";

    # a transaction: the pinned connection
    my $tx = eval {
      $h->await($async->txn_do_async(sub { $_[0]->_query_async($sql, $bind) }));
      1;
    } ? '' : $@;
    ok length "$tx", "$locale: $label: the transaction fails";
    ok index("$tx", $gone) < 0, "$locale: $label: in a transaction, no $gone in the message";
    like "$tx", $keep, "$locale: $label: in a transaction, the key or column stays";
  }

  # the listen connection's statement runner
  {
    my $conn = eval { $h->await($async->_listen_open) };
    ok $conn, "$locale: the listen connection opens" or diag $@;
    if ($conn) {
      # the listen connection is outside the pool: no connect actions reach it
      my $set = $async->future_class->new;
      $conn->{mdb}->query("SET SESSION lc_messages = '$locale'", sub { $set->done(1) });
      $h->await($set);
      for my $case (@cases) {
        my ($label, $sql, $bind, $gone, $keep) = @$case;
        my $f = $async->_mysql_listen_statement($conn, $sql, $bind);
        eval { $h->await($f) };
        my $err = $@ || '';
        ok length "$err", "$locale: $label: the listen statement fails";
        ok index("$err", $gone) < 0, "$locale: $label: on the listen connection, no $gone in the message";
        like "$err", $keep, "$locale: $label: on the listen connection, the key or column stays";
      }
      $async->_listen_close($conn);
    }
  }

  $run->("DROP TABLE IF EXISTS $T");
  $h->disconnect;
}

done_testing;
