# ADR 0012 — The text Oracle writes into an error carries no values

- Status: accepted (coordinator decision of 2026-11-02, under the maintainer's order to check every driver for values in error texts; core ADR 0075)
- Date: 2026-11-02
- Tags: storage, errors, security, core-adr-0075

## Context

Core ADR 0075 (addendum of 2026-11-02): an error message names keys, columns
and options, never values, passwords or bind contents. The core masks the bound
values of the running statement in the engine's text (`_mask_error_values`,
values of at least four characters), and a driver adds the forms its engine
writes. From 23ai on Oracle writes values into its own text, also when the
value was a bind; older servers do not for the same errors. Measured live
(Oracle 23ai Free, DBD::Oracle 1.95):

| Server text | Value in it |
|---|---|
| `ORA-01722: unable to convert string value containing 'g' to a number` | the first character |
| `ORA-03302: (ORA-01722 details) invalid string value: X` (no quotes; may span lines, up to the `Help:` line or the end) | the value |
| `ORA-03301: (ORA-00001 details) row with column values (ID:1, EMAIL:'X') already exists` | the key values, with column names |
| `ORA-01438: value X greater than specified precision (4, 1) for column` | the value |
| `ORA-61800: invalid boolean literal: X` | the value |
| `ORA-01428: Argument X is out of range.` | the value |

Without a value: ORA-12899 (lengths only), ORA-02290, ORA-02291, ORA-02292,
ORA-01400, ORA-01407, the date and time errors (ORA-01847, 01861, 01867, 01873
and the like), ORA-01465, JSON (ORA-40441), ORA-06502, ORA-24381 (the head; the
single errors in `ArrayTupleStatus` carry the forms above).

## Decision

1. `DBIO::Oracle::Util::mask_error_details($text, \@binds, $statement)` holds
   the form rules: each form above has the value replaced by `***`; the error
   code, the type, the table, the column, the constraint and the position stay.
   Values of any length are caught where the server writes them. A text of no
   known form is returned as it is.
2. The key text of ORA-03301 keeps its column names only where they can be read
   in one way: they are taken from the `columns (...)` list of the error before
   it, and each `, NAME:` must occur once and in that order. Oracle escapes
   nothing, so a value holding `, B:` or `)` could pass for a column; then the
   whole parenthesis becomes `(***)`. A doubt masks more.
3. The `(DBD ERROR: error possibly near <*> indicator at char N in '...')`
   that DBD::Oracle appends holds the statement with `:pN` placeholders, not
   values, and stays; it is told apart from a value by its form (it ends the
   text, the indicator stands at char N, the statement is the one that ran).
   Otherwise it counts as plain text.
4. `DBIO::Oracle::Storage::_mask_error_values` applies the form rules and
   **then** calls `next::method`, which masks the bound values of four
   characters or more as they were written and as the handle quotes them. The
   order matters: the form rules read the key text, which the core's masking
   would break up. The method is on the storage class that `Storage::WhereJoins`
   inherits.
5. Not masked: names of tables, columns and constraints; the literals of the
   statement; texts the application writes itself (`ORA-20000` and up);
   `$dbh->errstr`, which is a DBI attribute and stays raw.

## Consequences

- No other path in this driver carries engine text into an exception: there is
  no async storage and no own `DBIO::Exception::Server`; the handler, the
  statement execution, the connection actions and the populate and bulk
  reports are core's and call the hook, each single `ArrayTupleStatus` text
  separately. `Deploy` masks passwords by its own means and writes only names.
- Limits: a new server sentence that quotes a value is not masked until a rule
  for it is added (or the value is a bind of four characters or more). A bind
  equal to a column or constraint name (four characters or more) is replaced
  there as well. A short value whose own text ends in `\nORA-06512: at line 1`
  can leave that tail behind. Servers before 23ai write no values for these
  errors; the rules then find nothing and leave the text alone.
- Pinned offline in `t/100-error-values-mask.t` with the measured texts, live
  in `t/101-error-values-live.t`.

## Addendum 2026-11-09 — the masking does not depend on the session language

Oracle writes its messages in the language of the session (`NLS_LANGUAGE`, taken
from `NLS_LANG` or `LC_ALL`). The form rules above were written against the
English sentences; under `NLS_LANG=GERMAN_GERMANY.AL32UTF8` a short bound value
(below the four characters of the core's masking) stood in the clear in the
message. Measured on Oracle 23ai Free, DBD::Oracle 1.95:

| Code | German text |
|---|---|
| ORA-01722 | `Zeichenfolgenwert mit 'a' kann nicht in eine Zahl konvertiert werden:` |
| ORA-03302 | `(ORA-01722-Details) Ungültiger Zeichenfolgenwert: ab` |
| ORA-00001 | `Unique Constraint (DBIO.FW_P_PK) für Tabelle DBIO.FW_P mit Spalten (id) verletzt` |
| ORA-03301 | `(ORA-00001-Details) Zeile mit Spaltenwerten (id:7) ist bereits vorhanden` |
| ORA-01438 | `Wert 77 ist größer als die angegebene Dezimalstellenanzahl (1, 0) für Spalte` |
| ORA-61800 | `Ungültiges boolesches Literal: ab` |
| ORA-01428 | `Argument 3 befindet sich außerhalb des zulässigen Wertebereichs.` |
| help line, PL/SQL stack | `Hilfe: https://docs.oracle.com/error-help/...`, `ORA-06512: in Zeile 1` |

Decision:

1. Masking is independent of the language. A message that quotes a value is
   recognised by its **code** and read by its **structure**, not by its words:
   label and value of ORA-03302/ORA-61800 are split at the first colon; the key
   of ORA-03301 is the first brackets after the label up to the last bracket
   that is followed by words (the columns come from the last brackets of the
   ORA-00001 line before it); the value of ORA-01722 is what stands between the
   first and the last quote of its line; the value of ORA-01438 and ORA-01428
   is the number in the line (before the precision for ORA-01438). The end of
   a value is found by the link to the error help and the ORA-06512 code, in
   any language.
2. **Where the structure is not there, the text after the code is dropped**
   (`ORA-03302: ***`, `ORA-03301: ***`, `ORA-01438: ***`): a label with no
   colon, a key with no brackets or no details, a line with no number (or, for
   ORA-01438, no precision), an ORA-01722 line with no quote. The code stays,
   and for ORA-03301 the ORA-00001 line with the columns; no value does. An
   unknown language thus loses wording, never hides a value.
3. The session language is not forced by the driver (no `ALTER SESSION` on
   connect). A test that asserts an English sentence puts its own connection on
   `NLS_LANGUAGE = 'AMERICAN'`; `t/101` runs every case in an AMERICAN and in a
   GERMAN session of its own, independent of the environment.
4. The decimal point is another matter: a number bound as `99999.9` is refused
   with ORA-01722 in a German territory before ORA-01438 is reached. `t/101`
   uses whole numbers for those cases; the cause is not treated here.

Pinned offline in `t/100-error-values-mask.t` (measured German texts and made-up
texts of an unknown language), live in `t/101-error-values-live.t`.

## Addendum 2026-11-10 — French, and the link line follows the client

Under `NLS_LANG=FRENCH_FRANCE.AL32UTF8` the test round of ORA-03301 was red in
the AMERICAN session as well as in the FRENCH one: `ORA-03301: ***`, the value
gone and the column with it. Two things in the structure were taken from the
English and German texts. Measured on Oracle 23ai Free, DBD::Oracle 1.95
(client `NLS_LANG` French; session language set with `ALTER SESSION SET
NLS_LANGUAGE`, with and without `NLS_TERRITORY`, no difference in the texts):

| Code | FRENCH session |
|---|---|
| ORA-01722 | `impossible de convertir une valeur de chaîne contenant 'a' en un nombre : ` |
| ORA-03302 | `(Détails ORA-01722) valeur de chaîne non valide : ab` |
| ORA-00001 | `violation de contrainte unique (DBIO.PRB_P_PK) sur la table DBIO.PRB_P colonnes (id, email)` |
| ORA-03301 | `(Détails ORA-00001) la ligne avec les valeurs de colonne (id:7, email:'a b') existe déjà` |
| ORA-01438 | `valeur 77 supérieure à la précision indiquée (1, 0) pour la colonne ` |
| ORA-61800 | `valeur littérale booléenne non valide : ab` |
| ORA-01428 | `L'argument 3 est hors limites.` |
| help line, PL/SQL stack | `Aide : https://docs.oracle.com/error-help/...` , `ORA-06512: à la ligne 1` |

1. **The label of the help line is the client's language, not the session's.**
   An AMERICAN session under a French client writes the English sentences and
   still `Aide : https://...`. The end of a value was found by `\n\S+: https://`,
   which does not match `Aide :` (a blank before the colon, French
   typography), so the key of ORA-03301 was not seen to end where it does and
   the whole text after the code was dropped. The label is now anything
   without a colon up to the colon, then optional white space and the link; the
   link stays what is recognised.
2. **The details bracket of ORA-03301 holds the code anywhere**
   (`(Détails ORA-00001)`; English and German have it first). It is a
   parenthesis without nested ones that contains an `ORA-` code.
3. The colons of French typography (`valide : ab`, `nombre : `) fall under the
   existing rule (label up to the first colon, the value after it), and the
   keys are written `id:7` without blanks, so the column reading is unchanged.
   A value with no-break or narrow no-break spaces, `, `, colons or line breaks
   is masked as before; the text of an array execution comes from the DBD as
   UTF-8 bytes, which the patterns must read as well (a character pattern with
   a blank class beyond Latin-1 turns the last byte of `déjà` into white
   space; the patterns therefore name no such character).

Not changed: the session language is still not forced by the driver, and the
masking does not look at it. `t/101` runs every case in an AMERICAN, a GERMAN
and a FRENCH session of its own; the French texts are pinned offline in
`t/100`.
