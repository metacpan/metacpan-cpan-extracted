# DBD::Firebird: a text bound to a BOOLEAN parameter is stored by its Perl truth

DRAFT, not sent. Target: DBD::Firebird issue tracker. Context: DBIO::Firebird karr k36.

## Observed

DBD::Firebird 1.39, Firebird 5.0.4, dialect 3.

```perl
$dbh->do('create table pb (id integer, b boolean)');
$dbh->do('insert into pb values (?, ?)', undef, 1, 'false');   # stored TRUE
$dbh->do('insert into pb values (?, ?)', undef, 2, 'x');       # stored TRUE
$dbh->do('insert into pb values (?, ?)', undef, 3, 0);         # stored FALSE
$dbh->do('insert into pb values (?, ?)', undef, 4, '0');       # stored FALSE
$dbh->do('insert into pb values (?, ?)', undef, 5, '');        # stored FALSE
$dbh->do('insert into pb values (?, ?)', undef, 6, 'true');    # stored TRUE
# select id from pb where b = ?   with 'false' finds the TRUE rows
```

A string parameter bound to a BOOLEAN is not converted by the server the way
the SQL literal `false` is; the value is the Perl truth of the string. 'false'
therefore means TRUE, silently, in INSERT, UPDATE and WHERE alike.

A FALSE column is also fetched as the empty string, a TRUE one as 1, with
`$sth->{TYPE}` 16.

## Expected

Either the words `true` / `false` (the server's own spellings, case-insensitive)
are passed to the server as such, or a text that is neither those nor 0 / 1 is
an error. Storing 'false' as TRUE with no diagnostic is the one outcome that is
wrong in every reading.

## Workaround in DBIO::Firebird

`Storage::InterBase::_bind_sth_params` translates 'true' / 'false' and throws
on any other string for a bind whose column type is boolean
(t/64-boolean-bind.t, t/26-boolean-live.t).
