# Draft for dbio (core), not sent: NoBindVars writes '' for a number unquoted

Origin: dbio-mssql karr k63 (measured 2026-10, MSSQL 2022, DBD::Sybase 1.27 /
FreeTDS 1.3.17, class `DBIO::MSSQL::Storage::Sybase::NoBindVars`; pinned in
dbio-mssql t/83 and t/84).

`DBIO::Storage::DBI::NoBindVars::_interpolate_bind_values` asks
`interpolate_unquoted($datatype, $value)` for every value that carries a data
type. Its default answer is true for an integer type when the value has no
non-digit character (`$_[2] !~ /\D/`). The empty string has no non-digit
character, so `''` for an `integer` column is written without quotes:

    INSERT INTO t (num) VALUES ( )
    UPDATE t SET num =  WHERE id = 1

The server refuses it (Msg 102, syntax error). Loud, no row, no data loss. With
a placeholder, or as the quoted literal `''`, the same server turns `''` into 0
for an INT.

Recommendation: `interpolate_unquoted` should require at least one digit
(`length $_[2] and $_[2] !~ /\D/`) so that `''` falls through to the quoted
branch and behaves as it does with placeholders on every NoBindVars driver
(Sybase ASE, MSSQL). Whether `''` should become 0 for a number at all is core's
decision; the minimal change keeps NoBindVars equal to the placeholder path.
The driver does not narrow `interpolate_unquoted` itself: that would patch one
driver around a rule all of them share.
