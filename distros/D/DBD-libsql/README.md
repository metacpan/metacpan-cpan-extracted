[![Actions Status](https://github.com/ytnobody/p5-DBD-libsql/actions/workflows/test.yml/badge.svg)](https://github.com/ytnobody/p5-DBD-libsql/actions)
# NAME

DBD::libsql - DBI driver for libsql databases

# SYNOPSIS

    use DBI;
    
    # Connect to a local libsql server
    my $dbh = DBI->connect('dbi:libsql:localhost', '', '', {
        RaiseError => 1,
        AutoCommit => 1,
    });
    
    # Connect to Turso with authentication token (recommended approach)
    my $dbh = DBI->connect(
        'dbi:libsql:my-db.aws-us-east-1.turso.io',
        '',                    # username (unused)
        'your_turso_token',    # password field used for auth token
        {
            RaiseError => 1,
            AutoCommit => 1,
        }
    );
    
    # Alternative: Turso connection with connection attribute
    my $dbh = DBI->connect('dbi:libsql:my-db.aws-us-east-1.turso.io', '', '', {
        RaiseError => 1,
        AutoCommit => 1,
        libsql_auth_token => 'your_turso_token',
    });
    
    # Create a table
    $dbh->do("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)");
    
    # Insert data
    $dbh->do("INSERT INTO users (name) VALUES (?)", undef, 'Alice');
    
    # Query data
    my $sth = $dbh->prepare("SELECT * FROM users WHERE name = ?");
    $sth->execute('Alice');
    while (my $row = $sth->fetchrow_hashref) {
        print "ID: $row->{id}, Name: $row->{name}\n";
    }
    
    $dbh->disconnect;

# DESCRIPTION

DBD::libsql is a DBI driver that provides access to libsql databases via HTTP.
libsql is a fork of SQLite that supports server-side deployment and remote access.

This driver communicates with libsql servers using the Hrana protocol over HTTP,
providing full SQL functionality including transactions, prepared statements, and
parameter binding.

# FEATURES

- HTTP-only communication with libsql servers
- Full transaction support (BEGIN, COMMIT, ROLLBACK)
- Prepared statements with parameter binding
- Session management using baton tokens
- Proper error handling with Hrana protocol responses
- Support for all standard DBI methods

# DSN FORMAT

The Data Source Name (DSN) format for DBD::libsql uses smart defaults for easy configuration:

    dbi:libsql:hostname
    dbi:libsql:hostname?scheme=https&port=8443

## Smart Defaults

The driver automatically detects the appropriate protocol and port based on the hostname:

- **Turso databases** (.turso.io domains) - Uses HTTPS on port 443
- **Localhost** - Uses HTTP on port 8080
- **Other hosts** - Uses HTTPS on port 443

## Examples

    # Turso Database (auto-detected: HTTPS, port 443)
    dbi:libsql:hono-prisma-ytnobody.aws-ap-northeast-1.turso.io
    
    # Local development server (auto-detected: HTTP, port 8080) 
    dbi:libsql:localhost
    
    # Custom configuration
    dbi:libsql:localhost?scheme=http&port=3000
    dbi:libsql:api.example.com?scheme=https&port=8443

# CONNECTION ATTRIBUTES

Standard DBI connection attributes are supported:

- RaiseError - Enable/disable automatic error raising
- AutoCommit - Enable/disable automatic transaction commit
- PrintError - Enable/disable error printing

# TURSO INTEGRATION

DBD::libsql provides seamless integration with Turso, the managed libsql service.

## Authentication

For Turso databases, authentication tokens can be provided via multiple methods (in priority order):

- 1. Password Parameter (recommended - DBI standard)

        my $dbh = DBI->connect(
            "dbi:libsql:my-db.aws-us-east-1.turso.io",
            "",                    # username (unused)
            "your_auth_token",     # password field for auth token
            { RaiseError => 1 }
        );

- 2. Username Parameter (alternative)

        my $dbh = DBI->connect(
            "dbi:libsql:my-db.aws-us-east-1.turso.io",
            "your_auth_token",     # username field for auth token
            "",                    # password (unused)
            { RaiseError => 1 }
        );

- 3. Connection Attributes

        my $dbh = DBI->connect(
            "dbi:libsql:my-db.aws-us-east-1.turso.io",
            "", "",
            {
                libsql_auth_token => "your_auth_token",
                RaiseError => 1,
            }
        );

- 4. Environment Variables (development/fallback)

        export TURSO_DATABASE_URL="libsql://my-db.aws-us-east-1.turso.io"
        export TURSO_DATABASE_TOKEN="your_auth_token"
        
        my $dbh = DBI->connect("dbi:libsql:my-db.aws-us-east-1.turso.io");

## Getting Turso Credentials

1\. Install the Turso CLI: [https://docs.turso.tech/reference/turso-cli](https://docs.turso.tech/reference/turso-cli)
2\. Create a database: `turso db create my-database`
3\. Get the URL: `turso db show --url my-database`
4\. Create a token: `turso db tokens create my-database`

# DEVELOPMENT AND TESTING

## Running Tests

Basic tests (no external dependencies):

    prove -lv t/

Extended tests (requires turso CLI):

    # Install turso CLI first
    curl -sSfL https://get.tur.so/install.sh | bash
    
    # Start local turso dev server
    turso dev --port 8080 &
    
    # Run integration tests
    prove -lv xt/01_integration.t xt/02_smoke.t

Live Turso tests (optional):

    export TURSO_DATABASE_URL="libsql://your-db.region.turso.io"
    export TURSO_DATABASE_TOKEN="your_token"
    prove -lv xt/03_turso_live.t

## Test Coverage

The test suite covers:

- Hrana protocol communication
- DBI connection management  
- SQL operations (CREATE, INSERT, SELECT, UPDATE, DELETE)
- Parameter binding and prepared statements
- Transaction support (BEGIN, COMMIT, ROLLBACK)
- Data fetching (fetchrow\_arrayref, fetchrow\_hashref, fetchrow\_array)
- Error handling and graceful failures
- Turso authentication and live database operations

# METHODS

This driver implements the standard DBI interface. All standard DBI methods are supported:

## Database Handle Methods

- **prepare($statement)**

    Prepares an SQL statement for execution. Returns a statement handle.

        my $sth = $dbh->prepare("SELECT * FROM users WHERE name = ?");

- **do($statement, $attr, @bind\_values)**

    Executes an SQL statement immediately. Returns the number of affected rows.

        my $rows = $dbh->do("INSERT INTO users (name) VALUES (?)", undef, 'Alice');

- **begin\_work()**

    Starts a transaction by setting AutoCommit to false.

        $dbh->begin_work();

- **commit()**

    Commits the current transaction.

        $dbh->commit();

- **rollback()**

    Rolls back the current transaction.

        $dbh->rollback();

- **disconnect()**

    Disconnects from the database and cleans up resources.

        $dbh->disconnect();

## Statement Handle Methods

- **execute(@bind\_values)**

    Executes the prepared statement with optional bind values.

        $sth->execute('Alice');

- **fetchrow\_arrayref()**

    Fetches the next row as an array reference.

        while (my $row = $sth->fetchrow_arrayref()) {
            print "ID: $row->[0], Name: $row->[1]\n";
        }

- **fetchrow\_hashref()**

    Fetches the next row as a hash reference.

        while (my $row = $sth->fetchrow_hashref()) {
            print "ID: $row->{id}, Name: $row->{name}\n";
        }

- **fetchrow\_array()**

    Fetches the next row as an array.

        while (my @row = $sth->fetchrow_array()) {
            print "ID: $row[0], Name: $row[1]\n";
        }

- **finish()**

    Finishes the statement and frees associated resources.

        $sth->finish();

- **rows()**

    Returns the number of rows affected by the last execute.

        my $affected = $sth->rows();

# TRANSACTION SUPPORT

DBD::libsql fully supports transactions through the Hrana protocol:

## AutoCommit Mode

By default, AutoCommit is enabled (1), meaning each SQL statement is automatically committed.

    # AutoCommit enabled - each statement auto-commits
    $dbh->do("INSERT INTO users (name) VALUES ('Alice')");

## Manual Transaction Control

Disable AutoCommit to use manual transaction control:

    $dbh->{AutoCommit} = 0;  # Start transaction mode
    $dbh->do("INSERT INTO users (name) VALUES ('Alice')");
    $dbh->do("INSERT INTO users (name) VALUES ('Bob')");
    $dbh->commit();  # Commit both inserts

Or use the convenience methods:

    $dbh->begin_work();
    $dbh->do("INSERT INTO users (name) VALUES ('Alice')");
    $dbh->do("INSERT INTO users (name) VALUES ('Bob')");
    
    if ($error) {
        $dbh->rollback();
    } else {
        $dbh->commit();
    }

# ERROR HANDLING

DBD::libsql provides comprehensive error handling:

## RaiseError Attribute

Enable automatic error raising (recommended):

    my $dbh = DBI->connect($dsn, '', '', {
        RaiseError => 1,
        AutoCommit => 1,
    });

## Manual Error Checking

    my $dbh = DBI->connect($dsn, '', '', { RaiseError => 0 });
    
    my $sth = $dbh->prepare("SELECT * FROM users");
    unless ($sth) {
        die "Prepare failed: " . $dbh->errstr;
    }
    
    unless ($sth->execute()) {
        die "Execute failed: " . $sth->errstr;
    }

## Common Error Conditions

- **Connection errors** - Server unreachable, invalid URL, authentication failure
- **SQL syntax errors** - Invalid SQL statements
- **Constraint violations** - UNIQUE, NOT NULL, FOREIGN KEY violations
- **Transaction errors** - ROLLBACK due to conflicts or constraints

# PERFORMANCE CONSIDERATIONS

## Connection Reuse

Reuse database connections when possible:

    # Good: Single connection for multiple operations
    my $dbh = DBI->connect($dsn, '', $token);
    for my $item (@items) {
        $dbh->do("INSERT INTO table VALUES (?)", undef, $item);
    }
    $dbh->disconnect();

## Prepared Statements

Use prepared statements for repeated queries:

    # Good: Prepare once, execute many times
    my $sth = $dbh->prepare("INSERT INTO users (name) VALUES (?)");
    for my $name (@names) {
        $sth->execute($name);
    }
    $sth->finish();

## Batch Operations

Group operations in transactions for better performance:

    $dbh->begin_work();
    my $sth = $dbh->prepare("INSERT INTO users (name) VALUES (?)");
    for my $name (@names) {
        $sth->execute($name);
    }
    $sth->finish();
    $dbh->commit();

# LIMITATIONS

- Only HTTP-based libsql servers are supported
- Local file databases are not supported
- In-memory databases are not supported
- Large result sets may consume significant memory
- No connection pooling (use at application level)

# EXAMPLES

## Basic Usage

    use DBI;
    
    # Connect to local libsql server
    my $dbh = DBI->connect('dbi:libsql:localhost', '', '', {
        RaiseError => 1,
        AutoCommit => 1,
    });
    
    # Create a table
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT UNIQUE,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    });
    
    # Insert data
    $dbh->do("INSERT INTO users (name, email) VALUES (?, ?)", 
             undef, 'Alice Johnson', 'alice@example.com');
    
    # Query data
    my $sth = $dbh->prepare("SELECT * FROM users WHERE name LIKE ?");
    $sth->execute('Alice%');
    
    while (my $row = $sth->fetchrow_hashref) {
        printf "User: %s <%s> (ID: %d)\n", 
               $row->{name}, $row->{email}, $row->{id};
    }
    
    $sth->finish();
    $dbh->disconnect();

## Turso Cloud Database

    use DBI;
    
    # Connect to Turso with authentication
    my $dbh = DBI->connect(
        'dbi:libsql:my-app.aws-us-east-1.turso.io',
        '',                    # username unused
        $auth_token,           # password field for token
        {
            RaiseError => 1,
            AutoCommit => 1,
        }
    );
    
    # Use the database normally
    my $sth = $dbh->prepare("SELECT COUNT(*) FROM sqlite_master WHERE type='table'");
    $sth->execute();
    my ($table_count) = $sth->fetchrow_array();
    print "Database has $table_count tables\n";
    
    $dbh->disconnect();

## Transaction Example

    use DBI;
    
    my $dbh = DBI->connect($dsn, '', $token, { RaiseError => 1 });
    
    eval {
        $dbh->begin_work();
        
        # Insert user
        $dbh->do("INSERT INTO users (name, email) VALUES (?, ?)",
                 undef, 'Bob Smith', 'bob@example.com');
        my $user_id = $dbh->last_insert_id('', '', 'users', 'id');
        
        # Insert user profile
        $dbh->do("INSERT INTO profiles (user_id, bio) VALUES (?, ?)",
                 undef, $user_id, 'Software developer');
        
        $dbh->commit();
        print "User and profile created successfully\n";
    };
    
    if ($@) {
        warn "Transaction failed: $@";
        $dbh->rollback();
    }
    
    $dbh->disconnect();

## Prepared Statement Example

    use DBI;
    
    my $dbh = DBI->connect($dsn, '', $token, { RaiseError => 1 });
    
    # Prepare statement once
    my $sth = $dbh->prepare(q{
        INSERT INTO log_entries (level, message, timestamp) 
        VALUES (?, ?, CURRENT_TIMESTAMP)
    });
    
    # Execute multiple times with different data
    my @log_data = (
        ['INFO', 'Application started'],
        ['DEBUG', 'Database connection established'],
        ['WARN', 'Configuration file not found'],
        ['ERROR', 'Failed to process request'],
    );
    
    for my $entry (@log_data) {
        $sth->execute(@$entry);
    }
    
    $sth->finish();
    print "Inserted " . scalar(@log_data) . " log entries\n";
    
    $dbh->disconnect();

# COMPATIBILITY

## libsql Server Versions

This driver is compatible with:

- libsql server v0.21.0 and later
- Turso managed databases
- sqld (libsql server daemon)

## Perl Versions

Requires Perl 5.18 or later.

## DBI Compliance

Implements DBI specification 1.631+ with the following notes:

- All standard DBI methods are supported
- Some DBD-specific attributes (like last\_insert\_id) may have limitations
- Prepared statements use Hrana protocol parameter binding

# DEPENDENCIES

This module requires the following Perl modules:

- DBI (1.631 or later)
- LWP::UserAgent (6.00 or later)
- HTTP::Request (6.00 or later)
- JSON (4.00 or later)
- IO::Socket::SSL (2.00 or later) - for HTTPS connections

# AUTHOR

ytnobody <ytnobody@gmail.com>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

## Related Perl Modules

- [DBI](https://metacpan.org/pod/DBI) - Database independent interface for Perl
- [DBD::SQLite](https://metacpan.org/pod/DBD%3A%3ASQLite) - SQLite driver for DBI (local file databases)
- [DBD::Pg](https://metacpan.org/pod/DBD%3A%3APg) - PostgreSQL driver for DBI
- [DBD::mysql](https://metacpan.org/pod/DBD%3A%3Amysql) - MySQL driver for DBI

## libsql and Turso Documentation

- [https://docs.turso.tech/](https://docs.turso.tech/) - Turso cloud database documentation
- [https://github.com/tursodatabase/libsql](https://github.com/tursodatabase/libsql) - libsql GitHub repository
- [https://docs.turso.tech/reference/libsql-urls](https://docs.turso.tech/reference/libsql-urls) - libsql URL format specification
- [https://docs.turso.tech/sdk/http/reference](https://docs.turso.tech/sdk/http/reference) - Hrana protocol documentation

## Development Tools

- [https://docs.turso.tech/reference/turso-cli](https://docs.turso.tech/reference/turso-cli) - Turso CLI for database management
- [https://github.com/tursodatabase/turso-cli](https://github.com/tursodatabase/turso-cli) - Turso CLI source code

## Alternative Solutions

- libsql official SDKs for other languages
- Direct HTTP API access using LWP::UserAgent
- SQLite with replication solutions
