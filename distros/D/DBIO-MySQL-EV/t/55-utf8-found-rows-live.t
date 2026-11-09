use strict;
use warnings;
use utf8;
use Test::More;

# LIVE, karr k80 (maintainer's decision 2026-10-22): what the DBD-only
# settings mean on the wire, measured against the DBDs themselves.
#
#   a) mysql_enable_utf8mb4=1 (DSN or attribute hash) is charset utf8mb4 plus
#      utf8 flagging on this transport. Umlauts, CJK and a 4-byte emoji go out
#      as bind values and come back as the same characters, and what the server
#      stored (CHAR_LENGTH, HEX) and the session character set are the same as
#      when DBD::mysql (mysql_enable_utf8mb4=1) and DBD::MariaDB (always
#      utf8mb4) do it. mysql_enable_utf8=1 asks for the utf8 session.
#   b) the control: without the switch the transport hands back bytes, as
#      DBD::mysql does without it. That is the deviation from DBD::MariaDB,
#      which always decodes (stated in the POD of ConnectInfo).
#   c) CLIENT_FOUND_ROWS: an UPDATE that matches a row and changes nothing
#      reports the row, on the DBDs and on this transport;
#      mysql_client_found_rows=0 turns it off on all of them and the count
#      is 0.
#
# The table lives in a database of its own, mysql_ev_k80, created here and
# dropped at the end. Gated like the other live tests; DBD::mysql and
# DBD::MariaDB are each used when installed.

use DBI;
use DBIO::MySQL::EV::Storage;
use DBIO::MySQL::EV::TestHarness;

BEGIN { DBIO::MySQL::EV::TestHarness->skip_all_unless_live }

alarm 120;

my $DB = 'mysql_ev_k80';
my ($DSN, $USER, $PASS) = map { $ENV{"DBIO_TEST_MYSQL_$_"} } qw( DSN USER PASS );

(my $own = $DSN) =~ s/(?<=[:;])(?:database|dbname|db)=[^;]*/database=$DB/
  or plan skip_all => 'DBIO_TEST_MYSQL_DSN names no database';

sub connect_sync {
  my ($dsn, %attr) = @_;
  return DBI->connect($dsn, $USER, $PASS, { RaiseError => 1, PrintError => 0, PrintWarn => 0, %attr });
}

my $CREATED;
{
  my $dbh = connect_sync($DSN);
  $dbh->do("DROP DATABASE IF EXISTS $DB");
  $dbh->do("CREATE DATABASE $DB CHARACTER SET utf8mb4");
  $CREATED = 1;
  $dbh->disconnect;
}
END {
  return unless $CREATED;
  my $dbh = eval { connect_sync($DSN) } or return;
  eval { $dbh->do("DROP DATABASE IF EXISTS $DB") };
  $dbh->disconnect;
}

{
  my $dbh = connect_sync($own);
  $dbh->do('CREATE TABLE words (id INT PRIMARY KEY, v VARCHAR(100) CHARACTER SET utf8mb4, n INT)');
  $dbh->do('INSERT INTO words VALUES (1, ?, 5)', undef, 'start');
  $dbh->disconnect;
}

sub dsn_for {
  my ($driver, $extra) = @_;
  (my $d = $own) =~ s/^dbi:\w+:/dbi:$driver:/;
  return $d . $extra;
}

# umlauts, sharp s, a 4-byte emoji, BMP CJK
my $TEXT  = "Müller äöü ß 😀 日本";
my $BYTES = do { my $t = $TEXT; utf8::encode($t); $t };

# --- the sync side: each DBD as installed ------------------------------------------

my %SYNC;
for my $case (
  # DBD::mysql 4.055 reads the switch from the attribute hash only: in the DSN
  # it is ignored (measured, see the POD of ConnectInfo), so the reference is
  # connected with the attribute.
  [ 'DBD::mysql (mysql_enable_utf8mb4=1)', 'DBD::mysql',   mysql   => '', mysql_enable_utf8mb4 => 1 ],
  [ 'DBD::mysql (default)',                'DBD::mysql',   mysql   => '' ],
  [ 'DBD::MariaDB',                        'DBD::MariaDB', MariaDB => '' ],
) {
  my ($label, $module, $driver, $extra, %attr) = @$case;
  (my $file = "$module.pm") =~ s{::}{/}g;
  next unless eval { require $file; 1 };
  my $dbh = eval { connect_sync(dsn_for($driver, $extra), %attr) } or next;
  $SYNC{$label} = $dbh;
}
ok scalar(keys %SYNC), 'at least one DBD is there to compare with: ' . join(', ', sort keys %SYNC);

# --- the ev side --------------------------------------------------------------------

my @harness;
sub ev {
  my (%opt) = @_;
  my $h = DBIO::MySQL::EV::TestHarness->new(dsn => dsn_for('mysql', $opt{extra} // ''), user => $USER, pass => $PASS);
  $h->async->connect_info($opt{connect_info}) if $opt{connect_info};
  push @harness, $h;
  return $h;
}
END { eval { $_->disconnect } for @harness }

sub ev_run {
  my ($h, $sql, @bind) = @_;
  return $h->await($h->async->_query_async($sql, \@bind));
}

# One round trip of $TEXT: inserted by bind, selected back by bind (the server
# compares it too), plus the session's character set.
sub trip_sync {
  my ($dbh, $id) = @_;
  $dbh->do('INSERT INTO words VALUES (?, ?, 0)', undef, $id, $TEXT);
  my ($back) = $dbh->selectrow_array('SELECT v FROM words WHERE id = ? AND v = ?', undef, $id, $TEXT);
  my ($cs)   = $dbh->selectrow_array('SELECT @@character_set_client');
  return { back => $back, cs => $cs, stored => stored($id) };
}
sub trip_ev {
  my ($h, $id) = @_;
  ev_run($h, 'INSERT INTO words VALUES (?, ?, 0)', $id, $TEXT);
  my $row = ev_run($h, 'SELECT v FROM words WHERE id = ? AND v = ?', $id, $TEXT);
  my $cs  = ev_run($h, 'SELECT @@character_set_client');
  return { back => $row && $row->[0], cs => $cs && $cs->[0], stored => stored($id) };
}

# What the server holds for a row, read by a client that is not in the case.
sub stored {
  my ($id) = @_;
  my $dbh = connect_sync($own);
  my $r = $dbh->selectrow_arrayref('SELECT CHAR_LENGTH(v), HEX(v) FROM words WHERE id = ?', undef, $id);
  $dbh->disconnect;
  return $r;
}

my $ID = 100;
my %REF;
for my $label (sort keys %SYNC) {
  $REF{$label} = trip_sync($SYNC{$label}, ++$ID);
}

# --- a) -----------------------------------------------------------------------------

for my $case (
  [ 'mysql_enable_utf8mb4=1 in the DSN',        { extra => ';mysql_enable_utf8mb4=1' } ],
  [ 'mysql_enable_utf8mb4 among the attributes', { connect_info =>
      [ dsn_for("mysql", ""), $USER, $PASS, { mysql_enable_utf8mb4 => 1 } ] } ],
) {
  my ($label, $opt) = @$case;
  my $r = trip_ev(ev(%$opt), ++$ID);
  is $r->{back}, $TEXT, "ev, $label: umlauts, CJK and the emoji go out as binds and come back as the same characters"
    or diag explain $r;
  ok utf8::is_utf8($r->{back} // ''), '... flagged as characters';
  is length($r->{back} // ''), length($TEXT), '... of the same length';
  is $r->{cs}, 'utf8mb4', '... the session character set is utf8mb4';
  is $r->{stored}[0], length($TEXT), '... the server counts the same characters';
  for my $sync (sort grep { !/default/ } keys %REF) {
    is $r->{back}, $REF{$sync}{back}, "... what $sync gets back, to the character";
    is $r->{cs}, $REF{$sync}{cs}, "... the session character set of $sync";
    is_deeply $r->{stored}, $REF{$sync}{stored}, "... the server holds the same bytes as after ${sync}'s insert";
  }
}

{
  # mysql_enable_utf8: the utf8 session, and the flagging
  my $h  = ev(extra => ';mysql_enable_utf8=1');
  my $cs = ev_run($h, 'SELECT @@character_set_client');
  like $cs->[0], qr/^utf8(?:mb3)?$/, 'ev, mysql_enable_utf8=1: the session character set is utf8';
  my $row = ev_run($h, 'SELECT ?', "Müller äöü");
  is $row->[0], "Müller äöü", '... and BMP characters round trip as characters';
  ok utf8::is_utf8($row->[0]), '... flagged';
}

# --- b) the control -----------------------------------------------------------------

{
  my $r = trip_ev(ev(), ++$ID);
  ok !utf8::is_utf8($r->{back} // ''), 'ev without the switch: a byte string comes back';
  is $r->{back}, $BYTES, '... the UTF-8 bytes of the text';
  if (my $d = $REF{'DBD::mysql (default)'}) {
    ok !utf8::is_utf8($d->{back} // ''), '... as DBD::mysql without the switch returns it';
    is $d->{back}, $BYTES, '... the same bytes';
  }
  if (my $m = $REF{'DBD::MariaDB'}) {
    ok utf8::is_utf8($m->{back} // ''), 'DBD::MariaDB always returns characters (the deviation, in the POD)';
  }
}

# --- c) CLIENT_FOUND_ROWS -----------------------------------------------------------

sub reset_row {
  my $d = connect_sync($own);
  $d->do('UPDATE words SET n = 5 WHERE id = 1');
  $d->disconnect;
}

my @UPDATES = (
  [ 'a matched row left as it is',   'UPDATE words SET n = 5 WHERE id = 1',     [],  'rows' ],
  [ 'a matched row changed',         'UPDATE words SET n = 6 WHERE id = 1',     [],  1 ],
  [ 'a row nobody matches',          'UPDATE words SET n = 6 WHERE id = 99999', [],  0 ],
  [ 'a bound statement, row left as it is', 'UPDATE words SET n = 5 WHERE id = ?', [1], 'rows' ],
);

for my $mode (
  [ 'default',             1, '',                           '',                           '' ],
  [ 'client_found_rows=0', 0, ';mysql_client_found_rows=0', ';mysql_client_found_rows=0', ';mariadb_client_found_rows=0' ],
) {
  my ($name, $on, $ev_extra, $mysql_extra, $mariadb_extra) = @$mode;
  my $h = ev(extra => $ev_extra);
  my %dbh;
  for my $case ([ 'DBD::mysql', mysql => $mysql_extra ], [ 'DBD::MariaDB', MariaDB => $mariadb_extra ]) {
    my ($module, $driver, $extra) = @$case;
    (my $file = "$module.pm") =~ s{::}{/}g;
    next unless eval { require $file; 1 };
    $dbh{$module} = eval { connect_sync(dsn_for($driver, $extra)) } or delete $dbh{$module};
  }

  for my $u (@UPDATES) {
    my ($what, $sql, $bind, $expect) = @$u;
    $expect = $on ? 1 : 0 if $expect eq 'rows';
    reset_row();
    my $got = ev_run($h, $sql, @$bind);
    is $got + 0, $expect, "$name, $what: ev reports $expect";
    for my $module (sort keys %dbh) {
      reset_row();
      is $dbh{$module}->do($sql, undef, @$bind) + 0, $got + 0, "... the same as $module";
    }
  }
  $_->disconnect for values %dbh;
}

$_->disconnect for values %SYNC;

done_testing;
