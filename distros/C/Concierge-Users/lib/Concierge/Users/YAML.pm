package Concierge::Users::YAML v0.8.4;
use v5.36;
use Carp qw/ croak /;
use YAML::Tiny;
use File::Path qw/ make_path /;
use File::Spec;
use parent qw/ Concierge::Users::Meta /;

# ABSTRACT: YAML file backend for Concierge::Users

# ==============================================================================
# Configure Class Method - One-time setup (called by Users->setup)
# ==============================================================================

sub configure {
    my ($class, $setup_config) = @_;

    # Extract storage_dir
    my $storage_dir = $setup_config->{storage_dir};

    # For YAML backend, storage is just the directory
    # No additional setup needed beyond ensuring storage_dir exists
    # (already done by Users->setup before calling configure)

    # Create temporary object for archiving
    my $temp_backend = bless {
        storage_dir => $storage_dir,
        fields      => $setup_config->{fields} || [],
        field_definitions => $setup_config->{field_definitions},
    }, $class;

    # Check for existing YAML files and archive if present
    if (opendir(my $dh, $storage_dir)) {
        my @yaml_files = grep { /\.yaml$/ && -f "$storage_dir/$_" } readdir $dh;
        closedir $dh;

        # Archive if YAML files exist
        if (@yaml_files) {
            my $archive_result = $temp_backend->_archive_user_data();
            unless ($archive_result->{success}) {
                return {
                    success => 0,
                    message => $archive_result->{message},
                };
            }
        }
    }

    # Return success with config
    return {
        success => 1,
        message => "YAML backend configured successfully",
        config => {
            storage_dir       => $storage_dir,
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

    return bless {
        storage_dir      => $storage_dir,
        fields           => $runtime_config->{fields} || [],
        field_definitions => $runtime_config->{field_definitions} || {},
    }, $class;
}

# Report backend configuration (for debugging/info)
sub config {
    my ($self) = @_;

    return {
        storage_dir       => $self->{storage_dir},
        fields	       	  => $self->{fields},
        field_definitions => $self->{field_definitions},
    };
}

# Get user file path
sub _get_user_file {
    my ($self, $user_id) = @_;

    return File::Spec->catfile($self->{storage_dir}, "$user_id.yaml");
}

# Archive existing user data (internal method, called by configure)
sub _archive_user_data {
    my ($self) = @_;

    # Generate timestamp for archive directory name
    my $timestamp = $self->archive_timestamp();
    my $archive_dir = "$self->{storage_dir}/users_$timestamp";

    # Create archive directory
    unless (mkdir $archive_dir) {
        return {
            success => 0,
            message => "Failed to create archive directory: $!"
        };
    }

    # Find and move all .yaml files
    my $dh;
    unless (opendir($dh, $self->{storage_dir})) {
        return {
            success => 0,
            message => "Failed to open storage directory: $!"
        };
    }

    my @yaml_files = grep { /\.yaml$/ && -f "$self->{storage_dir}/$_" } readdir $dh;
    closedir $dh;

    foreach my $file (@yaml_files) {
        my $old_path = "$self->{storage_dir}/$file";
        my $new_path = "$archive_dir/$file";

        unless (rename $old_path, $new_path) {
            return {
                success => 0,
                message => "Failed to archive YAML file '$file': $!"
            };
        }
    }

    return { success => 1 };
}

# Add bare record with user_id, moniker, defaults, and null_values from Users.pm
sub add {
    my ($self, $user_id, $initial_record) = @_;
    return { success => 0, message => "Add Record failed: missing user_id" }
    	unless $user_id;
    return { success => 0, message => "Add Record failed: missing initial record" }
    	unless $initial_record;

	my %record				= $initial_record->%*;
	$record{created_date}	= $self->current_timestamp();
	# Add last_mod_date timestamp
    $record{last_mod_date} = $self->current_timestamp();

    my $user_file = $self->_get_user_file($user_id);

    eval {
        YAML::Tiny::DumpFile($user_file, \%record);
    };

    if ($@) {
        return { success => 0, message => "Failed to create initial user record: $@" };
    }

    return { success => 1, message => "Initial record created for user '$user_id'" };
}

# Fetch user by ID
sub fetch {
    my ($self, $user_id) = @_;

    my $user_file = $self->_get_user_file($user_id);

    return {
        success => 0,
        data => '',
        message => "User '$user_id' not found"
    } unless -f $user_file;

    my $user_data;
    eval {
        $user_data = YAML::Tiny::LoadFile($user_file);
    };

    if ($@) {
        return {
            success => 0,
            data => '',
            message => "Failed to load user data: $@"
        };
    }

    return {
        success => 1,
        data => $user_data,
        message => ''
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

    my $user_file = $self->_get_user_file($user_id);

    return { success => 0, message => "User '$user_id' not found" } unless -f $user_file;

    # Load existing data
    my $user_data;
    eval {
        $user_data = YAML::Tiny::LoadFile($user_file);
    };

    return { success => 0, message => "Failed to load user data: $@" } if $@;

    # Apply updates
    foreach my $field (keys %$updates) {
        $user_data->{$field} = $updates->{$field};
    }

    # Save back
    eval {
        YAML::Tiny::DumpFile($user_file, $user_data);
    };

    if ($@) {
        return { success => 0, message => "Failed to update user file: $@" };
    }

    return { success => 1, message => "User '$user_id' updated" };
}

# List users with filters
sub list {
    my ($self, $filters, $options) = @_;

    # Read all YAML files
    opendir my $dh, $self->{storage_dir} or return { data => [], total_count => 0 };
    my @files = grep { /\.yaml$/ } readdir $dh;
    closedir $dh;

    my @users;
    foreach my $file (@files) {
        my $user_file = File::Spec->catfile($self->{storage_dir}, $file);
        my $user_data;

        eval {
            $user_data = YAML::Tiny::LoadFile($user_file);
        };

        next if $@;

        # Apply DSL filters
        my $match = 1;

        if (ref $filters eq 'HASH' && exists $filters->{or_groups}) {
            $match = 0;  # Start with no match, need at least one OR group to match

            foreach my $and_group (@{$filters->{or_groups}}) {
                my $group_match = 1;  # All conditions in this AND group must match

                foreach my $condition (@$and_group) {
                    my ($field, $op, $value) = ($condition->{field}, $condition->{op}, $condition->{value});
                    my $user_value = $user_data->{$field} || '';

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

        push @users, $user_data if $match;
    }

    return {
        data => \@users,
        total_count => scalar @users,
    };
}

# Delete user
sub delete {
    my ($self, $user_id) = @_;

    my $user_file = $self->_get_user_file($user_id);

    return { success => 0, message => "User '$user_id' not found" } unless -f $user_file;

    unlink $user_file or return { success => 0, message => "Failed to delete user file: $!" };

    return { success => 1, message => "User '$user_id' deleted" };
}

# Cleanup
sub disconnect {
    my $self = shift;
    # No resources to clean up for YAML backend
}

1;

__END__

=head1 NAME

Concierge::Users::YAML - YAML file-per-user storage backend for
Concierge::Users

=head1 VERSION

v0.8.2

=head1 SYNOPSIS

    use Concierge::Users;

    # Setup with the YAML backend
    Concierge::Users->setup({
        storage_dir             => '/var/lib/myapp/users',
        backend                 => 'yaml',
        include_standard_fields => 'all',
    });

    # Runtime -- the backend is loaded automatically
    my $users = Concierge::Users->new('/var/lib/myapp/users/users-config.json');

=head1 DESCRIPTION

Concierge::Users::YAML implements the Concierge::Users storage interface
using one YAML file per user via the L<YAML::Tiny> module.  Each user record
is stored as C<< <storage_dir>/<user_id>.yaml >>.

This backend is well-suited for applications that primarily access
individual users and for small-to-moderate user counts where
human-readable per-user files are convenient.

B<Archiving:> When C<setup()> is called and C<.yaml> files already exist
in the storage directory, all YAML files are moved into a timestamped
subdirectory C<< users_YYYYMMDD_HHMMSS/ >> before the new setup
proceeds.

Applications interact with this module indirectly through the
L<Concierge::Users> API; direct instantiation is not required.

=head1 METHODS

=head2 configure

    my $result = Concierge::Users::YAML->configure(\%setup_config);

Class method called by C<< Concierge::Users->setup() >>.  Archives any
existing YAML files in the storage directory and returns the backend
configuration.  Returns a hashref with C<success>, C<message>, and
C<config>.

=head2 new

    my $backend = Concierge::Users::YAML->new(\%runtime_config);

Constructor called by C<< Concierge::Users->new() >>.  Stores the
runtime configuration for file operations.

=head2 add

    my $result = $backend->add($user_id, \%initial_record);

Creates a new C<< <user_id>.yaml >> file.  Sets C<created_date> and
C<last_mod_date> to the current UTC timestamp.

=head2 fetch

    my $result = $backend->fetch($user_id);

Loads and returns the user data from C<< <user_id>.yaml >>.  Returns
C<< { success => 1, data => \%record } >> or
C<< { success => 0, message => "..." } >>.

=head2 update

    my $result = $backend->update($user_id, \%updates);

Loads the existing file, merges updates, and writes back.  Read-only
fields (C<user_id>, C<created_date>, C<last_mod_date>) are stripped
automatically; C<last_mod_date> is refreshed.

=head2 delete

    my $result = $backend->delete($user_id);

Removes the C<< <user_id>.yaml >> file.

=head2 list

    my $result = $backend->list(\%filters, \%options);

Reads every C<.yaml> file in the storage directory and applies the
parsed filter structure (see L<Concierge::Users::Meta/FILTER DSL>).
With no filters, returns all users.  Result:
C<< { data => \@records, total_count => $n } >>.

=head1 CAVEATS

=over 4

=item *

C<list()> reads B<all> C<.yaml> files in the storage directory,
including the C<users-config.yaml> reference file generated by
C<setup()>.  The config file will appear as an entry without a valid
C<user_id> and is included in the returned data.

=item *

Performance is linear with the number of users since every file must be
opened and parsed for list operations.

=back

=head1 DEPENDENCIES

L<YAML::Tiny>

=head1 SEE ALSO

L<Concierge::Users> -- main API

L<Concierge::Users::Meta> -- field definitions and validators

L<Concierge::Users::Database>, L<Concierge::Users::File> -- alternative
backends

=head1 AUTHOR

Bruce Van Allen <bva@cruzio.com>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

=cut
