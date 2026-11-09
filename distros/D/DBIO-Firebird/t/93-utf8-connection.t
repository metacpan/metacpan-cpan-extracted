use strict;
use warnings;
use Test::More;

use DBI;
use DBIO::AccessBroker;
use DBIO::Firebird::Storage;
use DBIO::Firebird::Storage::InterBase;
use DBIO::Firebird::Storage::ODBC;

# OFFLINE (karr k60, case bind-non-ascii).
#
# WHY: DBD::Firebird hands text to the server as the bytes Perl holds and
# reads it back as bytes, unless the connection says ib_enable_utf8 (with
# ib_charset=UTF8 in the DSN, the only charset the DBD decodes). Measured on
# Firebird 5.0.4 with DBD::Firebird 1.39, against a UTF8 and a NONE database
# alike: without it a string with a character above U+00FF is stored right but
# read back as its UTF-8 bytes, and "\x{fc}" (an unflagged Perl string)
# is stored as a single byte the server calls a malformed string. With
# ib_charset=UTF8 and ib_enable_utf8 every text is stored and read back as the
# characters written; an unflagged string still has to be upgraded (the DBD
# only encodes strings Perl flags as UTF-8), which the storage does when it
# binds. So a native connection speaks UTF8 unless its connect info says
# otherwise: a DSN that names an ib_charset, or an ib_enable_utf8 attribute of
# any value, is the caller's and stays.
#
# THE SUBSTITUTIONS: DBI->connect is a recorder returning a stand-in handle;
# no DBD connects. The bind tests use a stand-in statement handle.

delete @ENV{qw( DBI_DSN DBI_DRIVER )};

{
  package T::Broker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer}->() }
}

{
  package T::Handle;
  sub new   { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH { $_[0]->{ $_[1] } }
  sub disconnect { 1 }
  sub get_info   { 0 }
}

our @CONNECTS;
{
  no warnings 'redefine';
  *DBI::connect = sub { shift; push @CONNECTS, [ @_ ]; T::Handle->new };
}

my $PATH = '/k60/data/app.fdb';

# [ dsn, attrs ] of the one connection DBI->connect saw
sub connected_with {
  my ($class, @info) = @_;
  my $storage = $class->new(undef);
  $storage->connect_info([ @info ]);
  local @CONNECTS;
  $storage->_determine_driver;
  $storage->ensure_connected;
  is scalar @CONNECTS, 1, '... one connection';
  my ($dsn, $user, $pass, $attrs) = @{ $CONNECTS[0] };
  return ($dsn, $attrs || {});
}

for my $class (qw( DBIO::Firebird::Storage DBIO::Firebird::Storage::InterBase )) {
  my $both = sub {
    my ($label, $info, $dsn_is, $utf8_is) = @_;
    my ($dsn, $attrs) = connected_with($class, @$info);
    is $dsn, $dsn_is, "$class, $label: the DSN";
    is $attrs->{ib_enable_utf8}, $utf8_is, "$class, $label: ib_enable_utf8";
  };

  $both->('nothing said', [ "dbi:Firebird:dbname=$PATH", 'u', 'p' ],
    "dbi:Firebird:dbname=$PATH;ib_dialect=3;ib_charset=UTF8", 1);
  $both->('the caller\'s attributes kept', [ "dbi:Firebird:dbname=$PATH", 'u', 'p', { ib_softcommit => 1 } ],
    "dbi:Firebird:dbname=$PATH;ib_dialect=3;ib_charset=UTF8", 1);
  $both->('ib_charset=UTF8 already there', [ "dbi:Firebird:dbname=$PATH;ib_charset=UTF8", 'u', 'p' ],
    "dbi:Firebird:dbname=$PATH;ib_charset=UTF8;ib_dialect=3", 1);
  $both->('another ib_charset', [ "dbi:Firebird:dbname=$PATH;ib_charset=ISO8859_1", 'u', 'p' ],
    "dbi:Firebird:dbname=$PATH;ib_charset=ISO8859_1;ib_dialect=3", undef);
  $both->('ib_enable_utf8 => 0', [ "dbi:Firebird:dbname=$PATH", 'u', 'p', { ib_enable_utf8 => 0 } ],
    "dbi:Firebird:dbname=$PATH;ib_dialect=3", 0);
  $both->('ib_enable_utf8 => 1 without a charset', [ "dbi:Firebird:dbname=$PATH", 'u', 'p', { ib_enable_utf8 => 1 } ],
    "dbi:Firebird:dbname=$PATH;ib_dialect=3;ib_charset=UTF8", 1);
  $both->('another charset and ib_enable_utf8 => 0', [ "dbi:Firebird:dbname=$PATH;ib_charset=WIN1252", 'u', 'p', { ib_enable_utf8 => 0 } ],
    "dbi:Firebird:dbname=$PATH;ib_charset=WIN1252;ib_dialect=3", 0);

  # DBD::InterBase has no ib_enable_utf8 that was measured here: untouched
  $both->('a DBD::InterBase DSN', [ "dbi:InterBase:dbname=$PATH", 'u', 'p' ],
    "dbi:InterBase:dbname=$PATH;ib_dialect=3", undef);

  # the same through an AccessBroker (the answer is asked for every connection)
  for my $case (
    [ 'DBI form',   sub { [ "dbi:Firebird:dbname=$PATH", 'u', 'p', {} ] },
      "dbi:Firebird:dbname=$PATH;ib_dialect=3;ib_charset=UTF8", 1 ],
    [ 'hash with dsn', sub { { dsn => "dbi:Firebird:dbname=$PATH", user => 'u', password => 'p' } },
      "dbi:Firebird:dbname=$PATH;ib_dialect=3;ib_charset=UTF8", 1 ],
    [ 'own charset', sub { [ "dbi:Firebird:dbname=$PATH;ib_charset=ISO8859_1", 'u', 'p', {} ] },
      "dbi:Firebird:dbname=$PATH;ib_charset=ISO8859_1;ib_dialect=3", undef ],
    [ 'ib_enable_utf8 => 0', sub { [ "dbi:Firebird:dbname=$PATH", 'u', 'p', { ib_enable_utf8 => 0 } ] },
      "dbi:Firebird:dbname=$PATH;ib_dialect=3", 0 ],
    [ 'DBD::InterBase', sub { [ "dbi:InterBase:dbname=$PATH", 'u', 'p', {} ] },
      "dbi:InterBase:dbname=$PATH;ib_dialect=3", undef ],
  ) {
    my ($label, $answer, $dsn_is, $utf8_is) = @$case;
    my ($dsn, $attrs) = connected_with($class, T::Broker->new($answer));
    is $dsn, $dsn_is, "$class, broker, $label: the DSN";
    is $attrs->{ib_enable_utf8}, $utf8_is, "$class, broker, $label: ib_enable_utf8";
  }

  {
    my ($dsn, $attrs) = connected_with($class, T::Broker->new(
      sub { [ "dbi:Firebird:dbname=$PATH", 'u', 'p', {} ] }), { ib_softcommit => 1 });
    is $attrs->{ib_enable_utf8}, 1, "$class, broker with options beside it: ib_enable_utf8";
    is $attrs->{ib_softcommit}, 1, '... and the options stay';
  }

  {
    my $made = 0;
    my $storage = $class->new(undef);
    $storage->connect_info([ sub { $made++; T::Handle->new } ]);
    local @CONNECTS;
    $storage->ensure_connected;
    is $made, 1, "$class: a connection coderef is called as it is";
    is scalar @CONNECTS, 0, '... DBI->connect is not involved';
  }
}

{
  my ($dsn, $attrs) = connected_with('DBIO::Firebird::Storage::ODBC',
    "dbi:ODBC:Driver=Firebird;Dbname=$PATH", 'u', 'p');
  unlike $dsn, qr/ib_charset/, 'the ODBC storage adds no ib_charset';
  ok !exists $attrs->{ib_enable_utf8}, '... and no ib_enable_utf8';
}

# ---------------------------------------------------------------------------
# binding: an unflagged string with characters above 0x7F is upgraded, so the
# DBD encodes it; nothing else is touched
# ---------------------------------------------------------------------------
{
  package T::Sth;
  sub new { my ($c, %a) = @_; bless { bound => [], %a }, $c }
  sub bind_param { my ($s, $i, $v, $a) = @_; $s->{bound}[$i - 1] = $v; 1 }
  sub bind_param_inout { my ($s, $i, $r, $max, $a) = @_; $s->{bound}[$i - 1] = $$r; 1 }
  sub execute_for_fetch {
    my ($s, $fetch, $status) = @_;
    my $n = 0;
    while (my $t = $fetch->()) { push @{ $s->{tuples} }, $t; $n++ }
    return $n;
  }
  sub err { undef }
  sub errstr { undef }
  sub finish { 1 }
}

sub bound {
  my ($class, $utf8, @binds) = @_;
  my $st  = bless { _dbio_connect_attributes => { LongReadLen => 8000 } }, $class;
  my $sth = T::Sth->new(Database => { ib_enable_utf8 => $utf8 });
  $st->_bind_sth_params($sth, \@binds, [ (undef) x @binds ]);
  return $sth->{bound};
}

my $text = { sqlt_datatype => 'text',    dbic_colname => 'v' };
my $vc   = { sqlt_datatype => 'varchar', dbic_colname => 'v' };
my $blob = { sqlt_datatype => 'blob',    dbic_colname => 'b' };

for my $class (qw(DBIO::Firebird::Storage DBIO::Firebird::Storage::InterBase)) {
  my $r = bound($class, 1, [ $text, "\x{fc}" ]);
  ok utf8::is_utf8($r->[0]), "$class: an unflagged string is flagged for the DBD ...";
  is $r->[0], "\x{fc}", '... and is the same characters';

  $r = bound($class, 1, [ $vc, "caf\x{e9}" ], [ {}, "\x{e9}" ], [ $text, "\x{20ac}" ]);
  ok utf8::is_utf8($_), "$class: varchar, a bind without column information, a flagged string: flagged" for @$r;

  $r = bound($class, 1, [ $text, 'abc' ], [ $text, '' ], [ $text, undef ]);
  ok !utf8::is_utf8($r->[0]) && !utf8::is_utf8($r->[1]), "$class: ASCII and the empty string are left alone";
  ok !defined $r->[2], '... undef too';

  $r = bound($class, 1, [ $blob, join('', map { chr } 0 .. 255) ]);
  ok !utf8::is_utf8($r->[0]), "$class: a binary BLOB's bytes are not upgraded";
  is length $r->[0], 256, '... and keep their length';

  $r = bound($class, 0, [ $text, "\x{fc}" ]);
  ok !utf8::is_utf8($r->[0]), "$class: on a connection without ib_enable_utf8 nothing is upgraded";
}

# the bulk path
sub bulk {
  my ($class, $utf8, @rows) = @_;
  my $st  = bless { _dbh_details => {}, _dbio_connect_attributes => { LongReadLen => 8000 } }, $class;
  my $sth = T::Sth->new(Database => { ib_enable_utf8 => $utf8 });
  my $pb  = [
    [ { dbic_colname => 'id', sqlt_datatype => 'integer', _bind_data_slice_idx => 0 } => 1 ],
    [ { dbic_colname => 'v',  sqlt_datatype => 'text',    _bind_data_slice_idx => 1 } => 1 ],
    [ { dbic_colname => 'b',  sqlt_datatype => 'blob',    _bind_data_slice_idx => 2 } => 1 ],
  ];
  $st->_dbh_execute_for_fetch(undef, $sth, $pb, [qw(id v b)], \@rows);
  return $sth->{tuples};
}

for my $class (qw(DBIO::Firebird::Storage DBIO::Firebird::Storage::InterBase)) {
  my @rows = ([ 1, "\x{fc}", "\x{fc}" ], [ 2, 'plain', 'plain' ]);
  my $t = bulk($class, 1, @rows);
  ok utf8::is_utf8($t->[0][1]), "$class, populate: the text column is upgraded";
  ok !utf8::is_utf8($t->[0][2]), '... the binary column is not';
  ok !utf8::is_utf8($t->[1][1]), '... ASCII is not';
  ok !utf8::is_utf8($rows[0][1]), "... and the caller's rows are left alone";
  $t = bulk($class, 0, @rows);
  ok !utf8::is_utf8($t->[0][1]), "$class, populate: nothing without ib_enable_utf8";
}

done_testing;
