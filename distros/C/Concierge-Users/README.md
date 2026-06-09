# Concierge::Users

User data management with multiple storage backends.

## VERSION

v0.9.2

## SYNOPSIS

```perl
use Concierge::Users;

# One-time setup
Concierge::Users->setup({
    storage_dir             => '/var/lib/myapp/users',
    backend                 => 'database',   # 'database', 'file', or 'yaml'
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

## DOCUMENTATION

Comprehensive POD is available for each module:

```bash
perldoc Concierge::Users              # Main API and usage
perldoc Concierge::Users::Meta        # Field catalog, validators, filter DSL, customization
perldoc Concierge::Users::Database    # SQLite backend
perldoc Concierge::Users::File        # CSV/TSV backend
perldoc Concierge::Users::YAML        # YAML backend
```

## STORAGE BACKENDS

- **database** -- SQLite via DBI/DBD::SQLite.  Recommended for production.
- **file** -- CSV or TSV flat file via Text::CSV.  Set `file_format => 'csv'` or `'tsv'` (default) in `setup()`.
- **yaml** -- One YAML file per user via YAML.  Good for individual-user access patterns.

All three backends expose the same API and are selected at setup time.

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
