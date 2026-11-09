# ABSTRACT: Shared SQL utility functions for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

package DBIO::SQL::Util;

use Exporter 'import';
use DBIO::Exception ();

our @EXPORT_OK = qw(_quote_ident _split_statements);


# Quote a SQL identifier.
# Unquoted identifiers must match /\A[a-z_][a-z0-9_]*\z/i (case-insensitive).
# Embedded double-quotes in quoted identifiers are escaped as "".
sub _quote_ident {
  my ($name) = @_;

  # Simple unquoted identifier: starts with letter or underscore,
  # followed by letters, digits, or underscores (case-insensitive)
  return $name if $name =~ /\A[a-z_][a-z0-9_]*\z/i;

  # Double-quote the identifier, escaping embedded double-quotes as ""
  $name =~ s/"/""/g;
  return qq{"$name"};
}

# Split SQL text into its statements.
#
#   my @statements = _split_statements($sql);
#   my @statements = _split_statements($sql, { backslash_escapes => 1 });
#   my @statements = _split_statements($sql, { dialect => 'postgresql' });
#
# The text is read as SQL, so a semicolon ends a statement only where it
# stands as one. It does not inside
#
#   * a string literal '...' (a quote in it is doubled, ''), PostgreSQL's
#     E'...' and Oracle's q'[...]';
#   * a quoted identifier "...", `...` or [...] (the closing character in it is
#     doubled). A [ is no identifier but a subscript or an array where it
#     stands directly behind a word character, a ] or a ) -- PostgreSQL's
#     integer[], col[1], ARRAY['a', 'b'] -- and where it opens on a literal or
#     on another [ -- the lists of ClickHouse and DuckDB, ['a', 'b']. What
#     stands between such brackets is read like everything else;
#   * a comment, -- to the end of the line or /* ... */. Block comments do not
#     nest: the first */ closes. PostgreSQL nests them, the other engines do
#     not, and this reading never finds fewer statements than the other one --
#     except under dialect postgresql, which reads /* a /* b */ c */ as one
#     comment, in the scan and in the comments taken off in front of a statement.
#     MySQL's # comment is not read, # being an operator elsewhere;
#   * a dollar-quoted string $$...$$ or $tag$...$tag$, by PostgreSQL's rule:
#     the tag is empty or an identifier, and a $ directly behind a word
#     character or another $ belongs to that word (a$b$, Oracle's v$session;
#     $1 is a placeholder). One that is never closed is ordinary text;
#   * parentheses. A semicolon between ( and ) -- PostgreSQL's CREATE RULE ...
#     DO ALSO (INSERT ...; INSERT ...) -- ends nothing, in any dialect. The
#     depth never goes below zero, so a stray ) costs no boundary;
#   * the body of a CREATE TRIGGER, from its BEGIN to the END that closes it.
#     Inside the body CASE opens a further level, and BEGIN does where a
#     statement can start (behind a semicolon, a label, THEN, ELSE, DO, LOOP
#     or REPEAT); END closes one. An END that closes a BEGIN level stands
#     behind a semicolon or directly behind its BEGIN, so a bare end or begin
#     anywhere else -- SET end = 1, WHERE begin = 1 -- is a column; the END of
#     a CASE is not asked this, it closes its CASE wherever it stands.
#     END IF, END LOOP, END WHILE and END REPEAT close a construct whose
#     opening was not counted, and the CASE of END CASE opens nothing. This
#     is read ONLY in a statement that begins CREATE [OR REPLACE | OR ALTER]
#     [TEMP | TEMPORARY] [DEFINER = ...] TRIGGER. The body of a function, a
#     procedure or an event is NOT read: its semicolons still end a
#     statement, so a routine has to come dollar-quoted or go to the handle
#     whole (PostgreSQL's BEGIN ATOMIC and Oracle's PL/SQL units below
#     excepted). Neither is a trigger's DECLARE section before its BEGIN
#     (Firebird), nor Transact-SQL, where an END may be followed by a new IF.
#     One more body is read, under dialect postgresql only: CREATE [OR REPLACE]
#     FUNCTION | PROCEDURE ... BEGIN ATOMIC <statement>; ... END (PostgreSQL
#     14+). It is the same level mechanism: the semicolons from BEGIN ATOMIC
#     to its END end nothing, and the END closes at the end of the statement.
#     Without the dialect BEGIN ATOMIC is a word like any other.
#   * under dialect oracle a PL/SQL unit: a statement that begins CREATE [OR
#     REPLACE] [EDITIONABLE | NONEDITIONABLE] FUNCTION | PROCEDURE | PACKAGE
#     [BODY] | TRIGGER | TYPE BODY, or an anonymous block (DECLARE or BEGIN
#     first). It is one statement up to the semicolon behind the END that
#     closes its outermost level, and that statement KEEPS the semicolon,
#     which Oracle needs behind END. A line that holds nothing but / (SQL*Plus)
#     ends a statement as well and is not delivered. The levels: the IS | AS of
#     a function, a procedure, a package or a type body opens one (a forward
#     declaration PROCEDURE p; and a call specification do not), so does a
#     nested subprogram in a declaration part, a DECLARE or BEGIN of a trigger
#     or an anonymous block, and a nested BEGIN or DECLARE where a statement
#     can start; the BEGIN of a level already in its declaration part belongs
#     to that level. CASE opens a level that END or END CASE closes; END IF and
#     END LOOP close a construct of their own and END [name] closes a level. An
#     end or begin behind a dot, or anywhere but where a statement ends, is a
#     column. A COMPOUND TRIGGER is one unit as well: its declaration part and
#     each timing-point section (BEFORE STATEMENT IS ... END BEFORE STATEMENT;
#     and the like) are levels inside it, and the END [name]; of its outermost
#     level ends it. A block that is not closed at the end of the text, or at a / line,
#     is refused with an exception and not delivered as a remainder.
#
# What is delivered is each statement without its semicolon and without the
# whitespace around it. Comments in front of a statement are taken off, so no
# statement begins with one, and a piece that holds nothing but comments is no
# statement and is not delivered; a caller needs no filter of its own, and one
# that drops what begins with "--" would drop the statement behind the
# comment. /*! ... */ (MySQL runs it) and /*+ ... */ (a hint) are code and
# stay. Comments inside and behind a statement are left as they are, like
# every other character of it.
#
# The backslash is where the dialects part, and the text does not say which
# one it is written in. Standard SQL reads it as a character -- 'C:\' is a
# complete literal -- while MySQL and ClickHouse read it as an escape in
# '...', "..." and `...`, so 'it\'s' is one. Without the option both readings
# are taken and a semicolon ends a statement if it does under either. A text
# that is right under one reading keeps every statement boundary it has; a
# wrong cut can only happen where the readings really part, behind a backslash
# before a closing quote. One exception keeps that from reaching into a
# function body: a semicolon that only ONE reading takes for an end is none
# while it stands between dollar-quote delimiters. For that the delimiters are
# taken from the bare text, literals and comments unread, because that is
# what protected a body before this function read literals at all -- the
# reading that has lost its place in the text sees dollar quotes where there
# are none, and none where they are. A caller that knows the dialect names the
# reading: backslash_escapes => 1 for the MySQL one, 0 for the standard one.
# E'...' is the backslash reading under both.
#
# The seam for that is dialect => NAME (see %DIALECT below): the name of the
# engine's SQL, which a storage declares through _ddl_sql_dialect and
# DBIO::Deploy::Base::_split_ddl hands over. It stands for the readings that
# engine has -- today only the backslash -- so a driver names its engine once
# and not each property. An explicit backslash_escapes beats it, an unknown
# name throws, and no dialect (or undef) is the behaviour above, unchanged.

# What each named SQL dialect reads differently. One row per dialect, one
# column per property of the reading; a property is added here when a reader
# for it exists, not before.
#
#   backslash_escapes  1: a backslash escapes the next character inside '...'
#                         (MySQL, MariaDB); 0: it is a character (standard SQL)
#   nested_comments    1: /* ... */ nests (PostgreSQL); 0: the first */ closes
#   begin_atomic       1: a routine's BEGIN ATOMIC ... END body is one level
#                         (PostgreSQL 14+); 0: BEGIN ATOMIC is an ordinary word
#   plsql_units        1: a PL/SQL unit (function, procedure, package, type
#                         body, trigger, anonymous block) is one statement
#                         that keeps the semicolon behind its END, and a line
#                         of / ends a statement (Oracle); 0: not read
my %DIALECT = (
  postgresql => { backslash_escapes => 0, nested_comments => 1, begin_atomic => 1, plsql_units => 0 },
  sqlite     => { backslash_escapes => 0, nested_comments => 0, begin_atomic => 0, plsql_units => 0 },
  mysql      => { backslash_escapes => 1, nested_comments => 0, begin_atomic => 0, plsql_units => 0 },
  oracle     => { backslash_escapes => 0, nested_comments => 0, begin_atomic => 0, plsql_units => 1 },
);

sub _split_statements {
  my ($sql, $opt) = @_;

  my $backslash = $opt ? $opt->{backslash_escapes} : undef;
  my ($nest, $atomic, $plsql) = (0, 0, 0);
  if ($opt and defined $opt->{dialect}) {
    my $dialect = $DIALECT{ $opt->{dialect} }
      or DBIO::Exception->throw(sprintf
        "_split_statements: unknown SQL dialect '%s' (known: %s)",
        $opt->{dialect}, join ', ', sort keys %DIALECT);
    $backslash //= $dialect->{backslash_escapes};
    ($nest, $atomic, $plsql) = @$dialect{qw(nested_comments begin_atomic plsql_units)};
  }

  # The cuts behind which the statement keeps its semicolon (PL/SQL units).
  my $keep = $plsql ? {} : undef;

  my @cuts;
  if (defined $backslash) {
    @cuts = _scan_statements($sql, $backslash ? 1 : 0, $nest, $atomic, $keep);
  }
  elsif (index($sql, '\\') < 0) {
    # No backslash, no second reading.
    @cuts = _scan_statements($sql, 0, $nest, $atomic);
  }
  else {
    my %readings;
    $readings{$_}++ for _scan_statements($sql, 0, $nest, $atomic),
      _scan_statements($sql, 1, $nest, $atomic);

    my @dollar = _dollar_quoted_spans($sql);
    for my $cut (sort { $a <=> $b } keys %readings) {
      shift @dollar while @dollar and $dollar[0][1] <= $cut;
      push @cuts, $cut
        if $readings{$cut} == 2 or !@dollar or $dollar[0][0] > $cut;
    }
  }

  my @stmts;
  my $from = 0;
  for my $cut (@cuts, length $sql) {
    my $stmt = substr $sql, $from, $cut - $from;
    $from = $cut + 1;
    $stmt .= ';' if $keep and $keep->{$cut};

    if ($nest) {
      # The same comments, nesting: a block comment ends where the scanner
      # puts its end, not at the first */.
      while (1) {
        next if $stmt =~ s/\A(?:\s+|--[^\n]*)//;
        last unless $stmt =~ m{\A/\*(?![!+])};
        substr($stmt, 0, _comment_end(\$stmt, 0)) = '';
      }
    }
    else {
      1 while $stmt =~ s{\A(?:\s+|--[^\n]*|/\*(?![!+]).*?(?:\*/|\z))}{}s;
    }
    $stmt =~ s/\s+\z//;
    push @stmts, $stmt if length $stmt;
  }

  return @stmts;
}

my %Q_QUOTE_CLOSE = ('[' => ']', '{' => '}', '(' => ')', '<' => '>');

# The characters a quoted text runs over without looking: everything but its
# closing character, and under the backslash reading everything but that and
# the backslash.
my %QUOTED_RUN = map {
  my $close = quotemeta $_;
  ($_ => [ qr/\G[^$close]+/, qr/\G[^$close\\]+/ ]);
} "'", '"', '`', ']';

# A routine whose body may be BEGIN ATOMIC ... END.
my $ROUTINE_HEAD = qr{
  \A CREATE \s+
  (?: OR \s+ REPLACE \s+ )?
  (?: FUNCTION | PROCEDURE ) \b
}xi;

my $TRIGGER_HEAD = qr{
  \A CREATE \s+
  (?: OR \s+ (?: REPLACE | ALTER ) \s+ )?
  (?: TEMP (?: ORARY )? \s+ )?
  (?: DEFINER \s* = \s* (?: '[^']*' | "[^"]*" | `[^`]*` | [^\s'"`] )+ \s+ )?
  TRIGGER \b
}xi;

# The start of a PL/SQL unit behind its CREATE, under dialect oracle.
my $PLSQL_WS = qr{(?:\s|--[^\n]*|/\*.*?\*/)+}s;
my $PLSQL_UNIT = qr{
  $PLSQL_WS
  (?: OR $PLSQL_WS REPLACE $PLSQL_WS )?
  (?: (?: NON )? EDITIONABLE $PLSQL_WS )?
  (?: FUNCTION | PROCEDURE | PACKAGE | TRIGGER | TYPE $PLSQL_WS BODY ) \b
}xi;

# The opening delimiter of a dollar-quoted string.
my $DOLLAR_QUOTE = qr/\$(?:[A-Za-z_][A-Za-z0-9_]*)?\$/;

# One pass over the text under one reading of the backslash. Returns the
# offsets of the semicolons that end a statement.
#
# No pattern matched against the text captures: a capturing match keeps a copy
# of the string it matched in, and that is the whole text, once per token.
sub _scan_statements {
  my ($sql, $backslash, $nest, $atomic, $keep) = @_;
  my $plsql = $keep ? 1 : 0;

  my @cuts;
  my $len = length $sql;
  my $start;           # offset of the statement's first token, undef before it
  my $trigger;         # is the statement a CREATE TRIGGER? asked at its first BEGIN
  my @levels;           # open BEGIN ('B') and CASE ('C') levels of a trigger body
  my $paren = 0;       # open parentheses
  my ($unit, $pending, $opened, $compound);   # dialect oracle: the PL/SQL unit being read
                       # ('block', 'trigger' or 'routine'), a subprogram head
                       # waiting for its IS | AS, a level opened on the unit,
                       # a COMPOUND TRIGGER
  my $prev = '';       # the token before: ';', '(', a word upper-cased, 'W' (a
                       # long word or a qualified one) or 'Q' (a literal)

  pos($sql) = 0;
  while ((my $at = pos $sql) < $len) {
    next if $sql =~ /\G\s+/gc;

    if ($nest and substr($sql, $at, 2) eq '/*') {
      pos($sql) = _comment_end(\$sql, $at);
      next;
    }

    next if $sql =~ m{\G(?:--[^\n]*|/\*.*?(?:\*/|\z))}gcs;

    # SQL*Plus: a line of nothing but / ends the statement before it.
    if ($plsql and substr($sql, $at, 1) eq '/'
        and ($at == 0 or substr($sql, 0, $at) =~ /(?:\A|\n)[ \t\r]*\z/)
        and $sql =~ m{\G/[ \t\r]*(?:\n|\z)}) {
      _incomplete_block($sql, $start) if @levels;
      pos($sql) = $at + 1;
      push @cuts, $at;
      ($start, $unit, $pending, $opened, $compound, $prev) = (undef, undef, 0, 0, 0, ';');
      next;
    }

    $start //= $at;

    # A word, with the $ that hangs on it (a$b$, v$session).
    if ($sql =~ /\G\w[\w\$]*/gc) {
      my $end = pos $sql;
      my ($was, $word) = ($prev, 'W');
      $prev = 'W';
      next if $end - $at > 5 and !$plsql;
      $word = uc substr $sql, $at, $end - $at;

      if (substr($sql, $end, 1) eq "'") {
        $prev = 'Q';
        if ($word eq 'E') {
          pos($sql) = $end + 1;
          _skip_quoted(\$sql, "'", 1);
        }
        elsif ($word eq 'Q' or $word eq 'NQ') {
          # Oracle q'[...]': up to the closing bracket and quote, whatever is
          # in it. One that is never closed is a word before a literal.
          my $open  = substr $sql, $end + 1, 1;
          my $close = index $sql, ($Q_QUOTE_CLOSE{$open} // $open) . "'", $end + 2;
          pos($sql) = $close + 2 if $close >= 0;
        }
        next;
      }

      if ($plsql) {
        $prev = $word;
        my $dotted = $at && substr($sql, $at - 1, 1) eq '.';

        if (!$unit and $at == $start and !$dotted) {
          if ($word eq 'DECLARE' or $word eq 'BEGIN') {
            ($unit, $opened) = ('block', 1);
            push @levels, $word eq 'BEGIN' ? 'X' : 'D';
          }
          elsif ($word eq 'CREATE') {
            my $here = pos $sql;
            if ($sql =~ /\G$PLSQL_UNIT/gc) {
              my $head = substr $sql, $here, pos($sql) - $here;
              $unit    = $head =~ /TRIGGER\z/i ? 'trigger' : 'routine';
              $pending = $unit eq 'routine' ? 1 : 0;
              $opened  = 0;
            }
            pos($sql) = $here;
          }
          next;
        }

        next if !$unit or $dotted;
        my $top = @levels ? $levels[-1] : '';

        if (!@levels and $unit eq 'trigger') {
          # BEGIN or DECLARE of the trigger: not a column of UPDATE OF ...
          if (($word eq 'BEGIN' or $word eq 'DECLARE') and !$paren and $was ne 'OF' and $was ne ',') {
            push @levels, $word eq 'BEGIN' ? 'X' : 'D';
            $opened = 1;
          }
          elsif ($word eq 'COMPOUND' and !$paren and $sql =~ /\G\s+TRIGGER\b/gci) {
            # COMPOUND TRIGGER: the unit's own level, its timing-point
            # sections open and close levels of their own inside it.
            push @levels, 'D';
            ($opened, $compound) = (1, 1);
            $prev = 'TRIGGER';
          }
        }
        elsif ($compound and @levels == 1 and $top eq 'D' and !$paren
               and ($word eq 'BEFORE' or $word eq 'AFTER' or $word eq 'INSTEAD')
               and $sql =~ /\G\s+(?:OF\s+)?(?:STATEMENT|EACH\s+ROW)\b/i) {
          $pending = 1;   # BEFORE STATEMENT IS ...: the section's head
        }
        elsif ($pending and !$paren and ($word eq 'IS' or $word eq 'AS')) {
          next if $word eq 'AS' and $sql =~ /\G\s+RESULT\b/i;   # RETURN SELF AS RESULT
          $pending = 0;
          # AS LANGUAGE ...: a call specification has no body.
          unless ($sql =~ /\G\s+(?:LANGUAGE|EXTERNAL)\b/i) {
            push @levels, 'D';
            $opened = 1;
          }
        }
        elsif ($top eq 'D' and ($word eq 'FUNCTION' or $word eq 'PROCEDURE')) {
          $pending = 1;
        }
        elsif (@levels and $word eq 'CASE') {
          push @levels, 'C';
        }
        elsif ($word eq 'BEGIN' and $top eq 'D') {
          $levels[-1] = 'X';
        }
        elsif (($word eq 'BEGIN' or $word eq 'DECLARE') and $top eq 'X'
               and $was =~ /\A(?:;|>|THEN|ELSE|LOOP|BEGIN)\z/) {
          push @levels, $word eq 'BEGIN' ? 'X' : 'D';
        }
        elsif ($word eq 'END' and @levels) {
          if ($sql =~ /\G\s+(?:IF|LOOP)\b/gci) {
            # END IF, END LOOP: the construct's own end.
          }
          elsif ($top eq 'C') {
            pop @levels;
            $sql =~ /\G\s+CASE\b/gci;   # END CASE
          }
          elsif ($top eq 'X' and $was ne ';' and $was ne 'BEGIN') {
            # SELECT end, ...: a column.
          }
          else {
            pop @levels;
            # END BEFORE STATEMENT: the name of the section it closes.
            $sql =~ /\G\s+(?:BEFORE|AFTER|INSTEAD)\s+(?:OF\s+)?(?:STATEMENT|EACH\s+ROW)\b/gci
              if $compound and @levels == 1;
          }
        }
        next;
      }

      unless ($word eq 'BEGIN' or @levels and ($word eq 'END' or $word eq 'CASE')) {
        $prev = $word if $word ne 'W';
        next;
      }

      # new.end, t.begin: a column.
      next if $at and substr($sql, $at - 1, 1) eq '.';

      if (!@levels) {
        $trigger //= substr($sql, $start, $at - $start) =~ $TRIGGER_HEAD ? 1 : 0;
        # BEGIN ATOMIC of a routine (dialect postgresql) is the same level.
        if ($trigger
            or $atomic and $word eq 'BEGIN'
              and substr($sql, $start, $at - $start) =~ $ROUTINE_HEAD
              and $sql =~ /\G\s+ATOMIC\b/gci) {
          push @levels, 'B';
          $prev = 'BEGIN';
        }
      }
      elsif ($word eq 'CASE') {
        push @levels, 'C';
      }
      elsif ($word eq 'BEGIN') {
        # Opens a block where a statement can start: behind a semicolon, a
        # label or THEN / ELSE / DO / LOOP / REPEAT. Anywhere else (SET begin
        # = 1, WHERE begin = 1) it is a column.
        if ($was =~ /\A(?:;|:|BEGIN|THEN|ELSE|DO|LOOP|REPEAT)\z/) {
          push @levels, 'B';
          $prev = 'BEGIN';
        }
      }
      elsif ($levels[-1] eq 'B' and $was ne ';' and $was ne 'BEGIN') {
        # SET end = 1, SELECT end, ...: an END that closes a block stands
        # where a statement ends or a body is empty. A CASE's END is not
        # asked this: it closes its CASE wherever it stands.
      }
      elsif ($sql =~ /\G\s+(?:IF|LOOP|WHILE|REPEAT)\b/gci) {
        # Closes a construct whose opening was not counted.
      }
      else {
        pop @levels;
        $sql =~ /\G\s+CASE\b/gci;   # END CASE: this CASE opens nothing
      }
      next;
    }

    my $char = substr $sql, $at, 1;
    pos($sql) = $at + 1;

    $prev = $char;

    if ($char eq ';') {
      next if @levels or $paren;
      push @cuts, $at;
      $keep->{$at} = 1 if $plsql and $unit and ($opened or $unit ne 'trigger');
      ($start, $trigger, $unit, $pending, $opened, $compound) = (undef, undef, undef, 0, 0, 0);
    }
    elsif ($char eq '(') {
      $paren++;
    }
    elsif ($char eq ')') {
      $paren-- if $paren;
    }
    elsif ($char eq "'" or $char eq '"' or $char eq '`') {
      $prev = 'Q';
      _skip_quoted(\$sql, $char, $backslash);
    }
    elsif ($char eq '[') {
      # An identifier, unless it is a subscript or an array: then the bracket
      # is a character and what follows it is read on.
      $prev = 'Q';
      _skip_quoted(\$sql, ']', 0)
        unless ($at and substr($sql, $at - 1, 1) =~ /[\w\]\)]/)
        or $sql =~ /\G\s*['\[]/;
    }
    elsif ($char eq '$') {
      $prev = 'Q';
      pos($sql) = $at;
      if ($sql =~ /\G$DOLLAR_QUOTE/gc) {
        my $tag   = substr $sql, $at, pos($sql) - $at;
        my $close = index $sql, $tag, pos $sql;
        if ($close >= 0) {
          pos($sql) = $close + length $tag;
          next;
        }
        pos($sql) = $at;
      }

      # A $ that opens nothing, with what hangs on it: $1, an unclosed $tag$.
      $sql =~ /\G\$[\w\$]*/gc;
    }
  }

  _incomplete_block($sql, $start) if $plsql and @levels;

  return @cuts;
}

sub _incomplete_block {
  my ($sql, $start) = @_;

  my $head = substr $sql, $start // 0, 60;
  $head =~ s/\s+/ /g;
  DBIO::Exception->throw(
    "_split_statements: PL/SQL block is not closed (begins '$head')");
}

# The offset behind the nesting block comment that opens at $at: its /* and */
# are counted, and one never closed runs to the end of the text. Sets pos().
sub _comment_end {
  my ($sql, $at) = @_;

  my $depth = 1;
  pos($$sql) = $at + 2;
  while ($$sql =~ m{\G.*?(?:/\*|\*/)}gcs) {
    $depth += substr($$sql, pos($$sql) - 2, 2) eq '/*' ? 1 : -1;
    return pos $$sql unless $depth;
  }

  return length $$sql;
}

# Moves pos() of $$sql from behind an opening quote to behind the closing one,
# or to the end of the text when the quote is never closed.
sub _skip_quoted {
  my ($sql, $close, $backslash) = @_;

  my $run = $QUOTED_RUN{$close}[ $backslash ? 1 : 0 ];
  my $len = length $$sql;

  while ((my $at = pos $$sql) < $len) {
    next if $$sql =~ /$run/gc;

    if (substr($$sql, $at, 1) ne $close) {
      # A backslash: it and the character behind it.
      pos($$sql) = $at + 2 > $len ? $len : $at + 2;
    }
    elsif (substr($$sql, $at + 1, 1) eq $close) {
      # Doubled: still inside.
      pos($$sql) = $at + 2;
    }
    else {
      pos($$sql) = $at + 1;
      return;
    }
  }

  return;
}

# The [from, to) spans between dollar-quote delimiters in the bare text, in
# ascending order: nothing else is read, so a delimiter inside a literal or a
# comment counts like any other.
sub _dollar_quoted_spans {
  my ($sql) = @_;

  my @spans;
  while ($sql =~ /(?<![\w\$])$DOLLAR_QUOTE/g) {
    my $from  = $-[0];
    my $tag   = substr $sql, $from, pos($sql) - $from;
    my $close = index $sql, $tag, pos $sql;
    next if $close < 0;
    push @spans, [ $from, $close + length $tag ];
    pos($sql) = $close + length $tag;
  }

  return @spans;
}

# The DROP statements of an add_drop_table pre-pass, shared by the synchronous
# deploy (DBIO::Deploy::Base::install) and the asynchronous one
# (DBIO::Storage::Async::_drop_statements_for).
#
#   my $sql = _drop_statements($schema, sub { quote($_[0]) }, { cascade => 1 });
#
# First DROP VIEW IF EXISTS ...; for every declared view that is a real view
# (virtual views and names that are no plain identifier are left out), in the
# reverse of their install order, then DROP TABLE IF EXISTS ... [CASCADE]; for
# every regular table source. Every name is written through the $quote code
# reference. The statements come back as one string, separated by a blank line.
sub _drop_statements {
  my ($schema, $quote, $opts) = @_;
  $opts ||= {};

  my (@tables, %view);
  for my $name ($schema->sources) {
    my $source = $schema->source($name);
    my $table = $source->name;
    next if ref $table;
    next if $table =~ /\s|\(/;
    if ($source->isa('DBIO::ResultSource::View')) {
      next if $source->is_virtual;
      $view{$name} = $source;
    }
    else {
      push @tables, $name;
    }
  }
  my @view_names = sort keys %view;

  # The install order: source names in order, each behind the views its
  # deploy_depends_on names (a class that is no view here orders nothing).
  my %view_of_class = map { ($view{$_}->result_class // '') => $_ } @view_names;
  my (@install, %placed);
  for my $first (@view_names) {
    next if $placed{$first};
    my @path = ($first);
    my %on_path = ($first => 1);
    while (@path) {
      next_view: {
        my $on = $view{ $path[-1] }->deploy_depends_on;
        for my $dep (
          grep { defined $_ && !$placed{$_} && !$on_path{$_} }
          map { $view_of_class{$_} }
          ref $on eq 'HASH' ? sort keys %$on : ref $on eq 'ARRAY' ? @$on : ()
        ) {
          push @path, $dep;
          $on_path{$dep} = 1;
          last next_view;
        }
        my $done = pop @path;
        delete $on_path{$done};
        push @install, $done;
        $placed{$done} = 1;
      }
    }
  }

  my @out = (
    (map { sprintf 'DROP VIEW IF EXISTS %s;', $quote->($view{$_}->name) } reverse @install),
    (map { sprintf 'DROP TABLE IF EXISTS %s' . ($opts->{cascade} ? ' CASCADE' : '') . ';', $quote->($schema->source($_)->name) } @tables),
  );
  return join("\n\n", @out);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQL::Util - Shared SQL utility functions for DBIO

=head1 VERSION

version 0.900004

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
