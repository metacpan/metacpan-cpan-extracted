# Concierge

Service layer orchestrator for user authentication, session management, and user data operations in Perl.

## Synopsis

```perl
use Concierge::Setup;
use Concierge;

# One-time desk setup
Concierge::Setup::build_quick_desk(
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

my $user = $login->{user};  # Concierge::User object
```

## Description

Concierge coordinates three component modules behind a single API:

- **Concierge::Auth** -- Argon2 password authentication
- **Concierge::Sessions** -- session management (SQLite or file backends)
- **Concierge::Users** -- user data storage (SQLite, YAML, or CSV/TSV backends)

It provides graduated user participation levels -- visitors, guests, and authenticated users -- each returning a `Concierge::User` object with methods appropriate to that level.

## Installation

Requires Perl 5.36 or later and the three component modules listed above.

```bash
perl Makefile.PL
make
make test
make install
```

## Modules

- **Concierge** -- Main orchestrator: lifecycle methods, admin operations
- **Concierge::Setup** -- One-time desk creation and configuration
- **Concierge::User** -- User object returned by lifecycle methods
- **Concierge::Base** -- Records-store base class for additional components

## Documentation

See the POD in each module for full API documentation:

```bash
perldoc Concierge
perldoc Concierge::Setup
perldoc Concierge::User
```

## Status

Under active development (v0.7.0). API may change before 1.0.

## Author

Bruce Van Allen <bva@cruzio.com>

## License

Artistic License 2.0
