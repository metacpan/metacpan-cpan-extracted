# Concierge::Auth

Concierge authorization framework - production-ready authentication and authorization with substitutable backends.

## VERSION

v0.5.2

## DESCRIPTION

Concierge::Auth provides comprehensive user authentication and authorization capabilities through a substitutable backend architecture — any backend implementing the same contract (LDAP, OAuth, etc.) can be swapped in. Token generation is available independent of the backend in use. The bundled `Concierge::Auth::Pwd` backend implements file-based password authentication using Crypt::Passphrase; see "Built-in Authentication" below.

## FEATURES

- **Substitutable Backends**: swap in any backend implementing the
  `Concierge::Auth::Base` contract (LDAP, OAuth, etc.)
- **Token Generation**: Generate cryptographically secure tokens and UUIDs
- **Generator Architecture**: Extensible generator system for tokens and identifiers
- **Built-in Backend**: a password-file backend (`Concierge::Auth::Pwd`)
  ships with this distribution — see "Built-in Authentication" below

## MODULE STRUCTURE

- **Concierge::Auth** - Backend factory / facade
- **Concierge::Auth::Base** - Backend contract that all backends implement
- **Concierge::Auth::Pwd** - Built-in password-file backend
- **Concierge::Auth::Generators** - Token and identifier generation system

## INSTALLATION

From source:
```bash
perl Makefile.PL
make
make test
make install
```

From CPAN:
```bash
cpanm Concierge::Auth
```

## QUICK START

```perl
use Concierge::Auth;

my $auth = Concierge::Auth->new(
    backend_class => 'Concierge::Auth::Pwd',
    file          => '/path/to/users.passwd',
);

my $result = $auth->enroll($user_id, $password);
my $result = $auth->authenticate($user_id, $password);
my $result = $auth->is_id_known($user_id);
my $result = $auth->change_credentials($user_id, $new_password);
my $result = $auth->revoke($user_id);

# Generators -- work with or without a file
# (backend_class => 'Concierge::Auth::Pwd', no_file => 1)
my $token = $auth->gen_random_token();
my $uuid  = $auth->gen_uuid();
```

Each of the five core methods above returns a hashref: `{ success => 1, ... }`
on success, or `{ success => 0, message => '...' }` on failure. See
`Concierge::Auth::Base` for the full contract.

## Built-in Authentication (Concierge::Auth::Pwd)

`Concierge::Auth::Pwd` is the password-file backend bundled with this
distribution — the `backend_class` used in the example above.

- **Password Management**: Argon2 encoder (via Crypt::Passphrase) with a
  Bcrypt fallback validator for legacy password verification
- **File-based Authentication**: encrypted passwords stored in a plain
  password file, never in plaintext
- **File Locking**: proper `flock()` support for concurrent access
- **Password Utilities**: password strength validation, on top of the
  random string/token generators shared with all backends
- **Flexible**: works with or without a password file (`no_file => 1`)
  when only the generator methods are needed

Password security defaults:
- Primary encoder: Argon2 (memory-hard, resistant to GPU/ASIC attacks)
- Fallback validator: Bcrypt (for backward compatibility)
- Password length: 8-72 characters (bcrypt limit)
- User ID validation: 2-32 characters, alphanumeric plus `. _ @ -`

See `perldoc Concierge::Auth::Pwd` for the full backend documentation.

The generator methods (`gen_random_token`, `gen_uuid`, etc.) are different:
they follow a `wantarray` `(value)` / `(value, message)` dual-return
convention rather than returning a hashref, so context matters:

```perl
my ($token, $msg) = $auth->gen_random_token();  # list context
my $token          = $auth->gen_random_token();  # scalar context: $msg discarded
```

## REQUIREMENTS

- Perl 5.36 or higher
- Carp
- Fcntl
- Crypt::Passphrase
- Crypt::PRNG
- parent
- Exporter
- Test2::V0 (for testing)

## PRODUCTION USE

Concierge::Auth is actively used in production environments. Key features for production:

- **Error Handling**: Comprehensive error checking and reporting
- **Token Security**: Cryptographically secure random token generation

See "Built-in Authentication" above for production-hardening details
specific to the bundled `Concierge::Auth::Pwd` backend (file locking,
secure password defaults).

## INTEGRATION

Concierge::Auth also integrates with the Concierge ecosystem:
- **Concierge::Users** - User data management
- **Concierge::Sessions** - Session management

These modules together form the core of the Concierge service layer, providing:
- Authentication (Concierge::Auth)
- User data management (Concierge::Users)
- Session tracking (Concierge::Sessions)

## EXAMPLES

The `examples/` directory currently contains one example:

- `1-custom-backend-ldap.pl` - sketch of a directory-backed (LDAP)
  `Concierge::Auth::Base` implementation

More examples covering the built-in `Concierge::Auth::Pwd` backend and
generator usage are planned. See `examples/README.md` for details.

## ARCHITECTURE

Concierge::Auth follows a service layer pattern:
- **Constructor**: May die on fatal errors (missing backend, file permissions)
- **Core contract methods**: Never die, always return a `{ success => ... }`
  hashref (see `Concierge::Auth::Base`)
- **Generator methods**: Never die, use a `wantarray` dual-return convention
  (see `Concierge::Auth::Generators`)

The module uses modern Perl practices:
- v5.36+ syntax
- Type validation
- Consistent error handling
- Clear separation of concerns

## AUTHOR

Bruce Van Allen <bva@cruzio.com>

## LICENSE

Artistic License 2.0

## SEE ALSO

- Concierge::Users
- Concierge::Sessions
- Crypt::Passphrase
- Crypt::PRNG

## CHANGES

See Changes file for revision history.
