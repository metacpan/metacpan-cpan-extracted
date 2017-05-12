# Database creation.

# Copyright 2007, 2008, 2009, 2011, 2014 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Database::Create;

use strict;
use warnings;
use DBI;
use File::Basename;
use File::Path;
use Locale::TextDomain ('App-Chart');

use App::Chart::Database;


# Cribs:
#
# "TEXT" for unlimited length isn't SQL standard, but it's in sqlite,
# postgres, and apparently others


my $create_latest = <<'HERE';
CREATE TABLE latest (
    symbol          TEXT     NOT NULL  PRIMARY KEY,
    name            TEXT     DEFAULT NULL,
    month           DATE     DEFAULT NULL,
    exchange        TEXT     DEFAULT NULL,
    currency        TEXT     DEFAULT NULL,
    quote_date      DATE     DEFAULT NULL,
    quote_time      TIME     DEFAULT NULL,
    bid             TEXT     DEFAULT NULL,
    offer           TEXT     DEFAULT NULL,
    last_date       DATE     DEFAULT NULL,
    last_time       TIME     DEFAULT NULL,
    open            TEXT     DEFAULT NULL,
    high            TEXT     DEFAULT NULL,
    low             TEXT     DEFAULT NULL,
    last            TEXT     DEFAULT NULL,
    change          TEXT     DEFAULT NULL,
    volume          TEXT     DEFAULT NULL,
    source          TEXT                    NOT NULL,
    halt            BOOLEAN  DEFAULT 0      NOT NULL,
    limit_up        BOOLEAN  DEFAULT 0      NOT NULL,
    limit_down      BOOLEAN  DEFAULT 0      NOT NULL,
    dividend        TEXT     DEFAULT NULL,
    note            TEXT     DEFAULT NULL,
    error           TEXT     DEFAULT NULL,
    fetch_timestamp TEXT                    NOT NULL,
    copyright       TEXT     DEFAULT NULL,
    url             TEXT     DEFAULT NULL,
    etag            TEXT     DEFAULT NULL,
    last_modified   TEXT     DEFAULT NULL)
HERE

my $create_intraday_image = <<'HERE';
CREATE TABLE intraday_image (
    symbol          TEXT     NOT NULL,
    mode            TEXT     NOT NULL,
    image           BLOB     DEFAULT NULL,
    error           TEXT     DEFAULT NULL,
    fetch_timestamp TEXT     NOT NULL,
    url             TEXT     DEFAULT NULL,
    etag            TEXT     DEFAULT NULL,
    last_modified   TEXT     DEFAULT NULL,
    PRIMARY KEY (symbol, mode))
HERE

my $create_preference = <<'HERE';
CREATE TABLE preference (
    key        TEXT     NOT NULL,
    value      TEXT     NOT NULL,
    PRIMARY KEY (key))
HERE

# DATABASE_SCHEMA_VERSION revisions
#
# Schema 1, version 99.015
#   - "latest" - fetch_timestamp rather than fetch_unixtime
#   - "intraday_image" - fetch_timestamp likewise
#   - "extra" - timestamp strings rather than unixtime numbers
#   - "info" - new exchange column
#   
# Schema 2, version 99.023
#   - "preference" - missed PRIMARY KEY
#
sub upgrade_database {
  my ($dbh, $dbversion) = @_;
  print "Chart: Upgrading database from $dbversion to ",
    App::Chart::DBI::DATABASE_SCHEMA_VERSION(),"\n";
  require App::Chart::Download;

  App::Chart::Database::call_with_transaction
      ($dbh, sub {
         # version 1 adopting timestamps instead of unixtime
         if ($dbversion <= 0) { _upgrade_0_to_1 ($dbh); }
         if ($dbversion <= 1) { _upgrade_1_to_2 ($dbh); }

         $dbh->do ("INSERT OR REPLACE INTO extra (symbol,key,value)
                    VALUES ('','database-schema-version',?)",
                   undef,
                   App::Chart::DBI::DATABASE_SCHEMA_VERSION());
       });
}
sub _upgrade_0_to_1 {
  my ($dbh) = @_;
  $dbh->do ('ALTER TABLE info ADD COLUMN
                      exchange TEXT DEFAULT NULL');

  $dbh->do ('DROP TABLE latest');
  $dbh->do ($create_latest);

  $dbh->do ('DROP TABLE intraday_image');
  $dbh->do ($create_intraday_image);

  $dbh->do ("DELETE FROM extra WHERE key like '%unixtime'");
  App::Chart::Download::consider_latest_from_daily
      ([ App::Chart::Database->symbols_list() ]);
}
sub _upgrade_1_to_2 {
  my $nbh = nbh();
  $nbh->do ('DROP TABLE preference');
  $nbh->do ($create_preference);
}


# $database_filename is in filesystem charset bytes
sub initial_database {
  my ($database_filename) = @_;
  print __x("Creating {filename}\n",
            filename => Glib::filename_display_name($database_filename));

  File::Path::mkpath (File::Basename::dirname ($database_filename));
  my $dbh = DBI->connect ("dbi:SQLite:dbname=$database_filename",
                       '', '', {RaiseError=>1});
  $dbh->{sqlite_unicode} = 1;

  $dbh->do ('PRAGMA encoding = "UTF-8"');

  $dbh->do (<<'HERE');
CREATE TABLE daily (
    symbol  TEXT     NOT NULL,
    date    DATE     NOT NULL,
    open    TEXT     DEFAULT NULL,
    high    TEXT     DEFAULT NULL,
    low     TEXT     DEFAULT NULL,
    close   TEXT     DEFAULT NULL,
    volume  TEXT     DEFAULT NULL,
    openint TEXT     DEFAULT NULL,
    PRIMARY KEY (symbol, date))
HERE

# 'exchange' is for yahoo index and US symbols to differentiate NYSE, AMEX,
# NASDAQ, Philadelphia, etc, for other symbols the suffix gives the exchange
#
  $dbh->do (<<'HERE');
CREATE TABLE info (
    symbol     TEXT     NOT NULL       PRIMARY KEY,
    name       TEXT     DEFAULT NULL,
    exchange   TEXT     DEFAULT NULL,
    isin       TEXT     DEFAULT NULL,
    decimals   INT      DEFAULT 0      NOT NULL,
    currency   TEXT     DEFAULT NULL,
    historical BOOLEAN  DEFAULT 0      NOT NULL,
    CHECK (decimals >= 0))
HERE

# 'type' is meant to allow multiple flavours on the same day, like a capital
# return and a dividend.  Empty string '' for ordinary dividends.  (It's not
# NULL because a null in a primary key defeats the uniqueness (you can
# insert multiple symbol+ex_date with type=null).
#
# 'qualifier' values:
#    TBA          with amount NULL
#    estimated    when amount present, but only estimated
#    unknown      when outright unknown, with amount NULL
#
  $dbh->do (<<'HERE');
CREATE TABLE dividend (
    symbol          TEXT     NOT NULL,
    ex_date         DATE     NOT NULL,
    record_date     DATE     DEFAULT NULL,
    pay_date        DATE     DEFAULT NULL,
    type            TEXT     NOT NULL DEFAULT '',
    amount          TEXT,
    imputation      TEXT     DEFAULT NULL,
    qualifier       TEST     DEFAULT NULL,
    note            TEXT     DEFAULT NULL,
    PRIMARY KEY (symbol, ex_date, type))
HERE

  $dbh->do (<<'HERE');
CREATE TABLE split (
    symbol TEXT     NOT NULL,
    date   DATE     NOT NULL,
    new    TEXT     NOT NULL,  -- number
    old    TEXT     NOT NULL,  -- number
    note   TEXT     DEFAULT NULL,
    PRIMARY KEY (symbol, date))
HERE

  $dbh->do ($create_latest);

  $dbh->do ($create_intraday_image);

  $dbh->do (<<'HERE');
CREATE TABLE extra (
    symbol        TEXT  NOT NULL,
    key           TEXT  NOT NULL,
    value         TEXT,
    PRIMARY KEY (symbol, key))
HERE

  $dbh->do ("INSERT INTO extra (symbol,key,value)
             VALUES ('','database-schema-version',?)",
            undef,
            App::Chart::DBI::DATABASE_SCHEMA_VERSION());
}

sub nbh {
  require App::Chart::DBI;
  my $notes_filename = App::Chart::DBI::notes_filename();
  File::Path::mkpath (File::Basename::dirname ($notes_filename));
  return DBI->connect ("dbi:SQLite:dbname=$notes_filename",
                       '', '', {RaiseError=>1});
}

# $notes_filename is in filesystem charset bytes
sub initial_notes {
  my ($notes_filename) = @_;
  print __x("Creating {filename}\n",
            filename => Glib::filename_display_name($notes_filename));

  my $nbh = nbh();
  $nbh->{sqlite_unicode} = 1;
  $nbh->do ('PRAGMA encoding = "UTF-8"');

  $nbh->do ($create_preference);

  $nbh->do (<<'HERE');
CREATE TABLE annotation (
    symbol     TEXT     NOT NULL,
    id         INT      NOT NULL,
    date       DATE     NOT NULL,
    note       TEXT     NOT NULL,
    PRIMARY KEY (symbol, id))
HERE

  $nbh->do (<<'HERE');
CREATE TABLE line (
    symbol     TEXT     NOT NULL,
    id         INT      NOT NULL,
    date1      DATE     NOT NULL,
    price1     TEXT     NOT NULL,
    date2      DATE     NOT NULL,
    price2     TEXT     NOT NULL,
    horizontal BOOLEAN  NOT NULL  DEFAULT 0,
    PRIMARY KEY (symbol, id))
HERE

  $nbh->do (<<'HERE');
CREATE TABLE alert (
    symbol     TEXT     NOT NULL,
    id         INT      NOT NULL,
    price      TEXT     NOT NULL,
    above      BOOLEAN  NOT NULL,
    PRIMARY KEY (symbol, id))
HERE

  # Ought to have "symlist.key" unique and NOT NULL, and the intention is
  # for "symlist_content.symbol" to be NOT NULL too, but it's easier for
  # treeview drag and drop to loosen both those, so it can insert an empty,
  # set it to a copy of the source, then delete the source.
  #
  # The symlist key lookups are mostly done in-memory, so don't really need
  # an index.  Or maybe should have it for the REFERENCES constraint, except
  # that's not enforced by sqlite anyway.
  #
  # CREATE INDEX symlist_key_index ON symlist (key)
  #
  $nbh->do (<<'HERE');
CREATE TABLE symlist (
    seq        INT      NOT NULL,
    key        TEXT     DEFAULT NULL,
    name       TEXT     DEFAULT NULL,
    condition  TEXT     DEFAULT NULL,
    PRIMARY KEY (seq))
HERE

  $nbh->do (<<'HERE');
CREATE TABLE symlist_content (
    key        TEXT     NOT NULL  REFERENCES symlist,
    seq        INT      NOT NULL,
    symbol     TEXT     DEFAULT NULL,
    note       TEXT     DEFAULT NULL,
    PRIMARY KEY (key, seq))
HERE

  my $sth = $nbh->prepare ('INSERT INTO symlist (seq, key, name, condition)
                            VALUES (?,?,?,?)');
  $sth->execute (0, 'alerts',     __('Alerts'),     'alert');
  $sth->execute (1, 'favourites', __('Favourites'), undef);
  $sth->execute (2, 'all',        __('All'),        'not historical');
  $sth->execute (3, 'historical', __('Historical'), 'historical');
  $sth->finish;
}

1;
__END__
