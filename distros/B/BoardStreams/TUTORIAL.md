# BoardStreams mini-tutorial

This tutorial builds a small chat room to show both halves of BoardStreams:

- the **Mojolicious plugin**, the [BoardStreams](https://metacpan.org/dist/BoardStreams) distribution on CPAN, which runs on the server, and
- the **JavaScript client**, the [boardstreams](https://www.npmjs.com/package/boardstreams) package on npm, which runs in the browser.

Their sources are at <https://codeberg.org/gandalf/boardstreams-perl> and <https://codeberg.org/gandalf/boardstreams-js>.

## Which versions work together

The two halves work together when they speak the same **protocol version**. That is a whole number of its own, currently 1: `BoardStreams::PROTOCOL_VERSION` in Perl, and the `PROTOCOL_VERSION` export of the npm package. It only goes up when a release changes the protocol in a way that earlier releases cannot work with, and the change log of that release says so. The version numbers of the libraries themselves do not have to match, so you can upgrade either half alone as long as the protocol version stays the same.

This is enforced. The server announces its protocol version when a connection opens; a client that speaks another logs an error to the browser console naming both, refuses every join and request with the reason `protocol_mismatch`, and does not reconnect.

When a release does raise the protocol version, upgrade both halves at the same time. To avoid picking up such a release by accident, pin the versions you install:

```sh
cpanm BoardStreams@v0.0.56
npm install boardstreams@0.0.56
```

Releases up to 0.0.55 compared the library versions instead, and do not work with later ones.

## The model in one minute

- A browser opens one WebSocket and **joins** any number of **channels**.
- Each channel has a **state** object. Only the server changes it; every member's copy is kept up to date automatically.
- The server emits **events** on a channel; every member receives them, in order.
- Browsers talk to the server with **actions** (fire and forget) and **requests** (answered with a success payload or a failure).
- If a browser disconnects, it reconnects by itself and receives whatever it missed. Actions and requests sent meanwhile are delivered once the connection is back, and take effect exactly once.

## Requirements

- Perl 5.44, Mojolicious, Mojo::Pg and Future::AsyncAwait
- A PostgreSQL database (the plugin creates its `bs_*` tables itself)
- For the client, either npm (if your front end uses a bundler) or nothing at all (if you load it with a `<script>` tag)

## 1. The server

Save this as `chat.pl`:

```perl
#!/usr/bin/env perl
use v5.44;
use Mojolicious::Lite -signatures;
use Future::AsyncAwait future_class => 'Mojo::Promise';

my $hub = plugin BoardStreams => { pg => 'postgresql://user@localhost/mydb' };

$hub->channel('chat:*',
    initial_state => { topic => 'Welcome', messages => [] },

    # Runs on every join, including every automatic rejoin.
    join => sub ($ctx) {
        $ctx->reject('members_only') if $ctx->channel eq 'chat:staff';
        return 1;
    },

    actions => {
        typing => sub ($ctx, $payload) {
            $ctx->emit(typing => { name => $payload->{name} });
        },
    },

    requests => {
        say => async sub ($ctx, $payload) {
            my $text = $payload->{text} // '';
            $ctx->reject('too_long', { max => 200 }) if length $text > 200;

            my $count;
            await $ctx->update(sub ($u) {
                push $u->state->{messages}->@*, { name => $payload->{name}, text => $text };
                $count = $u->state->{messages}->@*;
                $u->emit(said => { name => $payload->{name} });
            });
            return { count => $count };
        },
    },
);

get '/' => 'index';

app->start;
```

What each part does:

- **`plugin BoardStreams`** returns the *hub* and adds a WebSocket route at `/boardstreams`. The hub is also available anywhere as `$c->boardstreams` or `app->boardstreams`.
- **`$hub->channel($pattern, ...)`** registers handlers for one channel name, or for a family of names when the pattern contains `*` (see [Channel patterns](#channel-patterns)).
- **`initial_state`** is what a channel's state starts as, the first time anyone touches it.
- **`join`** accepts a browser by returning true. Returning false refuses it with the reason `forbidden`.
- **Handlers** receive a context object, `$ctx`, and may be plain or `async` subs.

### Channel patterns

A pattern without `*` covers exactly one channel name. There are two wildcards:

- `*` stands for any run of characters **other than a colon**, so it covers one colon-separated part of a name.
- `**` stands for any run of characters **at all**, colons included, so it covers any number of parts.

| Pattern | Covers | Does not cover |
|---|---|---|
| `lobby` | `lobby` | `lobby2` |
| `chat:*` | `chat:lobby`, `chat:` | `chat`, `chat:eu:lobby` |
| `chat:*:*` | `chat:eu:lobby` | `chat:lobby`, `chat:a:b:c` |
| `game:*:chat` | `game:42:chat` | `game:4:2:chat` |
| `*:admin` | `users:admin` | `a:b:admin` |
| `file*` | `file`, `file-1.txt` | `file:1` |
| `chat:**` | `chat:lobby`, `chat:eu:lobby`, `chat:` | `chat`, `chats:lobby` |
| `**:admin` | `users:admin`, `a:b:admin` | `admin`, `users:admins` |
| `game:**:chat` | `game:42:chat`, `game:4:2:chat` | `game:chat` |
| `**` | every name | |

The rules behind the table:

- **Either wildcard may cover nothing**, which is why `chat:*` and `chat:**` cover `chat:`.
- **A `*` never covers a colon.** Use one `*` per part, or `**` for any number of parts.
- **The literal parts are still required.** `game:**:chat` needs both colons, so it does not cover `game:chat`.
- **Wildcards can appear anywhere**, and more than once.
- **Every other character is literal**, including `.`, `?` and `+`.

If several patterns cover a name, the most specific one is used, decided in this order:

1. A pattern that is exactly the name.
2. The pattern with the most literal (non-wildcard) characters. With `chat:*:*` and `chat:eu:*` both registered, `chat:eu:berlin` uses `chat:eu:*`.
3. The pattern with the fewest `**`. With `chat:*` and `chat:**` both registered, `chat:lobby` uses `chat:*`, and `chat:eu:lobby` uses `chat:**` because only that one covers it.
4. The pattern registered first.

A lone `**` is therefore a catch-all that applies only to names nothing else covers.

A name that no pattern covers cannot be joined; the browser gets the reason `unknown_channel`.

### The context object

| Call | Meaning |
|---|---|
| `$ctx->channel` | The channel's name, e.g. `chat:lobby` |
| `$ctx->c` | The WebSocket's Mojolicious controller (sessions, stash, helpers) |
| `$ctx->update(sub ($u) { ... })` | Change the state and/or emit events, atomically |
| `$ctx->emit($name, $payload)` | Emit one event without changing the state |
| `$ctx->reject($reason, $data)` | Refuse the join, or fail the request, with something the browser can read |
| `$ctx->user` | Who the connection belongs to, if the `identify` option is set (see [Kicking and disconnecting users](#kicking-and-disconnecting-users)) |
| `$ctx->kick($reason, $data)` | Remove this browser from the channel |
| `$ctx->disconnect($reason, $data)` | Close this browser's connection for good |

`update` and `emit` return promises; `await` them in an `async` handler.

### Changing state

Inside the `update` callback, `$u->state` is the channel's current state. Change it in place, or replace it with `$u->state($new)`. Queue events with `$u->emit($name, $payload)`. The state change and its events are committed together and reach every member as one step.

### Authorisation

The join handler has the controller, so it can check the session:

```perl
join => sub ($ctx) {
    my $user = $ctx->c->session('user') or $ctx->reject('login_required');
    return 1;
},
```

### Updating a channel from elsewhere

Any part of the application can change a channel or emit on it, for example an ordinary HTTP action:

```perl
post '/admin/topic' => sub ($c) {
    my $topic = $c->param('topic');
    $c->boardstreams->update('chat:lobby', sub ($u) { $u->state->{topic} = $topic })
        ->then(sub { $c->render(text => 'ok') });
    $c->render_later;
};

# or just an event:
app->boardstreams->emit('chat:lobby', 'announcement', { text => 'Back in 5 minutes' });
```

### Kicking and disconnecting users

The server can remove a user from a channel, or close their connection altogether. For that it has to know which connections belong to which user, so give the plugin an `identify` option: a sub that receives the WebSocket's controller when a browser connects and returns something that identifies the user, typically from the session.

```perl
my $hub = plugin BoardStreams => {
    pg       => $pg,
    identify => sub ($c) { $c->session('user_id') },
};
```

Returning `undef` marks the connection as anonymous. Then, from anywhere in the application:

```perl
# Out of one channel. The reason and data are optional.
$c->boardstreams->kick($user_id, 'chat:lobby', 'spam', { strikes => 3 });

# Close every connection the user has.
$c->boardstreams->disconnect($user_id, 'banned', { days => 7 });

# Everyone out of one channel, whoever they are.
$c->boardstreams->kick_all('chat:lobby', 'closing_time', { reopens => 'tomorrow' });
```

All three return promises. `kick` and `disconnect` reach **all** of the user's browsers, on every server process. A handler can also act on just the browser it is serving, with `$ctx->kick(...)` and `$ctx->disconnect(...)`; those need no `identify`.

`kick_all` removes every member of the channel, on every server process, including anonymous ones, so it needs no `identify`. Each browser experiences it exactly as a `kick` (its default reason is also `kicked`). The channel itself is untouched: it keeps its state and history, and browsers may ask to join again, which is for the `join` handler to refuse if the channel is meant to stay empty.

What the browser experiences:

| | Kick | Disconnect |
|---|---|---|
| The channel's `status$` | `'rejected'` | `'rejected'`, for every channel |
| Unanswered requests | Reject with your reason and data | Same |
| The connection | Stays open; other channels carry on | Closed; `bs.status$` becomes `'closed'` |
| Reconnecting | Not applicable | The client does not reconnect |
| Default reason | `kicked` | `disconnected` |

Things to keep in mind:

- **Neither is a ban by itself.** A kicked browser can ask to join again, and a disconnected user can reload the page. Whether they get back in is decided by your `join` handler, which runs every time, so record the ban somewhere it checks.
- **The identity is read once, when the browser connects.** If the user logs in or out later on the same connection, BoardStreams still knows it by the earlier answer.
- **Keep the reason and data small.** They travel between server processes in a PostgreSQL notification, which holds under 8000 bytes; anything bigger is refused with an error.
- **A server process that cannot hear PostgreSQL at that moment does not receive the instruction.** It does not need to: such a process has already let go of all its browsers (see [What happens when things break](#3-what-happens-when-things-break)), and when they come back the `join` handler decides. So after an outage a kick is not replayed; the user is back in unless `join` refuses.

### Deleting a channel

A channel's row, with its state, stays in the database for as long as you leave it there. To get rid of one:

```perl
$c->boardstreams->delete_channel('chat:old-room', 'archived', { by => 'admin' });
```

It returns a promise of whether there was anything to delete. The reason and data are optional; the reason defaults to `deleted`. What it does:

- **Deletes the channel's state, its event history and its recorded request ids.** The last two go with the row automatically, through foreign keys.
- **Removes every member, on every server process, and tells them.** Each browser experiences it as a `kick`: the channel's `status$` becomes `'rejected'` and unanswered requests reject with the reason.
- **Leaves the name free.** If the channel is joined or updated again, it starts afresh from its `initial_state`. To keep people out, have the `join` handler refuse them.

Two details are worth knowing:

- **A new channel does not start counting from zero once any channel has been deleted.** Sequence numbers of deleted channels are never reused; a new channel starts above the highest number any deleted channel reached. That way a browser that comes back much later with its old position is recognised as out of date and given the fresh state, with `gaps$` emitting, instead of being sent the new channel's updates as if they continued the old one. Only the order of the numbers means anything.
- **Deleting the row yourself, with SQL, is safe but less tidy.** The history and request ids still go with it, and the numbering rule still holds. Members are not told at once, though: each keeps showing the old state until the channel's next update, at which point it is given the fresh state, with `gaps$` emitting. `delete_channel` tells them straight away.

### Plugin options

| Option | Default | Meaning |
|---|---|---|
| `pg` | required | A connection string or a `Mojo::Pg` object |
| `route` | `/boardstreams` | Path of the WebSocket route |
| `routes` | `app->routes` | Route object to attach it to, e.g. one behind an `under` |
| `retention` | `3600` | Seconds that event history and request IDs are kept |
| `heartbeat_interval` | `25` | Seconds between heartbeats to each browser |
| `retry_delay` | `1` | Seconds between retries while PostgreSQL is unreachable |
| `listener_check_interval` | `5` | Seconds between checks that the process still receives PostgreSQL notifications |
| `lazy_migrate` | false | If true, do not create the tables at startup (see below) |
| `identify` | none | Sub that says who a connection belongs to; needed for `kick` and `disconnect` by user |

By default the plugin creates its tables (`bs_channel`, `bs_event`, `bs_request`, `bs_floor`, plus Mojo::Pg's `mojo_migrations` if it is not there yet) as soon as it is loaded, which also means it connects to PostgreSQL at startup. With `lazy_migrate => 1` it does neither until the tables are first needed: when a browser joins a channel, or when your code calls `update`, `emit` or `snapshot`.

```perl
plugin BoardStreams => { pg => $pg, lazy_migrate => 1 };
```

That is useful when the application is also loaded where BoardStreams is never used, such as by command-line tools or tests, or when it must be able to start while the database is down. The price is that the first join or update in each server process takes slightly longer.

## 2. The client

The client is the `boardstreams` package on npm. It comes in two builds:

- an ES module for projects that use a bundler, which is what `import` gives you, and
- `dist/index.iife.js`, a single file for a plain `<script>` tag, with RxJS included.

### With a bundler

```sh
npm install boardstreams
```

```js
import { BoardStreams } from 'boardstreams';

const scheme = location.protocol === 'https:' ? 'wss' : 'ws';
const bs = new BoardStreams(`${scheme}://${location.host}/boardstreams`);

const chat = bs.join('chat:lobby');
```

### With a script tag

No build step is needed. Save the single-file build as your application's `public/boardstreams.js`, for example:

```sh
curl -L -o public/boardstreams.js https://unpkg.com/boardstreams@0.0.56/dist/index.iife.js
```

If you have installed the package with npm, the same file is at `node_modules/boardstreams/dist/index.iife.js`. You can also skip the copy and load it straight from the CDN with `<script src="https://unpkg.com/boardstreams@0.0.56"></script>`, at the cost of depending on that service. Keep the version in that address: without one the CDN serves the latest release, which stops working with your server if it ever speaks a newer protocol version.

The file defines one global, `BoardStreams`, which holds the library's exports, so the class is `BoardStreams.BoardStreams`.

Add this to `chat.pl`, after `app->start;`:

```perl
__DATA__

@@ index.html.ep
<!DOCTYPE html>
<h1 id="topic"></h1>
<ul id="messages"></ul>
<form id="form"><input id="text" autocomplete="off"><button>Send</button></form>
<p id="status"></p>

<script src="/boardstreams.js"></script>
<script>
  const scheme = location.protocol === 'https:' ? 'wss' : 'ws';
  const bs = new BoardStreams.BoardStreams(`${scheme}://${location.host}/boardstreams`);
  const chat = bs.join('chat:lobby');
  const name = 'guest' + Math.floor(Math.random() * 1000);

  // Runs with the current state as soon as it is known, then on every change.
  chat.state$.subscribe((state) => {
    document.querySelector('#topic').textContent = state.topic;
    document.querySelector('#messages').replaceChildren(
      ...state.messages.map((message) => {
        const li = document.createElement('li');
        li.textContent = `${message.name}: ${message.text}`;
        return li;
      }),
    );
  });

  chat.on('typing').subscribe((payload) => {
    document.querySelector('#status').textContent = `${payload.name} is typing…`;
  });

  document.querySelector('#text').addEventListener('input', () => chat.action('typing', { name }));

  document.querySelector('#form').addEventListener('submit', async (event) => {
    event.preventDefault();
    const input = document.querySelector('#text');
    try {
      const response = await chat.request('say', { name, text: input.value });
      input.value = '';
      document.querySelector('#status').textContent = `${response.count} messages so far`;
    } catch (error) {
      document.querySelector('#status').textContent =
        error.reason === 'too_long' ? `At most ${error.data.max} characters` : `Failed: ${error.reason}`;
    }
  });
</script>
```

Run it with `perl chat.pl daemon` and open the page in two browser windows.

### The channel object

| Member | Meaning |
|---|---|
| `chat.state$` | Observable of the state; replays the latest value to new subscribers |
| `chat.state` | The current state, or `undefined` before the first join completes |
| `chat.events$` | Observable of every event, as `{ name, payload, seq }` |
| `chat.on(name)` | Observable of the payloads of events with that name |
| `chat.action(name, payload)` | Sends an action; returns nothing |
| `chat.request(name, payload)` | Sends a request; returns a promise of the response payload |
| `chat.joined()` | Promise that resolves on the first successful join |
| `chat.status$` | `'joining'`, `'joined'`, `'rejected'` or `'left'` |
| `chat.gaps$` | Emits when events were missed for good (see below) |
| `chat.leave()` | Ends this use of the channel (see below) |

The connection object has `bs.status$` (`'connecting'`, `'connected'`, `'disconnected'`, `'idle'`, `'closed'`) and `bs.close()`.

**No channels, no connection.** When no channel has been joined for 30 seconds, the client closes its connection and `bs.status$` becomes `'idle'`; the next `bs.join` opens one again. The `idleDelay` option changes that time (in milliseconds), and `idleDelay: null` keeps the connection open regardless.

**Joining a channel more than once.** Every call of `bs.join` returns a channel object of its own, and the objects for one name share a single membership on the server: the channel is joined once, and each event travels over the WebSocket once. `leave()` ends only the object it is called on, and the client leaves the channel on the server when the last of them has left. So separate parts of a page can each join `chat:lobby` when they appear and leave it when they go, without knowing about each other. Call `leave()` once on every object you get from `join`; an object that is dropped without it keeps the channel joined. The Perl client works the same way.

The observables are RxJS observables, so they work with RxJS operators:

```js
import { distinctUntilChanged, map } from 'rxjs';

chat.state$
  .pipe(map((state) => state.topic), distinctUntilChanged())
  .subscribe((topic) => (document.title = topic));
```

Each state value is a new object, and the parts that did not change are shared with the previous one, so comparing by identity is a cheap way to see what changed.

### Knowing when a channel is joined

The server answers a join with one message that carries the channel's current state. From that moment the browser is a member: every later update reaches it, with nothing lost in between. There are three ways to observe this, and they differ in what happens on later rejoins:

| Signal | Fires | Use it for |
|---|---|---|
| `await chat.joined()` | Once, on the first successful join; rejects if the join is refused | "The channel is ready" |
| `chat.status$` emitting `'joined'` | On every join, including each automatic rejoin after a reconnection | Showing live connection state |
| First value of `chat.state$` | At the same moment as the first join | Rendering; not a join signal after that |

```js
await chat.joined();                 // resolves once
console.log(chat.state.topic);       // the state is available from here on

chat.status$.subscribe((status) => {
  // 'joining' while disconnected, 'joined' again after each rejoin
  document.body.classList.toggle('offline', status !== 'joined');
});
```

Do not use `state$` to detect rejoins: when nothing was missed while the browser was away, the server sends no state and `state$` does not emit, while `status$` still returns to `'joined'`.

What "joined" means for events:

- **Events from before the first join are not delivered.** You get the current state, then events from that point on.
- **On a rejoin, missed events are replayed first.** They arrive through `events$`, in order, before `status$` returns to `'joined'`.

### Requests settle after the state has caught up

When `await chat.request(...)` returns, `chat.state` already includes whatever that request changed on the channel, and its events have already been delivered:

```js
await chat.request('say', { name, text: 'hello' });
console.log(chat.state.messages.at(-1).text);   // "hello"
```

### Using a channel before it is joined

You do not have to wait for the join before using a channel. Actions and requests made right after `bs.join(...)` are held in the client and sent as soon as the server confirms the join:

```js
const chat = bs.join('chat:lobby');
const response = await chat.request('say', { name, text: 'first!' });   // sent once joined
```

- **If the join is refused**, the held requests are never sent. Their promises reject with the join's reason (for example `members_only`). Held actions are dropped silently, since an action has no promise to reject.
- **If the connection is down**, they wait through the reconnection attempts and are sent after the eventual join.
- **There is no timeout.** A request waits for as long as it takes. If you want a limit, race the promise against a timer:

```js
const timeout = new Promise((_, reject) => setTimeout(() => reject(new Error('timed out')), 5000));
const response = await Promise.race([chat.request('say', { name, text }), timeout]);
```

Giving up this way only stops your code from waiting; the request itself is still delivered when the connection returns.

### Failures

A refused join rejects `joined()`, and a failed request rejects its promise, with a `BoardStreamsError` that has a `reason` and optional `data`:

```js
bs.join('chat:staff').joined().catch((error) => {
  console.log(error.reason);   // "members_only"
});
```

Reasons you choose yourself come from `$ctx->reject`. The library uses these:

| Reason | When |
|---|---|
| `unknown_channel` | No registered channel matches the name, or it has no `join` handler |
| `forbidden` | The join handler returned false |
| `unknown_request`, `unknown_action` | No handler with that name |
| `internal_error` | A handler died; the real message is in the server log only |
| `left`, `rejected` | The channel was left, or its join refused, before the request was answered |
| `protocol_mismatch` | The client and the server speak different protocol versions; `error.data` is `{ client, server }` |
| `kicked`, `disconnected` | The server removed the browser from the channel, or closed its connection, without giving a reason of its own |
| `deleted` | The server deleted the channel, without giving a reason of its own |

## A client in Perl

The distribution also contains `BoardStreams::Client`, a Perl port of the JavaScript client, for programs that want to take part in channels without a browser: other services, command-line tools, tests of your own application. It behaves the same way, including reconnecting, catching up, exactly-once requests and the protocol version check.

```perl
use Mojo::Base -strict, -signatures;
use BoardStreams::Client;
use Mojo::IOLoop;

my $bs   = BoardStreams::Client->new(url => 'ws://localhost:3000/boardstreams');
my $chat = $bs->join('chat:lobby');

$chat->state_o->subscribe(sub ($state) { say scalar $state->{messages}->@*, ' messages' });
$chat->on('typing')->subscribe(sub ($payload) { say "$payload->{name} is typing" });

$chat->action(typing => { name => 'bot' });
$chat->request(say => { name => 'bot', text => 'hello from Perl' })->then(
    sub ($response) { say "$response->{count} messages so far" },
    sub ($error)    { say 'failed: ', $error->reason },
);

Mojo::IOLoop->start;
```

What differs from the JavaScript client is only what the language makes differ:

| JavaScript | Perl |
|---|---|
| `new BoardStreams(url, { minDelay, maxDelay, idleDelay })`, delays in milliseconds | `BoardStreams::Client->new(url => ..., min_delay => ..., max_delay => ..., idle_delay => ...)`, delays in seconds |
| `state$`, `events$`, `gaps$`, `status$` (RxJS) | `state_o`, `events_o`, `gaps_o`, `status_o` (RxPerl) |
| `state`, `on(name)`, `action`, `request`, `joined()`, `leave()`, `close()` | The same names |
| Promises | `Mojo::Promise` objects |
| `BoardStreamsError` with `reason` and `data` | `BoardStreams::Client::Error` with `reason` and `data` methods |
| A protocol mismatch is logged with `console.error` | It is reported with `warn` |

It runs on the Mojolicious event loop, so inside a Mojolicious application it needs nothing more; a standalone script starts the loop itself, as above. Its own documentation is in `perldoc BoardStreams::Client`.

## 3. What happens when things break

You do not write code for any of this; it is useful to know what to expect.

- **The connection drops, or goes silent.** The client reconnects with a growing delay (0.5 seconds doubling up to 30, each shortened at random by up to half) and rejoins every channel. The join handler runs again.
- **Missed updates.** On rejoining, the server replays what the browser missed, in order. `state$` and `events$` simply continue.
- **Away for longer than `retention`.** The history is gone, so the browser gets the current state in one piece and `gaps$` emits. Events from the gap are lost; the state is correct.
- **Actions and requests sent while offline.** They are queued and sent after rejoining. Anything sent but not confirmed before the drop is sent again, and the server recognises the repeat, so it takes effect once.
- **A server process loses PostgreSQL.** A process that cannot receive PostgreSQL's notifications would miss updates, kicks and disconnects, so it serves nobody: it closes all its WebSocket connections and refuses new ones until it hears PostgreSQL again. Browsers see a disconnection, keep retrying, and catch up when they get back in. This covers a PostgreSQL restart, a broken connection, and a connection that died silently, which each process detects by sending itself a notification every `listener_check_interval` seconds and checking that it arrives.
- **What that costs.** A PostgreSQL restart is visible to every user as a short disconnection, and all browsers rejoin within the same half minute or so afterwards, each rejoin running a join handler and a query. The random part of the client's delay spreads that out.
- **Several server processes.** Members of a channel can be connected to different worker processes or machines sharing the database; all of them receive every update.

React to a gap only if your page depends on events and not just on state:

```js
chat.gaps$.subscribe(() => showNotice('Some activity was missed while you were away'));
```

## Stopping and deploying

Mojolicious can stop a server in two ways, and BoardStreams is quick in both.

- **A graceful stop** is what the `QUIT` signal asks for, what hypnotoad does to its old workers in a hot deployment, and what happens to a worker that has served its share of connections. The server stops accepting connections and waits for the open ones to end, for up to its `graceful_timeout` (two minutes by default). A WebSocket never ends by itself, so when such a stop begins the plugin closes its WebSocket connections at once, and the process exits in about a second.
- **An immediate stop** is what `TERM` and `INT` ask for. Connections are simply cut.

Either way, browsers experience an ordinary lost connection. They are not told to stay away: they reconnect by themselves, to whichever process answers (another worker, or the new server once it is up), rejoin their channels and receive what they missed. A request or action that was on its way, or in the middle of being handled, is sent again and takes effect once.

So a deployment needs nothing special from your code. Ordinary HTTP requests are another matter: only a graceful stop lets the ones in progress finish, which is the reason to prefer it.

**With Docker.** `docker stop` sends `TERM` unless told otherwise, which is the immediate stop. For a graceful one, make the stop signal `QUIT`:

```yaml
services:
  web:
    command: ["perl", "app.pl", "prefork", "-m", "production"]
    stop_signal: SIGQUIT
```

or `STOPSIGNAL SIGQUIT` in the Dockerfile. The server must be the container's main process for the signal to reach it, so start it with the list form of `command` or `CMD` shown above, not through a shell. A container that takes its whole `stop_grace_period` to stop and is then killed is the sign of a graceful stop that something is holding up; BoardStreams connections no longer do.

## Upgrading

- **Upgrade all server processes together.** The client only needs upgrading with them when the new release raises the protocol version (see "Which versions work together"); in that case a mix of old and new processes leaves some browsers unable to connect.
- **The tables are upgraded automatically** by the first process of the new version that needs them (or when it loads, without `lazy_migrate`). If several start at once, one does the work and the others wait.
- **A process left running old code retires itself.** Each process announces the schema version it works with, when it has upgraded the tables and every few seconds after. A process that hears a higher version than its own code knows closes its WebSocket connections, refuses new ones, and fails every `update`, `emit` and `snapshot` with an error, until it is restarted with the new code. It logs an error saying so. This protection exists from the version that introduced it onwards; processes older than that do not listen for the announcement.
- **Several applications can share one database** if each keeps its BoardStreams tables in its own PostgreSQL schema (through the connection's search path). They do not hear each other's kicks, deletions or version announcements.

## Known limitations

- If a worker dies after committing a request's update but before recording its response, a resent copy of that request succeeds with a `null` payload.
- A change to an array that is not an append sends the whole array to members, so keep large arrays append-only where you can.
