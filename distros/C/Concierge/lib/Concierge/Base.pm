package Concierge::Base v0.7.0;
use v5.36;

our $VERSION = 'v0.7.0';

# ABSTRACT: Records-store base class for Concierge component modules

use Carp qw<croak>;

# =============================================================================
# STUB METHODS
# Each method croaks with an instructive message so subclasses cannot silently
# inherit a no-op implementation.  Every subclass MUST override all of these.
# =============================================================================

sub new ($class, $config_file=undef) {
    croak ref($class) || $class, " must implement new";
}

sub setup ($self, $config) {
    croak ref($self), " must implement setup";
}

sub add_record ($self, $id, $data) {
    croak ref($self), " must implement add_record";
}

sub remove_record ($self, $id) {
    croak ref($self), " must implement remove_record";
}

sub get_record ($self, $id, @fields) {
    croak ref($self), " must implement get_record";
}

sub update_record ($self, $id, $updates) {
    croak ref($self), " must implement update_record";
}

sub list_records ($self, $filter='', $opts={}) {
    croak ref($self), " must implement list_records";
}

1;

__END__

=head1 NAME

Concierge::Base - Records-store base class for Concierge component modules

=head1 VERSION

v0.7.0

=head1 SYNOPSIS

    package Concierge::Organizations;
    use parent 'Concierge::Base';

    sub new ($class, $config_file) {
        my $self = bless {}, $class;
        $self->{config_file} = $config_file;
        return $self;
    }

    sub setup ($self, $config) {
        # Initialize storage from desk config block
        # $config is the hashref for your component in concierge.conf
        return { success => 1, message => 'Organizations ready' };
    }

    sub add_record ($self, $id, $data) {
        # Persist a new organization record
        # ...
        return { success => 1, message => "Organization '$id' added", id => $id };
    }

    # ... implement remaining methods ...

    1;

=head1 DESCRIPTION

C<Concierge::Base> is an abstract base class for records-store components
that integrate with Concierge desks.  It documents the method contract that
Concierge expects from any additional component -- such as
C<Concierge::Organizations>, C<Concierge::Assets>, or similar -- and provides
stub implementations that die informatively if a subclass omits a required
method.

C<Concierge::Base> does B<not> depend on any of the identity core modules
(L<Concierge::Auth>, L<Concierge::Sessions>, L<Concierge::Users>) and does
not need to be used alongside them.  It is purely a contract-documentation
and safety-net class.

=head2 Return Convention

All methods in a conforming subclass should return a hashref:

    # Success, no payload beyond confirmation
    { success => 1, message => 'Record added' }

    # Success with payload
    { success => 1, message => 'Record found', record => \%data }

    # Failure
    { success => 0, message => 'Record not found' }

The C<success> key is always 0 or 1.  The C<message> key is always a
human-readable string.  Additional payload keys (C<record>, C<records>,
C<ids>, etc.) may be included as appropriate to the method.

Concierge itself follows this convention throughout; adopting it in
additional components makes error handling uniform across the entire desk.

=head1 METHODS

=head2 new

    my $component = Concierge::Organizations->new($config_file);

Constructor.  Receives the path to the component's configuration file (or
C<undef> if the component does not use a separate file).  The subclass is
responsible for initializing any storage handles or caches it needs.

Subclasses must override this method.

=head2 setup

    my $result = $component->setup($config);

One-time setup called during desk initialization (e.g., from
C<Concierge::Setup>).  C<$config> is a hashref containing the component's
block from the desk configuration -- whatever key/value pairs your component
needs (storage path, backend type, field schema, etc.).

Returns a C<{ success => 1|0, message => '...' }> hashref.

Subclasses must override this method.

=head2 add_record

    my $result = $component->add_record($id, \%data);

Creates a new record identified by C<$id> with the fields in C<%data>.

Returns C<{ success => 1|0, message => '...', id => $id }> on success,
or C<{ success => 0, message => '...' }> on failure (e.g., duplicate ID).

Subclasses must override this method.

=head2 remove_record

    my $result = $component->remove_record($id);

Deletes the record identified by C<$id>.

Returns C<{ success => 1|0, message => '...' }>.

Subclasses must override this method.

=head2 get_record

    # All fields
    my $result = $component->get_record($id);

    # Selected fields only
    my $result = $component->get_record($id, qw(name status));

Retrieves the record identified by C<$id>.  If C<@fields> is supplied,
returns only those fields; otherwise returns all fields.

Returns C<{ success => 1, message => '...', record => \%data }> on success,
or C<{ success => 0, message => '...' }> if the record is not found.

Subclasses must override this method.

=head2 update_record

    my $result = $component->update_record($id, \%updates);

Applies C<%updates> to the existing record identified by C<$id>.  Fields
not present in C<%updates> are left unchanged.

Returns C<{ success => 1|0, message => '...' }>.

Subclasses must override this method.

=head2 list_records

    # All records
    my $result = $component->list_records();

    # With filter string and options
    my $result = $component->list_records('active', { include_data => 1 });

Enumerates records.  C<$filter> is an optional string whose interpretation
is left to the subclass (e.g., a status value or SQL WHERE fragment).
C<%opts> is an optional hashref for pagination, field selection, or other
backend-specific options.

Returns C<{ success => 1, ids => \@ids, count => $n }> at minimum, with
optional C<records => \%data> when C<include_data> is requested.

Subclasses must override this method.

=head1 INTEGRATING WITH CONCIERGE

=head2 Error Return Convention

Concierge itself and all its component modules return
C<{ success => 1|0, message => '...' }> from every method.  Conforming to
this convention in your component lets application code use a single,
uniform error-handling idiom:

    my $result = $concierge->some_operation(...);
    unless ($result->{success}) {
        # handle $result->{message}
    }

=head2 Desk Config Block

During desk setup and at C<open_desk()> time, Concierge reads
C<concierge.conf> (a JSON file in the desk directory).  To integrate a new
component, add a key for it in that file:

    {
        "sessions_dir": "/path/to/desk",
        "users_config_file": "/path/to/desk/users.conf",
        "auth_file": "/path/to/desk/auth.json",
        "organizations_config": {
            "backend": "sqlite",
            "db_file": "/path/to/desk/orgs.db"
        }
    }

Your component's C<setup()> method receives the value of that key as
C<$config>:

    sub setup ($self, $config) {
        my $db = $config->{db_file};
        # initialize storage ...
    }

=head2 open_desk Hook

To load your component automatically when a desk is opened, the recommended
pattern is to subclass or monkey-patch C<Concierge::open_desk()>, or to
provide a thin wrapper around it in your application:

    my $result = Concierge->open_desk($desk_dir);
    my $c = $result->{concierge};

    # Load your component
    my $orgs = Concierge::Organizations->new(
        $desk_config->{organizations_config}{config_file}
    );
    $orgs->setup($desk_config->{organizations_config});
    $c->{organizations} = $orgs;

Alternatively, a future version of Concierge may provide a hook point for
additional components.  See the EXTENSIBILITY section in L<Concierge> for
the current recommended approach.

=head1 SUBCLASSING

A minimal subclass skeleton:

    package Concierge::Organizations;
    use v5.36;
    use parent 'Concierge::Base';
    use Carp qw<croak>;

    our $VERSION = 'v0.1.0';

    sub new ($class, $config_file=undef) {
        bless { config_file => $config_file, records => {} }, $class;
    }

    sub setup ($self, $config) {
        # $config comes from the desk's concierge.conf
        $self->{storage_path} = $config->{storage_path}
            or return { success => 0, message => 'storage_path required' };
        # ... initialize backend ...
        return { success => 1, message => 'Organizations initialized' };
    }

    sub add_record ($self, $id, $data) {
        return { success => 0, message => 'id is required' }
            unless defined $id && length $id;
        return { success => 0, message => "Record '$id' already exists" }
            if exists $self->{records}{$id};
        $self->{records}{$id} = $data;
        return { success => 1, message => "Organization '$id' added", id => $id };
    }

    sub remove_record ($self, $id) {
        return { success => 0, message => "Record '$id' not found" }
            unless exists $self->{records}{$id};
        delete $self->{records}{$id};
        return { success => 1, message => "Organization '$id' removed" };
    }

    sub get_record ($self, $id, @fields) {
        return { success => 0, message => "Record '$id' not found" }
            unless exists $self->{records}{$id};
        my $data = $self->{records}{$id};
        if (@fields) {
            my %selected = map { $_ => $data->{$_} }
                           grep { exists $data->{$_} } @fields;
            return { success => 1, record => \%selected };
        }
        return { success => 1, record => $data };
    }

    sub update_record ($self, $id, $updates) {
        return { success => 0, message => "Record '$id' not found" }
            unless exists $self->{records}{$id};
        $self->{records}{$id} = { %{$self->{records}{$id}}, %$updates };
        return { success => 1, message => "Organization '$id' updated" };
    }

    sub list_records ($self, $filter='', $opts={}) {
        my @ids = sort keys %{$self->{records}};
        return { success => 1, ids => \@ids, count => scalar @ids }
            unless $opts->{include_data};
        my %records = map { $_ => $self->{records}{$_} } @ids;
        return { success => 1, ids => \@ids, records => \%records, count => scalar @ids };
    }

    1;

=head1 SEE ALSO

L<Concierge> -- main orchestrator; see its EXTENSIBILITY section for the
component substitution and addition pattern.

L<Concierge::Setup> -- desk creation and configuration.

L<Concierge::Users> -- the identity core records-store component, which
provides a production example of a records-store component integrated with
a Concierge desk.

=head1 AUTHOR

Bruce Van Allen <bva@cruzio.com>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

=cut
