package Concierge::Users::File v0.9.2;
use v5.36;
use Carp qw/ croak /;
use Text::CSV;
use File::Path qw/ make_path /;
use File::Spec;
use parent qw/ Concierge::Users::Meta /;

# ABSTRACT: File backend (CSV/TSV) for Concierge::Users

# ==============================================================================
# Configure Class Method - One-time setup (called by Users->setup)
# ==============================================================================

sub configure {
    my ($class, $setup_config) = @_;

    # Extract parameters
    my $storage_dir = $setup_config->{storage_dir};
    my $format = lc($setup_config->{file_format} || 'tsv');

    # Validate format
    unless ($format =~ /^(csv|tsv)$/) {
        return {
            success => 0,
            message => "Invalid file_format: '$format' (must be 'csv' or 'tsv')",
        };
    }

    # Build file name
    my $file_name = "users.$format";
    my $file_full_path = "$storage_dir/$file_name";

    # Initialize CSV parser
    my $sep_char = ($format eq 'csv') ? ',' : "\t";
    my $csv = Text::CSV->new({
        sep_char => $sep_char,
        binary => 1,
        auto_diag => 1,
    });

    unless ($csv) {
        return {
            success => 0,
            message => "Failed to initialize CSV parser for format: $format",
        };
    }

    # Create temporary object for ensure_storage
    my $temp_backend = bless {
        storage_dir => $storage_dir,
        format      => $format,
        csv         => $csv,
        fields      => $setup_config->{fields} || [],
        field_definitions => $setup_config->{field_definitions},
    }, $class;

    # Check for existing file with data and archive if present
    my $user_file = "$storage_dir/users.$format";
    if (-f $user_file) {
        # Check if file has data rows (after header)
        open my $fh, '<:encoding(UTF-8)', $user_file;
        if ($fh) {
            my $header = <$fh>;  # Skip header
            my $data_count = 0;
            while (my $line = <$fh>) {
                chomp $line;
                $data_count++ if $line =~ /\S/;  # Count non-empty lines
            }
            close $fh;

            # Archive if file has data
            if ($data_count > 0) {
                my $archive_result = $temp_backend->_archive_user_data();
                unless ($archive_result->{success}) {
                    return {
                        success => 0,
                        message => $archive_result->{message},
                    };
                }
            }
            # If empty, just let ensure_storage() overwrite it
        }
    }

    # Ensure storage (file) exists
    my $storage_ok = $temp_backend->ensure_storage();
    unless ($storage_ok) {
        return {
            success => 0,
            message => "Failed to initialize storage for file backend",
        };
    }

    # Return success with config
    return {
        success => 1,
        message => "File backend configured successfully",
        config => {
            storage_dir       => $storage_dir,
            file_format       => $format,
            file_name         => $file_name,
            file_full_path    => $file_full_path,
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
    my $format = $runtime_config->{file_format};

    # Initialize CSV parser
    my $sep_char = ($format eq 'csv') ? ',' : "\t";
    my $csv = Text::CSV->new({
        sep_char => $sep_char,
        binary => 1,
        auto_diag => 1,
    });

    croak "Failed to initialize CSV parser for format: $format"
        unless $csv;

    return bless {
        storage_dir      => $storage_dir,
        format           => $format,
        csv              => $csv,
        fields           => $runtime_config->{fields} || [],
        field_definitions => $runtime_config->{field_definitions} || {},
    }, $class;
}

# Report backend configuration (for debugging/info)
sub config {
    my ($self) = @_;

    my $file_name = "users.$self->{format}";

    return {
        storage_dir       => $self->{storage_dir},
        file_format       => $self->{format},
        file_name         => $file_name,
        file_full_path    => "$self->{storage_dir}/$file_name",
        fields	       	  => $self->{fields},
        field_definitions => $self->{field_definitions},
    };
}

# Ensure storage (file) exists
sub ensure_storage {
    my ($self) = @_;

    my $user_file = $self->_get_user_file();

    return 1 if -f $user_file;

    # Create file with header
    open my $fh, '>:encoding(UTF-8)', $user_file
        or croak "File backend initialization failed: Cannot create user file '$user_file': $!";

    my @headers = @{$self->{fields}};

    if ($self->{csv}->print($fh, \@headers)) {
        print $fh "\n";
        close $fh;
        return 1;
    } else {
        close $fh;
        croak "File backend initialization failed: Cannot write header to file '$user_file': " . $self->{csv}->error_diag();
    }
}

# Archive existing user data (internal method, called by configure)
sub _archive_user_data {
    my ($self) = @_;

    my $user_file = $self->_get_user_file();

    # Generate timestamp for archive filename
    my $timestamp = $self->archive_timestamp();

    # Build archive filename: users_YYYYMMDD_HHMMSS.csv (or .tsv)
    my ($base, $ext) = $user_file =~ /^(.+)\.([^.]+)$/;
    my $archive_file = "${base}_${timestamp}.${ext}";

    # Rename file
    unless (rename $user_file, $archive_file) {
        return {
            success => 0,
            message => "Failed to archive existing user file: $!"
        };
    }

    return { success => 1 };
}

# Get user file path
sub _get_user_file {
    my ($self) = @_;

    return File::Spec->catfile($self->{storage_dir}, "users.$self->{format}");
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

    my $user_file = $self->_get_user_file();
    # Check if file exists, write header if not
    my $write_header = ! -f $user_file;

    # Open file in append mode
    open my $fh, '>>:encoding(UTF-8)', $user_file
        or return { success => 0, message => "Failed to open user file: $!" };

    # Write header if file is new
    if ($write_header) {
        $self->{csv}->print($fh, $self->{fields});
        print $fh "\n";
    }

    # Put row field values in order
    my @row		= map { $record{$_} } $self->{fields}->@*;
    # Write row
    if ($self->{csv}->print($fh, \@row)) {
        print $fh "\n";
        close $fh;
        return { success => 1, message => "User '$user_id' created" };
    } else {
        close $fh;
        return { success => 0, message => "Failed to create initial user record: " . $self->{csv}->error_diag() };
    }
}

# Fetch user by ID
sub fetch {
    my ($self, $user_id) = @_;

    my $user_file = $self->_get_user_file();

    open my $fh, '<:encoding(UTF-8)', $user_file
        or return {
            success => 0,
            data => '',
            message => "Cannot open user file: $!"
        };

    # Skip header
    my $header = <$fh>;
    chomp $header;
    my @fields = $self->{csv}->parse($header) ? $self->{csv}->fields() : ();

    # Search for user
    while (my $line = <$fh>) {
        chomp $line;
        next unless $line;

        $self->{csv}->parse($line);
        my @values = $self->{csv}->fields();

        my %user;
        @user{@fields} = @values;

        if ($user{user_id} eq $user_id) {
            close $fh;
            return {
                success => 1,
                data => \%user,
                message => ''
            };
        }
    }

    close $fh;
    return {
        success => 0,
        data => '',
        message => "User '$user_id' not found"
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

    my $user_file = $self->_get_user_file();

    # Read entire file
    open my $fh_in, '<:encoding(UTF-8)', $user_file
        or return { success => 0, message => "Failed to read user file: $!" };

    my @lines;
    my $header = <$fh_in>;
    push @lines, $header;

    chomp $header;
    $self->{csv}->parse($header);
    my @fields = $self->{csv}->fields();

    my $found = 0;
    while (my $line = <$fh_in>) {
        chomp $line;

        $self->{csv}->parse($line);
        my @values = $self->{csv}->fields();

        my %user;
        @user{@fields} = @values;

        if ($user{user_id} eq $user_id) {
            # Update user with provided data
            foreach my $field (keys %$updates) {
                $user{$field} = $updates->{$field};
            }
            $found = 1;
        }

        # Write back user data
        my @row;
        foreach my $field (@fields) {
            push @row, $user{$field} || '';
        }

        my $output;
        if ($self->{csv}->combine(@row)) {
            $output = $self->{csv}->string();
            push @lines, $output;
        }
    }

    close $fh_in;

    return { success => 0, message => "User '$user_id' not found" } unless $found;

    # Write entire file back
    open my $fh_out, '>:encoding(UTF-8)', $user_file
        or return { success => 0, message => "Failed to write user file: $!" };

    foreach my $line (@lines) {
        print $fh_out $line, "\n";
    }

    close $fh_out;
    return { success => 1, message => "User '$user_id' updated" };
}

# List users with filters
sub list {
    my ($self, $filters, $options) = @_;

    my $user_file = $self->_get_user_file();

    open my $fh, '<:encoding(UTF-8)', $user_file
        or return { data => [], total_count => 0 };

    # Skip header
    my $header = <$fh>;
    chomp $header;
    $self->{csv}->parse($header);
    my @fields = $self->{csv}->fields();

    my @users;

    while (my $line = <$fh>) {
        chomp $line;
        next unless $line;

        $self->{csv}->parse($line);
        my @values = $self->{csv}->fields();

        my %user;
        @user{@fields} = @values;

        # Skip rows where user_id is empty/undefined
        next unless $user{user_id};

        # Apply DSL filters
        my $match = 1;

        if (ref $filters eq 'HASH' && exists $filters->{or_groups}) {
            $match = 0;  # Start with no match, need at least one OR group to match

            foreach my $and_group (@{$filters->{or_groups}}) {
                my $group_match = 1;  # All conditions in this AND group must match

                foreach my $condition (@$and_group) {
                    my ($field, $op, $value) = ($condition->{field}, $condition->{op}, $condition->{value});
                    my $user_value = $user{$field} || '';

                    if ($op eq '=') {
                        $group_match = 0 unless $user_value eq $value;
                    } elsif ($op eq ':') {
                        $group_match = 0 unless $user_value =~ /\Q$value\E/i;
                    } elsif ($op eq '!') {
                        $group_match = 0 if $user_value =~ /\Q$value\E/i;
                    } elsif ($op eq '>') {
                        $group_match = 0 unless $user_value gt $value;
                    } elsif ($op eq '<') {
                        $group_match = 0 unless $user_value lt $value;
                    }
                }

                $match = 1 if $group_match;  # At least one OR group matched
                last if $match;
            }
        }

        push @users, \%user if $match;
    }

    close $fh;

    return {
        data => \@users,
        total_count => scalar @users,
    };
}

# Delete user
sub delete {
    my ($self, $user_id) = @_;

    my $user_file = $self->_get_user_file();

    # Read entire file
    open my $fh_in, '<:encoding(UTF-8)', $user_file
        or return { success => 0, message => "Failed to read user file: $!" };

    my @lines;
    my $header = <$fh_in>;
    push @lines, $header;

    chomp $header;
    $self->{csv}->parse($header);
    my @fields = $self->{csv}->fields();

    my $found = 0;
    while (my $line = <$fh_in>) {
        chomp $line;

        $self->{csv}->parse($line);
        my @values = $self->{csv}->fields();

        my %user;
        @user{@fields} = @values;

        if ($user{user_id} ne $user_id) {
            push @lines, $line;
        } else {
            $found = 1;
        }
    }

    close $fh_in;

    return { success => 0, message => "User '$user_id' not found" } unless $found;

    # Write entire file back
    open my $fh_out, '>:encoding(UTF-8)', $user_file
        or return { success => 0, message => "Failed to write user file: $!" };

    foreach my $line (@lines) {
        print $fh_out $line, "\n";
    }

    close $fh_out;
    return { success => 1, message => "User '$user_id' deleted" };
}

# Cleanup
sub disconnect {
    my $self = shift;
    # No resources to clean up for file backend
}

1;

__END__

=head1 NAME

Concierge::Users::File - CSV/TSV flat-file storage backend for
Concierge::Users

=head1 VERSION

v0.9.1

=head1 SYNOPSIS

    use Concierge::Users;

    # Setup with the file backend (TSV, default)
    Concierge::Users->setup({
        storage_dir             => '/var/lib/myapp/users',
        backend                 => 'file',
        include_standard_fields => 'all',
    });

    # Setup with CSV format
    Concierge::Users->setup({
        storage_dir             => '/var/lib/myapp/users',
        backend                 => 'file',
        file_format             => 'csv',
        include_standard_fields => [qw/ email phone /],
    });

    # Runtime -- the backend is loaded automatically
    my $users = Concierge::Users->new('/var/lib/myapp/users/users-config.json');

=head1 DESCRIPTION

Concierge::Users::File implements the Concierge::Users storage interface
using a single CSV or TSV flat file via L<Text::CSV>.  All records are
stored in C<< <storage_dir>/users.tsv >> (or C<users.csv>), with the
first row as a header containing field names.

The file format is selected at setup time with the C<file_format>
parameter (C<'csv'> or C<'tsv'>; default C<'tsv'>).

B<Write behavior:> Additions append to the file.  Updates and deletes
perform a full-file rewrite (read all rows, modify, write back).  This
is simple and reliable but means write performance is proportional to
file size.

B<Archiving:> When C<setup()> is called and the data file already
contains user rows, the existing file is renamed to
C<< users_YYYYMMDD_HHMMSS.tsv >> (or C<.csv>) before a new file is
created.

Applications interact with this module indirectly through the
L<Concierge::Users> API; direct instantiation is not required.

=head1 METHODS

=head2 configure

    my $result = Concierge::Users::File->configure(\%setup_config);

Class method called by C<< Concierge::Users->setup() >>.  Creates (or
archives and recreates) the data file with a header row.  Returns a
hashref with C<success>, C<message>, and C<config>.

=head2 new

    my $backend = Concierge::Users::File->new(\%runtime_config);

Constructor called by C<< Concierge::Users->new() >>.  Initializes the
L<Text::CSV> parser with the saved format.  Croaks if the parser cannot
be created.

=head2 add

    my $result = $backend->add($user_id, \%initial_record);

Appends a new row to the data file.  Sets C<created_date> and
C<last_mod_date> to the current UTC timestamp.

=head2 fetch

    my $result = $backend->fetch($user_id);

Reads the file sequentially to find the row with the matching
C<user_id>.  Returns C<< { success => 1, data => \%row } >> or
C<< { success => 0, message => "..." } >>.

=head2 update

    my $result = $backend->update($user_id, \%updates);

Rewrites the entire file, applying updates to the matching row.
Read-only fields (C<user_id>, C<created_date>, C<last_mod_date>) are
stripped automatically; C<last_mod_date> is refreshed.

=head2 delete

    my $result = $backend->delete($user_id);

Rewrites the file, omitting the row matching C<user_id>.

=head2 list

    my $result = $backend->list(\%filters, \%options);

Reads all rows and applies the parsed filter structure (see
L<Concierge::Users::Meta/FILTER DSL>).  With no filters, returns all
users.  Result: C<< { data => \@rows, total_count => $n } >>.

=head1 DEPENDENCIES

L<Text::CSV>

=head1 SEE ALSO

L<Concierge::Users> -- main API

L<Concierge::Users::Meta> -- field definitions and validators

L<Concierge::Users::Database>, L<Concierge::Users::YAML> -- alternative
backends

=head1 AUTHOR

Bruce Van Allen <bva@cruzio.com>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

=cut
