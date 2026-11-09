package DBIO::SQLite::Util;
# ABSTRACT: Shared SQLite-specific helper functions for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

use Exporter 'import';

use DBIO::Exception ();

our @EXPORT_OK = qw(
  column_is_nullable comparable_statement create_name_index
  foreign_key_action
  create_table_name_index default_literal_sql default_value_sql
  pk_is_rowid_alias quote_identifier refuse_qualified_name split_type_size
  sql_tokens
  token_identifier type_affinity type_with_size
);



my %FK_ACTION = map { $_ => 1 } ('NO ACTION', 'RESTRICT', 'CASCADE', 'SET NULL', 'SET DEFAULT');

sub foreign_key_action {
  my ($value, $context) = @_;
  return undef unless defined $value && length $value;

  my $action = $value;
  $action =~ s/\s+/ /g;
  $action =~ s/^ //;
  $action =~ s/ $//;
  return $action if $FK_ACTION{ uc $action };

  DBIO::Exception->throw(sprintf
    "Unknown foreign key action '%s' (%s): expected one of NO ACTION, RESTRICT, CASCADE, SET NULL, SET DEFAULT",
    $value, $context // 'unknown foreign key');
}


sub column_is_nullable {
  my ($not_null, $is_pk, $pk_is_rowid_alias) = @_;
  return 0 if $not_null;
  return 1 unless $is_pk;
  return $pk_is_rowid_alias ? 0 : 1;
}


sub quote_identifier {
  my ($name) = @_;
  $name =~ s/"/""/g;
  return qq{"$name"};
}


sub pk_is_rowid_alias {
  my ($dbh, $table) = @_;
  my $list = eval {
    $dbh->selectall_arrayref(
      sprintf('PRAGMA index_list(%s)', quote_identifier($table)),
      { Slice => {} },
    );
  } or return 1;
  return (grep { ($_->{origin} // '') eq 'pk' } @$list) ? 0 : 1;
}


my $BARE_DEFAULT = qr{\A(?:
    [+-]?(?:0[xX][0-9a-fA-F]+|(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?)   # number
  | [xX]?'(?:[^']|'')*'                                               # string, blob
  | [A-Za-z_\x{80}-\x{10FFFF}][A-Za-z0-9_\$\x{80}-\x{10FFFF}]*        # keyword, identifier
  | "(?:[^"]|"")*" | `(?:[^`]|``)*` | \[[^\]]*\]                      # quoted identifier
)\z}x;

sub default_value_sql {
  my ($default) = @_;
  return $default if $default =~ $BARE_DEFAULT;
  return $default =~ /--/ ? "($default\n)" : "($default)";
}


sub refuse_qualified_name {
  my ($kind, $name) = @_;
  return unless defined $name and !ref $name and $name =~ /\./;
  DBIO::Exception->throw(sprintf
    "SQLite refuses the %s name '%s': SQLite has no schemas to qualify a name "
    . "with, so it would be one %s named literally '%s'. A name that is "
    . "meant as SQL is declared as a scalar ref, \\'%s', and is written as given",
    $kind, $name, $kind, $name, $name);
}


sub split_type_size {
  my ($type) = @_;
  return ($type, undef) unless defined $type;
  return ($type, undef)
    unless $type =~ /\A\s*(\w[\w ]*?)\s*\(\s*(\d+)\s*(?:,\s*(\d+)\s*)?\)\s*\z/;
  my ($base, $first, $second) = ($1, $2, $3);
  return ($base, defined $second ? [ $first + 0, $second + 0 ] : $first + 0);
}


sub type_with_size {
  my ($type, $size) = @_;
  return $type unless defined $size;
  return $type . '(' . join(',', @$size) . ')' if ref $size eq 'ARRAY';
  return $type . "($size)";
}


sub type_affinity {
  my ($type) = @_;
  $type //= '';
  return 'INTEGER' if $type =~ /INT/i;
  return 'TEXT'    if $type =~ /CHAR|CLOB|TEXT/i;
  return 'BLOB'    if $type =~ /BLOB/i || $type eq '';
  return 'REAL'    if $type =~ /REAL|FLOA|DOUB/i;
  return 'NUMERIC';
}


sub default_literal_sql {
  my ($value, $type) = @_;
  # A number goes bare only when it is the canonical form of that number
  # (5, -1, 1.5; not 007 or 1.50): anything else is a string that merely holds
  # digits and keeps its quotes, so '007' stays '007' in a column of any type.
  return $value
    if $value =~ /\A-?(?:0|[1-9]\d*)(?:\.\d*[1-9])?\z/ && type_affinity($type) ne 'TEXT';
  (my $quoted = $value) =~ s/'/''/g;
  return "'$quoted'";
}


my $QUOTED = qr{ '(?:[^']|'')*' | "(?:[^"]|"")*" | `(?:[^`]|``)*` | \[[^\]]*\] }x;

my $TOKEN = qr{\G(?:
    (?<skip>   (?: \s+ | --[^\n]*\n? | /\*.*?(?:\*/|\z) )+ )
  | (?<quoted> $QUOTED )
  | (?<punct>  [(),] )
  | (?<word>   [^\s'"`\[(),/-]+ | . )
)}xs;

sub sql_tokens {
  my ($sql) = @_;
  my @tokens;
  while ($sql =~ /$TOKEN/gc) {
    my ($kind) = grep { defined $+{$_} } qw(skip quoted punct word);
    push @tokens, [ $kind, $+{$kind} ];
  }
  return @tokens;
}


sub token_identifier {
  my ($kind, $text) = @_;
  return $text unless $kind eq 'quoted';
  my $quote = substr $text, 0, 1;
  my $name  = substr $text, 1, -1;
  $name =~ s/\Q$quote$quote\E/$quote/g unless $quote eq '[';
  return $name;
}


sub create_name_index {
  my ($tokens, @words) = @_;

  # The tokens that count, by their place in the list.
  my @at = grep { $tokens->[$_][0] ne 'skip' } 0 .. $#$tokens;
  my $word = sub {
    my $token = defined $at[ $_[0] ] ? $tokens->[ $at[ $_[0] ] ] : return '';
    return $token->[0] eq 'word' ? uc $token->[1] : '';
  };

  return unless $word->(0) eq 'CREATE';
  $word->($_ + 1) eq $words[$_] or return for 0 .. $#words;

  # Only the three words together are the clause.
  my $name = @words + 1;
  $name += 3
    if $word->($name) eq 'IF' && $word->($name + 1) eq 'NOT'
      && $word->($name + 2) eq 'EXISTS';
  return unless defined $at[$name];

  my $kind = $tokens->[ $at[$name] ][0];
  return $kind eq 'word' || $kind eq 'quoted' ? $at[$name] : ();
}


sub create_table_name_index {
  my ($tokens) = @_;
  return create_name_index($tokens, 'TABLE');
}


sub comparable_statement {
  my ($sql, @words) = @_;
  my @tokens = sql_tokens($sql // '');
  my $at     = create_name_index(\@tokens, @words);
  $tokens[$at][1] = quote_identifier(token_identifier(@{ $tokens[$at] }))
    if defined $at;
  return join ' ', map { $_->[1] } grep { $_->[0] ne 'skip' } @tokens;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Util - Shared SQLite-specific helper functions for DBIO

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Small helpers that capture SQLite-specific truths shared across the driver,
so the same rule is not re-encoded in several places.

=head1 METHODS

=head2 foreign_key_action

    my $action = foreign_key_action($value, $context);

The one check of the action of a foreign key (C<on_delete>, C<on_update>),
shared by L<DBIO::SQLite::DDL> and L<DBIO::SQLite::Diff>. The value is read the
way SQLite reads it -- runs of white space count as one space, letter case does
not matter -- and has to be one of the five actions: C<NO ACTION>, C<RESTRICT>,
C<CASCADE>, C<SET NULL> or C<SET DEFAULT>. It is returned as declared, with
the white space collapsed and trimmed; the letter case is not changed.

A value that is not declared, C<undef> or C<''>, returns C<undef>. Any other
word throws a L<DBIO::Exception> that names the value, the five allowed
actions and C<$context> (the relationship or the table the caller is looking
at), so a typo in a schema is refused when it is read and not left to SQLite
as a syntax error.

=head2 column_is_nullable

    my $is_nullable = column_is_nullable($not_null, $is_pk, $pk_is_rowid_alias);

The single source of truth for SQLite column nullability, shared by the
introspect path (L<DBIO::SQLite::Introspect/table_columns_info>) and the live
C<PRAGMA> path (L<DBIO::SQLite::Storage/_dbh_columns_info_for>) so the driver
cannot answer two different things about the same column. Returns C<1> when
the column may hold NULL, C<0> otherwise.

A column declared C<NOT NULL> is never nullable, and a column that is not part
of the primary key is nullable exactly when C<PRAGMA table_info> says so. The
third argument decides the remaining case -- a key column that carries no
C<NOT NULL> attribute -- and it has to, because B<SQLite really does store NULL
in most such columns>:

    CREATE TABLE t (name TEXT PRIMARY KEY);      -- a rowid table
    INSERT INTO t (name) VALUES (NULL);          -- accepted
    INSERT INTO t (name) VALUES (NULL);          -- accepted again

Both rows are there afterwards; the two NULLs do not even collide with one
another. This is SQLite's documented, deliberately-kept bug (see "The PRIMARY
KEY" in L<https://sqlite.org/lang_createtable.html>) and it is why this driver
does B<not> take L<DBIO::Introspect::Base>'s C<< is_pk => not nullable >> fold
at face value (core ADR 0038): reporting C<< is_nullable => 0 >> for
that column makes L<DBIO::Generate> bake C<NOT NULL> into the regenerated
result class, and the redeployed table then refuses the very rows it was
generated from.

The one key column that genuinely cannot hold NULL is the B<rowid alias> --
C<INTEGER PRIMARY KEY> on a rowid table, where C<NULL> is an input token
meaning "assign the rowid" and the stored value is an integer. Pass
C<$pk_is_rowid_alias> true for it; L</pk_is_rowid_alias> answers that question
from the database. C<WITHOUT ROWID> tables need no special case: SQLite
reports C<notnull = 1> for their key columns itself.

Omitting the third argument answers "not the alias", i.e. nullable. That is
the safe direction of the two: guessing C<1> leaves the engine's own
constraint to reject a bad INSERT with a real error, while guessing C<0>
produces a schema that rejects data the database accepts.

=head2 quote_identifier

    my $sql = sprintf 'DROP TABLE %s;', quote_identifier($table_name);

A name as SQLite takes it for an identifier in a statement: between double
quotes, with every double quote inside it doubled. C<item> becomes C<"item">,
C<order> becomes C<"order">, C<my table> becomes C<"my table"> and C<a"b>
becomes C<"a""b">. It needs no database handle.

The name is B<always> quoted, whatever it looks like. A name cannot be told
from a reserved word by its shape -- C<order>, C<group> and C<index> are made
of the same letters as C<item> -- and written bare such a word is a syntax
error. Quoting changes nothing about which object is meant: SQLite does not
fold the letter case of a name, quoted or not, so C<"Name"> and C<Name> are
one table.

This is the one quoter of the driver. Every identifier it writes into a
statement of its own goes through here: the DDL of L<DBIO::SQLite::DDL> and of
the L<DBIO::SQLite::Diff> ops, and the C<PRAGMA> calls of
L<DBIO::SQLite::Introspect>. The queries of the ORM do not -- how those are
quoted is the SQL maker's business and that of the C<quote_names> connect
attribute.

=head2 pk_is_rowid_alias

    my $alias = pk_is_rowid_alias($dbh, $table);

True when C<$table>'s primary key is the rowid alias -- the one key shape
whose column cannot hold NULL. C<$table> is a bare table name, without a
schema prefix.

The test is C<PRAGMA index_list>: SQLite materialises every primary key as an
C<origin = 'pk'> automatic index B<except> the rowid alias, which is the rowid
itself and needs no index. So "the table declares a key but has no C<pk>-origin
index" identifies the alias exactly, with no parsing of the stored C<CREATE
TABLE> text.

Nothing cheaper is correct here. C<PRAGMA table_info> alone cannot tell the
alias apart from a key column that holds NULL -- it reports
C<type=INTEGER notnull=0 pk=1> for both C<id INTEGER PRIMARY KEY> (the alias)
and C<id INTEGER PRIMARY KEY DESC> (not an alias, stores NULL). Type affinity
is no better: C<INT> has INTEGER affinity but only the exact declared type
C<INTEGER> makes an alias, so C<id INT PRIMARY KEY> also stores NULL.

A table with no primary key at all has no C<pk>-origin index either and so
reads as "alias" here; that is harmless, because the answer is only ever
consulted for a column C<PRAGMA table_info> already marked C<pk>. If the
C<PRAGMA> cannot be run the function reports true, which falls back to the
L<DBIO::Introspect::Base> answer (a key column is not nullable) rather than
inventing a new one.

=head2 default_value_sql

    my $sql = 'DEFAULT ' . default_value_sql($column->{default_value});

Renders a column default of the introspected model -- the C<dflt_value> of
C<PRAGMA table_xinfo> -- as what has to follow the C<DEFAULT> keyword. Shared
by L<DBIO::SQLite::Diff::Table> and L<DBIO::SQLite::Diff::Column>, which both
write that clause.

The value cannot be written back as it is read. SQLite's grammar takes a
literal after C<DEFAULT> or an expression B<in parentheses>, and the C<PRAGMA>
reports the expression without them: C<DEFAULT (datetime('now'))> reads as
C<datetime('now')>, and C<DEFAULT datetime('now')> is a syntax error. Nor can
everything be wrapped:

=over 4

=item * a number, a string or blob literal, and a keyword (C<NULL>, C<TRUE>,
C<CURRENT_TIMESTAMP>, ...) are valid either way and are left as they are;

=item * an identifier -- C<DEFAULT abc>, C<DEFAULT "abc">, which SQLite reads
as the string C<'abc'> -- must B<not> be wrapped: C<(abc)> is a column
reference, refused as "default value of column is not constant";

=item * everything else is an expression and gets the parentheses, including
one that already begins and ends with one: C<DEFAULT ((1)+(2))> reads as
C<(1)+(2)>.

=back

The parentheses are harmless where they were not needed, so the rule errs
towards them: only what is recognisably a single literal or identifier token
goes without. An expression ending in a C<--> comment gets its closing
parenthesis on a new line, where the comment cannot swallow it.

=head2 refuse_qualified_name

    refuse_qualified_name(table => $name) if defined $name and !ref $name;

Throws a L<DBIO::Exception> when C<$name>, a table or view name a schema gave
as a string, has a dot in it. SQLite has no schemas to qualify a name with:
C<other.t> would be read as the one table whose name is literally that, and
nobody who writes it means that. The message names the kind, C<table> or
C<view>, and the name as declared, refuses, and points at the declaration that
is literal SQL, C<< \'other.t' >>, which is not touched by this.

=head2 split_type_size

    my ($type, $size) = split_type_size('CHARACTER(10)');   # 'CHARACTER', 10
    my ($type, $size) = split_type_size('NUMERIC(10, 2)');  # 'NUMERIC', [10, 2]
    my ($type, $size) = split_type_size('TEXT');            # 'TEXT', undef

Takes a declared column type apart into the type and its size. SQLite keeps a
column's length or precision inside the declared type text, and this is the
one place that reads it back out: a number, or two numbers separated by a
comma, in the parentheses at the end of the type. The size is the number, or
C<[ $precision, $scale ]> for two.

A type that does not end like that comes back whole, with C<undef> for the
size -- C<VARCHAR(max)>, C<TEXT>, C<DOUBLE PRECISION>. The introspected model
(L<DBIO::SQLite::Introspect::Columns>) and the compiled one
(L<DBIO::SQLite::Diff/target_from_compiled>) both go through it, so the two
sides of a diff are always split the same way.

=head2 type_with_size

    my $type = type_with_size('VARCHAR', 20);        # 'VARCHAR(20)'
    my $type = type_with_size('NUMERIC', [10, 2]);   # 'NUMERIC(10,2)'
    my $type = type_with_size('TEXT', undef);        # 'TEXT'

The reverse of L</split_type_size>, for a statement written from the fields of
a model column.

=head2 type_affinity

    my $affinity = type_affinity($declared_type);   # 'TEXT', 'INTEGER', ...

The affinity SQLite gives a column of that declared type: C<INTEGER>, C<TEXT>,
C<BLOB>, C<REAL> or C<NUMERIC>. The type is the text that follows the column's
name in the C<CREATE TABLE> -- what C<PRAGMA table_xinfo> reports as C<type>,
what L<DBIO::SQLite::DDL/install_ddl> writes there, the C<native_type> of a
compiled model.

It is SQLite's own rule (L<https://sqlite.org/datatype3.html>, section 3.1):
five questions about the letters of the type, in any letter case, asked in
this order, and the first that is answered with yes decides:

=over 4

=item 1. it contains C<INT> -- C<INTEGER>;

=item 2. it contains C<CHAR>, C<CLOB> or C<TEXT> -- C<TEXT>;

=item 3. it contains C<BLOB>, or there is no type -- C<BLOB>;

=item 4. it contains C<REAL>, C<FLOA> or C<DOUB> -- C<REAL>;

=item 5. anything else -- C<NUMERIC>.

=back

The order is part of the rule: C<CHARINT> holds C<CHAR> and has C<INTEGER>
affinity. And the rule reads letters, not type names: C<DATE>, C<BOOLEAN> and
C<STRING> are C<NUMERIC>, C<POINT> is C<INTEGER>. An undefined type is no type.

=head2 default_literal_sql

    my $sql = 'DEFAULT ' . default_literal_sql($info->{default_value}, $type);

Turns a C<default_value> that is a plain Perl value -- not a scalar ref -- into
what follows the C<DEFAULT> keyword. This is the one place where such a value
becomes SQL. C<$type> is the column's declared type, as L</type_affinity> takes
it.

Whether the value is a number or a string cannot be seen from the Perl scalar:
C<'007'> and C<7> are both digits. The column decides it.

=over 4

=item * In a column with B<TEXT affinity> the value is a string, and is always
written as an SQL string literal: in apostrophes, with every apostrophe inside
it doubled. C<007> becomes C<'007'>, C<10> becomes C<'10'>, C<it's> becomes
C<'it''s'>. Written bare, C<DEFAULT 007> is the number 7, which the column's
affinity stores as the text C<7>, and C<DEFAULT 1.50> arrives as C<1.5>: the
declared string never reaches a row.

=item * In B<any other column>, and when no type is given, a number goes bare
-- the canonical form of a number: no leading zeros, an optional leading minus,
an optional fraction without trailing zeros (C<5>, C<-1>, C<1.5>) -- so that
the column's default is a number and not a string holding one. Anything else is
a string and is written as the literal described above. That includes a string
of digits that is not the canonical number (C<007>, C<1.50>), which keeps its
quotes and its value, and what SQLite would read as a number if it stood there
bare but this rule does not name, such as C<1e3>, C<.5> or C<0x10>.

=back

L<DBIO::SQLite::DDL/install_ddl> writes the result into the C<CREATE TABLE>,
and C<PRAGMA table_xinfo> reports a default as the text it was declared with,
so the result is also how L<DBIO::SQLite::Introspect> reads that column back.
L<DBIO::SQLite::Diff/target_from_compiled> uses the same function for that
reason: its model has to hold the default the way the introspector reports the
installed one, or the two differ on a column nobody changed. Each of the two
passes the type it gives the column.

A default given as a scalar ref is literal SQL and does not come through here.
Not to be confused with L</default_value_sql>, which takes a default that is
already SQL text.

=head2 sql_tokens

    my @tokens = sql_tokens($statement);    # ([ $kind, $text ], ...)

Splits the text of a statement into its lexical units, as far as the driver
has to tell them apart to B<read> a statement SQLite stored -- the C<sql> of
C<sqlite_master>. This is the one lexer for that; L<DBIO::SQLite::Diff::Column>
reads a column's declaration with it, L<DBIO::SQLite::Diff::Rebuild> finds the
table's name, L<DBIO::SQLite::Diff::Index> compares two C<CREATE INDEX>
statements, L</comparable_statement> two views or two virtual tables, and
L<DBIO::SQLite::Introspect::Indexes> looks for a C<WHERE>.

Each token is a C<[ $kind, $text ]> pair, and the texts joined are the
statement again, character for character. The kinds:

=over 4

=item C<skip> -- whitespace and comments (C<-- ...> to the end of the line,
C</* ... */>), any run of them as one token;

=item C<quoted> -- anything in quotes, in the four forms SQLite knows:
C<'apostrophes'>, C<"double quotes">, C<`backticks`> (each with its own quote
character doubled inside) and C<[brackets]>. What is inside is never looked at,
so a comma, a parenthesis or a keyword in a name or a string separates nothing;

=item C<punct> -- one of C<(>, C<)> and C<,>;

=item C<word> -- everything else: a run of characters up to the next
whitespace, quote, parenthesis, comma, C</> or C<->, or a single character that
starts none of the above. A bare name or keyword is one word, and so is
C<main.item>.

=back

It is not SQLite's tokenizer and does not validate anything: operators and
numbers are just words.

=head2 token_identifier

    my $name = token_identifier($kind, $text);
    my $name = token_identifier(@$token);

The name a token of L</sql_tokens> stands for where SQLite's grammar has an
identifier: the text of a C<word>, and what is between the quotes of a
C<quoted> token, with a doubled quote character made one again. C<item>,
C<"item">, C<`item`> and C<[item]> are all C<item>, and C<"a""b"> is C<a"b>.

SQLite takes a name in any of the four quotings, apostrophes included, so
C<'item'> is C<item> here as well. Whether a token in apostrophes is a name or
a string is a matter of where it stands, and the caller's to know.

=head2 create_name_index

    my @tokens = sql_tokens($statement);
    my $at     = create_name_index(\@tokens, 'VIEW');
    my $at     = create_name_index(\@tokens, 'VIRTUAL', 'TABLE');

The index of the token that holds the object's name in a tokenised C<CREATE>
statement of the kind the words name: the first word or quoted token behind
C<CREATE> and those words, and behind C<IF NOT EXISTS> when that is there.
Whitespace and comments between them do not matter, nor does the letter case
of the keywords. Returns C<undef> for a statement that does not begin that
way -- asked for a C<VIEW>, a C<CREATE TABLE> has no name.

SQLite stores a statement from the name on behind a C<CREATE TABLE>, C<CREATE
VIEW> or C<CREATE VIRTUAL TABLE> of its own, so C<TEMP>, C<IF NOT EXISTS> and
a schema prefix never come back from C<sqlite_master>. A statement that was
not read from there and names its object as C<main.item> has that whole word
as its name token.

=head2 create_table_name_index

    my @tokens = sql_tokens($create_table);
    my $at     = create_table_name_index(\@tokens);
    my $name   = token_identifier(@{ $tokens[$at] }) if defined $at;

L</create_name_index> for a C<CREATE TABLE>: the index of the token that holds
the table's name. Returns C<undef> for anything that does not begin that way
-- a C<CREATE VIEW>, a C<CREATE VIRTUAL TABLE>.

=head2 comparable_statement

    my $same = comparable_statement($old_sql, 'VIEW')
      eq comparable_statement($new_sql, 'VIEW');

A stored C<CREATE> statement in the form two of them are compared in, for the
kind of statement the words name (as L</create_name_index> takes them): its
tokens without whitespace and comments, joined by one space, with the object's
B<name> written in the driver's own quoting, whichever quoting it came in.
C<CREATE VIEW v AS SELECT 1>, C<CREATE VIEW "v" AS SELECT 1> and

    CREATE VIEW [v] -- the first
      AS SELECT 1

are one statement that way. A database deployed before L<DBIO::SQLite::DDL>
quoted every name holds the first, the target of an upgrade the second.

Only the name is read. Everything behind it has to be the same token for
token, in the letter case it is written in: it is SQL the schema gave -- a
view's C<SELECT>, the arguments of a virtual table's module -- and comes back
the same from an unchanged schema. A statement that is not of that kind is
its tokens joined and nothing else.

L<DBIO::SQLite::Diff> compares views and virtual tables with it.
L<DBIO::SQLite::Diff::Index> reads more names than the first out of a
C<CREATE INDEX> and has a reader of its own.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
