# Connect info and AccessBroker — DBIO::PostgreSQL::EV

Users connect with a `dbi:Pg:` DSN; libpq conninfo is the transport-internal
shape, rendered by `conninfo_string` for `EV::Pg->new`.

## One reader

The dbh and the pool are opened from the same connect info and end up in the
same place as the same user. `Storage::_pg_read_connect_info` reads connect
info wherever it comes from — what `connect_info` is given, what a broker
answers at attach and for every connection (`broker => 1`) — into the
`[ \%conninfo, \%opts ]` pair. A form the sync storage reads as a connection
(`DBIO::Storage::DBI::_normalize_connect_info`) is read as that connection:

| Form | Read as |
|---|---|
| `[ 'dbi:Pg:...', $user, $pass, \%attrs, \%extra ]` | `dbi_to_conninfo` |
| `{ dsn => 'dbi:Pg:...', user, password, %attrs }`; a `dbname` that is a whole DSN | that DBI form — every other key an attribute, `host`/`sslmode` beside the `dsn` too |
| `{ dbname, host, user, password, sslmode, ... }` | libpq parameters, minus `pool_size` and the owner's keys: its options (core's `_strip_private_connect_attrs`) and DBI attributes by name (`_pg_is_dbi_attribute`) |
| `'host=... dbname=...'`, a `postgresql://` URI | libpq conninfo string |

A hash or string may be followed by an options hash. Everything else is refused
in `connect_info` (a refusal, see *Refusals* in SKILL.md) — through a schema at
the first `->async` — naming the form, never a value: a coderef or `dbh_maker`
(the owner's way to a dbh), a conninfo string with user and password beside it,
another driver's DSN. A rule about connect info lives in the reader, never as a
guard at a caller. Two rules depend on the origin: an answer that renders to an
**empty conninfo** (`[ {}, {} ]`, `{ pool_size => 3 }`, `{ dbname => undef }`, a
blank string, `dbi:Pg:;`) is refused — libpq would fill it from
`PGHOST`/`PGUSER` — while static connect info that does is taken; a hash
outside an array is a broker's answer only.

## dbi_to_conninfo

`dbi_to_conninfo` reads the DBI form **as DBI and DBD::Pg read it**, each a
port of the source, step by step — it changes only against the source.
`t/53-dbi-to-conninfo.t` holds each case against DBI's `connect` and libpq's
parser:

- DBI (`dbi_dsn_parts`, DBI's own pattern): attributes in front of the DSN,
  `dbi:Pg(RaiseError=>1):...`, count over `\%extra` over `\%attrs`; `Username`
  and `Password`, when defined, replace `$user`/`$pass`. Of the attributes
  only those two and `pool_size` are read; the rest is dropped — there is no
  DBD here.
- DBD::Pg and libpq (`_dbd_pg_params`): `db=`/`database=` → `dbname=`, `;`
  outside single quotes → blank, a non-empty user/password appended behind
  the DSN's parameters, so they win over a `user=` in it; quotes, `\`
  escapes, blanks as separators, the later value of a keyword.

It dies, quoting nothing of the DSN, for what libpq cannot read, and leaves
the array it is given alone.

## No password in a message

The reader names forms, keys and the DBI driver; every text that names connect
info or passes on libpq's goes through core's
`DBIO::Util::mask_connect_secrets` — the DSN `dbi_to_conninfo` does not read,
the croak of `EV::Pg->new` and every `on_error` text (both in `Pool::_pg_new`,
where every handle is made). `t/65` holds every message.

## Broker

With a broker attached, `_async_broker_conninfo` asks it anew for every pool
spawn and every open of the listen connection, through core's
`_current_async_connect_info`, and refuses without a broker attached — what
core's seam answers then is no broker's answer. A broker selects `ev` in its
own attrs (`dbi_attrs => { async => 'ev' }` on Vault) or as
`connect($broker, { async => 'ev' })`.

`connect_info` keeps no conninfo from a broker's answer: `$self->{_conninfo}`
holds only static connect info. Whatever the `connect_info` before stored —
conninfo, pool size, options — is dropped before anything is read, so a call
that throws leaves nothing of it: refused static connect info leaves nothing to
connect from, a failed attach its broker with what stood beside it. A storage
whose broker is detached has nothing to connect from — never the answer of the
attach.

The transport declares `broker_connect_options`, so core hands it the options
beside a broker as `[ $broker, \%options ]`. The `connect_info` override takes
that form only through core's seams — never a reading of its own:
`_strip_private_connect_attrs` + `_access_broker_call_options` split the
options, `_access_broker_pool_size($read, $beside)` sizes the pool from the
answer as the reader read it (its hash, any attribute of a DBI-form answer,
beside the broker; answer and beside must agree or it throws naming
`pool_size`). DBD attributes beside the broker are dropped like the same keys
in DBI-form connect info. The declaration is a promise:
`t/51-access-broker-connect-options-mock.t` holds the behaviour behind it.

A connection parameter beside the broker (`sslmode`, `connect_timeout`, any
lowercase key that is no DBI attribute by core's measure: uppercase first
letter, `private_`, `dbi_`, `dbd_`, `pg_`) is refused, never dropped:
`_pg_refuse_parameters_beside_broker` refuses naming the keys, no value, from
`connect_info` and again from `_async_broker_conninfo` for every connection, so
a refused storage opens nothing. Through a schema that is the first `->async`,
not `connect`; the sync owner refuses it as well, where it opens its own dbh.
Such a parameter belongs in the broker's answer. A hash to every storage
connects the schema and reaches every pooled and the listen connection; only
the owner's dbh is not opened from it — the sync owner refuses a hash answer
with more than `dbname`/`host`/`port` where it connects (first dbh use, every
reconnect), not at `Schema->connect`. The DBI form with the parameter in the
DSN reaches both halves; `connect_info_for_storage` answers each its own.
