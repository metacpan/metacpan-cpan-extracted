# AccessBroker

Reference for `dbio-core`. Load when connecting through a broker or writing one. The
driver-side obligations (DSN form, async conninfo, listen seams) are in
`dbio-driver-development`, `references/async-transport.md`.

A broker answers a connection's details — which database, and as whom. Pass it to `connect` in place of a DSN; the storage asks it again for every new connection.

```perl
use DBIO::AccessBroker::Static;

my $broker = DBIO::AccessBroker::Static->new(
  host     => 'localhost',
  dbname   => 'myapp',
  username => 'myapp',
  password => 'secret',
);

my $schema = MyApp::Schema->connect($broker);   # MyApp::Schema loads its driver component

# the connect options go beside the broker
my $schema = MyApp::Schema->connect($broker, {
  async         => 'future_io',
  on_connect_do => [ 'SET search_path TO app' ],
});
```

## Interface

A broker is a **CredentialSource**: one backend identity, one set of credentials. It does not route and owns no host list — routing and topology belong to `DBIO::Replicated`. See `CONTEXT.md`.

| Method | Returns | Purpose |
|--------|---------|---------|
| `connect_info_for` | HASHREF or ARRAYREF | The answer: connection parameters `{dbname, host, port, user, password}`, or DBI form `[$dsn, $user, $password, \%attrs]` |
| `connect_info_for_storage($storage)` | same | Storage-aware version; default delegates to `connect_info_for` |
| `needs_refresh` | Bool | True if credentials need rotation |
| `refresh` | - | Perform credential rotation |
| `has_rotating_credentials` | Bool | True if credentials rotate |
| `is_transaction_safe` | Bool | False if rotating (default) |
| `for_host($host)` | broker view | One credential, pinned to one host (HostBound) |

A subclass implements `connect_info_for` (the base throws) or overrides `connect_info_for_storage`; the rest have defaults. Routing decides read vs write, not the broker; a broker answers one set of credentials.

## Implemented brokers

| Broker | Answers | Use Case |
|--------|---------|----------|
| `DBIO::AccessBroker::Static` | connection parameters | Fixed details, transaction-safe |
| `DBIO::AccessBroker::Vault` | DBI form, `dbi_attrs` as `\%attrs` | TTL-based credential rotation |
| `DBIO::AccessBroker::HostBound` | its broker's shape, host/port bound in (DBI form: through the driver's `_bind_host_into_dsn`, which refuses forms it cannot translate) | One credential pinned to one host (via `for_host`) |

## Storage integration

Broker form is `[ $broker ]` or `[ $broker, \%options ]` (`_is_access_broker_connect_info`). `connect_info` attaches the broker (`set_access_broker`), asks it (`current_connect_info_for_storage`) and normalises the answer like any other connect info; `_connect` asks again for every connection, so rotated credentials reach the next one.

- **An answer without a DSN** (connection parameters): the storage builds the DSN for the one DBD its class is registered for (`register_driver`), leaving out parts not given. The form is the driver storage's seam `_connect_params_dsn($driver, \%params)` (ADR 0057) — default `dbi:<DBD>:dbname=…;host=…;port=…`; core's ODBC storage refuses (no driver/data-source name to build from). The schema always declares its driver (ADR 0059, 0067), so the DBD is that driver's. A `dbname` that starts with `dbi:` is taken as the DSN; `host`/`port` beside it throw (they cannot go into it).
- **Options beside the broker** take what the attribute hash of every other connect form takes: DBI attributes, the DBIO connection attributes (`on_connect_do`, `quote_names`, …), `async`, `pool_size`. The connection itself — `dsn`, `user`, `password`, `dbh_maker`, `dbname`, `host`, `port` — is the broker's answer and throws beside it. This is how a broker answering connection parameters gets an async mode or any option at all.
- **A setting in both places** — beside the broker and in a DBI-form answer (Vault's `dbi_attrs`) — has the same value (same plain value, both undef, or the very same reference), or the connect throws naming the setting, never its values (`_merge_access_broker_settings`). Checked in `connect_info` and again in every `_connect`.
- **Static connect info names its DSN** (ADR 0057 addenda): a hash needs `dsn` or `dbname`, connect info without DSN, broker or coderef throws, `$ENV{DBI_DSN}` / `$ENV{DBI_DRIVER}` never stand in. A DSN with an empty driver part (`dbi::…`) throws; a schema that only generates SQL connects with `connect('dbi:Pg:')`.
- **Connect key `schema`** (ADR 0065) names the namespace of a connection; a driver with namespaces implements `_set_connection_schema`, one without refuses the key.
- **With an async mode**, `pool_size` stays out of the owner's `DBI->connect`. The embedded backend gets `[ $broker ]` while the options hold only what the owner applies (mode, storage and SQL maker options; pooled connections replay `on_connect_*` from the owner). DBD attributes or `pool_size` beside the broker reach the backend as `[ $broker, \%options ]` only if its transport declares `broker_connect_options` in `transport_capabilities`; any other transport throws at first async use. `DBIO::Storage::Async::connect_info` takes that form: `pool_size` sizes the pool, the DBD attributes wait in `_access_broker_call_attributes` for the transport to merge into each connection.

`DBIO::Replicated` passes a broker (or a `for_host` view) through the master/replicant connect paths by identity — never merged into an options hash — and each backend, a storage of the declared driver, consumes it. The guard predicate is `DBIO::Util::is_access_broker($x)`.
