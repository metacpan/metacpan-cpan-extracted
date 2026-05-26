package Concierge::Users::Database v0.8.2;
use v5.36;
use Carp qw/ croak /;
use DBI;
use parent qw/ Concierge::Users::Meta /;

# ABSTRACT: Database backend for Concierge::Users

# ==============================================================================
# Configure Class Method - One-time setup (called by Users->setup)
# ==============================================================================

sub configure {
    my ($class, $setup_config) = @_;

    # Extract storage_dir
    my $storage_dir = $setup_config->{storage_dir};

    # Build SQLite DSN and file path
    my $db_file = "$storage_dir/users.db";
    my $dsn = "dbi:SQLite:$db_file";

    # Connect to database
    my $dbh = DBI->connect($dsn, '', '', {
        RaiseError => 0,
        AutoCommit => 1,
        PrintError => 0,
        sqlite_unicode => 1,
    });

    unless ($dbh) {
        return {
            success => 0,
            message => sprintf(
                "Database backend connection failed:\n" .
                "  - Database file: %s\n" .
                "  - Error: %s",
                $db_file,
                $DBI::errstr || 'Unknown error'
            ),
        };
    }

    # Create temporary object for ensure_storage
    my $temp_backend = bless {
        dbh         => $dbh,
        table_name  => 'users',
        storage_dir => $storage_dir,
        db_file     => $db_file,
        field_definitions => $setup_config->{field_definitions},
        fields      => $setup_config->{fields} || [],
    }, $class;

    # Check for existing data and archive if present
    my $check_sql = "SELECT name FROM sqlite_master WHERE type='table' AND name=?";
    my $sth = $dbh->prepare($check_sql);
    if ($sth) {
        $sth->execute('users');
        my ($table_exists) = $sth->fetchrow_array();
        $sth->finish();

        if ($table_exists) {
            # Check if table has data
            my $count_sql = "SELECT COUNT(*) FROM users";
            my $count_sth = $dbh->prepare($count_sql);
            if ($count_sth) {
                $count_sth->execute();
                my ($user_count) = $count_sth->fetchrow_array();
                $count_sth->finish();

                # Archive if table has data
                if ($user_count > 0) {
                    my $archive_result = $temp_backend->_archive_user_data();
                    unless ($archive_result->{success}) {
                        $temp_backend->disconnect();
                        return {
                            success => 0,
                            message => $archive_result->{message},
                        };
                    }
                } else {
                    # Drop empty table
                    $dbh->do("DROP TABLE users");
                }
            }
        }
    }

    # Ensure storage (table) exists
    my $storage_ok = $temp_backend->ensure_storage();
    unless ($storage_ok) {
        return {
            success => 0,
            message => "Failed to initialize storage for database backend",
        };
    }

    # Disconnect temp object
    $temp_backend->disconnect();

    # Return success with config
    return {
        success => 1,
        message => "Database backend configured successfully",
        config => {
            storage_dir       => $storage_dir,
            db_file           => 'users.db',
            db_full_path      => $db_file,
            table_name        => 'users',
            fields            => $setup_config->{fields} || [],
            field_definitions => $setup_config->{field_definitions},
        },
    };
}

# ==============================================================================
# Constructor - Runtime instantiation (called by Users->new)
# ==============================================================================
sub new {
    my ($class, $runtime_config) = @_;

    # Extract parameters from saved config (no validation needed)
    my $storage_dir = $runtime_config->{storage_dir};
    my $db_file     = $runtime_config->{db_full_path};
    my $table_name  = $runtime_config->{table_name} || 'users';

    # Build SQLite DSN
    my $dsn = "dbi:SQLite:$db_file";

    # Connect to database
    my $dbh = DBI->connect($dsn, '', '', {
        RaiseError => 0,
        AutoCommit => 1,
        PrintError => 0,
        sqlite_unicode => 1,
    });

    unless ($dbh) {
        croak sprintf(
            "Database backend connection failed:\n" .
            "  - Database file: %s\n" .
            "  - Error: %s",
            $db_file,
            $DBI::errstr || 'Unknown error'
        );
    }

    return bless {
        dbh              => $dbh,
        table_name       => $table_name,
        storage_dir      => $storage_dir,
        db_file          => $db_file,
        fields           => $runtime_config->{fields} || [],
        field_definitions => $runtime_config->{field_definitions} || {},
    }, $class;
}

# Report backend configuration (for debugging/info)
sub config {
    my ($self) = @_;

    return {
        storage_dir       => $self->{storage_dir},
        db_file           => $self->{db_file},
        db_full_path      => $self->{db_file},
        table_name        => $self->{table_name},
        fields	       	  => $self->{fields},
        field_definitions => $self->{field_definitions},
    };
}

# Ensure storage (table) exists
sub ensure_storage {
    my ($self) = @_;

    # Check if table exists
    my $check_sql = "SELECT name FROM sqlite_master WHERE type='table' AND name=?";
    my $sth = $self->{dbh}->prepare($check_sql);
    return 0 unless $sth;
    $sth->execute($self->{table_name});
    my ($exists) = $sth->fetchrow_array();

    return 1 if $exists;  # Table already exists

    # Build CREATE TABLE SQL
    my @field_defs;
    my @indexes;

    foreach my $field (@{$self->{fields}}) {
        # All fields are TEXT in our schema
        my $field_def = "$field TEXT";

        # Check if field is required
        my $field_def_info = $self->{field_definitions}{$field};
        if ($field_def_info && $field_def_info->{required}) {
            $field_def .= " NOT NULL";
        }

        push @field_defs, $field_def;
    }

    # Primary key on user_id
    push @indexes, "CREATE UNIQUE INDEX idx_user_id ON $self->{table_name}(user_id)";

    # Create table
    my $create_sql = "CREATE TABLE $self->{table_name} (\n" .
                     join(",\n    ", @field_defs) . "\n)";

    my $result = $self->{dbh}->do($create_sql);
    return 0 unless $result;

    # Create indexes
    foreach my $index_sql (@indexes) {
        $self->{dbh}->do($index_sql);
    }

    return 1;
}

# Archive existing user data (internal method, called by configure)
sub _archive_user_data {
    my ($self) = @_;

    # Generate timestamp for archive table name
    my $timestamp = $self->archive_timestamp();
    my $archive_table = "$self->{table_name}_$timestamp";

    # Rename table
    my $rename_sql = "ALTER TABLE $self->{table_name} RENAME TO $archive_table";
    my $result = $self->{dbh}->do($rename_sql);

    unless ($result) {
        return {
            success => 0,
            message => "Failed to archive existing table: " . $self->{dbh}->errstr
        };
    }

    return { success => 1 };
}

# Add bare record with user_id and null_values
sub add {
    my ($self, $user_id, $initial_record) = @_;
    return { success => 0, message => "Add Record failed: missing user_id" }
    	unless $user_id;
    return { success => 0, message => "Add Record failed: missing initial record" }
    	unless $initial_record;

	my %record	= $initial_record->%*;
	$record{created_date}	= $self->current_timestamp();
	# Add last_mod_date timestamp
    $record{last_mod_date} = $self->current_timestamp();

    # Insert into database
    my @fields = keys %record;
    my @placeholders = map { '?' } @fields;
    my @values = @record{@fields};

    my $sql = "INSERT INTO $self->{table_name} (" .
              join(', ', @fields) . ") VALUES (" .
              join(', ', @placeholders) . ")";

    my $sth = $self->{dbh}->prepare($sql);
    if ($sth->execute(@values)) {
        return { success => 1, message => "Initial record created for user '$user_id'" };
    } else {
        return { success => 0, message => "Failed to create initial user record: " . $self->{dbh}->errstr };
    }
}

# Fetch user by ID
sub fetch {
    my ($self, $user_id) = @_;

    my $sql = "SELECT * FROM $self->{table_name} WHERE user_id = ?";
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute($user_id);

    my $user_data = $sth->fetchrow_hashref();

    return {
        success => $user_data ? 1 : 0,
        data => $user_data,
        message => $user_data ? '' : "User '$user_id' not found"
    };
}

# Update user
sub update {
    my ($self, $user_id, $updates) = @_;

    # Remove readonly fields from updates
    my %readonly = map { $_ => 1 } qw(user_id created_date last_mod_date);
    delete $updates->{$_} for keys %readonly;

    # Add last_mod_date timestamp
    $updates->{last_mod_date} = $self->current_timestamp();

    my @fields = keys %$updates;
    my @values = values %$updates;
    push @values, $user_id;  # For WHERE clause

    my $sql = "UPDATE $self->{table_name} SET " .
              join(', ', map { "$_ = ?" } @fields) .
              " WHERE user_id = ?";

    my $sth = $self->{dbh}->prepare($sql);
    unless ($sth) {
        return { success => 0, message => "Failed to prepare update: " . $self->{dbh}->errstr };
    }

    if ($sth->execute(@values)) {
        return { success => 1, message => "User '$user_id' updated" };
    } else {
        return { success => 0, message => "Failed to update user: " . $self->{dbh}->errstr };
    }
}

# List users with filters
sub list {
    my ($self, $filters, $options) = @_;

    # Build WHERE clause from DSL filter structure
    my @where_clauses;
    my @where_values;

    if (ref $filters eq 'HASH' && exists $filters->{or_groups}) {
        # Parse DSL filter structure
        my @or_groups;

        foreach my $and_group (@{$filters->{or_groups}}) {
            my @and_clauses;
            foreach my $condition (@$and_group) {
                my ($field, $op, $value) = ($condition->{field}, $condition->{op}, $condition->{value});

                my $clause;
                if ($op eq '=') {
                    $clause = "$field = ?";
                    push @where_values, $value;
                } elsif ($op eq ':') {
                    $clause = "$field LIKE ?";
                    push @where_values, "%$value%";
                } elsif ($op eq '!') {
                    $clause = "$field NOT LIKE ?";
                    push @where_values, "%$value%";
                } elsif ($op eq '>') {
                    $clause = "$field > ?";
                    push @where_values, $value;
                } elsif ($op eq '<') {
                    $clause = "$field < ?";
                    push @where_values, $value;
                } else {
                    next; # Skip unknown operators
                }

                push @and_clauses, $clause;
            }

            # Join AND conditions
            if (@and_clauses) {
                push @or_groups, "(" . join(" AND ", @and_clauses) . ")";
            }
        }

        # Join OR groups
        if (@or_groups) {
            push @where_clauses, join(" OR ", @or_groups);
        }
    }

    # Data query
    my $sql = "SELECT * FROM $self->{table_name}";
    if (@where_clauses) {
        $sql .= " WHERE " . join(' AND ', @where_clauses);
    }

    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute(@where_values);

    my @users;
    while (my $row = $sth->fetchrow_hashref()) {
        push @users, $row;
    }

    return {
        data => \@users,
        total_count => scalar @users,
    };
}

# Delete user
sub delete {
    my ($self, $user_id) = @_;

    my $sql = "DELETE FROM $self->{table_name} WHERE user_id = ?";
    my $sth = $self->{dbh}->prepare($sql);

    if ($sth->execute($user_id)) {
        return { success => 1, message => "User '$user_id' deleted" };
    } else {
        return { success => 0, message => "Failed to delete user: " . $self->{dbh}->errstr };
    }
}

# Cleanup
sub disconnect {
    my $self = shift;
    if ($self->{dbh}) {
        $self->{dbh}->disconnect();
        $self->{dbh} = undef;
    }
}

sub DESTROY {
    my $self = shift;
    $self->disconnect();
}

1;

__END__

=head1 NAME

Concierge::Users::Database - SQLite storage backend for Concierge::Users

=head1 VERSION

v0.8.2

=head1 SYNOPSIS

    use Concierge::Users;

    # Setup with the database backend
    Concierge::Users->setup({
        storage_dir             => '/var/lib/myapp/users',
        backend                 => 'database',
        include_standard_fields => 'all',
    });

    # Runtime -- the backend is loaded automatically
    my $users = Concierge::Users->new('/var/lib/myapp/users/users-config.json');

=head1 DESCRIPTION

Concierge::Users::Database implements the Concierge::Users storage
interface using SQLite via L<DBI> and L<DBD::SQLite>.  User records are
stored in a single C<users> table inside C<< <storage_dir>/users.db >>.

This is the recommended backend for production deployments and larger
datasets.  It provides indexed lookups, SQL-based filtering, and
transactional writes with no external database server required.

B<Archiving:> When C<setup()> is called and the C<users> table already
contains data, the existing table is renamed to
C<< users_YYYYMMDD_HHMMSS >> before a new table is created.  Empty
tables are silently dropped.

Applications interact with this module indirectly through the
L<Concierge::Users> API; direct instantiation is not required.

=head1 METHODS

=head2 configure

    my $result = Concierge::Users::Database->configure(\%setup_config);

Class method called by C<< Concierge::Users->setup() >>.  Creates (or
archives and recreates) the SQLite database and C<users> table.  Returns
a hashref with C<success>, C<message>, and C<config>.

=head2 new

    my $backend = Concierge::Users::Database->new(\%runtime_config);

Constructor called by C<< Concierge::Users->new() >>.  Connects to the
existing SQLite database using the saved configuration.  Croaks on
connection failure.

=head2 add

    my $result = $backend->add($user_id, \%initial_record);

Inserts a new row.  Sets C<created_date> and C<last_mod_date> to the
current UTC timestamp.

=head2 fetch

    my $result = $backend->fetch($user_id);

Retrieves a single user by C<user_id>.  Returns
C<< { success => 1, data => \%row } >> or
C<< { success => 0, message => "..." } >>.

=head2 update

    my $result = $backend->update($user_id, \%updates);

Updates the specified fields for an existing user.  Read-only fields
(C<user_id>, C<created_date>, C<last_mod_date>) are stripped
automatically; C<last_mod_date> is refreshed.

=head2 delete

    my $result = $backend->delete($user_id);

Deletes the row matching C<user_id>.

=head2 list

    my $result = $backend->list(\%filters, \%options);

Returns all users matching the parsed filter structure (see
L<Concierge::Users::Meta/FILTER DSL>).  With no filters, returns all
users.  Result: C<< { data => \@rows, total_count => $n } >>.

=head2 disconnect

    $backend->disconnect();

Closes the database handle.  Also called automatically during object
destruction.

=head1 DEPENDENCIES

L<DBI>, L<DBD::SQLite>

=head1 SEE ALSO

L<Concierge::Users> -- main API

L<Concierge::Users::Meta> -- field definitions and validators

L<Concierge::Users::File>, L<Concierge::Users::YAML> -- alternative
backends

=head1 AUTHOR

Bruce Van Allen <bva@cruzio.com>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

=cut
