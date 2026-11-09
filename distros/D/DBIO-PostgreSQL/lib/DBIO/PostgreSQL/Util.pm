package DBIO::PostgreSQL::Util;
# ABSTRACT: Shared PostgreSQL-specific helper functions for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

use Carp 'croak';
use Exporter 'import';

our @EXPORT_OK = qw(
  quote_ident quote_qualified quote_literal quote_role quote_channel
  create_schema_if_missing trim_end
  mask_detail_values mask_error_details
  type_takes_modifier type_with_modifier
  number_placeholders
  quote_dsn_value dsn_names_target
  deferrable_clause
  connection_search_path declared_search_path quote_search_path_entry
);

# the libpq parameters that name where to connect
my %TARGET_KEY = map { $_ => 1 } qw(dbname host port hostaddr service);



# Every key word PostgreSQL does not class as "unreserved": the reserved ones,
# the ones that cannot be a function or type name (col_name) and the ones that
# can be a function or type name but nothing else (type_func_name) --
# pg_get_keywords() with catcode <> 'U'. quote_ident() on the server quotes
# exactly these, so a name that is one of them is never written bare.
#
# The list is PostgreSQL 18's, read from a 18.6 server. A word that is on it
# but is no such key word on an older server is quoted there without need and
# names the same object. t/91-ddl-quoting-live.t reads pg_get_keywords() from
# the server it runs against and fails for every word missing here.
my %KEYWORD = map { $_ => 1 } qw(
  all analyse analyze and any array as asc asymmetric authorization between
  bigint binary bit boolean both case cast char character check coalesce
  collate collation column concurrently constraint create cross
  current_catalog current_date current_role current_schema current_time
  current_timestamp current_user dec decimal default deferrable desc
  distinct do else end except exists extract false fetch float for foreign
  freeze from full grant greatest group grouping having ilike in initially
  inner inout int integer intersect interval into is isnull join json
  json_array json_arrayagg json_exists json_object json_objectagg
  json_query json_scalar json_serialize json_table json_value lateral
  leading least left like limit localtime localtimestamp merge_action
  national natural nchar none normalize not notnull null nullif numeric
  offset on only or order out outer overlaps overlay placing position
  precision primary real references returning right row select session_user
  setof similar smallint some substring symmetric system_user table
  tablesample then time timestamp to trailing treat trim true union unique
  user using values varchar variadic verbose when where window with
  xmlattributes xmlconcat xmlelement xmlexists xmlforest xmlnamespaces
  xmlparse xmlpi xmlroot xmlserialize xmltable
);


sub quote_ident {
  my ($name) = @_;
  croak 'an identifier must be a non-empty string'
    unless defined $name && !ref $name && length $name;
  croak 'an identifier cannot contain a NUL byte'
    if index($name, "\0") >= 0;

  return $name if $name =~ /\A[a-z_][a-z0-9_]*\z/ && !$KEYWORD{$name};

  (my $quoted = $name) =~ s/"/""/g;
  return qq{"$quoted"};
}


sub quote_qualified {
  my (@parts) = @_;
  croak 'a qualified name needs at least one part' unless @parts;
  return join '.', map { quote_ident($_) } @parts;
}


sub quote_literal {
  my ($value) = @_;
  croak 'a literal must be a defined, plain value'
    unless defined $value && !ref $value;
  croak 'a literal cannot contain a NUL byte'
    if index($value, "\0") >= 0;

  (my $quoted = $value) =~ s/'/''/g;
  return qq{'$quoted'};
}


sub trim_end {
  my ($text, $also) = @_;
  $also //= '';
  my $end = length $text;
  while ($end > 0) {
    my $char = substr($text, $end - 1, 1);
    last unless $char =~ /\s/ || ($also ne '' && index($also, $char) >= 0);
    $end--;
  }
  return substr($text, 0, $end);
}


sub create_schema_if_missing {
  my ($name) = @_;
  my $body = sprintf
    "BEGIN\n  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_namespace WHERE nspname = %s) THEN\n    CREATE SCHEMA %s;\n  END IF;\nEND",
    quote_literal($name), quote_ident($name);
  my ($tag, $n) = ('dbio', 0);
  $tag = 'dbio' . ++$n while index($body, "\$$tag\$") >= 0;
  return "DO \$$tag\$\n$body\n\$$tag\$";
}

# What stands in for a value in an error text.
my $MASK = '***';

# The start of a field of the server's message, at the start of a line. A field
# runs to the next one or to the end of the text.
my $FIELD_START = qr/^(?:DETAIL:  |HINT:  |CONTEXT:  |QUERY:  |LINE \d+: |STATEMENT:|LOCATION:)/m;

# Where the quoted value of a primary text ends: at the end of the text, which
# DBI may follow with the place of its caller.
my $VALUE_END = qr/(?=(?: at \S+ line \d+\.?)?\s*\z)/;

# The sentences of the primary text that end in the quoted value; what stands
# in front of the quote is kept.
my @SENTENCE_ENDING_IN_VALUE = (
  qr/\binvalid input syntax for (?:type )?[^:\n]+: /,
  qr/\binvalid input value for enum [^\n]*?: /,
  qr/\bout of range: /,
  qr/\bmalformed (?:array|record|range|multirange) literal: /,
  qr/\bin ts(?:vector|query): /,
  qr/\binvalid (?:hexadecimal|binary) digit: /,
  qr/\bunrecognized encoding: /,
  qr/\binvalid (?:destination |source )?encoding name /,
  qr/\bunrecognized time zone name: /,
  qr/\binvalid value for parameter "[^"\n]*": /,
  qr/\binvalid regular expression option: /,
  qr/\binvalid configuration parameter name /,
);

my $IDENT = qr/[A-Za-z_\x{80}-\x{10FFFF}][\w\$\x{80}-\x{10FFFF}]*/;

# "(cols)": a list of plain identifiers, or an expression of names, dots,
# colons, commas and balanced parentheses. Anything else (a quoted name, an
# "=") could hold a part of the value and is not read.
sub _readable_columns {
  my ($cols) = @_;
  return 1 if $cols =~ /\A$IDENT(?:, $IDENT)*\z/;
  return 0 unless $cols =~ /\A[\w\$\x{80}-\x{10FFFF} ,:.()]+\z/ && $cols =~ /\(/;
  my $depth = 0;
  for my $c (split //, $cols) {
    $depth++ if $c eq '(';
    $depth-- if $c eq ')';
    return 0 if $depth < 0;
  }
  return $depth == 0;
}

# "(cols)=(value)": the columns where they can be read, the value never.
sub _mask_key_text {
  my ($key) = @_;
  return $MASK unless $key =~ /\A\(([^=]*?)\)=\(/;
  my $cols = $1;
  return _readable_columns($cols) ? "($cols)=($MASK)" : $MASK;
}

# The sentences of the primary text that hold a value.
sub _mask_primary {
  my ($text) = @_;

  $text =~ s/($_)"(.*)"$VALUE_END/$1"$MASK"/s for @SENTENCE_ENDING_IN_VALUE;

  $text =~ s/(\bvalue )"(.*)"( is out of range for type )/$1"$MASK"$3/s;
  $text =~ s/(\binvalid value )"(.*)"( for ")/$1"$MASK"$3/s;
  $text =~ s/(?<!\w)"(.*)"( is not a valid (?:binary|hexadecimal) digit)/"$MASK"$2/s;
  $text =~ s/(\btime zone )"(.*)"( not recognized)/$1"$MASK"$3/s;
  $text =~ s/(\bsyntax error at or near )"(.*)"( of jsonpath input)/$1"$MASK"$3/s;

  # invalid byte sequence for encoding "UTF8": 0xc3 0x28
  # character with byte sequence 0xe2 0x82 in encoding "UTF8" has no equivalent ...
  $text =~ s/(\bbyte sequence for encoding "[^"\n]*": )0x[0-9A-Fa-f]{2}(?: 0x[0-9A-Fa-f]{2})*/$1$MASK/g;
  $text =~ s/(\bbyte sequence )0x[0-9A-Fa-f]{2}(?: 0x[0-9A-Fa-f]{2})*/$1$MASK/g;

  return $text;
}

# The lines of the context that hold a value.
sub _mask_context {
  my ($text) = @_;

  # JSON data, line 1: {"a":x...
  $text =~ s/(\bJSON data, line \d+: )[^\n]*/$1$MASK/g;

  # COPY t, line 1, column c: "value"
  $text =~ s/(\bCOPY [^\n,]+, line \d+(?:, column [^:\n]+)?: )"(.*)"/$1"$MASK"/s;

  # unnamed portal with parameters: $1 = 'a''b', $2 = NULL
  $text =~ s/(\$\d+ = )'(?:[^']|'')*'/$1'$MASK'/g;

  return $text;
}


sub mask_detail_values {
  my ($text) = @_;
  return $text unless defined $text;

  my $tail = qr/ (?:already exists|is duplicated|is not present in table|is still referenced from table|conflicts with existing key)/;
  unless ($text =~ s/\bKey (\(.*\)=\(.*\))(?=$tail)/'Key ' . _mask_key_text($1)/se) {
    $text =~ s/\bKey (\(.*\)=\(.*\))(?=[^)]*\z)/'Key ' . _mask_key_text($1)/se;
  }
  $text =~ s/(\bconflicts with existing key )(\(.*\)=\(.*\))(?=[^)]*\z)/$1 . _mask_key_text($2)/se;

  $text =~ s/(\bFailing row contains \().*\)/$1$MASK)/s;
  $text =~ s/(\bPartition key of the failing row contains \([^=]*?\) = \().*\)/$1$MASK)/s;

  $text =~ s/(\bToken )"(.*)"( is invalid\.)/$1"$MASK"$3/s;
  $text =~ s/(, but found )"(.*)"(\.?)/$1"$MASK"$3/s;
  $text =~ s/(\bEscape sequence )"(.*)"( is invalid\.)/$1"$MASK"$3/s;
  $text =~ s/(\bUnexpected )"(.*)"( character\.)/$1"$MASK"$3/s;
  $text =~ s/(\bCharacter with value )0x[0-9A-Fa-f]+/$1$MASK/g;

  $text =~ s/((?:\A|\bDETAIL:  )line \d+: ).*?(\n?)\z/$1$MASK$2/s;

  return $text;
}


sub mask_error_details {
  my ($message) = @_;
  return $message unless defined $message && length $message;

  my $tail = '';
  ($message, $tail) = ($1, $2) if $message =~ /\A(.*)(\s\[for Statement\b.*)\z/s;

  my @fields = split /(?=$FIELD_START)/, $message;
  for my $field (@fields) {
    if    ($field =~ /\ADETAIL:  /)  { $field = mask_detail_values($field) }
    elsif ($field =~ /\ACONTEXT:  /) { $field = _mask_context($field) }
    elsif ($field =~ $FIELD_START)   { }
    else                             { $field = _mask_primary($field) }
  }
  return join('', @fields) . $tail;
}


my %ROLE_KEYWORD = map { $_ => 1 } qw(
  public current_user current_role session_user
);

sub quote_role {
  my ($role) = @_;
  return $role
    if defined $role && !ref $role && $ROLE_KEYWORD{lc $role};
  return quote_ident($role);
}


sub deferrable_clause {
  my ($deferrable, $initially_deferred) = @_;
  croak "initially_deferred needs deferrable: PostgreSQL has no constraint that is INITIALLY DEFERRED and NOT DEFERRABLE"
    if $initially_deferred && !$deferrable;
  return '' unless $deferrable;
  return $initially_deferred ? ' DEFERRABLE INITIALLY DEFERRED' : ' DEFERRABLE INITIALLY IMMEDIATE';
}


# Every type that takes a type modifier, under every name it can be declared
# by. The built-in ones are the ten of pg_catalog.pg_type with a typmodin --
# bpchar, varchar, bit, varbit, numeric, time, timetz, timestamp, timestamptz,
# interval -- each under its catalog name, the name format_type() gives it and
# the further spellings the grammar has for it. Of the interval forms with
# fields, the ones that end in the seconds take the precision. vector, halfvec
# and sparsevec are pgvector's.
#
# Read from a PostgreSQL 18.6 server. t/98-ddl-type-modifier-live.t reads
# pg_type from the server it runs against, fails for every built-in type with
# a typmodin that is missing here, and has the server take every name below
# with a modifier.
my %TAKES_MODIFIER = map { $_ => 1 } (
  'character', 'char', 'bpchar', 'nchar', 'national character', 'national char',
  'character varying', 'char varying', 'varchar', 'nchar varying',
  'national character varying', 'national char varying',
  'bit', 'bit varying', 'varbit',
  'numeric', 'decimal', 'dec',
  'time', 'time without time zone', 'timetz', 'time with time zone',
  'timestamp', 'timestamp without time zone', 'timestamptz', 'timestamp with time zone',
  'interval', 'interval second', 'interval day to second',
  'interval hour to second', 'interval minute to second',
  'vector', 'halfvec', 'sparsevec',
);


sub type_takes_modifier {
  my ($type) = @_;
  return 0 unless defined $type && !ref $type;
  (my $name = lc $type) =~ s/\s+/ /g;
  $name =~ s/\A | \z//g;
  return $TAKES_MODIFIER{$name} ? 1 : 0;
}


sub type_with_modifier {
  my ($type, $size, $context) = @_;
  my $where = defined $context && length $context ? " for column $context" : '';
  croak 'a size must be a scalar or an arrayref, got a ' . ref($size) . ' reference' . $where
    if ref $size && ref $size ne 'ARRAY';

  my @parts = grep { defined && length } ref $size ? @$size : $size;
  return $type unless @parts;

  my $text = join ',', @parts;
  croak 'a size must be digits, or two numbers of digits joined by a comma' . $where
    unless $text =~ /\A\d+(?:,\d+)?\z/;

  my $modifier = "($text)";
  return $1 . $modifier . $2
    if $type =~ /\A(\s*\w+)(\s+with(?:out)?\s+time\s+zone\s*)\z/i;
  return $type . $modifier;
}


sub quote_channel {
  my ($channel) = @_;
  croak 'a LISTEN channel name must be a non-empty string'
    unless defined $channel && !ref $channel && length $channel;
  croak 'a LISTEN channel name cannot contain a NUL byte'
    if index($channel, "\0") >= 0;

  my $bytes = $channel;
  utf8::encode($bytes);
  croak sprintf(
    "LISTEN channel name '%s' is %d bytes long; PostgreSQL channel names are "
  . 'identifiers of at most 63 bytes (NAMEDATALEN - 1) -- LISTEN would '
  . 'truncate it and pg_notify refuses it',
    $channel, length $bytes,
  ) if length $bytes > 63;

  (my $quoted = $channel) =~ s/"/""/g;
  return qq{"$quoted"};
}


# What number_placeholders() takes from PostgreSQL's scanner:
#   * a stretch of SQL with no '?' in it and nothing left open: characters that
#     start none of the constructs number_placeholders() looks at, closed '...'
#     and "..." runs (a doubled quote reads as two runs back to back, which is
#     the same text), and words. A word -- identifier or keyword -- is taken as
#     a whole, so a '$' inside it opens no dollar quote; only the word E before
#     a quote is left standing, for the escape string it opens;
#   * the delimiter of a dollar quote;
#   * the whitespace behind a closing quote that continues the literal: a
#     newline in it, '--' comments allowed.
# Each is anchored at the scan position itself and used as a whole pattern:
# that way perl takes the compiled pattern as it is on every match.
my $PG_WORD             = qr/[A-Za-z_\x80-\x{10FFFF}][A-Za-z_0-9\$\x80-\x{10FFFF}]*/;
my $PG_SQL_STRETCH      = qr/\G(?:[^A-Za-z_\x80-\x{10FFFF}'"\$?\/-]+|(?![eE]')$PG_WORD|'[^']*+'|"[^"]*+")++/;
my $PG_DOLLAR_DELIMITER = qr/\G(\$(?:[A-Za-z_\x80-\x{10FFFF}][A-Za-z_0-9\x80-\x{10FFFF}]*)?\$)/;
my $PG_STRING_CONTINUES = qr/\G(?:[ \t\f\x0B]|--[^\n\r]*)*[\n\r](?:[ \t\n\r\f\x0B]+|--[^\n\r]*[\n\r])*'/;


sub number_placeholders {
  my ($sql) = @_;
  croak 'a statement must be a defined, plain value'
    unless defined $sql && !ref $sql;

  my $len    = length $sql;
  my $out    = '';
  my $copied = 0;   # $sql up to this offset is in $out
  my $n      = 0;
  my $dollar = 0;   # a $N written in the statement (outside text)

  pos($sql) = 0;
  while (pos($sql) < $len) {
    if ($sql =~ /$PG_SQL_STRETCH/gc) {
      # nothing to number in it
    }
    elsif ($sql =~ /\G\?/gc) {
      my $at = pos($sql) - 1;
      # '\?' is a literal question mark: the backslash goes, no placeholder
      if ($at > 0 && substr($sql, $at - 1, 1) eq '\\') {
        $out .= substr($sql, $copied, $at - 1 - $copied) . '?';
        $copied = $at + 1;
        next;
      }
      $out .= substr($sql, $copied, $at - $copied) . '$' . ++$n;
      $copied = $at + 1;
    }
    elsif ($sql =~ /\G\$[0-9]+/gc) {
      $dollar++;
    }
    elsif ($sql =~ /\G[eE]'/gc) {
      # an escape string, and what continues it on the following lines
      do {
        $sql =~ /\G(?:[^\\']+|\\.|'')*+'/gcs or pos($sql) = $len;
      } while ($sql =~ /$PG_STRING_CONTINUES/gc);
    }
    elsif ($sql =~ /\G--[^\n\r]*/gc) {
      # a comment to the end of the line
    }
    elsif ($sql =~ m{\G/\*}gc) {
      my $depth = 1;
      while ($depth && $sql =~ m{\G.*?(/\*|\*/)}gcs) {
        $depth += $1 eq '/*' ? 1 : -1;
      }
      pos($sql) = $len if $depth;
    }
    elsif ($sql =~ /$PG_DOLLAR_DELIMITER/gc) {
      my $end = index($sql, $1, pos($sql));
      pos($sql) = $end < 0 ? $len : $end + length $1;
    }
    elsif ($sql =~ /\G['"]/gc) {
      pos($sql) = $len;            # a quote the stretch did not close: never closed
    }
    else {
      pos($sql) = pos($sql) + 1;   # a '-', '/' or '$' that opens nothing
    }
  }

  croak 'refusing to number placeholders: the statement mixes $N and ?; '
      . 'write one style, and \\? for a literal question mark'
    if $dollar && $n;

  return $out . substr($sql, $copied);
}



sub quote_dsn_value {
  my ($value) = @_;
  croak 'a connection parameter value must be a defined, plain value'
    unless defined $value && !ref $value;
  croak 'a connection parameter value cannot contain a NUL byte'
    if index($value, "\0") >= 0;

  return $value if length $value && $value !~ /[\s;'\\="]/;

  (my $quoted = $value) =~ s/(['\\=])/\\$1/g;
  return qq{'$quoted'};
}


sub dsn_names_target {
  my ($dsn) = @_;
  croak 'a DSN must be a defined, plain value'
    unless defined $dsn && !ref $dsn;

  $dsn =~ s/\Adbi:\w*(?:\([^)]*\))?://i;

  # libpq takes a URI for its whole connection string; what it names is its
  # own business, and this does not judge it.
  return 1 if $dsn =~ m{\A\s*postgres(?:ql)?://}i;

  while ($dsn =~ /\G[\s;]*([^\s;='\\]+)[\s;]*=[\s;]*((?:'(?:[^'\\]|\\.)*'|(?:\\.|[^\s;'\\])+)?)/gcs) {
    my ($key, $value) = (lc $1, $2);
    $key = 'dbname' if $key eq 'db' || $key eq 'database';
    next unless $TARGET_KEY{$key};
    return 1 if length $value && $value ne q{''};
  }

  return 0;
}



sub connection_search_path {
  my ($namespace, $extensions, $extension_schemas, $activation, $control) = @_;
  $extension_schemas //= {};
  $control //= {};

  my @schemas = map { $extension_schemas->{$_} // $control->{$_} // 'public' }
    @{ $extensions // [] };
  @schemas = ('public') unless @schemas;

  my %seen;
  return grep { !$seen{$_}++ } $namespace, @schemas, @{ $activation // [] };
}


sub declared_search_path {
  my ($declared, $extensions, $extension_schemas, $activation) = @_;
  $extension_schemas //= {};

  my @ext = grep { defined } map { $extension_schemas->{$_} } @{ $extensions // [] };

  my %seen;
  return grep { !$seen{$_}++ } @{ $declared // [] }, @ext, @{ $activation // [] };
}


sub quote_search_path_entry {
  my ($entry) = @_;
  croak sprintf(
    'pg_search_path entry %s is not a name. Entries are schema names; write each as a plain string',
    defined $entry && !ref $entry ? "'$entry'" : (defined $entry ? 'a reference' : 'undef'))
    unless defined $entry && !ref $entry && length $entry && index($entry, "\0") < 0;
  return '"$user"' if $entry eq '$user';
  croak sprintf(
    'pg_search_path entry %s is already quoted; write the name without quotes (%s)',
    $entry, substr($entry, 1, -1))
    if $entry =~ /\A"/;
  return quote_ident($entry);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Util - Shared PostgreSQL-specific helper functions for DBIO

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::PostgreSQL::Util qw(
    quote_ident quote_qualified quote_literal quote_role quote_channel
  );

  quote_ident('users');                  # users
  quote_ident('user');                   # "user"
  quote_ident('MixedCase');              # "MixedCase"
  quote_qualified('auth', 'Users');      # auth."Users"
  quote_literal("it's");                 # 'it''s'
  quote_role('PUBLIC');                  # PUBLIC

  my $sql = 'LISTEN ' . quote_channel($channel);   # LISTEN "jobs"

  use DBIO::PostgreSQL::Util qw(type_takes_modifier type_with_modifier);

  type_takes_modifier('bit varying');                 # true
  type_takes_modifier('integer');                     # false
  type_with_modifier('numeric', [ 10, 2 ]);           # numeric(10,2)
  type_with_modifier('timestamp with time zone', 3);  # timestamp(3) with time zone

  use DBIO::PostgreSQL::Util qw(number_placeholders);

  number_placeholders(q{SELECT * FROM t WHERE a = ? AND b = ?});
  # SELECT * FROM t WHERE a = $1 AND b = $2
  number_placeholders(q{SELECT $$ what? $$, 'why?', ? -- really?});
  # SELECT $$ what? $$, 'why?', $1 -- really?

  use DBIO::PostgreSQL::Util qw(quote_dsn_value);

  my $dsn = 'dbi:Pg:dbname=' . quote_dsn_value($dbname);
  quote_dsn_value('appdb');                # appdb
  quote_dsn_value('my db');                # 'my db'
  quote_dsn_value('app sslmode=disable');  # 'app sslmode\=disable'

  use DBIO::PostgreSQL::Util qw(connection_search_path);

  connection_search_path('tenant_a', [ 'vector' ], { vector => 'extensions' });
  # ('tenant_a', 'extensions')

=head1 DESCRIPTION

Small helpers that capture PostgreSQL-specific truths shared across the
driver and the transports built on it, so the same rule is not re-encoded in
each of them. Nothing is exported by default.

This module depends on L<Carp> and L<Exporter> only. A transport outside this
distribution -- the native C<ev> backend in C<dbio-postgresql-ev> -- can load
it without pulling in the C<future_io> transport
(L<DBIO::PostgreSQL::Storage::Async>), C<dbio-async> or L<Future::IO>.

=head1 METHODS

=head2 quote_ident

  my $sql_ident = quote_ident($name);

Write a name as B<one> PostgreSQL identifier, by the rule of the server's own
C<quote_ident()>: bare when the name is all lower-case ASCII letters, digits
and underscores, does not start with a digit and is no key word other than an
"unreserved" one; otherwise in double quotes with an embedded C<"> doubled.

  quote_ident('users')        # users
  quote_ident('user')         # "user"        reserved
  quote_ident('position')     # "position"    key word, not unreserved
  quote_ident('name')         # name          key word, unreserved
  quote_ident('MixedCase')    # "MixedCase"   bare it would fold to mixedcase
  quote_ident('uuid-ossp')    # "uuid-ossp"
  quote_ident('a.b')          # "a.b"         one identifier, not two

The name is taken exactly: its case is kept, and a C<.> is part of it. For a
name of several parts use L</quote_qualified>.

Throws for an undefined or empty name, a reference, and a name containing a
NUL byte -- none of them can name anything, and writing them would produce a
statement that fails for a reason nobody can read off it.

=head2 quote_qualified

  my $sql_name = quote_qualified($schema_name, $table_name);
  my $sql_name = quote_qualified($table_name);

Write a qualified name: every part quoted by L</quote_ident> for itself, the
parts joined with C<.>.

  quote_qualified('auth', 'users')          # auth.users
  quote_qualified('Auth', 'user')           # "Auth"."user"
  quote_qualified('my.schema', 'tbl')       # "my.schema".tbl

The caller says where the parts end. A name is never taken apart at its dots
here, because a schema or a table may have one in its name.

Throws without a part, and for every part L</quote_ident> refuses.

=head2 quote_literal

  my $sql_literal = quote_literal($value);

Write a value as a SQL string literal: in single quotes, an embedded C<'>
doubled.

  quote_literal('draft')      # 'draft'
  quote_literal("it's")       # 'it''s'
  quote_literal('')           # ''

This is the standard form, the one the server writes itself when it shows a
constant (C<pg_get_expr>). A backslash is an ordinary character in it, which
is how PostgreSQL reads a literal with C<standard_conforming_strings> on --
the default since 9.1.

Throws for an undefined value, a reference and a value containing a NUL byte.

=head2 trim_end

  my $text = trim_end($text);          # trailing whitespace off
  my $text = trim_end($text, ';');     # trailing whitespace and semicolons off

Cut the whitespace at the end of a string, and with a second argument also
each of the characters it names, in any order and number. The string is read
once from its end, so the time is linear in the length of what is cut, however
long a run of whitespace stands inside the text. Used for the texts the
catalog hands over (view and function definitions).

=head2 create_schema_if_missing

  my $sql = create_schema_if_missing($name);   # a DO block, no closing semicolon

Write the creation of a schema (namespace) for a role that may not have
C<CREATE> on the database. C<CREATE SCHEMA> checks that privilege before it
looks at C<IF NOT EXISTS>, so C<CREATE SCHEMA IF NOT EXISTS> fails for a role
that may use an existing namespace but has no C<CREATE> on the database. This
statement asks C<pg_catalog.pg_namespace> first and runs a plain C<CREATE
SCHEMA> only where the name is missing. It is a DO block, so it is one piece
wherever it stands: in the install script, which is written without a
connection, in the SQL of a diff and in the temporary database of a diff. The
name is a literal in the lookup (exactly as given) and an identifier in the
statement (L</quote_ident>). The block is dollar-quoted with a tag the name
does not contain.

=head2 mask_detail_values

  my $text = mask_detail_values('Key (email)=(a@b.c) already exists.');
  # Key (email)=(***) already exists.

The values of a server's detail text are replaced by C<***>. A message names
keys, columns and options, never values; the column names, the constraint and
the table stay, and so does the rest of the text. The text is the detail field
with or without its C<DETAIL:  > label, and may hold line breaks. The forms:

  Key (a, b)=(***) already exists.
  Key (id)=(***) is not present in table "users".
  Key (r)=(***) conflicts with existing key (r)=(***).
  Failing row contains (***).
  Partition key of the failing row contains (k) = (***).
  Token "***" is invalid.
  Expected string, but found "***".
  Escape sequence "***" is invalid.
  Unexpected "***" character.
  Character with value *** must be escaped.
  line 1: ***

The columns of a key stay where they are a list of plain identifiers or an
expression of names and balanced parentheses; a key text that could hold a
part of its value in what looks like a column (a quoted name, an C<=>) is
masked whole, C<Key *** already exists.>. A libxml detail (C<line N: ...>) is
masked after its line number, it repeats the input. A text without any of
these forms is returned as it is.

=head2 mask_error_details

  my $message = mask_error_details($message);

Mask the values in the text of a server's error. The message is cut into the
fields of the server (the primary text, C<DETAIL:  >, C<HINT:  >, C<CONTEXT:  >,
C<QUERY:  >, C<LINE n: >, C<STATEMENT:>, C<LOCATION:>; a field runs to the
next one) and each is read by its own rules. A prefix (C<DBD::Pg::st execute
failed: >) and the C<[for Statement ...]> DBI appends are no part of any rule.

The C<DETAIL:  > field is L</mask_detail_values>. The primary text keeps its
sentence and masks the quoted value:

  ERROR:  invalid input syntax for type integer: "***"
  ERROR:  invalid input value for enum mood: "***"
  ERROR:  date/time field value out of range: "***"
  ERROR:  value "***" is out of range for type smallint
  ERROR:  malformed array literal: "***"
  ERROR:  invalid hexadecimal digit: "***"
  ERROR:  invalid byte sequence for encoding "UTF8": ***
  ERROR:  time zone "***" not recognized
  ERROR:  invalid value for parameter "TimeZone": "***"

The C<CONTEXT:  > field loses the values the server quotes into it: the bound
parameters of the portal (C<$1 = '***'>, whose number and C<NULL> stay), the
excerpt of a JSON text and the data of a C<COPY> line. The C<LINE n: ...>
excerpt of the statement, its caret line, the hint, the query and the position
fields are the statement's text and stay as they are, as does a text of no
known form, and the names of a relation, a column, a function or a constraint.
Each rule gives the same text when it is applied to its own result.

=head2 quote_role

  my $sql_role = quote_role($role);

Write one entry of a role list, as it follows C<TO> in C<CREATE POLICY>. A
role name is an identifier and is quoted by L</quote_ident>. C<PUBLIC>,
C<CURRENT_USER>, C<CURRENT_ROLE> and C<SESSION_USER> are not names but key
words standing for a role; they are recognised in any case and written as
given, because quoted they would name a role that is called that
(C<TO "PUBLIC"> fails with I<role "PUBLIC" does not exist>).

  quote_role('app_user')      # app_user
  quote_role('AppUser')       # "AppUser"
  quote_role('PUBLIC')        # PUBLIC
  quote_role('current_user')  # current_user

=head2 deferrable_clause

  deferrable_clause(1, 1)   # " DEFERRABLE INITIALLY DEFERRED"
  deferrable_clause(1, 0)   # " DEFERRABLE INITIALLY IMMEDIATE"
  deferrable_clause(0, 0)   # ""

The timing clause of a FOREIGN KEY or UNIQUE constraint, from the model keys
C<deferrable> and C<initially_deferred>, with the space that leads it. A
constraint that is not deferrable has none (it is the server's default).
C<initially_deferred> without C<deferrable> is no constraint PostgreSQL has
(it refuses it), so it throws here too.

=head2 type_takes_modifier

  if (type_takes_modifier($type)) { ... }

True when C<$type> names a PostgreSQL type that takes a type modifier: the
built-in ones, under each of their names, and the pgvector types.

  character  char  bpchar  nchar  national character  national char
  character varying  char varying  varchar  nchar varying
  national character varying  national char varying
  bit  bit varying  varbit
  numeric  decimal  dec
  time  time without time zone  timetz  time with time zone
  timestamp  timestamp without time zone  timestamptz  timestamp with time zone
  interval  interval second  interval {day|hour|minute} to second
  vector  halfvec  sparsevec

The name is compared in lower case and with single spaces between its words.
A name that already carries a modifier (C<character(10)>), an array type
(C<varchar[]>) and a quoted name (C<"char">, which is another type) are not
on the list.

False for every other name. That covers two cases this function does not
tell apart: a built-in type without a modifier, for which the server refuses
one (C<integer(11)> is a syntax error, C<text(255)> gives I<type modifier is
not allowed for type "text">), and a type this distribution does not know --
an extension's, a domain -- which may take one or not.

=head2 type_with_modifier

  my $sql_type = type_with_modifier($type, $size);

Write C<$type> with C<$size> as its type modifier, where the server's grammar
takes it: behind the name, and for the C<... with time zone> and C<... without
time zone> forms behind their first word.

  type_with_modifier('character', 10)                # character(10)
  type_with_modifier('numeric', [ 10, 2 ])           # numeric(10,2)
  type_with_modifier('numeric', 10)                  # numeric(10)
  type_with_modifier('timestamp with time zone', 3)  # timestamp(3) with time zone
  type_with_modifier('time without time zone', 0)    # time(0) without time zone
  type_with_modifier('interval day to second', 3)    # interval day to second(3)
  type_with_modifier('character', undef)             # character

C<$size> is a column's C<size>: one value, or an arrayref of them in the
order the type takes them. Undefined, an empty string and an empty arrayref
are no size, and C<$type> is returned as it is. The name itself is written as
given.

This function writes; it does not ask whether C<$type> takes a modifier. A
caller that may find a size beside a type without one asks
L</type_takes_modifier> first.

Throws for a size that is any other reference: written out it would be
C<HASH(0x...)>. Throws for a size that is not
C<N> or C<N,M> in digits (a list of one or two numbers is written the same
way): a size is a number, never SQL, and the message does not repeat it.

The optional third argument C<$context> names the column the size belongs to,
as the caller writes it (C<users.name>). A refusal then ends in C<for column
users.name>, so the message points at the column and still not at the value.
Without a context the message is the same without that ending.

  type_with_modifier('character', 'x', 'users.name')
  # dies: a size must be digits, ... comma for column users.name

=head2 quote_channel

  my $sql_ident = quote_channel($channel);   # "jobs"

Validate a LISTEN / NOTIFY channel name and quote it as B<one> PostgreSQL
identifier: wrapped in double quotes, embedded C<"> doubled. Returns the
quoted identifier, ready to follow C<LISTEN> or C<UNLISTEN>; the argument is
not modified.

Quoting makes the name exact -- case included -- which is also how
C<pg_notify> takes it, so C<LISTEN> on C<Jobs> and C<pg_notify('Jobs', ...)>
meet. A C<.> stays part of the name: C<app.events> becomes C<"app.events">,
not the schema-qualified C<"app"."events">.

Refused, by throwing: an undefined, empty or reference channel, one
containing a NUL byte, and one longer than 63 bytes in UTF-8 (PostgreSQL's
C<NAMEDATALEN> - 1). The limit counts bytes, not characters: 32 characters of
U+00E9 are 64 bytes and refused. It is a refusal, not a truncation, because a
longer name can never deliver: C<LISTEN> would silently truncate it and then
report notifications under the truncated name, which matches no registered
channel, and C<pg_notify> rejects it outright (I<"channel name too long">).

It is the channel rule of the C<future_io> transport, whose
L<DBIO::PostgreSQL::Storage::Async/_pg_quote_channel> delegates here, and the
native C<ev> transport applies the same rule.

=head2 number_placeholders

  my $positional = number_placeholders($sql);

Number every C<?> placeholder of one statement as PostgreSQL's positional
C<$N>, left to right, so that they line up with the bind values in the order
the SQL maker gives them. Returns the numbered statement; the argument is not
modified.

  number_placeholders(q{UPDATE t SET a = ? WHERE id = ?})
  # UPDATE t SET a = $1 WHERE id = $2

A C<?> is a placeholder where PostgreSQL reads SQL. Text it reads as something
else is passed over as a whole, delimited as its scanner delimits it:

=over 4

=item * a string C<'...'> and a quoted identifier C<"...">, a doubled quote
inside staying inside. The prefixes C<B>, C<X>, C<N> and C<U&> change nothing
about where the string ends.

=item * an escape string C<E'...'> / C<e'...'>, in which a backslash takes the
next character with it, so C<\'> does not end it. Its continuation on a
following line (C<E'a'>, newline, C<'b'>) is an escape string as well.

=item * a dollar-quoted body, C<$$...$$> or C<$tag$...$tag$>, closed by the
very same delimiter only. A tag starts with a letter or an underscore, so
C<$1> is a parameter and opens nothing; a C<$> inside an identifier (C<a$b$>)
opens nothing either.

=item * a C<--> comment up to the end of the line, and a C</* ... */> comment,
which nests.

=back

  number_placeholders(q{SELECT $body$ what? $body$, ?})   # SELECT $body$ what? $body$, $1
  number_placeholders(q{SELECT /* a /* b? */ c? */ ?})    # SELECT /* a /* b? */ c? */ $1
  number_placeholders(q{SELECT E'it\'s ?', ?})            # SELECT E'it\'s ?', $1

A string, body or comment that is never closed runs to the end of the
statement; the server reports it.

Outside of these a C<?> is a placeholder wherever it stands, behind an
operator character as well: no operator is known here. C<< tags <@?::int[] >> becomes
C<< tags <@$1::int[] >>, C<@@?> becomes C<@@$1> and C<@? ?> becomes C<@$1 $2>
-- as L<DBD::Pg> reads the same statement at the dbh.

A C<\?> outside a string, a body and a comment is a literal question mark and
no placeholder, as L<DBD::Pg> reads it (since 3.5.0): the way to write the
operators C<?>, C<?|>, C<?&> and C<@?>, and how the SQL maker writes the
jsonpath operator (L<DBIO::PostgreSQL::SQLMaker/_where_op_jsonb_path>). The
backslash is dropped, so the statement that comes back holds a bare C<?> --
what the server reads, and what DBD::Pg leaves standing under
C<pg_placeholder_dollaronly>:

  number_placeholders(q{SELECT a @\? ?::jsonpath})   # SELECT a @? $1::jsonpath
  number_placeholders(q{SELECT a \?| ARRAY[?, ?]})   # SELECT a ?| ARRAY[$1, $2]

Inside a string, a body or a comment the backslash is text and stays. Only the
one backslash directly before the C<?> goes. Because it goes, a statement with
a C<\?> is numbered once: the C<?> it left is a placeholder to a second pass,
which refuses the statement where a C<$N> stands beside it and numbers the
C<?> where none does.

A statement that has C<$N> beside a C<?> placeholder is refused, as DBD::Pg
refuses it (I<Cannot mix placeholder styles>): numbering both would give one
parameter two meanings and run the statement with one value twice. A C<$N> in
a string, a body or a comment is text and counts as none; so does a C<\?>.

C<standard_conforming_strings> is taken to be C<on>, the server's default: a
backslash in a plain C<'...'> string is text. DBD::Pg's C<:name> placeholders
are not read. The statement is not otherwise validated: what the server would
refuse reaches it and is refused there.

Throws for an undefined statement and a reference, as L</quote_literal> does
for a value: neither is a statement anybody wrote, and numbered they would
come back as an empty query and as the reference's address, which the server
reads as SQL.

This is the interface the C<future_io> transport and the C<ev> backend of
C<dbio-postgresql-ev> share (see L</PLACEHOLDERS>): it is public and stable.

=head2 quote_dsn_value

  my $dsn = "dbi:Pg:dbname=" . quote_dsn_value($dbname)
          . ";host="         . quote_dsn_value($host);

Write the value of one libpq connection parameter as it goes into a
L<DBD::Pg> DSN, so that libpq reads back exactly the value given. Bare when
nothing on the way touches it; otherwise in single quotes, with C<'>, C<\>
and C<=> escaped by a backslash.

  quote_dsn_value('appdb')                 # appdb
  quote_dsn_value('2001:db8::1')           # 2001:db8::1
  quote_dsn_value('my db')                 # 'my db'
  quote_dsn_value(q{it's})                 # 'it\'s'
  quote_dsn_value('back\slash')            # 'back\\slash'
  quote_dsn_value('"app"')                 # '"app"'
  quote_dsn_value('app sslmode=disable')   # 'app sslmode\=disable'
  quote_dsn_value('')                      # ''

Quoted is every value that is empty or contains whitespace, C<;>, C<'>, C<\>,
C<=> or C<">. Two readers make that list:

=over 4

=item * B<libpq> (C<conninfo_parse>) ends a bare value at whitespace and reads
a backslash as an escape, bare or quoted. Behind a C<=> it skips whitespace
before the value starts, so an empty value written bare would take the next
parameter for its value.

=item * B<DBD::Pg> edits the DSN as text before libpq sees it
(C<DBD::Pg::dr::connect>, C<dbd_db_login6>; measured on 3.20.2). A C<;>
outside single quotes separates parameters. The first C<db=> or C<database=>
anywhere becomes C<dbname=>, and the first C<dbname="..."> becomes
C<dbname='...'> -- both inside a quoted value as well. Both rewrites need a
C<=> to match, and the second a C<"> straight behind it: with every C<=> of a
value written as C<\=> neither finds one inside a value, and a quoted
C<dbname> starts with C<'> where the second looks for C<">. libpq reads C<\=>
as C<=>.

=back

So the double quotes of C<"app"> are part of the value -- the database
C<"app">, not C<app>. The L<DBD::Pg> way of quoting a name belongs into a DSN
somebody writes, not into a value. For the same reason a parameter cannot be
put in behind a value: C<app sslmode=disable> is a database of that name.

Only the value is written. The keyword in front of it, and the C<;> between
two parameters, are the caller's.

Throws for an undefined value, a reference and a value containing a NUL byte
-- no connection string can carry one: the DSN is a C string from L<DBD::Pg>
on and would end there, the parameters behind it lost. The message does not
repeat the value. A caller that knows which parameter it is writing checks
these first and names it.

=head2 dsn_names_target

  dsn_names_target('dbi:Pg:dbname=app');            # true
  dsn_names_target('dbi:Pg:service=prod');          # true
  dsn_names_target('dbi:Pg:sslmode=require');       # false
  dsn_names_target('dbi:Pg:');                      # false

Whether a whole C<dbi:Pg:> DSN names where to connect: at least one of
C<dbname> (C<db>, C<database>), C<host>, C<port>, C<hostaddr> or C<service>
with a value. A DSN without one leaves the target to libpq's environment
(C<PGHOST>, C<PGDATABASE>, a service file), so the credentials would go
wherever the process environment says; the storages refuse to connect with it
(L<DBIO::PostgreSQL::Storage/_refuse_dsn_without_target>,
L<DBIO::PostgreSQL::Storage::Async>), as they refuse connection parameters
that give none. The parameters of a DSN are read as
L</quote_dsn_value> describes the two readers: C<;> outside single quotes
separates them like whitespace, a value is bare or in single quotes with a
backslash as the escape, and an empty value is no value. The part
C<< dbi:Pg(attributes): >> in front is skipped, and a libpq URI
(C<postgresql://...>, C<postgres://...>) in place of the parameters counts as
a target -- it is libpq's to read. It is a function of the text
alone: nothing is connected, and it does not judge a value.

=head2 connection_search_path

  my @schemas = connection_search_path($namespace, \@extensions, \%extension_schemas, \@activation, \%control_schemas);

The schemas of the C<search_path> of a connection that works in
C<$namespace>, in order: the namespace, then the schema of each declared
extension -- C<@extensions> are the names in the order they were declared,
C<%extension_schemas> the schema of those that name one, as
L<DBIO::PostgreSQL/pg_extensions> and
L<DBIO::PostgreSQL/pg_extension_schemas> answer them. An extension that names
no schema stands for the one its control file fixes (C<%control_schemas>, the
optional fifth argument: extension name to schema, as
L<DBIO::PostgreSQL::DDL/control_schemas_sql> reads it from the server), else
for C<public> -- the rule of the C<CREATE EXTENSION> of the install, so the
path finds where the extension was put. Without a server, and
therefore without the fifth argument, it is C<public>. With no extension
declared, C<public> follows the namespace. Behind them stand the C<search_path> entries the extensions'
activation gives (C<@activation>: L<DBIO::PostgreSQL::Storage/_extension_activation>,
already in name order of the extensions), so the order is: the namespace, the
schemas of the declaration, the entries of the activation. Every schema stands
once, at its first place.

  connection_search_path('tenant_a', [], {})
  # tenant_a, public
  connection_search_path('tenant_a', [ 'vector' ], {})
  # tenant_a, public
  connection_search_path('tenant_a', [ 'vector' ], { vector => 'extensions' })
  # tenant_a, extensions
  connection_search_path('tenant_a', [ 'pgcrypto', 'vector' ], { vector => 'extensions' })
  # tenant_a, public, extensions
  connection_search_path('tenant_a', [ 'age' ], {}, [ 'ag_catalog', 'public' ])
  # tenant_a, public, ag_catalog
  connection_search_path('tenant_a', [ 'age' ], {}, [], { age => 'ag_catalog' })
  # tenant_a, ag_catalog

The answer is names, not SQL: each goes into a statement through
L</quote_ident>.

=head2 declared_search_path

  my @schemas = declared_search_path(\@declared, \@extensions, \%extension_schemas, \@activation);

The schemas of the C<search_path> of a connection that names no namespace and
whose schema class declared L<DBIO::PostgreSQL/pg_search_path>, in order: the
declared entries, then the schema of each declared extension that names one
(an extension without a schema adds nothing -- unlike
L</connection_search_path>, which stands C<public> for it: here the list is the
user's, and C<public> is written into it where it is wanted), then the entries
of the extensions' activation. Every schema stands once, at its first place.

  declared_search_path([ 'a', 'b' ], [ 'pgcrypto', 'vector' ], { vector => 'extensions' })
  # a, b, extensions

=head2 quote_search_path_entry

  my $sql = quote_search_path_entry($entry);

One entry of a C<search_path> as SQL: a name by L</quote_ident>, so
C<MySchema> becomes C<"MySchema">, and C<$user> -- no name, the schema of the
session's role -- as C<"$user">, the one way the server reads it. An entry
already in double quotes would be quoted twice into another schema, and one
that is empty, not a plain string or holds a NUL byte is no name: both are
refused, naming the entry.

=head1 NAMES AND VALUES IN GENERATED SQL

Everything in this distribution that writes a name or a value into a DDL
statement -- L<DBIO::PostgreSQL::DDL>, the L<DBIO::PostgreSQL::Diff> operation
classes, L<DBIO::PostgreSQL::Deploy> -- goes through L</quote_ident>,
L</quote_qualified>, L</quote_literal> and L</quote_role>, and through nothing
else. A name is whatever a declaration or the catalog says an object is
called; it becomes an identifier here, once, by the server's own rule.

What a declaration documents as a SQL fragment is not a name and is written as
given: an index C<where> or C<expression>, a policy's C<using> and
C<with_check>, a trigger's C<when>, C<event> and C<execute>, a
C<< default_value => \'...' >>, a type string (C<data_type>, C<pg_enum_type>,
C<pg_type_name>), C<pg_extra_ddl> and a function's SQL. So is what the server
hands back ready-made (C<pg_get_indexdef>, C<pg_get_triggerdef>,
C<pg_get_functiondef>, C<pg_get_expr>, C<format_type>).

=head1 TYPES WITH A MODIFIER

A column's C<size> is PostgreSQL's I<type modifier>: the length of a
C<character(10)>, the precision and scale of a C<numeric(10,2)>, the
fractional seconds of a C<timestamp(3) with time zone>. Which types take one,
and where it is written, are two facts about the server. They are kept here,
once -- L</type_takes_modifier> and L</type_with_modifier> -- and
L<DBIO::PostgreSQL::DDL>, L<DBIO::PostgreSQL::Adapter>,
L<DBIO::PostgreSQL::Diff::Column> and
L<DBIO::PostgreSQL::Diff/target_from_compiled> write a type with a size
through them and through nothing else.

=head1 PLACEHOLDERS

L<DBIO::PostgreSQL::SQLMaker> writes a bind as C<?>: the sync driver hands
its statements to L<DBD::Pg>, which takes that form. PostgreSQL itself takes
only C<$1>, C<$2>, ..., so a transport that sends a statement with its binds
beside it has to number them first -- and has to know which C<?> is one. A
C<?> is a placeholder where PostgreSQL reads SQL; inside a string, a
dollar-quoted body or a comment it is text. That is one fact about the
server's scanner (F<src/backend/parser/scan.l>). It is kept here, once, in
L</number_placeholders>: the C<future_io> transport numbers through it
(L<DBIO::PostgreSQL::Storage::Async/_transform_sql>), and the native C<ev>
transport in C<dbio-postgresql-ev> reads a statement by the same rule.

L</number_placeholders> is the interface the two transports share: public and
stable, called by its name and with one statement, by this distribution's
C<future_io> transport and by the C<ev> backend of C<dbio-postgresql-ev>
(maintainer's decision 2026-10-16). What it answers for a statement
changes only together with the server's reading or L<DBD::Pg>'s.

=head2 Where DBD::Pg reads less than the server

The sync driver does not number through L</number_placeholders>: L<DBD::Pg>
finds the placeholders of a statement with a scanner of its own, and that one
reads less than the server's. This cannot be mended here; it is a fact of
L<DBD::Pg> (measured against DBD::Pg 3.x and PostgreSQL 18).
Four forms are read differently, each with a C<?> or a C<$> the server takes
as text or as no delimiter:

=over 4

=item * a nested comment, C</* a /* b ? */ c ? */>: the server nests, so the
whole is one comment; L<DBD::Pg> ends it at the first C<*/> and counts the
C<?> behind it as a placeholder.

=item * a lower case escape string, C<e'it\'s ?'>: the server reads it as an
escape string and the C<\'> does not end it; L<DBD::Pg> takes it for a plain
string, ends it at the C<\'> and reads on from there. (The upper case
C<E'...'> is read as the server reads it.)

=item * a carriage return as the end of a C<--> comment: the server ends the
comment at a C<\r> as well as at a C<\n>; L<DBD::Pg> only at the C<\n>, so a
C<?> behind the C<\r> is lost to it.

=item * a C<$> inside an identifier, C<a$b$>: the server reads a word as a
whole and opens no dollar quote in it; L<DBD::Pg> opens one at C<$b$> and
passes over the placeholders up to the next C<$b$>.

=back

The count of placeholders then differs from the count of binds, or a C<?>
that is text is bound. The C<future_io> transport (and C<ev>) numbers by the
server's rule, so the same statement can run over the sync dbh and not over
the transport, or the other way round. What to do: do not write these four
forms into SQL that has placeholders -- close a nested comment into one level,
write C<E'...'> in upper case, end a C<-->comment with C<\n>, and keep a C<$>
out of identifiers (or quote them, C<"a$b$">) -- or send what the text has to
carry as a bind value instead of a literal. A C<?> that must stay a question
mark is C<\?>, which both read the same.

=head1 CONNECTION PARAMETERS IN A DSN

A connection may be given by its parameters instead of a DSN -- C<dbname>,
C<host>, C<port>, as L<DBIO::AccessBroker::Static> answers them. This
distribution then writes the C<dbi:Pg:> DSN itself, and a parameter's value
has to arrive at libpq as it was given: a database is called what it is
called, blanks and quotes included, and a value is never read as a second
parameter. How a value is written so that it does is one fact about the two
readers between the DSN and the value, L<DBD::Pg> and libpq. It is kept here,
once, in L</quote_dsn_value>: the sync storage writes through it
(L<DBIO::PostgreSQL::Storage/_connect_params_dsn>), and so does the
C<future_io> transport
(L<DBIO::PostgreSQL::Storage::Async/_async_broker_conninfo>) -- which is what
makes the two connections of one schema open the same database.

=head1 THE SEARCH PATH OF A CONNECTION

A connection opened with the connect key C<schema> works in one namespace
(L<DBIO::PostgreSQL/ONE SCHEMA CLASS IN SEVERAL NAMESPACES>). Which schemas
its C<search_path> holds is one rule. It is kept here, once, in
L</connection_search_path>: the storage sets the path of every connection by
it (L<DBIO::PostgreSQL::Storage/_set_connection_schema>), and the install
script of such a connection sets the same one
(L<DBIO::PostgreSQL::DDL/install_ddl>).

=head1 SEE ALSO

L<DBIO::PostgreSQL::DDL>, L<DBIO::PostgreSQL::Diff>,
L<DBIO::PostgreSQL::Storage/_set_connection_schema>,
L<DBIO::PostgreSQL::Storage/_connect_params_dsn>,
L<DBIO::PostgreSQL::Storage::Async/_async_broker_conninfo>,
L<DBIO::PostgreSQL::Storage::Async/_transform_sql>,
L<DBIO::PostgreSQL::Storage::Async/"LISTEN / NOTIFY">,
L<DBIO::Storage::Async/"LISTEN / NOTIFY">

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
