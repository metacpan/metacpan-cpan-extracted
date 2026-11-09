package DBIO::Firebird::Storage::InterBase;
# ABSTRACT: Driver for the Firebird RDBMS via L<DBD::InterBase>

use strict;
use warnings;

our $VERSION = '0.900004';

use base qw/DBIO::Firebird::Storage::Common/;
use mro 'c3';

DBIO::Storage::DBI->register_driver('InterBase' => __PACKAGE__);

__PACKAGE__->datetime_parser_type('DBIO::Firebird::DateTime::Format');

use Try::Tiny;
use Scalar::Util ();
use DBIO::Exception ();
use DBIO::Storage::DBI::NoBindVars ();
use DBIO::Firebird::Type qw(is_boolean_type is_binary_type is_numeric_type lob_kind);
use namespace::clean;

# The driver's Deploy class, one source for both native transports
# (DBIO::Firebird::Storage inherits it); Storage::ODBC does not (karr k40).
sub dbio_deploy_class { 'DBIO::Firebird::Deploy' }


# karr k49 -- a handle whose last DDL commit the server refused is alive.
#
# DBD::Firebird commits after DDL and does not roll back when the server refuses
# the commit (DROP TABLE of a table a live statement holds: `object TABLE "..."
# is in use`). The transaction stays as it is and every later statement on the
# handle fails with the same error, the ping's select included. core's dbh_do
# retries when `! $storage->connected`, so the refused DDL read as a dead
# connection: the handle was replaced and the block run again on the new one,
# where nothing holds the table -- success reported for a statement the server
# had refused, the session's state (context variables, on_connect actions) gone.
#
# So a failed ping is not the answer yet. With AutoCommit on there is no
# transaction of the application on the handle, and begin_work + rollback
# discards the one the failed commit left (rollback alone is "ineffective with
# AutoCommit enabled" and does nothing; measured, Firebird 5.0.4, DBD 1.39).
# Then the ping is asked once more: a live connection answers, a dead one fails
# again -- or already in begin_work (a guard for a handle already inside a
# transaction; with DBD::Firebird 1.39 that case does not occur, it was not
# measured). With AutoCommit off the application's own
# transaction is on the handle, which is not ours to roll back, and the failed
# ping stands.
sub _ping {
  my $self = shift;

  my $dbh = $self->_dbh or return 0;

  local $dbh->{RaiseError} = 1;
  local $dbh->{PrintError} = 0;

  my $ping = sub {
    return try {
      $dbh->do('select 1 from rdb$database');
      1;
    } catch {
      0;
    };
  };

  return 1 if $ping->();

  return 0 unless $dbh->{AutoCommit};

  return 0 unless try { $dbh->begin_work; $dbh->rollback; 1 };

  return $ping->();
}

# A commit the server refuses (CREATE UNIQUE INDEX over duplicate rows is
# accepted as a statement and refused at the commit; karr k35). DBD::Firebird
# fails the commit and leaves the handle in AutoCommit; DBI then dies with
# "DBD driver has not implemented the AutoCommit attribute" and the server's
# text is only on $dbh->errstr. Raise that text as core raises a refused
# statement (_dbi_handle_error): a DBIO::Exception::Server reading
# "DBI Exception: ..." with the sqlstate of the handle, so a caller tells the
# error apart by class and sqlstate whether the statement or the commit was
# refused. Only for DBI's own text: a commit that died of anything else keeps
# its error, and a stale errstr is never taken in its place.
sub _exec_txn_commit {
  my $self = shift;

  my $dbh = $self->_dbh;
  return 1 if eval { $dbh->commit; 1 };

  my $err = $@;
  my $server = $dbh->errstr;
  $self->_dbi_handle_error($server, $dbh)
    if $err =~ /has not implemented the AutoCommit attribute/
      && defined $server && length $server;

  die $err;
}

# We want dialect 3 for new features and quoting to work, DBD::InterBase uses
# dialect 1 (interbase compat) by default.
sub _init {
  my $self = shift;
  $self->_set_sql_dialect(3);
  $self->_set_utf8_connection;
}

# karr k60 -- a native connection speaks UTF8 unless its connect info says
# otherwise: ib_charset=UTF8 in the DSN (the DBD reads the charset from the DSN
# alone) and ib_enable_utf8 as an attribute, which makes the DBD encode the
# Perl strings it is given and decode the text it reads. Only DBD::Firebird: the
# attribute was not measured on DBD::InterBase. What the caller wrote stays: a
# DSN that names an ib_charset (any value), an ib_enable_utf8 attribute (any
# value, 0 to opt out). ib_enable_utf8 is set only for a UTF8 connection, the
# one charset the DBD decodes.
#
# Returns the DSN to use and whether ib_enable_utf8 => 1 is to be added.
sub _utf8_connection_defaults {
  my ($self, $dsn, @attr_hashes) = @_;

  return ($dsn, 0) unless defined $dsn and !ref $dsn and $dsn =~ /\Adbi:Firebird\b/i;

  my $charset;
  while ($dsn =~ /(?:\A|[;:])\s*ib_charset\s*=\s*([^;]*)/ig) {
    ($charset = $1) =~ s/\s+\z//;
  }

  my ($named, $wanted);
  for my $hash (grep { ref $_ eq 'HASH' } @attr_hashes) {
    for my $key (grep { /\Aib_enable_utf8\z/i } keys %$hash) {
      $named  = 1;
      $wanted = $hash->{$key} ? 1 : 0;
    }
  }
  $wanted = 1 unless $named;

  if (!defined $charset) {
    # the DBD decodes nothing but UTF8: asking for ib_enable_utf8 is asking for it
    return $wanted ? ("$dsn;ib_charset=UTF8", $named ? 0 : 1) : ($dsn, 0);
  }

  return ($dsn, ($named || $charset !~ /\Autf-?8\z/i) ? 0 : 1);
}

# Without a broker the connect info is the storage's own and is completed here,
# once, as the dialect is. With one it is formed anew for every connection and
# completed in _access_broker_dbi_args.
sub _set_utf8_connection {
  my $self = shift;

  return if $self->access_broker;

  my $info = $self->_dbi_connect_info;
  return unless defined $info->[0] and !ref $info->[0];

  my ($dsn, $set) = $self->_utf8_connection_defaults($info->[0], $info->[3]);

  return if $dsn eq $info->[0] and !$set;

  $info->[0] = $dsn;
  $info->[3] = { %{ $info->[3] || {} }, ib_enable_utf8 => 1 } if $set;

  my $connected = defined $self->_dbh;
  $self->disconnect;
  $self->ensure_connected if $connected;
}

# The dialect is a DSN attribute: DBD::Firebird and DBD::InterBase read
# ib_dialect from the DSN alone (see "ib_ attributes through an AccessBroker").
#
# Without a broker the DSN is the storage's own, rewritten here and the
# connection opened anew. With one, _dbi_connect_info is not stored but derived
# from the broker's answer at every call (core k266), so rewriting it changed
# nothing: the reconnect asked the broker again, and both connections were
# opened with the DSN the broker answered, without ib_dialect -- dialect 1 over
# DBD::InterBase, silently (karr k43). With a broker the dialect therefore joins
# every answer in _access_broker_dbi_args, and there is nothing to rewrite or
# reconnect here.
sub _set_sql_dialect {
  my $self = shift;
  my $val  = shift || 3;

  return if $self->access_broker;

  my $dsn = $self->_dbi_connect_info->[0];

  return if ref($dsn) eq 'CODE';

  if ($dsn !~ /ib_dialect=/) {
    $self->_dbi_connect_info->[0] = "$dsn;ib_dialect=$val";
    my $connected = defined $self->_dbh;
    $self->disconnect;
    $self->ensure_connected if $connected;
  }
}

# karr k43 -- the DSN of every connection a broker's answer opens carries the
# dialect. A code reference or dbh_maker opens its connection itself and is not
# ours to rewrite (as without a broker, where such a DSN is left alone too); a
# DSN of another DBD (an ODBC one) has no ib_ attribute to carry.
#
# An answer that names ib_dialect itself is read the way the DBD reads it --
# the key in any letter case and with blanks, in the DSN or in the attribute
# hash (to refuse a value loudly) -- and only 3 stands: this storage speaks dialect 3 (quoted identifiers, the modern
# types) and a connection in dialect 1 would run every statement of it in a
# different language without a word. Refused loudly, naming the place and
# never the DSN or a password. An ib_dialect attribute of 3 is not enough by
# itself (the DBD reads the DSN alone and drops the attribute), so the DSN
# gets ib_dialect=3 then too. So does a DSN spelling the key the DBD does not
# read (_OdbcParse compares with eq and does not trim: IB_DIALECT=3 and
# "ib_dialect = 3" are other keys to it): ;ib_dialect=3 is appended unless the
# DBD itself reads 3 (_dbd_reads_dialect_3).
sub _access_broker_dbi_args {
  my $self = shift;

  my ($args, $attrs) = $self->next::method(@_);

  my $dsn = $args->[0];
  if (defined $dsn and !ref $dsn and $dsn =~ /\Adbi:(?:Firebird|InterBase)\b/i) {
    my @named = $self->_named_sql_dialects($dsn, $attrs, $args->[3]);

    my %where = map { $_->[0] => 1 } grep { $_->[1] ne '3' } @named;
    $self->throw_exception(
      'AccessBroker ' . ref($self->access_broker) . ' answered an ib_dialect '
    . 'other than 3 (in ' . join(' and ', sort keys %where)
    . '). DBIO::Firebird speaks SQL dialect 3 and refuses a connection in '
    . 'another one; answer ib_dialect=3 or none.'
    ) if %where;

    if (!$self->_dbd_reads_dialect_3($dsn)) {
      $args = [ @$args ];
      $args->[0] = "$dsn;ib_dialect=3";
      $dsn = $args->[0];
    }

    # karr k60: the connection speaks UTF8 unless the answer says otherwise
    my ($utf8_dsn, $set) = $self->_utf8_connection_defaults($dsn, $args->[3], $attrs);
    if ($utf8_dsn ne $dsn or $set) {
      $args = [ @$args ];
      $args->[0] = $utf8_dsn;
      if ($set) {
        $args->[3] = { %{ $args->[3] || {} }, ib_enable_utf8 => 1 };
        $attrs     = { %{ $attrs || {} },     ib_enable_utf8 => 1 };
      }
    }
  }

  return ($args, $attrs);
}

# What DBD::Firebird's _OdbcParse reads from the DSN: parts split at ';',
# key compared with eq (exactly 'ib_dialect'), the value as it stands, no
# trimming, the last one wins. "IB_DIALECT=3" or "ib_dialect = 3" are other
# keys to it and read as nothing.
sub _dbd_reads_dialect_3 {
  my ($self, $dsn) = @_;

  (my $rest = $dsn) =~ s/\Adbi:[^:]*://i;
  my $read;
  for my $part (split /;\r?\n?/, $rest) {
    $read = $2 if $part =~ /\A([^=]*)=(.*)\z/s and $1 eq 'ib_dialect';
  }
  return defined $read && $read eq '3';
}

# Every ib_dialect an answer names, as [ place, value ]: DSN parts as the
# DBD's parser reads them (key in any case, value up to the next semicolon,
# blanks around the value ignored) and attribute keys in any case.
sub _named_sql_dialects {
  my ($self, $dsn, @attr_hashes) = @_;

  my @named;
  while ($dsn =~ /(?:\A|[;:])\s*ib_dialect\s*=\s*([^;]*)/ig) {
    (my $value = $1) =~ s/\s+\z//;
    push @named, [ 'the DSN', $value ];
  }

  for my $hash (@attr_hashes) {
    next unless ref $hash eq 'HASH';
    for my $key (grep { /\Aib_dialect\z/i } keys %$hash) {
      my $v = $hash->{$key};
      push @named, [ 'the attributes', defined $v ? "$v" : '' ];
    }
  }

  return @named;
}

# karr k39 (core k298, k307) -- which lowercase keys of a broker's answer are
# attributes of the DBD and may go to DBI->connect. DBI's own registry, which
# core asks, knows ib_ for DBD::InterBase and nothing for DBD::Firebird.
# $driver is the DBD name off the DSN, not this class's: any other one,
# InterBase included, is core's to answer. Here rather than on Storage::Common
# so that the ODBC transport does not vouch for ib_ (ADR 0010).
sub _dbd_attribute_prefixes {
  my ($self, $driver) = @_;

  return 'ib_' if defined $driver && $driver eq 'Firebird';

  return $self->next::method($driver);
}

# karr k50 (core k276) -- the host of a HostBound view in a DSN of the native
# DBDs. Core's default knows a host= and port= token and declines db=host:path;
# these DBDs take the server three ways, and the view must reach the host it
# names, never the master of the answer:
#
#   db=host[/port]:path          the host rides in the database name
#   host=h[/port] | hostname=h   a token, the port inside it or in port=
#   db=path                      no host: a local database
#
# Whichever the answer uses is rewritten where it stands; a local database gets
# host= (and port=) put in front, as core does. What is not translated is
# declined with the form named -- a key or a dialect, never a value of the DSN:
# a part that is not key=value, a host named in two places, several database
# keys, a URL-style database name (inet://...), a view host the form cannot
# carry, and any other DBD's DSN (this storage knows Firebird and InterBase).
# Like core, a view without a port leaves the answer's.
sub _bind_host_into_dsn {
  my ($self, $driver, $dsn, $host, $port) = @_;

  return (undef, 'a DSN without a dbi:Driver: prefix')
    unless defined $dsn and $dsn =~ /\A(dbi:([^:(]*)(?:\([^)]*\))?:)(.*)\z/is;
  my ($prefix, $dbd, $rest) = ($1, $2, $3);

  return (undef, "a DSN of the DBD '$dbd', not Firebird or InterBase")
    unless $dbd =~ /\A(?:Firebird|InterBase)\z/i;

  my (@tokens, %at);
  for my $part (split /;/, $rest) {
    next unless $part =~ /\S/;
    return (undef, 'a part without key=value form')
      unless $part =~ /\A\s*(\w+)\s*=(.*)\z/s;
    my ($key, $value) = ($1, $2);
    my $slot = lc $key;
    $slot = 'db'   if $slot eq 'dbname' or $slot eq 'database';
    $slot = 'host' if $slot eq 'hostname';
    return (undef, 'more than one of the keys db, dbname and database') if $slot eq 'db'   and $at{db};
    return (undef, 'more than one of the keys host and hostname')        if $slot eq 'host' and $at{host};
    return (undef, "more than one '$key' key")                           if $slot eq 'port' and $at{port};
    push @tokens, { raw => $part, key => $key, value => $value };
    $at{$slot} = $tokens[-1] if $slot =~ /\A(?:db|host|port)\z/;
  }

  my $db = $at{db}
    or return (undef, 'no db, dbname or database key');

  return (undef, "the key '$db->{key}' with a URL-style database name")
    if $db->{value} =~ m{\A\s*[A-Za-z][A-Za-z0-9+.-]*://};

  # the view's host must fit the place it is written to
  return (undef, 'a view host with a colon, slash or space in it')
    if $host =~ m{[:/\s]};

  # forms of the database name that name a server in a way this translation
  # does not carry, or that cannot be told from a local path: refused, never
  # translated into something else
  return (undef, "an IPv6 address in the key '$db->{key}'")
    if $db->{value} =~ /\A\s*\[/;
  return (undef, "a drive-relative path in the key '$db->{key}'")
    if $db->{value} =~ m{\A\s*[A-Za-z]:(?![\\/])};
  return (undef, "a service name after the host in the key '$db->{key}'")
    if $db->{value} =~ m{\A[^:/\\\s]+/[^:/\\\s]*\D[^:/\\\s]*:};

  # a host in the database name -- but a drive letter (C:\data\a.fdb) is not
  my ($dbhost, $dbport, $path) = $db->{value} =~ m{\A([^:/\\\s]+)(?:/(\d+))?:(.*)\z}s;
  undef $dbhost if defined $dbhost and $db->{value} =~ m{\A[A-Za-z]:[\\/]};

  if (defined $dbhost) {
    return (undef, "a host in both the key '$db->{key}' and a host key")
      if $at{host};
    return (undef, "a port key beside a host in the key '$db->{key}'")
      if $at{port};

    $port //= $dbport;
    $db->{raw} = "$db->{key}=$host" . (defined $port ? "/$port" : '') . ":$path";
    return $prefix . join ';', map { $_->{raw} } @tokens;
  }

  # no host in the database name: a host token, the port inside it (h/3050) or
  # in port=. A view port goes to port= and out of the host; without one the
  # answer's port stays where it was.
  my $hostvalue = $host;
  if (my $h = $at{host}) {
    my ($oldport) = $h->{value} =~ m{/(\d+)\s*\z};
    return (undef, "a service name in the key '$h->{key}' and a view without a port")
      if !defined $port and $h->{value} =~ m{/} and !defined $oldport;
    $hostvalue .= "/$oldport" if defined $oldport and !defined $port;
    $h->{raw} = "$h->{key}=$hostvalue";
  }
  else {
    unshift @tokens, $at{host} = { raw => "host=$hostvalue" };
  }

  if (defined $port) {
    if ($at{port}) { $at{port}{raw} = "$at{port}{key}=$port" }
    else {
      my ($index) = grep { $tokens[$_] == $at{host} } 0 .. $#tokens;
      splice @tokens, $index + 1, 0, { raw => "port=$port" };
    }
  }

  return $prefix . join ';', map { $_->{raw} } @tokens;
}

# karr k37 -- never hand out a statement handle the DBD has destroyed.
#
# DBD::Firebird 1.39 (dbdimp.c) keeps a list of the statements of a connection
# and calls dbd_st_finish + dbd_st_destroy on every one of them: in
# ib_commit_transaction when DDL ran since the last commit (with or without
# ib_softcommit; ib_set_tx_param under AutoCommit counts itself as DDL and
# commits), and in ib_rollback_transaction on a hard rollback inside a
# transaction. The Perl handles know nothing of it: they stay in
# $dbh->{CachedKids} and prepare_cached goes on handing them out. See
# "Statements the DBD destroys" in the POD for what such a handle then does.
#
# This is the one place every statement of the storage is prepared through
# (_dbh_execute, _dbh_prepare and the bulk insert), so it is where a destroyed
# handle is stopped. On this class and not on Storage::Common: it is a fact
# about the DBD's API, not about the engine's SQL, and the ODBC transport has
# no part in it (ADR 0010).
#
# Two things here are shaped by a second fact about that list. dbd_st_destroy
# unlinks its statement unconditionally, and Perl runs it AGAIN when the handle
# is finally freed; for a statement that is already unlinked that second run
# reads as "the list is empty now" (first_sth = last_sth = NULL). Every
# statement prepared in between is then alive but off the list: the DBD no
# longer destroys it before a DDL commit, and it keeps its table "in use" for a
# later DROP TABLE on this connection (measured, Firebird 5.0). So:
#
#   - the whole cache goes, not only the one entry. Every cached handle
#     prepared before the event is destroyed as well, and each of them freed
#     later, one by one as its SQL comes up again, would take the handles
#     prepared since off the list. A handle prepared after the event that is
#     thrown out along the way costs one prepare;
#   - the destroyed handle is let go before the new one is prepared, not after.
#
# What this cannot reach is a destroyed handle something else still holds --
# a cursor that was being read from. Whenever that is freed, the list is
# emptied the same way.
#
# The new handle is not asked again: one freshly prepared is alive, and a DBD
# that says otherwise must cost a prepare per statement, not a loop.
sub _prepare_sth {
  my ($self, $dbh, $sql) = @_;

  my $sth = $self->next::method($dbh, $sql);

  return $sth
    if $self->disable_sth_caching or $self->_sth_is_alive($sth);

  undef $sth;
  %{ $dbh->{CachedKids} } = () if $dbh->{CachedKids};

  return $self->next::method($dbh, $sql);
}

# A value bound for a BOOLEAN column (karr k36). DBD::Firebird 1.39 binds every
# parameter as text and, for a BOOLEAN, takes Perl's truth of that text:
# '0', '' and 0 are FALSE, every other string is TRUE -- 'false' and 'x'
# included, stored as TRUE without an error (measured against Firebird 5.0.4).
# The words are what SQL spells the values with, so they are translated; ''
# is what the same DBD hands back for a FALSE it has read, so it is FALSE too
# (a read value must be writable: $row->copy, search({ on => $row->on })).
# Any other value is refused instead of being stored as whatever its truth is.
# The column is known from the bind's sqlt_datatype, so a parameter without
# column information is left as the caller wrote it.
sub _boolean_bind_value {
  my ($self, $info, $v) = @_;

  if    ($v =~ /\A[01]\z/)    { return $v }
  elsif ($v =~ /\Atrue\z/i)   { return 1 }
  elsif ($v =~ /\A(?:false)?\z/i) { return 0 }

  $self->throw_exception(sprintf
    q{The value bound to the BOOLEAN column '%s' is none of 1, 0, 'true', 'false', '' or undef; }
    . q{DBD::Firebird would store any other string as TRUE},
    $info->{dbic_colname} // '?',
  );
}

# karr k60 -- DBD::Firebird converts the text it is given for a numeric
# parameter in Perl, and a text that is no number becomes 0 ('', ' ', 'x') or
# the number its first characters read as ('5x' is 5), with a warning and no
# error; the server answers a conversion error to the same text (measured on
# Firebird 5.0.4, DBD::Firebird 1.39: INTEGER, BIGINT, DOUBLE PRECISION and
# NUMERIC(9,2) alike). A row the server would refuse is stored as another
# number, so a value that is no number for a numeric column is refused before
# the DBD reads it. Whatever Perl calls a number is one (leading and trailing
# blanks, an exponent, '.5').
sub _numeric_bind_check {
  my ($self, $info, $v) = @_;

  return if Scalar::Util::looks_like_number($v);

  DBIO::Exception->throw(sprintf
    q{refusing the value bound to the numeric column '%s': it is no number, and DBD::Firebird would }
  . q{store 0 (or the number its first characters read as) where the server answers a conversion error},
    $info->{dbic_colname} // '?',
  );
}

# karr k60 -- on a connection with ib_enable_utf8 the DBD encodes the Perl
# strings it is given to UTF-8, but only those Perl flags as such: "\x{fc}"
# written in a source file is a one-byte string and reaches the server as the
# byte FC, a malformed UTF-8 string (measured, Firebird 5.0.4 / DBD::Firebird
# 1.39). A string is characters, so a text bound with a character above 0x7F
# is flagged here. A binary column's bytes are not text and stay as they are.
# Whether the connection decodes is asked of the handle the statement belongs
# to.
sub _utf8_bind_value {
  my ($self, $sth, $info, $v) = @_;

  return $v if !defined $v or ref $v or utf8::is_utf8($v) or $v !~ /[^\x00-\x7f]/;
  return $v unless eval { $sth->{Database}{ib_enable_utf8} };
  return $v if ref $info eq 'HASH' and is_binary_type($info->{sqlt_datatype});

  utf8::upgrade(my $copy = $v);
  return $copy;
}

# karr k60 -- DBD::Firebird dies on a BLOB parameter in a SELECT ("BLOB as an
# input param for SELECT is not allowed"), and the server compares a BLOB with
# a VARCHAR. So the placeholder of a value bound against a text or binary BLOB
# column of a SELECT is written CAST(? AS VARCHAR(n) ...): the text with
# CHARACTER SET UTF8 (the connection's, see "Text is UTF8 on every native
# connection"), 8191 characters at most, the bytes with OCTETS, 32765 at most
# -- Firebird's VARCHAR is 32765 bytes. A value above them cannot be compared
# at all and is refused here, before the DBD says something less clear.
# UPDATE and DELETE are left alone: the DBD takes a BLOB parameter there.
#
# The placeholders are found in the generated SQL (the binds carry their
# column only after the SQL maker has run, see _resolve_bindattrs) by core's
# scanner, DBIO::Storage::DBI::NoBindVars::placeholder_offsets: a '?' in a
# string, an identifier or a comment is not one (core k388). If the count does not match
# the binds the statement is left as it is.
my %LOB_CAST = (
  text   => [ 'CAST(? AS VARCHAR(8191) CHARACTER SET UTF8)',   8191,  'characters' ],
  binary => [ 'CAST(? AS VARCHAR(32765) CHARACTER SET OCTETS)', 32765, 'bytes' ],
);

sub _gen_sql_bind {
  my ($self, $op, $ident) = @_;

  my ($sql, $bind) = $self->next::method(@_[1 .. $#_]);

  return ($sql, $bind) unless $op eq 'select';
  return ($self->_cast_lob_binds($sql, $bind, $ident), $bind);
}

sub _cast_lob_binds {
  my ($self, $sql, $bind, $ident) = @_;

  my @lobs;
  for my $i (0 .. $#$bind) {
    my ($info, $v) = @{ $bind->[$i] };
    next unless ref $info eq 'HASH' and defined $v and !ref $v;
    my $kind = lob_kind($info->{sqlt_datatype}, $info->{sqlt_size}) or next;
    push @lobs, [ $i, $kind, $info, $v ];
  }
  return $sql unless @lobs;

  my @at = DBIO::Storage::DBI::NoBindVars::placeholder_offsets($sql);
  return $sql unless @at == @$bind;

  for my $lob (reverse @lobs) {
    my ($i, $kind, $info, $v) = @$lob;
    my ($cast, $limit, $unit) = @{ $LOB_CAST{$kind} };

    if (length($v) > $limit) {
      my $column = $info->{dbic_colname} // '?';
      my ($alias) = $column =~ /\A(.*)\.[^.]*\z/;
      $column =~ s/\A.*\.//;
      DBIO::Exception->throw(sprintf
        'refusing to compare the %s BLOB column %s.%s with a value of %d %s: DBD::Firebird '
      . 'binds no BLOB parameter in a SELECT, so the value is compared as a VARCHAR, which '
      . 'holds %d %s at most (32765 bytes, Firebird Language Reference, Character data '
      . 'types). Compare a shorter value, or a column that is not a BLOB.',
        $kind, $self->_select_table_name($ident, $alias), $column, length($v), $unit, $limit, $unit,
      );
    }

    substr($sql, $at[$i], 1) = $cast;
  }

  return $sql;
}

# The table behind an alias of a SELECT's from, for a message. A source gives
# its name; a from is [ { alias => table }, [ { alias => table, -join_type ... },
# \%condition ], ... ].
sub _select_table_name {
  my ($self, $ident, $alias) = @_;

  return $ident->name if Scalar::Util::blessed($ident) and $ident->can('name') and !ref $ident->name;

  my %table;
  for my $part (ref $ident eq 'ARRAY' ? @$ident : ()) {
    my $hash = ref $part eq 'ARRAY' ? $part->[0] : $part;
    next unless ref $hash eq 'HASH';
    for my $key (grep { !/\A-/ } keys %$hash) {
      $table{$key} = $hash->{$key} unless ref $hash->{$key};
    }
  }

  return $table{$alias} if defined $alias and defined $table{$alias};
  return (values %table)[0] if keys %table == 1;
  return '?';
}

# The one place the values of a bind are adjusted (karr k63), for core's two
# ways of binding: _bind_sth_params (create, search, update) and, per row,
# _dbh_execute_for_fetch (populate in void context). This storage overrides
# neither of them. A literal bind (\[ '?', [ on => 'false' ] ]) is resolved by
# core into a pair of its own before it gets here, so it is adjusted like any
# other. The column is known from the meta's sqlt_datatype, which the
# core's _resolve_bindattrs fills from the source for both ways.
#
# The answer is a new list of new pairs; the pairs of the caller are never
# written to. A reference in the value slot (a bind_param_inout target) is
# left as it is. The attributes are not touched.
sub _adjust_bind_values {
  my ($self, $sth, $bind, $bind_attrs) = @_;

  my @bind;
  for my $b (@$bind) {
    my ($info, $v) = @$b;
    my $new = $v;

    if (defined $v and !ref $v) {
      my $type = ref $info eq 'HASH' ? $info->{sqlt_datatype} : undef;

      if (ref $info eq 'HASH' and is_boolean_type($type)) {
        $new = $self->_boolean_bind_value($info, $v);
      }
      elsif (ref $info eq 'HASH' and is_numeric_type($type)) {
        $self->_numeric_bind_check($info, $v);
      }
      else {
        $new = $self->_utf8_bind_value($sth, $info, $v);
      }
    }

    push @bind, [ $info, $new ];
  }

  return \@bind;
}

# Whether the DBD still has the statement behind this handle, asked without a
# round trip to the server: bind a placeholder one past the last. dbd_bind_ph
# of DBD::Firebird 1.39 reads
#
#   if (!imp_sth || !imp_sth->in_sqlda)                 return FALSE;
#   if ((int)SvIV(param) > imp_sth->in_sqlda->sqld)     return TRUE;
#
# and in_sqlda is what dbd_st_destroy frees and sets to NULL. So a prepared
# statement answers true and nothing is bound, and a destroyed one answers
# false -- without setting an error, which is why nothing else notices.
#
# This rests on those two lines. A DBD that answered false for a prepared
# handle would have every statement prepared anew on each use: slower, never
# wrong. One that answered true for a destroyed handle would bring k37 back;
# t/23-statement-cache-ddl-live.t asks a handle before and after DDL for that.
sub _sth_is_alive {
  my ($self, $sth) = @_;

  return $sth->bind_param($sth->{NUM_OF_PARAMS} + 1, undef) ? 1 : 0;
}

# ADR 0040 / karr k17 -- the whole operation of getting a query plan here.
# There is no statement to issue: the plan is an attribute of the PREPARED
# statement, so the query itself is prepared and never executed, and the plan
# is read off the handle with the DBD's private ib_plan function. See the
# DESCRIPTION for why it is func('ib_plan') and not $sth->{ib_plan}, and why
# this lives on the DBD::InterBase class rather than on Storage::Common.
#
# _prepare_rendered is the seam core built for exactly this shape and it is not
# optional: reaching for $self->dbh would lose tracing and with it
# redact_bind_value over the caller's own bind values, dbh_do's retry,
# NoBindVars interpolation, and the read handler of a replicated storage.
sub _explain_query {
  my ($self, $sql, $bind) = @_;

  my $sth = $self->_prepare_rendered($sql, $bind);

  my $plan = $sth->func('ib_plan');

  # undef here is the DBD's fixed 2048-byte plan buffer overflowing, not "this
  # query has no plan" -- every prepared statement has one. Answering
  # [ [ undef ] ] would put that indistinguishably into the caller's plan.
  $self->throw_exception(
    'Firebird prepared the statement but the driver returned no plan for it. '
  . 'Every prepared statement has a plan, so this is the DBD rather than the '
  . 'engine: DBD::Firebird and DBD::InterBase read isc_info_sql_get_plan into '
  . 'a fixed 2048-byte buffer (PLAN_BUFFER_LEN) and answer undef when the '
  . 'plan does not fit. Explain a smaller query, or read the plan through the '
  . 'API directly.'
  ) unless defined $plan;

  return [ [ $plan ] ];
}

# Every connection reads dates and timestamps in the ISO formats (karr k55).
# DBD::Firebird answers in the locale's %c format until ib_time_all is set,
# which the DateTime parser of this driver and any string comparison do not
# expect -- a silent wrong value for a user who did not know to ask for
# connect_call_datetime_setup. Done before the caller's own actions, so an
# on_connect_call that sets another format wins; setting the same value again
# (datetime_setup) changes nothing.
sub _run_connection_actions {
  my $self = shift;

  $self->_dbh->{ib_time_all} = 'ISO';

  return $self->next::method(@_);
}


sub connect_call_use_softcommit {
  my $self = shift;

  $self->_dbh->{ib_softcommit} = 1;
}


sub connect_call_datetime_setup {
  my $self = shift;

  $self->_get_dbh->{ib_time_all} = 'ISO';
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird::Storage::InterBase - Driver for the Firebird RDBMS via L<DBD::InterBase>

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

This driver is a subclass of L<DBIO::Firebird::Storage::Common> for
use with L<DBD::InterBase>, see that driver for general details.

Without L</connect_call_use_softcommit> every commit on the connection closes
the cursors still open on it, so a result set you are part-way through is cut
off by the next statement that commits (see L</CAVEATS>). 
L<disable_sth_caching|DBIO::Storage::DBI/disable_sth_caching> is not needed for
your code to function correctly: see L</Statements the DBD destroys>.

Every connection reads dates and timestamps in the ISO formats without being
asked (L</connect_call_datetime_setup>); L<DBIO::InflateColumn::DateTime>
support needs nothing more on the connection.

=head2 dbio_deploy_class

Answers C<DBIO::Firebird::Deploy>, for this storage and for
L<DBIO::Firebird::Storage>, which inherits it. L<DBIO::Firebird::Storage::ODBC>
does not inherit this class and answers nothing of its own.

=head2 Statements the DBD destroys

L<DBD::Firebird> keeps a list of the statements prepared on a connection and
destroys all of them -- drops them on the server and frees what the handle
binds and fetches with -- in two situations (C<ib_commit_transaction> and
C<ib_rollback_transaction> in C<dbdimp.c> of 1.39):

=over 4

=item *

on the commit that follows DDL, whatever table the DDL was about, with or
without C<ib_softcommit>. Under C<AutoCommit> that is the DDL statement itself;

=item *

on a rollback inside a transaction, unless C<ib_softcommit> is set -- every
C<txn_do> that dies.

=back

The Perl handles are not told. They stay in L<DBI>'s statement cache, which
this storage prepares through, and a handle taken from there afterwards does
not fail: a C<SELECT> executes and fetches nothing, with the warning C<no
statement executing>; an C<INSERT> or C<UPDATE> executes, answers C<undef> (not
an error: C<RaiseError> stays silent) and writes nothing (measured, Firebird
5.0.4, DBD::Firebird 1.39); only C<INSERT ... RETURNING> dies, with C<invalid statement
handle>.

So this storage asks every handle that comes out of the cache whether the DBD
still has its statement -- a question the DBD answers without a round trip to
the server -- and when it has not, empties the cache and prepares the statement
anew. Reading and writing through L<DBIO>, then changing the schema over the
same connection (L<DBIO::Firebird::Deploy> does) or rolling a transaction back,
then reading and writing again works with statement caching on, which is the
default.

What the storage cannot repair is a statement that was in use when it was
destroyed: a cursor you are still fetching from goes with all the others, and
the iteration ends there -- with that warning, and without an error.

=head2 A commit the server refuses

C<CREATE UNIQUE INDEX> over duplicate rows is accepted as a statement and
refused at the commit. L<DBD::Firebird> fails that commit and leaves the handle
in C<AutoCommit>; L<DBI> then dies with I<DBD driver has not implemented the
AutoCommit attribute>, and the server's text is only on C<< $dbh->errstr >>.
C<txn_commit> raises that text. A commit that died of anything else keeps its
own error. The handle stays usable. C<_use_transactional_ddl>
stays 0 (L<DBIO::Firebird::Deploy/Transactional DDL -- not claimed>).

=head2 Query plans

L<DBIO::ResultSet/explain> asks the storage for the B<whole operation> of
obtaining a query plan, through L<DBIO::Storage::DBI/_explain_query> (ADR 0040;
it replaced the string-valued C<_explain_sql>). This engine is the one in the
family with B<no statement to issue at all>, and the override lives on this
class -- inherited by L<DBIO::Firebird::Storage> -- because it is a fact about
these two DBDs rather than about the SQL:

=over 4

=item *

there is no C<EXPLAIN>. The token appears nowhere in Appendix C of the
Firebird 5.0 Language Reference, which lists every keyword reserved and
non-reserved, so core's inherited C<EXPLAIN E<lt>queryE<gt>> is a
C<Token unknown> parse error here rather than a wrong answer;

=item *

the plan is an attribute of the B<prepared> statement, read with the API call
C<isc_dsql_sql_info(isc_info_sql_get_plan)>. Nothing is executed to obtain it,
which is why this driver prepares through
L<DBIO::Storage::DBI/_prepare_rendered> -- the prepare-without-execute seam
core built for this engine (ADR 0040 section 6) -- and never reaches for
C<< $self->dbh >>. Going past the seam would cost C<_query_start> /
C<_query_end> tracing and therefore C<redact_bind_value> (ADR 0025) over the
explained query's B<own> C<WHERE>-clause values, C<dbh_do> retry over a
dropped connection, L<DBIO::Storage::DBI::NoBindVars> interpolation, and the
read handler of a L<DBIO::Replicated::Storage>;

=item *

both DBDs expose that API call, and both expose it as a private
B<statement-handle function>: C<< $sth->func('ib_plan') >>. Verified in the
sources -- C<Firebird.xs> of L<DBD::Firebird> 1.39 and C<InterBase.xs> of
L<DBD::InterBase> 0.48 carry the same XSUB, DBD::Firebird being a fork of
DBD::InterBase. It is B<not> the attribute C<< $sth->{ib_plan} >> that ADR
0040 section 6 and core's C<_explain_query> / C<_prepare_rendered> POD spell:
neither DBD has an C<ib_plan> key in its C<dbd_st_FETCH_attrib>, so that
spelling asks DBI for an unrecognised attribute and gets C<undef>.

=back

The plan is one opaque string, so it comes back as a single row of a single
column, C<< [ [ $plan ] ] >>, rather than as invented columns -- ADR 0040
section 2: the return type is rows and their contents were never portable.

Two caveats, both from the XS rather than from a server:

=over 4

=item *

what you get is Firebird's B<legacy> plan (C<PLAN (FOO NATURAL)>), with a
trailing newline the XS appends. The richer C<explained plan> of Firebird 3
and up, C<isc_info_sql_explain_plan>, is not reachable: neither DBD mentions
it;

=item *

both XSUBs read the plan into a fixed 2048-byte buffer (C<PLAN_BUFFER_LEN>)
and answer C<undef> when the plan does not fit. This driver throws on that
C<undef> instead of handing back a row containing nothing, since an empty plan
cell is indistinguishable from a query that has no plan.

=back

=head2 ib_ attributes through an AccessBroker

A storage connecting through a L<DBIO::AccessBroker> refuses a lowercase key
it would not apply -- in the broker's hash answer or beside the broker --
unless the key starts with a prefix the storage declares for the DBD its DSN
names (L<DBIO::Storage::DBI/_dbd_attribute_prefixes>). Core asks L<DBI>'s
registry of driver prefixes, which knows C<ib_> for L<DBD::InterBase> and has
no entry for L<DBD::Firebird>, although that DBD, a fork of the other, takes
its attributes under the same prefix. This class declares it: asked about the
DBD C<Firebird> it answers C<ib_>, and leaves every other DBD to core. So

  $schema->connect($broker, { ib_softcommit => 1 });

and a broker answering C<< { dbname => ..., ib_softcommit => 1 } >> connect
over C<dbi:Firebird:> as they do over C<dbi:InterBase:>.

The declaration is on this class, and so inherited by
L<DBIO::Firebird::Storage>, because this is where the C<ib_*> API is spoken;
L<DBIO::Firebird::Storage::ODBC> does not inherit it, and an C<ib_> key on a
C<dbi:ODBC:> connection is refused.

B<The prefix says less than it seems to.> It tells the storage that the key is
addressed to this DBD, not that the DBD reads it from where a broker's answer
puts it. That place is the attribute hash of C<< DBI->connect >>, and
L<DBD::Firebird> 1.39 (C<dbdimp.c>) takes from it only C<ib_softcommit>,
C<ib_enable_utf8>, C<ib_time_all>, C<ib_dateformat>, C<ib_timeformat>,
C<ib_timestampformat> and C<ib_db_triggers>. C<ib_dialect>, C<ib_charset>,
C<ib_role>, C<ib_cache> and C<ib_dbkey_scope> are read from the B<DSN> alone:
as attributes they pass this check, and L<DBI> then drops them without a word
-- the connection is opened without them. Give those inside the DSN, which a
broker does by answering the DBI form
C<< [ 'dbi:Firebird:dbname=...;ib_charset=UTF8', $user, $password ] >>.

=head2 SQL dialect 3 through an AccessBroker

The storage forces SQL dialect 3 (quoted identifiers, the modern types) by
adding C<ib_dialect=3> to the DSN, because L<DBD::InterBase> takes dialect 1
otherwise and both DBDs read C<ib_dialect> from the DSN alone. With an
L<DBIO::AccessBroker> the DSN is the broker's answer, asked again for every
connection, so the dialect joins each answer that is a DSN of C<Firebird> or
C<InterBase>: a DBI-form answer, a hash carrying a C<dsn>, and the
connection parameters of L<DBIO::AccessBroker::Static> alike. The connection is
opened once, with it.

An answer that names C<ib_dialect> itself is checked -- the key in any letter
case and with blanks around it, in the DSN or in the attribute hash -- and only
C<3> stands: such a connection would run every statement in a language other
than the one this storage speaks, so an answer naming another dialect is
refused with an exception that names the place (the DSN, the attributes) and
never a value of the DSN or the password. An C<ib_dialect> attribute of C<3>
alone is not enough, since the DBD reads the DSN only and drops the attribute:
the DSN gets C<ib_dialect=3> then too. The same holds for a DSN spelling the
key as the DBD does not read it (C<IB_DIALECT=3>, C<ib_dialect = 3>: its
parser compares the key exactly and trims nothing): C<;ib_dialect=3> is
appended unless the DBD itself reads a C<3>. (That DBD::InterBase takes dialect 1
without it is taken from that DBD's documentation, not measured here;
t/22-broker-live.t measures that a plain connection in dialect 1 reads
C<"RDB$DATABASE"> as a string literal.) What
this cannot reach is a connection that code opens -- a coderef or
C<dbh_maker> answer: there the dialect is the code's to set, as it is without
a broker.

=head2 Text is UTF8 on every native connection

Over L<DBD::Firebird> the storage adds C<ib_charset=UTF8> to the DSN and
C<< ib_enable_utf8 => 1 >> to the attributes (with an AccessBroker to
every answer, as the dialect). Without them L<DBD::Firebird> 1.39 stores the
bytes Perl holds and reads bytes back: a string with a character above
U+00FF is stored right and comes back as its UTF-8 bytes, and C<"\x{fc}">, an
unflagged string, is a malformed UTF-8 string to a UTF8 column. Measured on
Firebird 5.0.4 against a database of character set UTF8 and one of NONE:
with both settings every text round-trips as the characters written, in
either, so the database's character set needs no change. The DBD encodes
only strings Perl flags as UTF-8, which is why the storage flags a text
that has a character above 0x7F when it binds (not the bytes of a binary
BLOB, C<binary>, C<varbinary>), in C<_adjust_bind_values>, core's one seam
for both the single and the bulk path of C<populate>.

What the connect info says stays: a DSN that names an C<ib_charset>, whatever
its value, and an C<ib_enable_utf8> attribute, C<0> included, switch the
default off for what they name (C<ib_enable_utf8> is set only with a UTF8
charset, the one the DBD decodes). A DBD::InterBase DSN and the ODBC storage
are not touched. B<A text column of an existing database holding bytes in
another encoding> (character set NONE, written by a connection that had none)
is read as UTF-8 through a default connection; give that connection
C<ib_enable_utf8 => 0> or its own C<ib_charset>.

=head2 A BLOB compared with a bound value

DBD::Firebird refuses a BLOB parameter in a C<SELECT> (I<BLOB as an input
param for SELECT is not allowed>), and a text or binary BLOB column is what
C<text>, C<clob>, C<blob> are written as, so C<< search({ v => 'x' }) >> would
die in the DBD. Firebird itself compares a BLOB with a C<VARCHAR>, so the
storage writes the placeholder of such a bound value in a C<SELECT> as
C<CAST(? AS VARCHAR(8191) CHARACTER SET UTF8)> (a text BLOB) or
C<CAST(? AS VARCHAR(32765) CHARACTER SET OCTETS)> (a binary one), measured on
Firebird 5.0.4 with a UTF8 and a NONE database. The limits are those of
C<VARCHAR> (32 765 bytes, Firebird Language Reference, I<Character data
types>): a value above them cannot be compared, and the storage says so
before the DBD does -- a L<DBIO::Exception> that C<refuse>s, naming table
and column. C<UPDATE> and C<DELETE> are not rewritten: the DBD takes a BLOB
parameter there. The cast assumes the connection speaks UTF8, the default
above; with another C<ib_charset> a non-ASCII value in such a comparison is not
supported.

=head2 A HostBound view over a DSN of this driver

L<DBIO::AccessBroker::HostBound> (L<DBIO::Replicated>: one host per replicant,
one credential) binds its host into a broker's DSN through the storage's
L<DBIO::Storage::DBI/_bind_host_into_dsn>. Core's default knows C<host=> and
C<port=> (it also declines C<hostname=>) and declines C<db=host:path>, while
C<db=/path;host=...> and a local name it translates; this class translates the forms the DBDs
take:

=over 4

=item * C<db=host[/port]:path> (also C<dbname=>, C<database=>): the prefix of
the database name is replaced;

=item * C<host=h[/port]> or C<hostname=h>, with the port inside the host or in
C<port=>: replaced where it stands. A view port goes to C<port=>; a view
without a port leaves the answer's;

=item * a local database name: C<host=> (and C<port=>) are put in front.

=back

It declines, naming the form and never a value of the DSN, a part that is not
C<key=value>, a host named both in the database name and in C<host=>, more than
one database or host key, a URL-style database name (C<inet://...>), a
service name where a port stands (C<db=host/service:path>, and C<host=h/service>
when the view brings no port to take its place: the service would drop out of
the DSN without a word), an IPv6 database name (C<db=[::1]:path>), a
drive-relative path (C<db=C:data.fdb>, neither a host nor an absolute local
path), a view host with a colon, slash or space in it, and a DSN of any other
DBD. The ODBC
storage declines every DSN: its driver takes the server inside
C<DBNAME=host/port:path>.

=head1 METHODS

=head2 connect_call_use_softcommit

Used as:

  on_connect_call => 'use_softcommit'

In L<connect_info|DBIO::Storage::DBI/connect_info> to set the
L<DBD::InterBase> C<ib_softcommit> option.

With it L<DBD::Firebird> commits and rolls back I<retaining>, and a cursor that
still has rows to fetch stays open across the commits of other statements on
the connection. Without it the first such commit closes it, and the next fetch
dies with C<Cursor is not open>; C<< disable_sth_caching => 1 >> does not
change that.

Neither setting keeps a cursor open across the commit that follows DDL: see
L</Statements the DBD destroys>.

The downside of using this option is that your process will B<NOT> see UPDATEs,
INSERTs and DELETEs from other processes for already open statements.

=head2 connect_call_datetime_setup

Used as:

  on_connect_call => 'datetime_setup'

In L<connect_info|DBIO::Storage::DBI/connect_info> to set the date and
timestamp formats using:

  $dbh->{ib_time_all} = 'ISO';

Every connection of this storage does that by itself, before the
caller's C<on_connect_*> actions run: without it L<DBD::Firebird> reads a
timestamp back in the locale's C<%c> format ("Mon 19 Oct 2026 04:43:18 AM
CET"), which the parser of this driver does not expect. This call does the
same and is harmless twice; an action of your own that sets another
C<ib_time_all> comes after the default and wins.

See L<DBD::InterBase> for more details.

The C<TIMESTAMP> data type supports up to 4 digits after the decimal point for
second precision. The full precision is used.

The C<DATE> data type stores the date portion only, and it B<MUST> be declared
with:

  data_type => 'date'

in your Result class.

Timestamp columns can be declared with either C<datetime> or C<timestamp>.

Datetime inflation is handled by L<DBIO::Firebird::DateTime::Format> (a
L<DBIO::Storage::DateTimeFormat> subclass backed by L<DateTime::Format::Strptime>),
which loads L<DateTime::Format::Strptime> when a datetime column is first
inflated. It is a recommended, not a required, dependency of this
distribution: install it to use datetime columns.

For L<DBIO::Firebird::Storage::ODBC>, this is a noop.

=head1 CAVEATS

=over 4

=item *

with L</connect_call_use_softcommit>, you will not be able to see changes made
to data in other processes. If this is an issue, do without it and do not keep
a cursor open across another statement's commit: fetch the rows first.
L<disable_sth_caching|DBIO::Storage::DBI/disable_sth_caching> is no workaround
for that: a cursor is closed by the commit whether or not its statement came
out of the cache.

=item *

a cursor that is still open does not survive the commit that follows DDL on the
same connection, nor, without L</connect_call_use_softcommit>, a rollback
inside a transaction. See L</Statements the DBD destroys>.

=back

=head1 SEE ALSO

=over

=item * L<DBIO::Firebird> - Firebird schema component

=item * L<DBIO::Firebird::Storage> - Firebird driver via L<DBD::Firebird>

=item * L<DBIO::Firebird::Storage::Common> - Shared Firebird/InterBase logic

=item * L<DBIO::Firebird::Storage::ODBC> - Firebird via L<DBD::ODBC>

=item * L<DBIO::Storage::DBI> - Base DBI storage class

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
