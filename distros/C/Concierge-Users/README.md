# Concierge::Users

Configurable user data management for applications.

## VERSION

v0.9.4

## SYNOPSIS

```perl
use Concierge::Users;

# One-time setup
Concierge::Users->setup({
    storage_dir             => '/var/lib/myapp/users',
    backend_class           => 'Concierge::Users::SQLite',
    include_standard_fields => 'all',
    app_fields              => ['role', 'theme'],
});

# Runtime
my $users = Concierge::Users->new('/var/lib/myapp/users/users-config.json');

# CRUD operations
$users->register_user({ user_id => 'alice', moniker => 'Alice', email => 'alice@example.com' });
my $result = $users->get_user('alice');
$users->update_user('alice', { email => 'new@example.com' });
$users->list_users('user_status=OK;access_level=member');
$users->delete_user('alice');
```

## DESCRIPTION

Concierge::Users manages user data records with a two-phase lifecycle:
`setup()` configures storage and the field schema once, then `new()`
loads the saved config for runtime CRUD operations.  All methods return
hashrefs with a `success` key.

Concierge::Users can be used standalone, or as one of the three core
components (alongside Concierge::Auth and Concierge::Sessions) that make
up the Concierge service layer.

## DOCUMENTATION

Comprehensive POD is available for each module:

```bash
perldoc Concierge::Users              # Main API and usage
perldoc Concierge::Users::Meta        # Field catalog, validators, filter DSL, customization
perldoc Concierge::Users::SQLite      # SQLite backend
perldoc Concierge::Users::File        # CSV/TSV backend
perldoc Concierge::Users::YAML        # YAML backend
```

## STORAGE BACKENDS

A backend is selected by passing its fully-qualified class name as
`backend_class` to `setup()`.

- **Concierge::Users::SQLite** -- SQLite via DBI/DBD::SQLite.  Recommended for production.
- **Concierge::Users::File** -- CSV or TSV flat file via Text::CSV.  Set `file_format => 'csv'` or `'tsv'` (default) in `setup()`.
- **Concierge::Users::YAML** -- One YAML file per user via YAML.  Good for individual-user access patterns.

All three backends expose the same API and are selected at setup time.

## FIELD CUSTOMIZATION

Concierge::Users provides a standard set of fields and their metadata for
typical user data; definitions and metadata (labels, options, validation,
etc.) for these fields may be overridden at setup time with
`field_overrides`, and the Users data store may be configured to use none
or only a subset of the standard fields with `include_standard_fields`.

Beyond the standard fields, applications can add their own with
`app_fields`.

Standard fields are:

| Field | Notes |
|---|---|
| `user_id` | Required, unique identifier |
| `moniker` | Required, display name |
| `user_status` | Required, account status, e.g. `Eligible`, `OK`, `Inactive` |
| `access_level` | Required, permission level, e.g. `anon`, `visitor`, `member`, `staff`, `admin` |
| `first_name` | User's first name |
| `middle_name` | User's middle name |
| `last_name` | User's last name |
| `prefix` | Name prefix or title, e.g. `Dr`, `Mr`, `Ms` |
| `suffix` | Name suffix or professional designation, e.g. `Jr`, `PhD` |
| `organization` | User's organization or affiliation |
| `title` | User's position or job title |
| `email` | Email address for notifications |
| `phone` | Phone number with country code |
| `text_ok` | Consent for text messages |
| `term_ends` | Membership/subscription expiry |
| `last_login_date` | Auto-updated on login |
| `last_mod_date` | Auto-updated on every profile write |
| `created_date` | Set once when the account is created |

See `perldoc Concierge::Users::Meta` for the full field catalog and the
filter DSL used by `list_users()`.

## INSTALLATION

From CPAN:
```bash
cpanm Concierge::Users
```

From source:
```bash
perl Makefile.PL
make
make test
make install
```

## REQUIREMENTS

- Perl 5.36 or higher
- JSON::PP (core)
- File::Path (core)
- DBI and DBD::SQLite (database backend)
- Text::CSV (file backend)
- YAML (YAML backend)
- Test2::V0 (testing)

## AUTHOR

Bruce Van Allen <bva@cruzio.com>

## LICENSE

This module is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

## SEE ALSO

- [Concierge::Auth](https://metacpan.org/pod/Concierge::Auth) -- password authentication
- [Concierge::Sessions](https://metacpan.org/pod/Concierge::Sessions) -- session management
- Changes file for revision history
