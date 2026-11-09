package DBIO::MSSQL::Storage::Sybase;
# ABSTRACT: Support for Microsoft SQL Server via DBD::Sybase

use strict;
use warnings;

our $VERSION = '0.900004';

use base qw/
  DBIO::Sybase::Storage
  DBIO::MSSQL::Storage
/;
use mro 'c3';

use DBIO::Carp;
use DBIO::Storage::Composed ();
use DBIO::Storage::DBI::NoBindVars ();
use DBIO::Util 'is_plain_value';
use version ();
use namespace::clean;


__PACKAGE__->datetime_parser_type(
  'DBIO::MSSQL::Storage::Sybase::DateTime::Format'
);

# DBIO::Sybase::Storage precedes DBIO::MSSQL::Storage in this class's
# linearisation and names DBIO::Sybase::Deploy (ASE: a `text` column is a TEXT
# there, not the NVARCHAR(MAX) of DBIO::MSSQL::DDL). Over DBD::Sybase
# $schema->deploy and the diff must still be this driver's (karr k81).
sub dbio_deploy_class { 'DBIO::MSSQL::Deploy' }

# Deliberately without next::method. DBIO::Sybase::Storage precedes
# DBIO::MSSQL::Storage in this class's linearisation, and the hook there is
# the ASE hook's: it would move the storage into the ASE class, which a
# declared MSSQL storage never becomes.
sub _adapt_to_access_path {
  my ($self, $dbd) = @_;

  # A storage pinned to this class and connected through another DBD: core
  # reports that, and there is no DBD::Sybase client library to ask.
  return if defined $dbd and $dbd ne 'Sybase';

  $self->_adapt_to_placeholder_support;

  return;
}

# The one decision this class makes about itself, for a declared storage
# (_adapt_to_access_path).
# True when the storage moved into the NoBindVars class.
sub _adapt_to_placeholder_support {
  my $self = shift;

  # This class itself, or a class synthesised over it: a storage pinned here
  # with storage layers registered on the schema is an instance of a
  # DBIO::Storage::Composed class whose base is this one (karr k48). The
  # layers go back over the NoBindVars class when core recomposes after the
  # hook (DBIO::Storage::DBI::_adapt_declared_storage). A storage already in
  # a NoBindVars class has made the decision.
  my $class = ref $self;
  if (my $composition = DBIO::Storage::Composed->composition_of($class)) {
    $class = $composition->{base};
  }
  return if $class ne __PACKAGE__;

  if (not $self->_use_typeless_placeholders) {
    carp_once <<'EOF' unless $ENV{DBIO_MSSQL_FREETDS_LOWVER_NOWARN};
Placeholders do not seem to be supported in your configuration of
DBD::Sybase/FreeTDS.

This means you are taking a large performance hit, as caching of prepared
statements is disabled.

Make sure to configure your server with "tds version" of 8.0 or 7.0 in
/etc/freetds/freetds.conf .

To turn off this warning, set the DBIO_MSSQL_FREETDS_LOWVER_NOWARN environment
variable.
EOF
    require
      DBIO::MSSQL::Storage::Sybase::NoBindVars;
    bless $self,
      'DBIO::MSSQL::Storage::Sybase::NoBindVars';
    return 1;
  }

  return;
}

sub _init {
  my $self = shift;

  $self->next::method(@_);

  # work around massively broken freetds versions after 0.82
  # - no sth caching
  #
  # NOT "no scope_identity" (karr k39): the workaround of the old FreeTDS
  # versions turned SELECT SCOPE_IDENTITY() off and read @@identity, the last
  # identity of the SESSION, which a trigger that inserts into another
  # IDENTITY table overwrites -- create() returned the other table's key
  # (1000 for the row 1). SCOPE_IDENTITY() works over FreeTDS 1.3.17
  # (measured live, t/60 part C, with a trigger); the base class always asked
  # it. Only that version is measured: an older FreeTDS that really cannot
  # take the trailing SELECT would show as a missing key, and its
  # workaround would be a deliberate choice for that version, not for
  # every one above 0.82.
  #
  # warn about the fact as well, do not provide a mechanism to shut it up
  #
  # Parse as a dotted version so modern FreeTDS strings like "1.3.17" are not
  # coerced to a number (which truncates at the second dot and warns "isn't
  # numeric"). An undeterminable version (0/undef) keeps the historic 999
  # sentinel so it is still treated as a new/buggy build.
  if ($self->_using_freetds) {
    my $ver = $self->_using_freetds_version || 999;
    if (version->parse("v$ver") > version->parse('v0.82')) {
      carp_once(
        "Your DBD::Sybase was compiled against buggy FreeTDS version $ver. "
      . 'Statement caching does not work and will be disabled.'
      );

      $self->disable_sth_caching(1);
    }
  }
}

# invoked only if DBD::Sybase is compiled against FreeTDS
sub _set_autocommit_stmt {
  my ($self, $on) = @_;

  return 'SET IMPLICIT_TRANSACTIONS ' . ($on ? 'OFF' : 'ON');
}

sub _get_server_version {
  my $self = shift;

  my $product_version = $self->_get_dbh->selectrow_hashref('master.dbo.xp_msver ProductVersion');

  if ((my $version = $product_version->{Character_Value}) =~ /^(\d+)\./) {
    return $version;
  }
  else {
    $self->throw_exception(
      "MSSQL Version Retrieval Failed, Your ProductVersion's Character_Value is missing or malformed!"
    );
  }
}

# karr k40. What FreeTDS declares every placeholder as when it prepares a
# statement for SQL Server ("@P1 varchar(4000)", read in its protocol dump):
# the server cuts a longer value to this many bytes, without an error.
my $PLACEHOLDER_BYTES = 4000;

# A string as DBD::Sybase sends it: the bytes of Perl's internal form, for a
# statement and for a bound value alike (measured: a character string and
# the bytes of its UTF-8 form are stored as the same thing).
sub _wire_bytes {
  my $string = shift;
  utf8::encode($string) if utf8::is_utf8($string);
  return $string;
}

# The Transact-SQL literal for a value that cannot be bound, from its bytes.
sub _long_value_literal {
  my $value = shift;

  # A plain literal is the varchar the placeholder was declared as. Beyond
  # ASCII it would go through the code page of the database, which stores a
  # character it lacks as "?" without an error; a Unicode literal does not.
  my $n = $value =~ /[^\x00-\x7F]/ ? 'N' : '';

  $value =~ s/'/''/g;

  # Two things the server reads in a literal and not in a bound value: a
  # backslash before a line break continues the literal in the next line
  # (both are dropped), and a NUL ends the statement text. The literal is
  # closed after such a backslash and around a NUL, and the pieces joined.
  my $pieces = ( $value =~ s/\\(?=[\r\n])/\\' + $n'/g )
             + ( $value =~ s/\0/' + ${n}CHAR(0) + $n'/g );

  return "$n'$value'" unless $pieces;

  # Joined onto a MAX value: pieces joined to each other alone are cut at
  # 8000 bytes.
  return "(CAST($n'' AS ${n}VARCHAR(MAX)) + $n'$value')";
}

# True for a bind value the server would cut, were it bound.
sub _over_placeholder_size {
  my $value = shift;

  return 0 if not defined $value or ref $value eq 'SCALAR';   # NULL, bind_inout

  # an object is bound as its string form (DBIO::Storage::DBI::_bind_sth_params)
  $value = "$value" if length ref $value and is_plain_value $value;

  # characters are never more than their bytes
  return 1 if length $value > $PLACEHOLDER_BYTES;
  return 0 unless utf8::is_utf8($value);
  return length _wire_bytes($value) > $PLACEHOLDER_BYTES ? 1 : 0;
}

# The string a bind value is sent as, or undef for one that is no string to
# look at: NULL, bind_inout, and an object that is not a plain value (core
# binds that untouched).
sub _bind_string {
  my $value = shift;

  return undef if not defined $value or ref $value eq 'SCALAR';

  if (length ref $value) {
    return undef unless is_plain_value $value;
    $value = "$value";
  }

  return $value;
}

# karr k49. A string with a character beyond ASCII does not arrive when it is
# bound, at any length: FreeTDS sends it as a CHAR of its length in client
# bytes, converted to the code page of the server, which the server pads with
# blanks (a-umlaut arrives as itself and a blank, the euro sign with two); a
# character the code page lacks is refused by the client library after the
# row has been written, with blanks for the whole value. Nothing the
# statement could say about the placeholder changes that, and rewriting the
# value is not this class's to decide, so it is refused -- before anything is
# sent. "Beyond ASCII" is a question of characters: a byte string with a high
# byte is as much beyond it as a character string.
sub _non_ascii_bind {
  my $string = _bind_string(shift);

  return ( defined $string and $string =~ /[^\x00-\x7F]/ ) ? 1 : 0;
}

# What is told, never the value.
sub _refuse_non_ascii {
  my ($self, $column, $position, $of) = @_;

  $self->throw_exception(sprintf
    'Cannot send this statement through DBD::Sybase: %s has a character '
  . 'beyond ASCII. FreeTDS sends a bound string as a fixed-length CHAR in '
  . "the bytes of the client's character set, converted to the code page of "
  . 'the server, and the server pads it with blanks (an a-umlaut arrives '
  . 'as itself and a blank); a character the code page lacks is refused by '
  . 'the client library after the row has been written, with blanks for '
  . 'the value. Nothing the statement says about the placeholder changes '
  . 'that, so the value is not sent. Connect through DBD::ODBC instead '
  . '(a dbi:ODBC: DSN, class DBIO::MSSQL::Storage::ODBC), which carries '
  . 'the string whole into an NCHAR, NVARCHAR or NTEXT column when the ODBC '
  . "driver's client character set is UTF-8 (ClientCharset=UTF-8), and into "
  . 'a VARCHAR column as far as the code page of the database has the '
  . 'characters.',
    ( defined $position
        ? "bind value $position of $of"
          . ( defined $column ? " (column '$column')" : '' )
        : ( defined $column ? "a value for the column '$column'" : 'a bind value' )
    ),
  );
}

# karr k55. DBD::Sybase binds an empty string as one blank (it has a space for
# "" in its code, an inheritance from ASE, which has no empty string). The
# server gets the same byte for '' and for ' '. So an empty value is not
# bound: the statement gets the literal '' where its placeholder stood, as for
# a value over the placeholder size. Nothing of a value is in the statement.
sub _empty_bind {
  my $string = _bind_string(shift);

  return ( defined $string and not length $string ) ? 1 : 0;
}

# karr k50. A value for a binary column cannot be bound as it is either: it
# is varchar to the server, which refuses to make VARBINARY of that (Msg 257)
# -- and DBD::Sybase ignores a bind type for anything but an EXEC. What can be
# bound is its hex form, which is ASCII and therefore arrives as it was sent,
# to a placeholder the statement turns back into the bytes:
#
#   CONVERT(VARBINARY(MAX), ?, 1)        bound: "0x" and the hex digits
#
# Style 1, with the "0x": the bound string is then never empty, which
# DBD::Sybase would bind as a blank, or as NULL (karr k55).
#
# One placeholder carries 4000 bytes, so 1999 bytes of the value; a longer
# value is bound in pieces, which the statement joins. MAX, because pieces of
# a sized type are cut to 8000 bytes when joined, without an error; and joined
# as a balanced tree, because joined one after the other the server copies
# what it has so far for every piece (measured: 3 MB in 77 s that way, in
# 1.1 s this way).
my $PIECE_BYTES = 1999;

# What one statement takes: the server counts 2100 parameters and the handle
# of the prepared statement is one of them (Msg 8003 from 2100 placeholders).
my $MAX_PLACEHOLDERS = 2099;

# How many placeholders a binary value takes: one per piece, one for an empty
# value and one for NULL.
sub _piece_count {
  my $bytes = shift;

  return 1 unless defined $bytes and length $bytes;
  return int( ( length($bytes) + $PIECE_BYTES - 1 ) / $PIECE_BYTES );
}

# The strings bound to them.
sub _hex_pieces {
  my $bytes = shift;

  return (undef) unless defined $bytes;
  return ('0x')  unless length $bytes;
  return map { '0x' . uc unpack 'H*', $_ } unpack "(a$PIECE_BYTES)*", $bytes;
}

# The expression that stands where the "?" of a binary value stood.
sub _hex_placeholders {
  my $count = shift;

  return 'CONVERT(VARBINARY(MAX), ?, 1)' if $count == 1;

  my $left = int( ( $count + 1 ) / 2 );

  return '(' . _hex_placeholders($left) . ' + '
             . _hex_placeholders( $count - $left ) . ')';
}

# The statement to prepare and what to bind to it, when a bind value cannot
# go the way it came: a value for a binary column (karr k50) is bound as its
# hex pieces, a value over the placeholder size (karr k40) is in the
# statement as a literal. undef when there is neither. On the NoBindVars
# class there are no binds to look at.
sub _rewrite_binds {
  my ($self, $sql, $bind) = @_;

  my (%literal, %binary, %empty);

  for my $i (0 .. $#$bind) {
    my ($attrs, $value) = @{ $bind->[$i] };

    if (
      ref $attrs eq 'HASH'
        and $self->_is_binary_data_type( $attrs->{sqlt_datatype} )
        and ref $value ne 'SCALAR'                               # bind_inout
    ) {
      $binary{$i}
        = $self->_binary_value_bytes( $value, $attrs->{dbic_colname} );
    }
    elsif (_over_placeholder_size($value)) {
      $literal{$i} = _long_value_literal(_wire_bytes("$value"));
    }
    elsif (_non_ascii_bind($value)) {
      $self->_refuse_non_ascii( $attrs->{dbic_colname}, $i + 1, scalar @$bind );
    }
    elsif (_empty_bind($value)) {
      $empty{$i} = 1;
    }
  }

  return undef unless %literal or %binary or %empty;

  # DBD::Sybase sends a statement that begins with EXEC as a remote procedure
  # call and reads nothing of it but the name and the placeholders: what
  # stands where a placeholder stood is dropped, and the procedure is handed
  # the hex string -- or, for an empty value, a blank.
  $self->throw_exception(
    'Cannot send this statement through DBD::Sybase: it has an empty string '
  . 'as a bind value, which DBD::Sybase binds as one blank and which is '
  . "therefore written into the statement as the literal '' -- and "
  . 'DBD::Sybase sends a statement that begins with EXEC as a remote '
  . 'procedure call, without what stands around a placeholder: the '
  . "procedure would be handed a blank. Write '' into the statement "
  . 'yourself, or connect through DBD::ODBC (class '
  . 'DBIO::MSSQL::Storage::ODBC), which binds an empty string as it is.'
  ) if %empty and $sql =~ /\A\s*exec/i;

  $self->throw_exception(
    'Cannot send this statement through DBD::Sybase: it has a bind value for '
  . 'a binary column, which is bound as its hex form to a placeholder that '
  . 'the statement turns back into bytes -- and DBD::Sybase sends a '
  . 'statement that begins with EXEC as a remote procedure call, without '
  . 'what stands around a placeholder. Hand the procedure the value in a '
  . 'form it converts itself.'
  ) if %binary and $sql =~ /\A\s*exec/i;

  # Put together as bytes: a byte string joined to a character string would
  # be encoded a second time, and arrive as something else than it does bound.
  # The placeholders are the free "?" of the statement: one in a string
  # literal or in a quoted name is part of the text.
  my @part = DBIO::Storage::DBI::NoBindVars::split_at_placeholders(_wire_bytes($sql));

  $self->throw_exception(sprintf
    'Cannot send this statement through DBD::Sybase: it has %s -- but the '
  . 'statement has %d placeholder%s and %d bind value%s, and the two numbers '
  . 'have to agree for the statement to be rewritten.',
    ( %literal
        ? "a bind value of more than $PLACEHOLDER_BYTES bytes, which the "
        . "server would cut to $PLACEHOLDER_BYTES without an error if it "
        . 'were bound, and which therefore goes into the statement as a '
        . 'literal'
        : %binary
        ? 'a bind value for a binary column, whose placeholder has to be '
        . 'rewritten for the server to take the value'
        : "an empty string as a bind value, which DBD::Sybase would bind as "
        . "a blank and which therefore goes into the statement as ''"
    ),
    $#part, ( $#part == 1 ? '' : 's' ), scalar @$bind, ( @$bind == 1 ? '' : 's' ),
  ) unless $#part == @$bind;

  # counted before a value is turned into its hex form: a statement that is
  # refused costs nothing
  my %count = map { $_ => _piece_count( $binary{$_} ) } keys %binary;

  my $placeholders = @$bind - keys(%literal) - keys(%empty);
  $placeholders += $_ - 1 for values %count;

  if (%count and $placeholders > $MAX_PLACEHOLDERS) {
    my ($largest) = sort { $count{$b} <=> $count{$a} } keys %count;

    $self->throw_exception(sprintf
      'Cannot send this statement through DBD::Sybase: it would have %d '
    . 'placeholders, and the server takes %d. A value for a binary column is '
    . 'bound in pieces of %d bytes, one placeholder each; the largest of '
    . 'this statement%s has %d bytes and needs %d. One statement carries '
    . 'about %d bytes of binary values, less what its other bind values '
    . 'take.',
      $placeholders, $MAX_PLACEHOLDERS, $PIECE_BYTES,
      ( defined $bind->[$largest][0]{dbic_colname}
          ? " (column '$bind->[$largest][0]{dbic_colname}')" : '' ),
      length( defined $binary{$largest} ? $binary{$largest} : '' ),
      $count{$largest},
      $MAX_PLACEHOLDERS * $PIECE_BYTES,
    );
  }

  my $rewritten = shift @part;
  $rewritten .= (
      exists $literal{$_} ? $literal{$_}
    : exists $empty{$_}   ? "''"
    : exists $binary{$_}  ? _hex_placeholders( $count{$_} )
    :                       '?'
  ) . $part[$_] for 0 .. $#$bind;

  return {
    sql => $rewritten,

    # per bind value: nothing (it is in the statement), its hex pieces, or
    # its own position
    bound => [ map {
        ( exists $literal{$_} or exists $empty{$_} ) ? ()
      : exists $binary{$_}  ? [ _hex_pieces( $binary{$_} ) ]
      :                       $_
    } 0 .. $#$bind ],

    # a statement with a value in it does not come again
    literal => scalar keys %literal,
  };
}

# Core runs a statement in three steps -- trace it, prepare it, bind its
# values (_dbh_execute; _dbh_prepare without the execute) -- and the prepare,
# the one step that has to be given another statement, is not handed the
# values. So what is to be prepared is worked out here, ahead of the three,
# and kept for the last two. The trace gets the statement and the values as
# they were, through redact_bind_value (ADR 0025) like any other: put into
# the statement before the trace, a long value would pass that hook by.
#
# Not after the prepare either: a second prepare while a prepared statement
# with placeholders is alive makes DBD::Sybase open a second connection.
sub _dbh_execute {
  my $self = shift;

  local $self->{_rewritten_binds} = $self->_rewrite_binds(@_[1, 2]);

  return $self->next::method(@_);
}

sub _dbh_prepare {
  my $self = shift;

  local $self->{_rewritten_binds} = $self->_rewrite_binds(@_[1, 2]);

  return $self->next::method(@_);
}

sub _prepare_sth {
  my ($self, $dbh, $sql) = @_;

  my $rewritten = $self->{_rewritten_binds}
    or return $self->next::method($dbh, $sql);

  # A statement with a value in it does not come again: never into the
  # statement cache, whatever the setting.
  local $self->{disable_sth_caching} = 1 if $rewritten->{literal};

  return $self->next::method($dbh, $rewritten->{sql});
}

sub _bind_sth_params {
  my ($self, $sth, $bind, $bind_attrs) = @_;

  if (my $rewritten = $self->{_rewritten_binds}) {
    my (@bind, @attrs);

    for my $bound (@{ $rewritten->{bound} }) {
      if (ref $bound) {             # the hex pieces of a binary value
        push @bind,  map { [ {}, $_ ] } @$bound;
        push @attrs, (undef) x @$bound;
      }
      else {
        push @bind,  $bind->[$bound];
        push @attrs, $bind_attrs->[$bound];
      }
    }

    ($bind, $bind_attrs) = (\@bind, \@attrs);
  }

  return $self->next::method($sth, $bind, $bind_attrs);
}

# populate in void context: core prepares one statement from the first row
# and executes it once per row, with every value bound. A value over the
# placeholder size in any row cannot go that way, and neither can a value
# for a binary column, whose placeholders are as many as its size asks for.
# Such a data set is inserted row by row -- in one transaction, as the fast
# path does it.
sub _insert_bulk {
  my ($self, $source, $cols, $data) = @_;

  # No placeholders: core's fast path prepares one statement and executes it
  # once per row, and throws when the values were interpolated into it
  # instead (karr k57). Row by row, in one transaction, as the fast path does
  # it. What the other branches below check is about binds, of which this
  # class has none: core's literal is what it is.
  return $self->_insert_rows_in_transaction($source, $cols, $data)
    if $self->isa('DBIO::Storage::DBI::NoBindVars');

  # refuses a value that is no binary value before the first row is sent
  my (undef, $binary)
    = $self->_bulk_binary_values_as_bytes($source, $cols, $data);

  # refuses a value beyond ASCII (karr k49) before the first row is sent. A
  # binary value is not text and not looked at: it is in $binary, and its
  # data set goes row by row anyway.
  my @values = $self->_bulk_text_values($source, $cols, $data);

  for my $value (@values) {
    $self->_refuse_non_ascii( $value->[0] ) if _non_ascii_bind( $value->[1] );
  }

  return $self->next::method($source, $cols, $data)
    unless $binary
      or grep { _over_placeholder_size( $_->[1] ) or _empty_bind( $_->[1] ) }
        @values;

  return $self->_insert_rows_in_transaction($source, $cols, $data);
}

sub _insert_rows_in_transaction {
  my ($self, $source, $cols, $data) = @_;

  my $guard = $self->txn_scope_guard;

  for my $row (@$data) {
    my %row;
    @row{@$cols} = @$row;
    $self->insert($source, \%row);
  }

  $guard->commit;

  return scalar @$data;
}

# The values of a populate data set that are text, each as [ column, value ]:
# a literal with binds, \[ $sql, @bind ], gives the values of its binds.
# Binary columns have none; with a binary value the data set is row by row
# in any case.
sub _bulk_text_values {
  my ($self, $source, $cols, $data) = @_;

  my $colinfos = $source->columns_info($cols);
  my @binary   = map {
    $self->_is_binary_data_type( $colinfos->{ $cols->[$_] }{data_type} ) ? 1 : 0
  } 0 .. $#$cols;

  return map {
    my $row = $_;
    map {
      my $i = $_;
      ( ref $row->[$i] eq 'REF' and ref ${ $row->[$i] } eq 'ARRAY' )
        ? ( map { [ $_->[0]{dbic_colname} // $cols->[$i], $_->[1] ] }
            grep { not $self->_is_binary_data_type( $_->[0]{sqlt_datatype} ) }
              @{ $self->_resolve_bindattrs(
                   $source, [ @{ ${ $row->[$i] } }[ 1 .. $#{ ${ $row->[$i] } } ] ],
                   $colinfos ) } )
        : $binary[$i] ? ()
        : [ $cols->[$i], $row->[$i] ];
    } 0 .. $#$row;
  } @$data;
}

# karr k56. Reading a binary column. DBD::Sybase hands back a BINARY(n) or a
# VARBINARY(n) value as its hex digits, an IMAGE value too unless
# syb_binary_images is on -- and it has a buffer of ONE byte for a
# VARBINARY(MAX) column (the client library describes that as 2147483647
# bytes, and twice that plus two, for the hex digits, comes out as 0 in 32
# bits). The fetch of a row with a value in such a column fails, and the DBD
# drops a row whose fetch fails, without an error: the row seems not to exist.
#
# The one form in which this DBD carries the bytes of a binary value as they
# are is an IMAGE column with syb_binary_images on. So a column of a result
# source whose data type is a binary one is asked for as that:
#
#   CAST([me].[body] AS IMAGE)
#
# Which entry of a select list is such a column is what its data type says,
# as for a bind value (_is_binary_data_type) -- not what comes back. Only an
# entry that is the column itself: a function, an expression and literal SQL
# stay what they are.
#
# Done here and not in _select_args, which _select_args_to_query (as_query)
# shares: a subquery keeps the column as it is. An IMAGE cannot be compared,
# and a condition on what a subquery selects is a comparison.
sub _select {
  my $self = shift;

  my ($op, $ident, $select, $where, $attrs, @limit) = $self->_select_args(@_);

  my ($rewritten, $binary) = $self->_long_columns_guarded($ident, $select)
    or return $self->_execute($op, $ident, $select, $where, $attrs, @limit);

  # for _execute_sth below: this statement's IMAGE columns are to be bytes
  local $self->{_binary_select} = $binary ? 1 : 0;

  return $self->_execute(
    $op, $ident, $rewritten, $where,
    # the limit dialect builds its subqueries from the list in the attributes
    { %$attrs, select => $rewritten },
    @limit,
  );
}

# karr k47. The kind of column whose value the session's TEXTSIZE can cut, by
# the type it has ON THE SERVER (_server_data_type: what DBIO::MSSQL::DDL
# deploys the declared type as -- a 'text' column is an NVARCHAR(MAX), not a
# TEXT): 'binary' (read as an IMAGE, k56, whatever its size), 'ntext' (of
# which a CASE cannot return one), 'varchar_max' and 'nvarchar_max'. The
# sized VARCHAR(n) and NVARCHAR(n) are not subject to TEXTSIZE (measured: 8000
# bytes whole under a TEXTSIZE of 100), the XML type is not either (50007
# characters under 32768). A real TEXT cannot be declared (the portable
# 'text' is NVARCHAR(MAX)), so it has no kind.
sub _long_column_kind {
  my ($self, $info) = @_;

  my $type = $info->{data_type};
  return undef unless defined $type;

  return 'binary' if $self->_is_binary_data_type($type);

  my $server = $self->_server_data_type($info);

  my ($name, $length) = $server =~ /\A \s* (\w+) \s* (?: \( \s* (\w+|-1) \s* \) )? \s* \z/x
    or return undef;

  return 'ntext' if $name eq 'ntext';

  return "${name}_max"
    if ( $name eq 'varchar' or $name eq 'nvarchar' )
       and defined $length and $length =~ /\A (?: -1 | max ) \z/xi;

  return undef;
}

# The select list with every column that the session's TEXTSIZE can cut asked
# for in a form that fails when it does, and every column of a binary data
# type as an IMAGE (karr k56); and whether there is a binary one. Nothing when
# there is no such column.
#
# karr k47. SET TEXTSIZE (the FreeTDS class sets it from LongReadLen, 32768
# bytes unless the connect info says otherwise) cuts a longer value of a TEXT,
# NTEXT, IMAGE, VARCHAR(MAX), NVARCHAR(MAX) or VARBINARY(MAX) column on the
# way back WITHOUT AN ERROR -- exactly at TEXTSIZE bytes: 32768 characters of
# a VARCHAR(MAX), 16384 of an NVARCHAR(MAX). The client cannot tell a value
# that was cut from one that is that long, the server can:
#
#   CASE WHEN DATALENGTH(col) > @@TEXTSIZE
#        THEN CONVERT(<type>, CONVERT(INT, 'message')) ELSE col END
#
# The conversion of the message to an integer is what fails, with Msg 245,
# and the server's text carries the message. Exact: a value of exactly
# TEXTSIZE bytes is whole and is not refused. Server side, so there is no
# fetch site that could miss it (cursor, single, get_column, ...).
#
# Only an entry that is the column itself, as for k56; not in a subquery.
sub _long_columns_guarded {
  my ($self, $ident, $select) = @_;

  return unless grep { defined $_ and not length ref $_ } @$select;

  # of every column of every source in the FROM, as core resolves the type
  # of a bind value: asked by name, a selected name that is no column of its
  # source would throw
  my $colinfos = $self->_resolve_column_info($ident);
  my ($found, $binary);

  my @select = map {
    my $kind = ( defined $_ and not length ref $_ and $colinfos->{$_} )
      ? $self->_long_column_kind( $colinfos->{$_} )
      : undef;

    if ($kind) {
      $found  = 1;
      $binary = 1 if $kind eq 'binary';
      \( $self->_guarded_long_column($_, $colinfos->{$_}, $kind) );
    }
    else {
      $_;
    }
  } @$select;

  return $found ? ( \@select, $binary ) : ();
}

# What the failing conversion carries to the caller; _execute_sth reads it.
my $TEXTSIZE_EXCEEDED = 'DBIO::MSSQL TEXTSIZE guard: column';

# The failing conversion of the guard reaches the caller as the server's
# Msg 245, from the execute or -- when the row that does not fit comes after
# others -- from a fetch. Every error of this storage goes through
# throw_exception, so the guard's message is put into words here, whichever
# call it came from.
sub throw_exception {
  my ($self, $message, @rest) = @_;

  if ( defined $message and not ref $message
       and $message =~ /\Q$TEXTSIZE_EXCEEDED\E '([^']*)' holds a value longer than the session's TEXTSIZE, (\d+) bytes/
  ) {
    $message = sprintf
      'Cannot read this result through DBD::Sybase: the column \'%s\' holds a '
    . 'value longer than the TEXTSIZE of the session, %d bytes. DBD::Sybase '
    . 'would return it cut to that size, without an error. The FreeTDS '
    . 'class sets TEXTSIZE from LongReadLen of the connect info (32768 '
    . 'unless that says otherwise): connect with a LongReadLen of at '
    . 'least the longest value, in bytes. An empty value of a binary '
    . 'column costs the client LongReadLen bytes of memory (see '
    . '"VALUES LONGER THAN TEXTSIZE").',
      $1, $2;
  }

  return $self->next::method($message, @rest);
}

sub _guarded_long_column {
  my ($self, $name, $info, $kind) = @_;

  my $column = $self->sql_maker->_quote($name);

  ( my $label = $name ) =~ s/'/''/g;
  # Short: it is in the text of every statement that reads the column. The
  # exception that reaches the caller says the rest (throw_exception).
  my $message = "'$TEXTSIZE_EXCEEDED ''$label'' holds a value longer than "
    . "the session''s TEXTSIZE, ' + CONVERT(VARCHAR(20), \@\@TEXTSIZE) "
    . "+ ' bytes'";

  my $fail = "CONVERT(INT, $message)";

  my $too_long = "DATALENGTH($column) > \@\@TEXTSIZE";

  return "CAST(CASE WHEN $too_long THEN CONVERT(VARBINARY(MAX), $fail) "
       . "ELSE CAST($column AS VARBINARY(MAX)) END AS IMAGE)"
    if $kind eq 'binary';

  # A CASE returns one type, the higher of its branches. For an NTEXT that is
  # the MAX type it is cast to (a CASE cannot return the NTEXT itself).
  return "CASE WHEN $too_long THEN CONVERT(NVARCHAR(MAX), $fail) "
       . "ELSE CAST($column AS NVARCHAR(MAX)) END"
    if $kind eq 'ntext';

  # VARCHAR(MAX) and NVARCHAR(MAX) must stay the type they are: the TEXTSIZE
  # cuts the value as the type the statement returns, and a CASE between a
  # VARCHAR and an NVARCHAR branch would hand it over as an NVARCHAR, cut at
  # half as many characters than the guard looks for (measured: a VARCHAR(MAX)
  # value of 20000 characters came back as 16384, without an error). The type
  # is known (the server's, _server_data_type), so the failing branch is of
  # that type and the CASE returns the column itself. No concatenation: under
  # CONCAT_NULL_YIELDS_NULL OFF that turns a NULL into '' (k47). Here a NULL
  # has no length, the condition is unknown and the ELSE hands the NULL over.
  my $type = $kind eq 'nvarchar_max' ? 'NVARCHAR(MAX)' : 'VARCHAR(MAX)';

  return "CASE WHEN $too_long THEN CONVERT($type, $fail) ELSE $column END";
}

# What a result column of unlimited binary size is to DBI on this DBD: the
# type and the size the client library describes VARBINARY(MAX) with.
my $SQL_BINARY       = -2;
my $UNLIMITED_BINARY = 2147483647;

# And SQL_VARIANT: a CHAR of 8009 (karr k59).
my $SQL_CHAR              = 1;
my $SQL_VARIANT_PRECISION = 8009;

# Two things around the execute of a statement.
#
# syb_binary_images, for a statement _select has rewritten and for nothing
# else: the DBD decides how an IMAGE column is fetched when it describes the
# result, which is in the execute. The handle is as it was afterwards, so what
# hand-written SQL and dbh_do read from an IMAGE column is what it was.
#
# And a result column this DBD cannot read is refused, loudly. That is every
# VARBINARY(MAX) column _select did not rewrite -- a function, an expression,
# literal SQL, a column whose data type is not declared as a binary one.
# Decided by how the handle describes the column, before a row is fetched
# and whatever the rows hold: with NULLs and empty values alone the result
# would be right, with the first value it would be short.
sub _execute_sth {
  my ($self, $dbh, $sth) = @_;

  local $dbh->{syb_binary_images} = 1 if $self->{_binary_select};

  my @executed = $self->next::method($dbh, $sth);

  # nothing to look at for an INSERT, an UPDATE, a DELETE, DDL
  return @executed unless $sth->{NUM_OF_FIELDS};

  my ($types, $sizes) = map { $sth->{$_} || [] } qw(TYPE PRECISION);

  # karr k59. A SQL_VARIANT column is described as a CHAR of 8009 (8000 and
  # the 9 bytes of its header; no CHAR, VARCHAR, NCHAR or NVARCHAR has that
  # precision: the client library gives 4 times the length). A variant with a
  # binary base type loses its row, silently -- or comes back as hex digits
  # when other rows were fetched before it (measured). What it holds is not
  # known before the rows are.
  my ($variant) = grep {
    ( $types->[$_] || 0 ) == $SQL_CHAR
      and ( $sizes->[$_] || 0 ) == $SQL_VARIANT_PRECISION
  } 0 .. $#$types;

  if (defined $variant) {
    my $name = ( $sth->{NAME} || [] )->[$variant];

    $sth->finish;

    $self->throw_exception(sprintf
      'Cannot read this result through DBD::Sybase: its column %d%s is '
    . 'SQL_VARIANT, and DBD::Sybase drops the row of a value with a binary '
    . 'base type without an error (the row seems not to exist), or returns '
    . 'its hex digits as text when rows were fetched before it. Which of '
    . 'the two cannot be told before the rows are. Select a form of the '
    . 'value that does not depend on its base type: '
    . 'CONVERT(VARCHAR(8000), <expression>) for text, numbers and dates, '
    . 'CONVERT(VARCHAR(MAX), CONVERT(VARBINARY(8000), <expression>), 2) for '
    . 'the hex digits of a binary value; SQL_VARIANT_PROPERTY(<expression>, '
    . "'BaseType') says which. DBD::ODBC reads the column.",
      $variant + 1,
      ( defined $name and length $name ) ? " ('$name')" : '',
    );
  }

  my ($unreadable) = grep {
    ( $types->[$_] || 0 ) == $SQL_BINARY
      and ( $sizes->[$_] || 0 ) == $UNLIMITED_BINARY
  } 0 .. $#$types
    or return @executed;

  my $name = ( $sth->{NAME} || [] )->[$unreadable];

  $sth->finish;

  $self->throw_exception(sprintf
    'Cannot read this result through DBD::Sybase: its column %d%s is '
  . 'VARBINARY(MAX), and DBD::Sybase drops every row that has a value of '
  . 'one byte or more in such a column, without an error -- the rows would '
  . 'seem not to exist. A column of a result source is read when its '
  . 'data_type is declared as a binary one and it is selected as the column '
  . 'itself, not through a function or literal SQL: the storage then asks '
  . 'for it in a form DBD::Sybase carries. For anything else, select the '
  . 'hex digits of '
  . 'the value, CONVERT(VARCHAR(MAX), <expression>, 2): they arrive up to '
  . 'the TEXTSIZE of the session in characters, half as many bytes, and are '
  . 'cut beyond that without an error.',
    $unreadable + 1,
    ( defined $name and length $name ) ? " ('$name')" : '',
  );
}


sub connect_call_datetime_setup {
  my $self = shift;
  my $dbh = $self->_get_dbh;

  if ($dbh->can('syb_date_fmt')) {
    # amazingly, this works with FreeTDS
    $dbh->syb_date_fmt('ISO_strict');
  }
  else{
    carp_once
      'Your DBD::Sybase is too old to support '
    . 'DBIO::InflateColumn::DateTime, please upgrade!';
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Storage::Sybase - Support for Microsoft SQL Server via DBD::Sybase

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Storage driver for Microsoft SQL Server accessed via L<DBD::Sybase>
(including FreeTDS-based connections). Inherits from both
L<DBIO::Sybase::Storage> and L<DBIO::MSSQL::Storage>.

A schema that declares the driver -- the L<DBIO::MSSQL> component or the
C<-ms> shortcut -- has its storage pinned to L<DBIO::MSSQL::Storage>, which
moves into this class at its first use when the DSN is a C<dbi:Sybase:> one
(L<DBIO::MSSQL::Storage/_adapt_to_access_path>). The server is not asked what
it is.

A schema without a declared driver is refused at connect (core ADR 0067):
the DSN alone does not name this driver -- C<< DBIO->driver_for >> answers
C<Sybase> for a C<dbi:Sybase:> DSN.

The driver then checks whether your L<DBD::Sybase> build
supports placeholders. If not, the storage is reblessed to
C<DBIO::MSSQL::Storage::Sybase::NoBindVars>. FreeTDS versions above 0.82
have known statement-caching bugs; the driver detects these and disables
statement caching automatically. The key of a new row is read with
C<SCOPE_IDENTITY()> as in L<DBIO::MSSQL::Storage>, also over such a FreeTDS:
the C<@@identity> workaround this class had for it returned, with a trigger
that inserts into another table with an identity column, that other table's
key (1000 for the row 1), and C<SCOPE_IDENTITY()> works with FreeTDS 1.3.17
(the only version measured, no version limit is assumed). The
NoBindVars class reads the key the same way, with an INSERT trigger on the
table included (F<t/84-nobindvars-live.t>).

A storage pinned to this class itself, through
L<DBIO::Schema/storage_type>, gets the placeholder check too, with storage
layers registered on the schema as well: the storage is then an
instance of a synthesised class that derives from this one, and the check
looks through it to its base. The layers stay over whichever class the
storage becomes.

=head1 METHODS

=head2 connect_call_datetime_setup

Used as:

  on_connect_call => 'datetime_setup'

In L<connect_info|DBIO::Storage::DBI/connect_info> to set:

  $dbh->syb_date_fmt('ISO_strict'); # output fmt: 2004-08-21T14:36:48.080Z

On connection for use with L<DBIO::InflateColumn::DateTime>

This works for both C<DATETIME> and C<SMALLDATETIME> columns, although
C<SMALLDATETIME> columns only have minute precision.

=head1 VALUES OF MORE THAN 4000 BYTES

When FreeTDS prepares a statement for SQL Server it declares every
placeholder as C<varchar(4000)>, whatever is bound to it afterwards, and the
server cuts a longer value to that size B<without an error> -- into any
column, C<VARCHAR(MAX)> included, and in a condition as well, where the cut
value then matches another row or none. No bind type, no C<CAST> around the
placeholder and no client setting changes the declaration (measured
with L<DBD::Sybase> 1.27 and FreeTDS 1.3.17 against SQL Server 2022).

This class therefore does not bind such a value. A value of more than 4000
bytes goes into the statement as a literal, where it arrives whole; every
other value of the same statement stays a bind.

=over

=item * B<The line is drawn in bytes>, as L<DBD::Sybase> sends them: the bytes
Perl holds the string in. A character string of 1334 euro signs is 4002 bytes
and goes into the statement.

=item * B<A value of ASCII alone is a plain literal>, the C<varchar> the
placeholder was. B<Anything else is a Unicode literal>, C<N'...'>, so that no
character depends on the code page of the database: an C<NVARCHAR> column
gets every character. Where the server has to convert the value to a code
page -- a C<VARCHAR> column -- a character that code page lacks is stored as
C<?>, without an error; that is the server's conversion, and a bind does not
do better (the client library refuses the value, after a row of blanks has
been written). In an expression where the type matters -- C<HASHBYTES>,
C<DATALENGTH>, a conversion to C<VARBINARY> -- a long value beyond ASCII is
C<nvarchar> where a short one is C<varchar>.

=item * B<The value arrives as it was given.> Quotes are doubled, and the two
things the server reads in a literal and not in a bound value are written
around: a backslash before a line break (the server drops both) and a NUL
(the end of the statement text for it).

=item * B<The trace is unchanged.> It shows the statement with its
placeholder and hands the value to
L<redact_bind_value|DBIO::Storage::DBI/redact_bind_value>, as for any bind.
The statement that carries the value is never put into the statement cache.

=item * B<populate in void context> executes one prepared statement once per
row and cannot carry a long value for some rows. A data set with such a value
is inserted row by row, in one transaction.

=item * B<A statement whose placeholders cannot be told apart throws.> A C<?>
inside a literal or a name of hand-written SQL, in a statement that also has
a long bind value, leaves it open which C<?> the value belongs to. Nothing is
sent.

=back

Not covered:

=over

=item * a statement run on the handle directly (C<< $storage->dbh_do >>,
C<on_connect_do> with bind values): L<DBD::Sybase> binds there, and the
server cuts. The caller has the handle in hand and binds, or writes the
literal, as it sees fit. The same
holds there for a string beyond ASCII and for an empty string
(L</STRINGS BEYOND ASCII>, L</EMPTY STRINGS>);

=item * a storage of another class on a L<DBD::Sybase> handle -- a private
subclass of L<DBIO::MSSQL::Storage> pinned by hand -- does not get here: it is
refused (L<DBIO::MSSQL::Storage/_adapt_to_access_path>). Derive from this
class.

=back

A value for a binary column is not text and does not go this way at any
length: see L</BINARY VALUES>.

L<DBIO::MSSQL::Storage::Sybase::NoBindVars> has no placeholders and is not
affected; L<DBD::ODBC> binds long values whole.

=head1 STRINGS BEYOND ASCII

A string with a character beyond ASCII B<does not arrive when it is bound>
over this transport, at any length (measured with L<DBD::Sybase>
1.27 and FreeTDS 1.3.17 against SQL Server 2022). FreeTDS sends it as a CHAR
of fixed length -- its length in bytes of the client's character set --
after converting it to the code page of the server, and the server pads it
with blanks: an a-umlaut arrives as itself and a blank, the euro sign with
two. A character the code page lacks is refused by the client library
B<after the row has been written>, and the row holds blanks. No bind type,
no C<CAST> around the placeholder and no setting of L<DBD::Sybase> changes
that; a statement that rewrote the placeholder would make the value an
C<nvarchar>, which changes what a condition compares and whether an index is
used, and this class does not decide that for a caller.

So this class B<refuses such a value, before anything is sent>:

=over

=item * B<Beyond ASCII> is a question of characters: a character string
with a character above C<U+007F> is, and so is a byte string with a byte
above C<0x7F>. An object is looked at as its string form.

=item * B<The message names> the position of the value among the bind
values of the statement and, when known, the column; it names the cause and
the way out, L<DBD::ODBC> with L<DBIO::MSSQL::Storage::ODBC>: there the value
arrives whole in an C<NCHAR>, C<NVARCHAR> or C<NTEXT> column, with the client
character set of the ODBC driver at UTF-8, and in a C<VARCHAR> column as far
as the code page has the characters (L<DBIO::MSSQL::Storage::ODBC/STRINGS
BEYOND THE CODE PAGE>). It never carries the value, a password or the DSN.

=item * B<It holds for> C<INSERT>, C<UPDATE>, C<DELETE> and conditions
(C<=>, C<LIKE>, C<IN>), for literal SQL with bind values, for an C<EXEC>, and
for C<populate> in void context, which refuses before the first row is sent.

=item * B<Not refused:> C<NULL>; a value for a binary column
(L</BINARY VALUES>), which is bytes and bound as its hex form; a value of more
than 4000 bytes, which is a literal and arrives whole
(L</VALUES OF MORE THAN 4000 BYTES>); everything of ASCII alone.

=item * B<Not looked at:> L<DBIO::MSSQL::Storage::Sybase::NoBindVars> and a
statement run on the handle directly. The first has no binds -- core puts
every value into the statement as a plain literal, and a character the code
page lacks becomes C<?> there; that is core's, not rewritten here.

=back

=head1 EMPTY STRINGS

L<DBD::Sybase> binds an empty string as B<one blank> (its C<dbdimp.c> has a
space for C<"">, an inheritance from ASE, which has no empty string), and
the server gets the same byte for C<''> and for C<' '>. Bound, an empty
string was stored as a blank in C<VARCHAR>, C<NVARCHAR> and C<TEXT>,
C<LIKE ''> found the row of the blank, and C<REPLACE(?, ...)> and
C<DATALENGTH(?)> saw it (measured as for the section before).
C<syb_bind_empty_string_as_null> makes C<NULL> of it, not an empty string.

This class therefore does not bind an empty string. It writes the literal
C<''> into the statement where the placeholder stood -- the seam that carries
a long value (L</VALUES OF MORE THAN 4000 BYTES>), and the same rules:

=over

=item * B<Nothing of a value is in the statement> otherwise, an empty string
being nothing. The trace shows the statement with its placeholder and the
value, as for any bind.

=item * B<C<NULL> is C<NULL>>, and a value of one blank is one blank, still a
bind.

=item * B<An C<EXEC> with an empty string throws>: L<DBD::Sybase> sends it
as a remote procedure call, without what stands around a placeholder, and
the procedure would be handed a blank. Write C<''> into the statement
yourself, or use L<DBD::ODBC>.

=item * B<A statement whose placeholders cannot be told apart throws>, as for
a long value.

=item * B<populate in void context> inserts row by row, in one transaction,
when a row has an empty string.

=item * B<Other column types> are what they were and what they are over
L<DBD::ODBC>: C<''> is 0 in an C<INT>, C<1900-01-01> in a C<DATETIME>, blanks
in a C<CHAR(n)>, and a conversion error in a C<DECIMAL> (Msg 8114).

=back

=head1 BINARY VALUES

A bound value is C<varchar> to the server, and the server refuses to make
C<VARBINARY> of that (Msg 257) -- for a value of any length, C<NULL>
included. L<DBD::Sybase> honours a bind type for an C<EXEC> only. So a value
for a binary column is bound as something that is text and arrives unchanged,
its hex form, to a placeholder the statement turns back into the bytes:

  CONVERT(VARBINARY(MAX), ?, 1)      -- bound: 0x4A5B...

B<Nothing of the value is in the statement.> (Measured with
L<DBD::Sybase> 1.27 and FreeTDS 1.3.17 against SQL Server 2022, from an empty
value to 4 MB, into C<VARBINARY(MAX)>, C<VARBINARY(n)>, C<BINARY(n)> and
C<IMAGE>, in C<INSERT>, C<UPDATE> and conditions.)

=over

=item * B<Which bind value is a binary one> is what its data type says:
C<binary>, C<varbinary>, C<image>, and the names L<DBIO::MSSQL::DDL> makes
one of them (C<blob>, C<bytea>, ...) -- the type of the column of the result
source, in a condition as in an C<INSERT> or an C<UPDATE>, or the type given
with a bind value in literal SQL
(C<< \[ '?', [ { sqlt_datatype => 'varbinary' } => $value ] ] >>). Not what
the value looks like: a value of plain ASCII in a binary column is bytes too.
A value bound without a type is text.

=item * B<The value is the bytes of the string>, one per character, whatever
form Perl holds the string in. B<A character above 255 is no byte>: such a
value throws before anything is sent, naming the column and the position,
not the value.

=item * B<A value of more than 1999 bytes is bound in pieces>, one
placeholder each, which the statement joins -- a placeholder is
C<varchar(4000)> to the server (L</VALUES OF MORE THAN 4000 BYTES>), and that
is C<0x> and the hex digits of 1999 bytes. A condition on a binary column is
rewritten the same way; an index on the column is still used for a seek.

=item * B<One statement takes 2099 placeholders>, the pieces and every other
bind value together: about 4 MB of binary values. A statement that would
have more throws before anything is sent, with the sizes.

=item * B<An empty value is empty>, zero bytes -- not the blank L<DBD::Sybase>
makes of an empty string -- and C<NULL> is C<NULL>.

=item * B<An C<EXEC> with such a value throws.> L<DBD::Sybase> sends a
statement that begins with C<EXEC> as a remote procedure call, without what
stands around a placeholder: the procedure would be handed the hex string.

=item * B<A statement whose placeholders cannot be told apart throws>, as
for a long value: a C<?> inside a literal or a name of hand-written SQL,
beside a binary value.

=item * B<The trace is unchanged>: the statement with its plain placeholder,
the value through
L<redact_bind_value|DBIO::Storage::DBI/redact_bind_value>.

=item * B<populate in void context> inserts row by row, in one transaction,
when the data set has a value for a binary column: how many placeholders a
row takes depends on the size of its value.

=back

Not covered:

=over

=item * a statement run on the handle directly (C<< $storage->dbh_do >>):
bind the hex form and write the C<CONVERT> yourself;

=item * L<DBIO::MSSQL::Storage::Sybase::NoBindVars>, which has no
placeholders: core puts every value into the statement as a text literal,
and a binary value does not arrive that way (Msg 257, or the client library
refuses to convert its bytes);

=item * a private subclass of L<DBIO::MSSQL::Storage> pinned by hand on a
L<DBD::Sybase> handle is refused, not left to bind a binary value as text
(L<DBIO::MSSQL::Storage/_adapt_to_access_path>). Derive from this class.

=back

L<DBD::ODBC> carries a binary value as a bind of its own type:
L<DBIO::MSSQL::Storage::ODBC/BINARY VALUES>.

=head1 READING BINARY VALUES

L<DBD::Sybase> hands back the value of a C<BINARY(n)> or a C<VARBINARY(n)>
column as its hex digits, and that of an C<IMAGE> column too unless
C<syb_binary_images> is on. For a C<VARBINARY(MAX)> column it has a buffer of
one byte: the fetch of a row with a value in such a column fails, and
L<DBD::Sybase> drops a row whose fetch fails B<without an error>. A result set
with such a column has the rows whose value is C<NULL> or empty and no other
-- C<find> on a table with such a column finds nothing. (Measured with
L<DBD::Sybase> 1.27 and FreeTDS 1.3.17 against SQL Server 2022. The client
library describes the column as 2147483647 bytes long, and the room for its
hex digits, twice that and two, comes out as nothing in 32 bits.)

The one form in which L<DBD::Sybase> carries a binary value as the bytes it
is, is an C<IMAGE> column read with C<syb_binary_images> on. This class
therefore asks for a binary column as that:

  SELECT [me].[id], CAST([me].[body] AS IMAGE) FROM [doc] [me] ...

and what comes back is B<the bytes>, for C<VARBINARY(MAX)>, C<VARBINARY(n)>,
C<BINARY(n)> and C<IMAGE> alike. B<A caller that turned the hex digits back
into bytes itself now gets bytes.>

=over

=item * B<Which entry of a select list is a binary column> is what its data
type says, as for a bind value (L</BINARY VALUES>): the C<data_type> of the
column in its result source. Not what comes back. A column whose
C<data_type> is not declared is not rewritten.

=item * B<Only an entry that is the column itself> is rewritten -- in
C<find>, C<single>, C<next>, C<all>, a cursor, C<get_column>, with an alias,
through a join or a prefetch, under C<rows> and C<offset>, C<distinct> and
C<group_by>, for C<retrieve_on_insert>. A function over the column
(C<< get_column('body')->max >>), an expression and literal SQL are not.

=item * B<A subquery is not rewritten> (C<as_query>, and with it C<count>,
a condition C<< -in => $rs->as_query >>, a set operation, the subquery of a
C<delete> or an C<update> over a join): an C<IMAGE> cannot be compared. The
outer statement is.

=item * B<C<syb_binary_images> is on for the execute of a rewritten statement
alone>, and the handle is as it was afterwards, after a failed execute too.
What hand-written SQL reads from an C<IMAGE> column is what it was.

=item * B<A value arrives whole up to the C<TEXTSIZE> of the session>, which
L<DBIO::Sybase::Storage::FreeTDS> sets to C<LongReadLen> of the connect info
-- 32768 bytes unless that says otherwise. B<A longer value is refused>, not
cut: the column is read behind the TEXTSIZE guard (L</VALUES LONGER THAN
TEXTSIZE>). Connect with C<< LongReadLen => $bytes >> for larger
values; measured up to 4195901 bytes.

=item * B<An empty value costs C<TEXTSIZE> bytes of memory> while its
statement handle lives: the client library fills the whole buffer of an
empty C<IMAGE> value (measured: 48 MB with a C<TEXTSIZE> of 50000000). With
the default that is 32 kB per binary column of a result (the
column types that do not pay it: L</VALUES LONGER THAN TEXTSIZE>).

=item * B<A C<DISTINCT> written in literal SQL beside a binary column is
refused by the server> (Msg 421): the column is an C<IMAGE> then, and an
C<IMAGE> cannot be compared. C<< distinct => 1 >> is a C<GROUP BY> over the
column as it is, and works.

=back

B<A C<VARBINARY(MAX)> result column that was not rewritten throws.> After
the execute, before a row is fetched, the storage looks at how the handle
describes the result; a column that is C<VARBINARY(MAX)> there would lose
its rows, and the statement is refused with an exception that says so. That
is decided by the column and not by the rows: a result whose values are all
C<NULL> throws as well. It is what happens to

=over

=item * a function or an expression over such a column
(C<< { max => 'body' } >>, C<CAST(... AS VARBINARY(MAX))>), and the column
in literal SQL (C<< \'me.body' >>);

=item * a column whose C<data_type> is not declared as a binary one.

=back

Select the hex digits instead, C<CONVERT(VARCHAR(MAX), E<lt>expressionE<gt>, 2)>:
they arrive up to C<TEXTSIZE> characters, half as many bytes, and are cut
beyond that without an error. C<CAST(E<lt>expressionE<gt> AS VARBINARY(8000))>
arrives as hex digits too, cut to 8000 bytes by the server.

Not covered:

=over

=item * B<a C<BINARY(n)>, C<VARBINARY(n)> or C<IMAGE> value that is not the
column itself> -- a function (C<< get_column('sized')->max >>, C<HASHBYTES>),
an expression, literal SQL, a column without a declared C<data_type>: it
comes back as its hex digits, as before. An C<IMAGE> value of more than half
of C<TEXTSIZE> bytes read that way loses its row, without an error. That is
not refused: the same result with a shorter value reads right, and a
refusal would hit it (measured by F<t/77-long-values-live.t>:
16384 bytes read at a C<TEXTSIZE> of 32768, 16385 bytes: no row);

=item * a statement run on the handle directly (C<< $storage->dbh_do >>):
hex digits, and no rows for C<VARBINARY(MAX)>, as before. Nothing is refused
there (F<maint/upstream/dbd-sybase-row-fail.md>);

=item * a private subclass of L<DBIO::MSSQL::Storage> pinned by hand on a
L<DBD::Sybase> handle is refused (L<DBIO::MSSQL::Storage/_adapt_to_access_path>).
Derive from this class.

=back

L<DBIO::MSSQL::Storage::Sybase::NoBindVars> reads as this class does.
L<DBD::ODBC> reads a binary value as its bytes, up to C<LongReadLen>, and
throws beyond.

=head1 VALUES LONGER THAN TEXTSIZE

Measured 2026-10-17 with L<DBD::Sybase> 1.27 and FreeTDS 1.3.17 against SQL
Server 2022 (F<t/77-long-values-live.t>).

L<DBIO::Sybase::Storage::FreeTDS> sets C<SET TEXTSIZE> at connect from
C<LongReadLen> of the connect info -- 32768 bytes unless that says otherwise.
The server then cuts a longer value of a C<TEXT>, C<NTEXT>, C<IMAGE>,
C<VARCHAR(MAX)>, C<NVARCHAR(MAX)> or C<VARBINARY(MAX)> column on its way back,
B<without an error>, exactly at C<TEXTSIZE> bytes: 32768 characters of a
C<VARCHAR(MAX)>, 16384 of an C<NVARCHAR(MAX)>. A value of exactly C<TEXTSIZE>
bytes is whole. The sized C<VARCHAR(n)>, C<NVARCHAR(n)> and C<VARBINARY(n)>
and the C<XML> type are not subject to it (8000 bytes whole under a
C<TEXTSIZE> of 100; 50007 characters of C<XML> under 32768).

The client cannot tell a value that was cut from one that is that long, the
server can. So a column of a result source that is a C<(N)VARCHAR(MAX)>, an
C<NTEXT> or a binary type (L</READING BINARY VALUES>) B<on the server> is
asked for behind a check the server runs. What the column is on the server is
what L<DBIO::MSSQL::DDL> deploys the declared type as
(L<DBIO::MSSQL::Adapter> is the one table, C<_server_data_type>):
the declared C<text> is an C<NVARCHAR(MAX)> -- not a C<TEXT> -- and so are a
C<varchar> or C<string> of size C<-1>; C<varchar(max)>, the server's own
spelling, is a C<VARCHAR(MAX)>. A C<text> column is therefore read as the
C<NVARCHAR(MAX)> it is, CJK and emoji included (it was read through
C<CAST(.. AS VARCHAR(MAX))>, which turned them into C<?>), and the check
counts its bytes as the server holds them, two per character. The check:

  CASE WHEN DATALENGTH([me].[body]) > @@TEXTSIZE
       THEN <failing conversion carrying a message> ELSE [me].[body] END

and a value that does not fit B<fails the statement> instead of arriving cut:
exactly -- one of C<TEXTSIZE> bytes is read, one byte more is refused.
The exception names the column and the size and says to connect with a
C<LongReadLen> of at least the longest value. It is the same for C<find>,
C<single>, C<first>, C<all>, a cursor, C<get_column>, the hashref inflator,
C<rows>, a prefetch -- the check is in the statement, there is no fetch site
that could miss it -- and when the long value is not the first row, the whole
read fails.

=over

=item * B<The type of the column is kept.> An C<NTEXT> is read as an
C<NVARCHAR(MAX)> (a C<CASE> cannot return an C<NTEXT>); a C<VARCHAR(MAX)> and
an C<NVARCHAR(MAX)> are read as the type they are, the failing branch of the
C<CASE> being of that type -- a C<CASE> between the two would return an
C<NVARCHAR(MAX)> and halve the characters that fit, silently (measured). The
column itself is the C<ELSE> branch, so a C<NULL> stays C<NULL>: the check
was a concatenation (C<col + CASE .. ELSE '' END>) before, which turns a
C<NULL> into C<''> in a session with C<CONCAT_NULL_YIELDS_NULL OFF> (it is
ON on a fresh session over C<dbi:Sybase:>, measured).

=item * B<The bytes are the server's.> C<TEXTSIZE> counts an C<NVARCHAR(MAX)>
in the two bytes per character the server holds it in: 16384 characters fit
under the default, and 20000 are refused, not cut. They are read with a
C<LongReadLen> of 40000 or more. The only form that would carry more
characters under 32768 bytes is a C<VARCHAR(MAX)> in a UTF-8 collation (SQL
Server 2019 and later), which is not used.

=item * B<Only an entry that is the column itself,> as for binary columns: a
function, an expression and literal SQL are not behind it, a subquery
(C<as_query>, C<count>) keeps the column as it is, and the handle
(C<< $storage->dbh_do >>) is not reached. Those cut a value over C<TEXTSIZE> to
it without an error, as before (pinned by the live test).

=item * B<The declared type counts,> as for binary columns; a column whose
C<data_type> does not say it is a LOB is not looked at, whatever the table
holds. A real C<TEXT> column cannot be declared (the portable C<text> is an
C<NVARCHAR(MAX)>): declared C<text> over a legacy C<TEXT> column it is read
through the check as if it were an C<NVARCHAR(MAX)>.

=item * B<LongReadLen is the regulator,> as it was: the default stays 32768.
Raising it costs memory only where the client library fills a buffer for an
EMPTY value (below), so the right value is the length of the longest value
read, not the largest number.

=back

B<The memory price of an empty value.> For an empty C<TEXT>, C<NTEXT> or
C<IMAGE> value the client library fills the whole buffer: C<TEXTSIZE> bytes
for an C<IMAGE>, twice that for an C<NTEXT>, four times for a C<TEXT>
(measured with plain L<DBI> and a C<TEXTSIZE> of 50000000: 48, 95 and 191 MB;
with an unlimited C<TEXTSIZE> the OOM killer ended the read of a row with an
empty C<TEXT>). A value of one byte and C<NULL> cost nothing, and neither does
a C<VARCHAR(MAX)>, an C<NVARCHAR(MAX)> or an C<XML> value, empty or not.
Behind the guard an C<NTEXT> is read as C<NVARCHAR(MAX)>, B<so it no longer
pays it>; a legacy C<TEXT> column, which cannot be declared as such, is not
cast and pays (measured: 193 MB at a C<LongReadLen> of 50000000). A binary
column is an C<IMAGE> and B<does>: about C<LongReadLen> bytes of memory per
binary column of a result while its statement handle lives, if one value of
the column is empty. No way around it was found: C<NULLIF> would turn an empty
value into C<NULL>, and the hex digits of a C<VARBINARY(MAX)> need decoding at
every fetch site. With the default that is 32 kB per column; a C<LongReadLen>
of 50000000 costs 48 MB for each.

L<DBD::ODBC> has neither the cut nor the price (L<DBIO::MSSQL::Storage::ODBC/LONG VALUES>).

B<Recommendation for a default, not taken:> 32768 is small for a document
store and cheap for everything else. A higher default would cost the binary
columns above; an unlimited one would make the read of a row with an empty
binary value ask for 2 GB per column. Whoever reads values over 32 kB sets
C<LongReadLen> to what they are, and the guard says so when the setting is
too small.

=head1 SQL_VARIANT AND OTHER TYPES

Measured 2026-10-17 on the handle (F<t/77-long-values-live.t>).

B<SQL_VARIANT> is described by the client library as a C<CHAR> of 8009 (no
C<CHAR>, C<VARCHAR>, C<NCHAR> or C<NVARCHAR> has that precision: it gives
four times the length). What the column holds decides what happens: a value
with a text, number or date base type reads; a value with a binary base type
loses its row without an error when it is the first of the result, or comes
back as the hex digits of the value, as text, when rows were fetched before it
(two binary variants alone: both lost). What the column holds is not known
before the rows are, so B<a C<SQL_VARIANT> result column is refused> after the
execute, before a fetch, with an exception that says what to select instead:
C<< CONVERT(VARCHAR(8000), E<lt>expressionE<gt>) >> for text, numbers and dates,
C<< CONVERT(VARCHAR(MAX), CONVERT(VARBINARY(8000), E<lt>expressionE<gt>), 2) >> for the hex
digits of a binary value, C<< SQL_VARIANT_PROPERTY(E<lt>expressionE<gt>, 'BaseType') >> for
which one a value is. The refusal also hits a column that holds no binary
variant at all: that is the price of not losing a row. L<DBD::ODBC> reads the
column.

B<Fetched with their rows, nothing to do:> C<DECIMAL(38,10)> and
C<DECIMAL(38,0)> (exact at 38 digits), C<NUMERIC>, C<MONEY>, C<DATETIME2(7)>,
C<DATETIMEOFFSET>, C<TIME(7)>, C<DATE>, C<UNIQUEIDENTIFIER>, C<BIT>,
C<ROWVERSION>, C<XML> (also 50007 characters, past C<TEXTSIZE>),
C<VARCHAR(8000)>, C<NVARCHAR(4000)>.

B<Refused by the client library, loud:> the CLR types C<HIERARCHYID>,
C<GEOGRAPHY> and C<GEOMETRY> -- "ct_describe() failed"; the storage takes the
execute that returned false for the error it is. A CLR type of an assembly
of your own was not measured (no CLR on the test server).

B<Not refused, limits:> an C<IMAGE> read as hex digits (literal SQL, a
function, a column without a declared C<data_type>) loses its row above
C<TEXTSIZE / 2> bytes, and a C<VARBINARY(MAX)> read on the handle directly
loses it from one byte on, both without an error; a refusal would hit results
that read right (the same statement with a shorter value). Pinned by the live
test; upstream draft: F<maint/upstream/dbd-sybase-row-fail.md>.

=head1 SUPPORT MATRIX

L<DBD::ODBC> is the supported access path (L<DBIO::MSSQL::Storage::ODBC>).
L<DBD::Sybase> over FreeTDS works within the limits below: where the DBD
corrupts data silently and the storage cannot repair it, the storage
B<refuses loudly> and names L<DBD::ODBC> as the way out. Each row is pinned
by a test (the cards are named in the row); a card that changes a row changes it here, in
L<DBIO::MSSQL::Storage::ODBC/SUPPORT MATRIX> and in F<CLAUDE.md>.

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

=item * L<DBIO::Sybase::Storage> - Sybase storage base class

=item * L<DBIO::Sybase::Storage::FreeTDS> - FreeTDS connection layer

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
