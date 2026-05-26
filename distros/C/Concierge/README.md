# Concierge

Service layer orchestrator for authentication, session management, and user
data operations in Perl. Concierge combines three independent component
modules behind a single, consistent API so applications never deal with
credential storage, session backends, or user record schemas directly.

## Synopsis

```perl
use Concierge::Desk::Setup;
use Concierge;

# One-time desk setup
Concierge::Desk::Setup::build_quick_desk(
    './desk',
    ['role', 'theme'],       # application-specific user fields
);

# Runtime
my $desk = Concierge->open_desk('./desk');
my $concierge = $desk->{concierge};

# Register and log in a user
$concierge->add_user({
    user_id  => 'alice',
    moniker  => 'Alice',
    email    => 'alice@example.com',
    password => 'secret123',
    role     => 'admin',
});

my $login = $concierge->login_user({
    user_id  => 'alice',
    password => 'secret123',
});

my $user = $login->{user};  # Concierge::Desk::User object
say $user->moniker;         # "Alice"
say $user->session_id;      # random hex token
```

## How It Works

### Desks

A *desk* is a directory containing the configuration and data files for all
three components. You create one with `Concierge::Desk::Setup`, then open it at
runtime with `open_desk()`. Opening a desk instantiates all components from
the saved configuration and runs session cleanup automatically.

```perl
# One-time setup (run once, not on every request)
use Concierge::Desk::Setup;
Concierge::Desk::Setup->build_desk('./desk', {
    users_backend    => 'database',
    sessions_backend => 'sqlite',
    app_fields       => ['department', 'theme'],
});

# Every request
use Concierge;
my $result    = Concierge->open_desk('./desk');
my $concierge = $result->{concierge};
```

### User Participation Levels

Concierge provides three graduated levels, each returning a
`Concierge::Desk::User` object with methods appropriate to that level:

| Level | Method | Session | User record | Auth |
|---|---|---|---|---|
| Visitor | `admit_visitor()` | No | No | No |
| Guest | `checkin_guest()` | Yes | No | No |
| Logged-in | `login_user()` | Yes | Yes | Yes |

A guest can be promoted to a logged-in user with `login_guest()`, which
transfers any session data (shopping cart, preferences, etc.) to the new
authenticated session.

Between requests, users are restored by `user_key` (typically stored in a
cookie): `restore_user($user_key)` rehydrates the correct object type with
the right data and backend access.

## Component Capabilities

### Authentication — Concierge::Auth

- **Argon2id** password hashing and verification; no plaintext credentials
  written to disk
- Random value generators: hex IDs, alphanumeric tokens, UUIDs (v4),
  word-passphrases from a system dictionary
- Designed for substitution: swap in any replacement that implements the
  same method contract (`checkPwd`, `setPwd`, `resetPwd`, `deleteID`, etc.)
  for LDAP, OAuth, or other schemes

### Sessions — Concierge::Sessions

- **Multiple backends**: SQLite (recommended), flat-file, or in-memory text
- Sessions carry arbitrary key/value data (shopping carts, wizard state,
  preferences, etc.)
- Configurable timeout per session; expired sessions cleaned up automatically
  on `open_desk()`
- **Single-session-per-user** enforced at login: a new session replaces any
  prior session for that user
- Full lifecycle: create, get, update data, save, delete, cleanup

### User Records — Concierge::Users

- **Multiple backends**: SQLite, YAML, CSV/TSV
- **Configurable field schema**: built-in standard fields plus
  application-defined fields added at setup time

Standard fields include:

| Field | Notes |
|---|---|
| `user_id` | Required, unique identifier |
| `moniker` | Required, display name |
| `email`, `phone` | Contact fields |
| `access_level` | e.g. `admin`, `staff`, `member` |
| `user_status` | e.g. `OK`, `suspended` |
| `term_ends` | Membership/subscription expiry |
| `last_login_date` | Auto-updated on login |

Applications extend this with `app_fields` at setup time:

```perl
Concierge::Desk::Setup->build_desk('./desk', {
    app_fields => [
        { field_name => 'department', type => 'text' },
        { field_name => 'plan',       type => 'enum',
          options => ['free', 'pro', 'enterprise'] },
    ],
});
```

Field definitions can also override built-in defaults (labels, null values,
required flags, etc.) via `field_overrides`.

## Consistent Return Values

All Concierge methods return a hashref:

```perl
# Success
{ success => 1, message => '...', ... }

# Failure
{ success => 0, message => 'error description' }
```

Methods never `die` or `croak` during normal operation (the one exception is
`open_desk()`, which croaks if the desk directory does not exist). This makes
Concierge safe to use in event-loop and persistent-process environments.

## Extensibility

Each identity core component can be replaced with a conforming alternative.
Additional components (Organizations, Assets, Guides, Catalog, etc.) can be
added following the same conventions using `Concierge::Desk::Base` as a base class.

See the `EXTENSIBILITY` section in `perldoc Concierge` for the method
contracts and patterns for both substitution and extension.

## Installation

Installing `Concierge` from CPAN automatically installs the three component
distributions as dependencies:

```bash
cpanm Concierge
```

Or manually:

```bash
perl Makefile.PL
make
make test
make install
```

Requires Perl 5.36 or later.

## Documentation

```bash
perldoc Concierge          # orchestration API, lifecycle methods, extensibility
perldoc Concierge::Desk::Setup   # desk creation and configuration
perldoc Concierge::Desk::User    # user object methods
perldoc Concierge::Desk::Base    # base class for additional components
perldoc Concierge::Auth    # authentication and token generation
perldoc Concierge::Sessions  # session lifecycle and backends
perldoc Concierge::Users   # user records, field schema, backends
```

## Status

Under active development (v0.8.0). API may change before 1.0.

## Author

Bruce Van Allen <bva@cruzio.com>

## License

Artistic License 2.0
