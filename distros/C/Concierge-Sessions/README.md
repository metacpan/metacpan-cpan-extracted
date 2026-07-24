# Concierge::Sessions - Session Management System

**Version:** 0.11.2

Concierge::Sessions is a comprehensive session management system for Perl
applications, maintaining state across multiple operations — in online
services, CLI tools, games, time-billing systems, or any application that
needs to track state over time.

## Features

- **Application-controlled data storage**: Store any serializable data structure in sessions
- **In-memory performance**: Fast access to state and configuration
- **Optional persistence**: Session tracks changes, saves when App tells it to
- **Single-session enforcement**: Enforces one active session per user
- **Sliding window expiration**: Sessions auto-extend when users are active
- **Indefinite sessions**: Application-wide sessions that never expire
- **Multiple backends**: database (production), file (testing/small user population)
- **Modern Perl**: v5.36+ with contemporary best practices
- **Service layer pattern**: Non-fatal errors with descriptive messages

## Installation

Standard CPAN installation:

```bash
cpanm Concierge::Sessions
# OR
perl Makefile.PL
make
make test
make install
```

## Requirements

- Perl 5.36 or later
- DBI (for SQLite backend)
- DBD::SQLite (for SQLite backend)
- JSON::PP
- Time::HiRes
- File::Spec
- Crypt::PRNG
- Test2::V0 (for testing)

## Quick Start

```perl
use Concierge::Sessions;

# Create session manager
my $sessions = Concierge::Sessions->new(
    backend_class => 'Concierge::Sessions::SQLite',
    storage_dir => '/var/app/sessions',
);

# Create user session
my $result = $sessions->new_session(
    user_id => 'user123',
    data => {
        cart => [],
        preferences => { theme => 'dark' },
    },
);

unless ($result->{success}) {
	return $result; # { success => 0, message => '...' }
}
my $session = $result->{session};
my $session_id = $session->session_id();

# Read session data
my $data_result = $session->get_data();
my $data = $data_result->{value};

# Update session data
$data->{cart} = ['item1', 'item2'];
$session->set_data($data);

# Save changes (extends session timeout)
$session->save();

# Retrieve session later
my $retrieved = $sessions->get_session($session_id);
```

## Usage Patterns

### Sliding Window Expiration

`save()` is the method used to persist session data to the backend (see
"Data Access" below); calling it also extends the session automatically:

```perl
my $session = $sessions->new_session(
    user_id => 'user123',
    session_timeout => 3600,  # 1 hour
)->{session};

# User activity - save() extends the session
$session->save();  # Session now expires 1 hour from now
```

Active users stay logged in; inactive users expire automatically.

### Indefinite Sessions

For application-wide state that never expires:

```perl
my $app_session = $sessions->new_session(
    user_id         => 'application_main',
    session_timeout => 'indefinite',
    data            => {
        metrics    => { requests_processed => 0 },
        subsystems => { database => 'connected' },
    },
)->{session};

# This session never expires
$app_session->is_expired();  # Always returns false
```

### Data Access

A session object has its own simple data field in the form of a hashref
that may store any serializable Perl construct. Data storage operations by
the session object are strictly limited to inserting and retrieving the
whole hashref; any modifications to the hashref must be done by the app,
with the updated hashref then replacing the previous one.

```perl
# Get entire data structure
my $result = $session->get_data();
my $data = $result->{value};

# Modify the data structure
$data->{username} = 'alice';
$data->{preferences}{language} = 'en';
$data->{cart} = [@items];

# Replace entire data field (marks session as dirty)
$session->set_data($data);

# Persist to backend (also extends session timeout)
$session->save();  # Session is clean again (is_dirty() now false)
```

### Session Lifecycle

```perl
# Create
my $result = $sessions->new_session(user_id => 'user123');
my $session = $result->{session};

# Check session status
if ($session->is_valid()) {
    # Session is active and not expired
}

# Retrieve later
my $retrieved = $sessions->get_session($session->session_id());

# Delete when done
$sessions->delete_session($session->session_id());
```

### Backend Selection

```perl
# SQLite backend (production, high performance)
my $sessions = Concierge::Sessions->new(
    backend_class => 'Concierge::Sessions::SQLite',
    storage_dir   => '/var/app/sessions',
);

# File backend (testing, human-readable)
my $sessions = Concierge::Sessions->new(
    backend_class => 'Concierge::Sessions::File',
    storage_dir   => '/tmp/sessions',
);
```

## API Overview

### Concierge::Sessions (Factory)

All factory methods return hashrefs with `{success => 1|0, ...}`:

```perl
$sessions->new_session(user_id => ..., data => ...)
# Returns: {success => 1, session => $session_object}

$sessions->get_session($session_id)
# Returns: {success => 1, session => $session_object}

$sessions->delete_session($session_id)
# Returns: {success => 1, message => '...'}

$sessions->delete_user_session($user_id)
# Returns: {success => 1, deleted_count => 3}

$sessions->cleanup_sessions()
# Returns: {success => 1, deleted_count => 5}
```

### Concierge::Sessions::Session (Session Object)

```perl
# Data methods
$session->get_data()           # {success => 1, value => $data}
$session->set_data($data)      # {success => 1}
$session->save()               # {success => 1}

# Status checks
$session->is_valid()           # 1 if active and not expired
$session->is_active()          # 1 if state is 'active'
$session->is_expired()         # 1 if past expiration time
$session->is_dirty()           # 1 if unsaved changes exist

# Accessors
$session->session_id()         # Session ID string
$session->created_at()         # Creation timestamp
$session->expires_at()         # Expiration timestamp
$session->last_updated()       # Last update timestamp
$session->storage_backend()    # Backend class name
$session->status()             # {state => 'active', dirty => 0}
```

## Design Principles

### Explicit Persistence

No automatic saving on scope exit. You control when data is persisted:

```perl
$session->set_data($new_data);  # Changes in memory only
$session->is_dirty();            # True - changes not saved
$session->save();                # Persists to backend
$session->is_dirty();            # False - saved
```

### Single-Session Enforcement

Only one active session per user. Creating a new session invalidates old ones:

```perl
my $session1 = $sessions->new_session(user_id => 'user123')->{session};
my $session2 = $sessions->new_session(user_id => 'user123')->{session};

# $session1 is now deleted (enforced by backend)
```

### Service Layer Pattern

All methods return consistent result hashrefs. The module only dies/croaks during
initialization if the backend cannot be initialized. All other failures are non-fatal:

```perl
# Factory methods return hashrefs
my $result = $sessions->new_session(user_id => 'user123');

if ($result->{success}) {
    my $session = $result->{session};
    # Use session
} else {
    warn "Failed to create session: " . $result->{message};
}

# Session object methods also return hashrefs
my $save_result = $session->save();

if ($save_result->{success}) {
    # Session saved successfully
} else {
    warn "Failed to save session: " . $save_result->{message};
}
```

**Default Session Timeout**: If not specified, sessions timeout after 3600 seconds (1 hour).
Use `session_timeout => 'indefinite'` for sessions that never expire.

## Documentation

Full API documentation is available in the module POD:

```bash
perldoc Concierge::Sessions
perldoc Concierge::Sessions::Session
```

## Testing

```bash
# Run all tests
prove -lv t/

# Run specific test file
prove -lv t/01-sessions-manager.t
```

Test coverage: 104 tests across 4 test files, all passing.

## Examples

See the `examples/` directory for usage examples:

- `04-indefinite-session.pl` - Application-wide session demonstration

## Performance

- **SQLite backend**: 4,000-5,000 operations per second
- **File backend**: ~1,000 operations per second

Benchmarks performed on typical hardware with default settings.

## License

Artistic License 2.0 - See [LICENSE](LICENSE) file for details.

This is the same license as Perl itself.

## Author

Bruce Van Allen <bva@cruzio.com>

## See Also

- [DBI](https://metacpan.org/pod/DBI) - Database interface
- [JSON::PP](https://metacpan.org/pod/JSON::PP) - JSON handling
- [Time::HiRes](https://metacpan.org/pod/Time::HiRes) - High resolution time
- [Crypt::PRNG](https://metacpan.org/pod/Crypt::PRNG) - Session ID generation
