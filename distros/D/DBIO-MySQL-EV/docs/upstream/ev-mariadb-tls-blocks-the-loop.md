# DRAFT -- not sent. Report to MariaDB Connector/C (libmariadb), copy to EV::MariaDB

Target: MariaDB Connector/C (CONC) issue tracker; for information also the
EV::MariaDB maintainer, because a one-line work-around exists on its side.

## Summary

With a TLS connection the non-blocking API (`mysql_real_query_start` /
`_cont`, `mysql_stmt_*_start` / `_cont`) never returns `MYSQL_WAIT_*`: the
`_start` call blocks until the server has answered. Over plain TCP the same
call returns at once with `MYSQL_WAIT_READ`. An event loop driving the
connection (EV::MariaDB) is therefore held for the whole round trip of every
statement.

## Cause

After the connect the socket of a TLS connection is in **blocking** mode
(measured: `O_NONBLOCK` is not set on `mysql_get_socket()`). In the sources of
v3.4.9 (libmariadb/secure/openssl.c, `ma_tls_connect`) the mode is only
touched before `SSL_connect`, and only when the socket is not blocking; the
socket is never made non-blocking for the later reads and writes. Plain TCP does not depend
on the socket mode: `pvio_socket_async_read` calls `recv(..., MSG_DONTWAIT)`.
The TLS path does: `ma_tls_read_async` / `ma_tls_write_async` call `SSL_read` /
`SSL_write` and suspend (`my_context_yield`) only on `SSL_ERROR_WANT_READ` /
`WANT_WRITE`. On a blocking fd OpenSSL never reports those, it blocks in the
kernel, so the suspension is never reached.

Evidence that the socket mode is the cause: setting `O_NONBLOCK` on
`mysql_get_socket()` after the connect, from the application, makes the TLS
case behave like plain TCP (table below).

## Reproduction (EV::MariaDB 0.08, Perl)

```perl
my $m = EV::MariaDB->new(host => ..., user => ..., password => ...,
                         database => ..., ssl_cipher => 'DEFAULT',   # TLS
                         on_connect => sub { $ready = 1 });
EV::run(EV::RUN_ONCE) until $ready;
my $ticks = 0;
my $timer = EV::timer(0.05, 0.05, sub { $ticks++ });
my $t0 = time;
$m->query('SELECT SLEEP(0.5)', sub { $inside = $in_query; $done = 1 });
$in_query = 0;      # set after query() returned
# measured: query() returns after 0.502 s, $inside is true, $ticks == 0
```

Without `ssl_cipher`: `query()` returns at once, callback runs later from the
loop, 10-11 ticks. Work-around check: `fcntl($fd, F_SETFL, O_NONBLOCK)` on
`$m->socket` after `on_connect` with `ssl_cipher => 'DEFAULT'`: query()
returns at once, 11 ticks.

## Numbers (`SELECT SLEEP(0.5)`, 50 ms timer, TLSv1.3 TLS_AES_256_GCM_SHA384)

| Server           | Transport | query() returned after | callback inside query() | ticks | TLS, `O_NONBLOCK` set by hand |
|------------------|-----------|------------------------|-------------------------|-------|-------------------------------|
| MySQL 8.0.30     | plain     | 0.000 s                | no                      | 11    |                               |
| MySQL 8.0.30     | TLS       | 0.502 s                | yes                     | 0     | 0.000 s, no, 11 ticks         |
| MariaDB 11.8.9   | plain     | 0.000 s                | no                      | 10    |                               |
| MariaDB 11.8.9   | TLS       | 0.502 s                | yes                     | 0     | 0.000 s, no, 11 ticks         |

The same holds for prepare / execute (observed in the transport on both servers)
and for a `CALL` that sleeps 0.4 s after its result set: settled after 0.002 s
over plain TCP, after 0.404 s over TLS. The handshake itself also does not
overlap (`ma_tls_connect` waits with `wait_io_or_timeout`, a blocking poll).

## Versions

- libmariadb 3.4.9 (sources read: upstream tag v3.4.9; Debian libmariadb3 1:11.8.6, OpenSSL 3 backend)
- EV::MariaDB 0.08 (0.09 uses the same `_start` / `_cont` calls)
- Servers: MySQL 8.0.30, MariaDB 11.8.9; both negotiate TLSv1.3

## Asks

- libmariadb: keep the socket non-blocking for the asynchronous TLS path (set
  it in `ma_tls_connect` only when no async context is in use, or restore the
  non-blocking mode once the handshake is done), or have `ma_tls_read_async` /
  `ma_tls_write_async` use a non-blocking read of their own. Document that
  the non-blocking API needs a non-blocking fd under TLS if that is by design.
- EV::MariaDB (meanwhile): after a successful connect, set `O_NONBLOCK` on
  `mysql_get_socket()`. Not verified against the whole test suite of
  EV::MariaDB, nor for `mysql_close_start` and the TLS shutdown.

## Work-around in DBIO::MySQL::EV (2026-10-23)

The transport applies the `O_NONBLOCK` ask itself (karr k85):
`DBIO::MySQL::EV::Pool::_mysql_new_handle` sets the flag on `$mdb->socket` in
`on_connect` (again after every `reset`) on every handle (karr k95; first only
when a `ssl_*` parameter was given -- over plain TCP the flag was measured to
change nothing, and without a `ssl_*` parameter libmariadb 3.4.9 negotiated no
TLS against either server).
Measured on MySQL 8.0.46 and MariaDB 11.8.9 (local containers): query and
prepare/execute leave the loop running (10 ticks per `SLEEP(0.5)`), reconnect
gets the flag again, `close_async`, `finish` and the TLS shutdown end in
milliseconds without an error and the server session is gone, a 6 MB result and
a 5 MB parameter go through whole. Not covered by it: the connect and the
handshake still block. This draft is unchanged otherwise and still not sent.
