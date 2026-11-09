package DBIO::MSSQL::Storage::ODBC;
# ABSTRACT: Support for Microsoft SQL Server via DBD::ODBC

use strict;
use warnings;

our $VERSION = '0.900004';

use base qw/
  DBIO::Storage::DBI::ODBC
  DBIO::MSSQL::Storage
/;
use mro 'c3';

use Scalar::Util ();
use DBIO::Exception ();
use DBIO::Util qw(is_plain_value);

use namespace::clean;


# karr k61. DBI's LongReadLen is 80, and DBD::ODBC reads a LOB value (TEXT,
# NTEXT, VARCHAR(MAX), NVARCHAR(MAX), VARBINARY(MAX), IMAGE, XML) only up to
# it. Beyond it the fetch throws -- but exactly AT the boundary it does not:
# measured with DBD::ODBC 1.61 over FreeTDS 1.3.17, a VARCHAR(MAX), TEXT or
# NTEXT value of LongReadLen + 1 characters comes back with its last
# character replaced by a NUL, and an NVARCHAR(MAX) value of exactly
# LongReadLen characters too, without an error. A LongReadLen that no value
# reaches takes the boundary out of reach. It is not free: see the POD, "The
# price of 1 GiB". It is the default only: the connect info's LongReadLen is
# the regulator, as it was.
my $LONG_READ_LEN = 1073741824;

# On the handle, after the connect, as the FreeTDS class of DBIO::Sybase does
# for the text size: the storage becomes this class at its first use, after
# the connect info was read and the first connection made, so the attribute
# defaults cannot carry it. Every connection gets it, a reconnect too.
sub _run_connection_actions {
  my $self = shift;

  my $dbh = $self->_dbh;

  $dbh->{LongReadLen} = $LONG_READ_LEN
    unless exists $self->_dbio_connect_attributes->{LongReadLen};

  # karr k81 (reading, the other half of k58). A DBD::ODBC without Unicode
  # support hands every SQL_CHAR value back as the bytes the client library
  # made of it -- UTF-8 when the ClientCharset is UTF-8, which is what the
  # write path requires before it sends a string beyond ASCII -- without the
  # UTF-8 flag: an a-umlaut read back is two characters, a CJK character
  # three. With odbc_utf8_on the driver decodes them. Set only on the
  # connection that was asked (the same question as for writing) and when
  # the connect info does not say; a DBD::ODBC with Unicode support decodes
  # by itself. Binary columns are not SQL_CHAR and stay bytes.
  unless ( $dbh->{odbc_has_unicode}
        or exists $self->_dbio_connect_attributes->{odbc_utf8_on} ) {
    my $utf8 = eval { $self->_client_charset_is_utf8($dbh) };
    $dbh->{odbc_utf8_on} = 1 if $utf8;
  }

  return $self->next::method(@_);
}

# karr k58. The columns a Unicode value is bound for (see STRINGS BEYOND THE
# CODE PAGE): those that are NCHAR, NVARCHAR or NTEXT ON THE SERVER, which is
# what DBIO::MSSQL::DDL deploys the declared type as (_server_data_type): a
# 'text', 'varchar', 'string' or 'char' column is national too.
sub _is_national_data_type {
  my ($self, $data_type) = @_;

  $data_type = $self->_server_data_type($data_type);

  return 0 unless defined $data_type;

  return $data_type =~ /\A \s*
    (?: nchar | nvarchar | ntext
      | national \s+ char (?: acter )? (?: \s+ varying )? )
    \s* (?: \( [^)]* \) )? \s* \z/xi ? 1 : 0;
}

sub bind_attribute_by_data_type {
  my ($self, $data_type) = @_;

  return DBI::SQL_LONGVARBINARY() if $self->_is_binary_data_type($data_type);

  # The one Unicode type that carries a value whole at every size
  # (SQL_WVARCHAR stops at 4000 characters without an error, SQL_WCHAR pads).
  return DBI::SQL_WLONGVARCHAR() if $self->_is_national_data_type($data_type);

  return $self->next::method($data_type);
}

# Does the connection read what the driver sends as UTF-8? A DBD::ODBC without
# Unicode support sends a string as bytes (the UTF-8 form of a string with the
# flag on) and the client library reads them in its ClientCharset. If that is
# not UTF-8 a string beyond ASCII is stored as other characters and nothing
# says so. The connection is asked what it holds for an a-umlaut, as Unicode
# (SQL_WLONGVARCHAR, so the code page of the server is no part of the
# question): 228, or the first byte of its UTF-8 form. Once per handle.
sub _client_charset_is_utf8 {
  my ($self, $dbh) = @_;

  return 1 if $dbh->{odbc_has_unicode};

  my $seen = $self->{_odbc_client_charset_utf8};
  return $seen->[1]
    if $seen and defined $seen->[0] and $seen->[0] == $dbh;

  my $probe = "\x{E4}";
  utf8::upgrade($probe);

  my $sth = $dbh->prepare('SELECT UNICODE(CAST(? AS NVARCHAR(10)))');
  $sth->bind_param(1, $probe, DBI::SQL_WLONGVARCHAR());
  $sth->execute;
  my ($code) = $sth->fetchrow_array;
  $sth->finish;

  my $is_utf8 = ( defined $code and $code == 0xE4 ) ? 1 : 0;

  $self->{_odbc_client_charset_utf8} = [ $dbh, $is_utf8 ];
  Scalar::Util::weaken( $self->{_odbc_client_charset_utf8}[0] );

  return $is_utf8;
}

# What is told, never the value.
sub _refuse_client_charset {
  my ($self, $what) = @_;

  $self->throw_exception(sprintf
    'Cannot send this statement through DBD::ODBC: %s has a character '
  . 'beyond ASCII, and the client character set of the ODBC driver is not '
  . 'UTF-8. This DBD::ODBC is built without Unicode support: it sends the '
  . 'UTF-8 bytes of a string, which the driver would read in its own '
  . 'character set and store as other characters (an a-umlaut as two), '
  . 'without an error. Set the client character set to UTF-8: '
  . 'ClientCharset=UTF-8 in the DSN (FreeTDS), or a UTF-8 locale.',
    $what,
  );
}

# The text the driver is given for a value of a text column: the string with
# its characters as UTF-8 (the flag on) when there is one beyond ASCII; undef
# for a value that has none, or is none (NULL, bind_inout, an object that is
# not a plain value -- core binds that untouched).
sub _beyond_ascii_as_characters {
  my $value = shift;

  return undef if not defined $value or ref $value eq 'SCALAR';

  if (length ref $value) {
    return undef unless is_plain_value $value;
    $value = "$value";
  }

  return undef unless $value =~ /[^\x00-\x7F]/;

  # A string is its characters, whatever form Perl holds it in: an a-umlaut
  # made with "\x{E4}" has no UTF-8 flag, and the driver would take its one
  # byte for a broken UTF-8 sequence.
  utf8::upgrade($value);

  return $value;
}

# The bind values of a statement with the text ones beyond ASCII as
# characters (UTF-8 flag on); the list itself when there is none. A binary
# value is bytes and left alone. Asks, once per handle, whether the client
# character set can take them, and refuses when it cannot.
sub _text_binds_as_characters {
  my ($self, $dbh, $bind) = @_;

  my ($i, $found, @new) = (0, 0);
  for my $b (@{ $bind || [] }) {
    $i++;
    my ($attrs, $value) = @$b;

    my $characters = ( ref $attrs eq 'HASH'
      and $self->_is_binary_data_type( $attrs->{sqlt_datatype} ) )
        ? undef
        : _beyond_ascii_as_characters($value);

    if (defined $characters) {
      $found = 1;
      $self->_refuse_client_charset(
        "bind value $i of " . scalar(@$bind)
        . ( ref $attrs eq 'HASH' and defined $attrs->{dbic_colname}
            ? " (column '$attrs->{dbic_colname}')" : '' )
      ) unless $self->_client_charset_is_utf8($dbh);
    }

    push @new, defined $characters ? [ $attrs, $characters ] : $b;
  }

  return $found ? \@new : $bind;
}

# populate in void context hands the storage rows, not bind values: the same
# for a text column's value beyond ASCII (and for the binds of a literal).
sub _text_rows_as_characters {
  my ($self, $source, $cols, $data) = @_;

  my $colinfos = $source->columns_info($cols);
  my @text     = map {
    $self->_is_binary_data_type( $colinfos->{ $cols->[$_] }{data_type} ) ? 0 : 1
  } 0 .. $#$cols;

  my $found = 0;
  my @rows  = map {
    my @row = @$_;

    for my $i (0 .. $#row) {
      if (ref $row[$i] eq 'REF' and ref ${ $row[$i] } eq 'ARRAY') {
        my ($sql, @bind) = @${ $row[$i] };
        my $resolved = $self->_resolve_bindattrs($source, \@bind, $colinfos);
        my $as_characters = $self->_text_binds_as_characters(
          $self->_get_dbh, $resolved,
        );
        if ($as_characters != $resolved) {
          $found   = 1;
          $row[$i] = \[ $sql, @$as_characters ];
        }
      }
      elsif ($text[$i]) {
        my $characters = _beyond_ascii_as_characters($row[$i]);
        next unless defined $characters;

        $self->_refuse_client_charset("a value for the column '$cols->[$i]'")
          unless $self->_client_charset_is_utf8( $self->_get_dbh );

        $found   = 1;
        $row[$i] = $characters;
      }
    }

    \@row;
  } @$data;

  return $found ? \@rows : $data;
}

# The bind values of a statement, those of a binary column as their bytes;
# the list itself when there is none. Throws for a character above 255.
sub _binary_binds_as_bytes {
  my ($self, $bind) = @_;

  return $bind unless grep {
    ref $_->[0] eq 'HASH' and $self->_is_binary_data_type( $_->[0]{sqlt_datatype} )
  } @{ $bind || [] };

  return [ map {
    ( ref $_->[0] eq 'HASH'
        and $self->_is_binary_data_type( $_->[0]{sqlt_datatype} )
        and ref $_->[1] ne 'SCALAR' )                       # bind_inout
      ? [ $_->[0], $self->_binary_value_bytes( $_->[1], $_->[0]{dbic_colname} ) ]
      : $_
  } @$bind ];
}

# ADR 0040, karr k71. Measured live 2026-10-19 (MSSQL 2022, DBD::ODBC 1.61 /
# tdsodbc 1.3.17): the base class's three round-trips do not give a plan over
# DBD::ODBC. The prepared SET SHOWPLAN_ALL ON does not outlive its prepare, so
# the explained query RUNS and its own rows come back as the "plan" -- well
# formed, no error, wrong. A silently wrong answer is refused. DBD::Sybase
# without placeholders returns the 18-column plan (base class, unchanged).
sub _explain_query {
  my ($self) = @_;

  DBIO::Exception->throw(
    'DBIO::MSSQL: explain is refused over DBD::ODBC: no plan over ODBC. SQL Server\'s '
  . 'SET SHOWPLAN_ALL does not take effect over a prepared statement there, '
  . 'so the query would run and its own rows would be returned as the plan. '
  . 'Connect through DBD::Sybase without placeholders for a plan '
  . '(DBIO::MSSQL::Storage::Sybase), or read it in SQL Server Management '
  . 'Studio.'
  );
}

# Ahead of the trace and the prepare (core's _dbh_execute, _dbh_prepare), so
# that a value that is no binary value is refused before anything is sent.
sub _dbh_execute {
  my ($self, $dbh, $sql, $bind, @rest) = @_;

  return $self->next::method(
    $dbh, $sql,
    $self->_binary_binds_as_bytes( $self->_text_binds_as_characters($dbh, $bind) ),
    @rest,
  );
}

sub _dbh_prepare {
  my ($self, $dbh, $sql, $bind, @rest) = @_;

  return $self->next::method(
    $dbh, $sql,
    $self->_binary_binds_as_bytes( $self->_text_binds_as_characters($dbh, $bind) ),
    @rest,
  );
}

sub _insert_bulk {
  my ($self, $source, $cols, $data) = @_;

  $data = $self->_text_rows_as_characters($source, $cols, $data);

  my ($as_bytes) = $self->_bulk_binary_values_as_bytes($source, $cols, $data);

  return $self->next::method($source, $cols, $as_bytes);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Storage::ODBC - Support for Microsoft SQL Server via DBD::ODBC

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Storage driver for Microsoft SQL Server accessed via L<DBD::ODBC>
(including FreeTDS-based ODBC connections). Inherits from both
L<DBIO::Storage::DBI::ODBC> and L<DBIO::MSSQL::Storage>.

A schema that declares the driver -- the L<DBIO::MSSQL> component or the
C<-ms> shortcut -- has its storage pinned to L<DBIO::MSSQL::Storage>, which
moves into this class at its first use when the DSN is a C<dbi:ODBC:> one
(L<DBIO::MSSQL::Storage/_adapt_to_access_path>). That is decided from the
DSN: no connection is opened for it and the server is not asked what it is.

A schema without a declared driver is refused at connect (core ADR 0067),
and C<< DBIO->driver_for >> throws for a C<dbi:ODBC:> DSN: DBD::ODBC names no
driver.

It carries the transport helpers from L<DBIO::Storage::DBI::ODBC> (such as
C<_using_freetds>) on top of the transport-neutral MSSQL semantics of
L<DBIO::MSSQL::Storage>, without pulling in any L<DBD::Sybase>-specific code.

The declared way is pinned offline in F<t/62-adapt-access-path.t> (which
class the storage becomes, and that nothing is reported) and live in
F<t/72-adapt-access-path-odbc-live.t> (L<DBD::ODBC> 1.61 over the
FreeTDS ODBC driver 1.3.17 against SQL Server 2022): the storage is
L<DBIO::MSSQL::Storage> before its first use and this class after it, over
one connection, and no driver mismatch is reported.

=head1 BINARY VALUES

A value for a binary column -- C<binary>, C<varbinary>, C<image>, and the
names L<DBIO::MSSQL::DDL> makes one of them (C<blob>, C<bytea>, ...) -- is
bound as C<SQL_LONGVARBINARY>. That is the one type that carries a value
whole in every place a bind value stands in: C<INSERT>, C<UPDATE> and a
condition, against C<VARBINARY(MAX)>, C<VARBINARY(n)>, C<BINARY(n)> and
C<IMAGE>, from an empty value to 100000 bytes (measured with
L<DBD::ODBC> 1.61 over the FreeTDS ODBC driver 1.3.17 against SQL Server
2022). Bound without a type, as it was before, a binary value did not arrive
at all: the driver takes it for text. Bound as C<SQL_VARBINARY> or
C<SQL_BINARY> it is cut to 8000 bytes B<without an error>.

=over

=item * B<The value is the bytes of the string>, one per character, whatever
form Perl holds the string in. L<DBD::ODBC> would send a string with the
UTF-8 flag on as the bytes of its UTF-8 form; the storage hands it the bytes
instead.

=item * B<A character above 255 is no byte.> Such a value throws before
anything is sent, naming the column and the position, not the value.

=item * B<populate in void context> stays the one prepared statement it is;
the type is bound once and holds for every row.

=item * B<Which bind value belongs to a binary column> is what its data type
says: a column of the result source, or the type given with a bind value in
literal SQL (C<< \[ '?', [ { sqlt_datatype => 'varbinary' } => $value ] ] >>).
A value bound without a type is text to the driver, as any other.

=back

Reading is not changed by any of this: L</LONG VALUES>.

=head1 STRINGS BEYOND THE CODE PAGE

Measured with L<DBD::ODBC> 1.61 B<built without Unicode support>
(C<odbc_has_unicode> is 0: a string goes to the driver as bytes, and a string
with the UTF-8 flag on as its UTF-8 form) over the FreeTDS ODBC driver 1.3.17
against SQL Server 2022 (code page 1252), pinned by
F<t/75-odbc-unicode-binds.t> and, live, F<t/76-odbc-unicode-binds-live.t>.

Bound without a type, as it was, a string is a C<CHAR> to the driver and goes
through the code page of the server whatever the column is: CJK and an emoji
were refused by the driver ("Error converting characters into server's
character set") even for an C<NVARCHAR> column, which could have held them.
A value for a column that is an C<NCHAR>, C<NVARCHAR> or C<NTEXT> B<on the
server> (C<NVARCHAR(MAX)> included) is therefore bound as
C<SQL_WLONGVARCHAR>. What the column is on the server is what
L<DBIO::MSSQL::DDL> deploys the declared type as (L<DBIO::MSSQL::Adapter> is
the one table): the declared C<nchar>, C<nvarchar> and
C<ntext>, but also C<text> (an C<NVARCHAR(MAX)>), C<varchar> and C<string>
(C<NVARCHAR(n)>) and C<char> (C<NCHAR(n)>). The server's own spelling stands:
C<varchar(50)>, C<varchar(max)> and C<char(10)> are a real C<VARCHAR> and
C<CHAR>. The value goes to the server as
Unicode and arrives exact, from one character to 100000, in C<INSERT>,
C<UPDATE> and conditions. C<SQL_WVARCHAR> is cut at 4000 characters
B<without an error> from C<NVARCHAR(MAX)> on, and C<SQL_WCHAR> pads.

=over

=item * B<A real C<VARCHAR> column (declared C<varchar(n)>, C<varchar(max)>,
C<char(n)>) keeps the driver's refusal.> A Unicode bind
into it would turn what the code page lacks into C<?> without a word. Text of
the code page (an a-umlaut, the euro sign) is stored as its code page byte;
CJK is refused, no row is written.

=item * B<The client character set must be UTF-8.> The driver sends the
UTF-8 bytes of a string and the client library reads them in its
C<ClientCharset>: with C<ISO-8859-1> (or a C locale, where the client
character set comes from the locale) an a-umlaut is stored as two other
characters, silently, with or without a bind type. The storage therefore asks
the connection once what it holds for an a-umlaut, when the connection is made
(it also decides how text is read, below), and B<refuses> a string
beyond ASCII when it is not one, naming C<ClientCharset>: write C<ClientCharset=UTF-8> into the DSN, or set a
UTF-8 locale. ASCII is never refused. A L<DBD::ODBC> built with Unicode
support sends wide strings and has no such question; the probe is not made.

=item * B<A string is its characters>, whatever form Perl holds it in: a
string with a character from C<U+0080> on is handed to the driver with the
UTF-8 flag on (an a-umlaut made with C<"\x{E4}"> has none, and the driver
would take its one byte for a broken UTF-8 sequence and refuse it). Text that
is already encoded as UTF-8 bytes must be decoded first, or it is encoded a
second time. A binary column's value is bytes and is not touched
(L</BINARY VALUES>).

=item * B<Reading returns characters>. A L<DBD::ODBC> without
Unicode support hands a character column back as the UTF-8 bytes of the
value, without the UTF-8 flag (an a-umlaut two characters long, CJK three
each): a silently wrong value for every caller that compares or prints it.
Once the connection has said its client character set is UTF-8 (the question
above), the storage sets C<odbc_utf8_on> on the handle, on every connection, a
reconnect too, and the driver decodes: the value is the string that was
written, with the flag on. An C<odbc_utf8_on> in the connect info is the
caller's choice and stays (C<0> gives the bytes again). Not set when the
character set is not UTF-8 (writing is refused there) and not for a DBD::ODBC
with Unicode support, which decodes by itself. Binary columns are bytes and
untouched. Before this the caller had to decode.

=back

=head1 LONG VALUES

Measured 2026-10-17 with L<DBD::ODBC> 1.61 over the FreeTDS ODBC driver 1.3.17
against SQL Server 2022 (F<t/77-long-values-live.t>).

L<DBD::ODBC> reads a LOB value -- C<TEXT>, C<NTEXT>, C<VARCHAR(MAX)>,
C<NVARCHAR(MAX)>, C<VARBINARY(MAX)>, C<IMAGE>, C<XML> -- only up to
C<LongReadLen>, which is DBI's 80 unless the connect info says otherwise, and
throws beyond it ("long truncated"). That was loud, but a schema with a LOB
column was unreadable past 80 bytes. The measurement that decided the default:

=over

=item * B<A large C<LongReadLen> cost nothing in the measurement.> No memory
or time showed for an empty or a short value at 50000000 and at 2147483647,
5 MB values were read whole, 20000 rows of C<TEXT> no slower. So the storage
sets C<LongReadLen> to B<1073741824> on every connection (a reconnect too)
unless the connect info names one, which stays the regulator. Mind the price
below: that measurement holds on a machine that overcommits memory.

=item * B<The price of 1 GiB.> L<DBD::ODBC> 1.61 allocates, for every LOB
column of every statement handle, a buffer of C<LongReadLen> bytes when it
binds the columns (C<dbdimp.c>, C<bind_columns>); in the Unicode build an
C<NVARCHAR(MAX)> or C<XML> column twice that. The buffer is allocated, not
touched, so it costs nothing as long as the operating system lets a process
allocate more than there is: B<only thanks to overcommit>. With
C<vm.overcommit_memory=2>, a C<ulimit -v>, a container limit on address space
or simply many LOB columns in one statement, the allocation fails with
C<Out of memory!>, which L<DBD::ODBC> raises as a Perl panic and which cannot
be caught with C<eval>. Cached statement handles (C<prepare_cached>, the
storage's own statement cache) multiply it: every live handle holds its
buffers. The maintainer's decision is that 1 GiB stays the default; where it
does not fit, set C<LongReadLen> in the connect attributes to more than the
longest value (never to exactly that, see the next item).

=item * B<The boundary of a small one is not loud.> With C<LongReadLen> N, a
C<VARCHAR(MAX)>, C<TEXT> or C<NTEXT> value of N + 1 characters, and an
C<NVARCHAR(MAX)> value of N, comes back with its last character replaced by a
NUL, B<without an error> (N + 2 and N + 1 throw; binary types are exact at N and
throw at N + 1). A default of 1073741824 puts that out of reach. A
C<LongReadLen> set by hand brings it back; it is held as a TODO test and an
upstream draft (F<maint/upstream/dbd-odbc-longreadlen-boundary.md>). Set it to
more than the longest value, never to exactly that.

=item * B<Beyond the limit it still throws>, for every LOB type alike.

=back

The FreeTDS class over L<DBD::Sybase> has the opposite default and a price
for it (L<DBIO::MSSQL::Storage::Sybase/VALUES LONGER THAN TEXTSIZE>); the two
paths agree on what matters: no value is cut without being said.

C<SQL_VARIANT> is read (a binary base type as the hex digits of the value, as
text; over L<DBD::Sybase> it loses its row). The CLR types C<HIERARCHYID>,
C<GEOGRAPHY> and C<GEOMETRY> are refused by the driver.

=head1 SUPPORT MATRIX

L<DBD::ODBC> is the supported access path; L<DBD::Sybase> over FreeTDS is
restricted (L<DBIO::MSSQL::Storage::Sybase/SUPPORT MATRIX>, the same table).

  Case                       DBD::ODBC (supported)         DBD::Sybase / FreeTDS (restricted)
  -------------------------  ----------------------------  -------------------------------------
  Bind of > 4000 bytes       bound, whole                  literal in the statement, whole
  Bind beyond ASCII, into    exact: SQL_WLONGVARCHAR; the  REFUSED, naming DBD::ODBC
  a column that is NCHAR,    ODBC client character set
  NVARCHAR or NTEXT ON THE   must be UTF-8, else the
  SERVER: declared nchar,    string is REFUSED. A
  nvarchar, ntext -- and     string already encoded as
  text, varchar, string,     UTF-8 bytes is encoded a
  char, which DBIO deploys   second time, silently (it
  as national                cannot be told from text)
  Bind beyond ASCII, into    what the code page has is     REFUSED
  a real VARCHAR/CHAR:       exact; what it lacks is
  declared varchar(n),       refused by the driver
  char(n), varchar(max)      (loud)
  Empty string ''            exact                         literal ''; EXEC refused
  Binary values, writing     SQL_LONGVARBINARY             hex pieces, 2099 placeholders per
                                                           statement; EXEC refused
  Binary values, reading     bytes, LongReadLen 1 GiB      bytes through CAST AS IMAGE up to
                             unless set                    TEXTSIZE; a longer value REFUSED
  TEXT, NTEXT, VARCHAR(MAX), whole by default; an          whole up to TEXTSIZE =
  NVARCHAR(MAX) read         explicit small LongReadLen    LongReadLen (32768); a longer value
                             throws beyond it, but a       REFUSED, exactly. On the
                             value AT the boundary comes   handle / in literal SQL: cut
                             back with a NUL for its last  without an error (limit)
                             character (TODO, upstream)
  Empty LOB value, memory    none                          TEXT/NTEXT/MAX types: none; binary
                                                           columns: LongReadLen bytes each
  SQL_VARIANT column         read (a binary value as hex   REFUSED: rows with a binary
                             digits, as text)              base type are lost
  IMAGE as hex digits above  n/a                           row lost, no error (limit)
  TEXTSIZE/2; VARBINARY(MAX)
  on dbh_do
  HIERARCHYID, GEOGRAPHY,    refused by the driver         refused (ct_describe failed), loud
  GEOMETRY
  Transaction with an open   cursor before: commit and     BEGIN TRAN and COMMIT throw,
  cursor                     rollback right, core warns    nothing is sent; ROLLBACK ends
                             that it abandoned the handle; the cursor and rolls back on
                             cursor inside: the next       the same connection (dbio-sybase t/61)
                             statement is refused (t/78)
  Binds on dbh_do /          DBD binds as it is            not covered; the caller has the
  on_connect_do                                            handle
  Private subclass pinned    core warns                    refused
  by storage_type
  $rs->explain               refused: no plan over ODBC    plan (18 columns) for a query without
                             (the query would run)         placeholders; with them it dies
  Key of a new row, with     SCOPE_IDENTITY()              SCOPE_IDENTITY(); @@identity
  a trigger on the table                                   was the trigger's key (1000 for 1)
  populate (void) with a     throws, nothing stays         same: stops at the first failing
  row the server refuses                                   tuple
  NoBindVars class,          n/a (binds)                   row by row in one transaction
  populate, void context
  NoBindVars class, pinned   n/a                           decision taken, layers kept
  to ::Sybase with layers
  NoBindVars class, ''       exact (0)                     core's literal is unquoted: Msg 102,
  for an INT column                                        loud, no row (core's)

=head1 SEE ALSO

=over

=item * L<DBIO::MSSQL> - MSSQL schema component

=item * L<DBIO::MSSQL::Storage> - MSSQL storage base class

=item * L<DBIO::MSSQL::Storage::Sybase> - MSSQL via L<DBD::Sybase>

=item * L<DBIO::Storage::DBI::ODBC> - Base class for ODBC drivers

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
