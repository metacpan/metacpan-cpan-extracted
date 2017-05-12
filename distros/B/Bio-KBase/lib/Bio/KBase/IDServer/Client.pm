package Bio::KBase::IDServer::Client;

use JSON::RPC::Client;
use strict;
use Data::Dumper;
use URI;

=head1 NAME

Bio::KBase::IDServer::Client

=head1 DESCRIPTION



=cut

sub new
{
    my($class, $url) = @_;

    my $self = {
	client => JSON::RPC::Client->new,
	url => $url,
    };
    my $ua = $self->{client}->ua;	 
    my $timeout = $ENV{CDMI_TIMEOUT} || (30 * 60);	 
    $ua->timeout($timeout);

    return bless $self, $class;
}




=head2 $result = kbase_ids_to_external_ids(ids)

Given a set of KBase identifiers, look up the associated external identifiers.
If no external ID is associated with the KBase id, no entry will be present in the return.

=cut

sub kbase_ids_to_external_ids
{
    my($self, @args) = @_;

    @args == 1 or die "Invalid argument count (expecting 1)";
    my $result = $self->{client}->call($self->{url}, {
	method => "IDServerAPI.kbase_ids_to_external_ids",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    die "Error invoking kbase_ids_to_external_ids: " . $result->error_message;
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
	die "Error invoking kbase_ids_to_external_ids: " . $self->{client}->status_line;
    }
}



=head2 $result = external_ids_to_kbase_ids(external_db, ext_ids)

Given a set of external identifiers, look up the associated KBase identifiers.
If no KBase ID is associated with the external id, no entry will be present in the return.

=cut

sub external_ids_to_kbase_ids
{
    my($self, @args) = @_;

    @args == 2 or die "Invalid argument count (expecting 2)";
    my $result = $self->{client}->call($self->{url}, {
	method => "IDServerAPI.external_ids_to_kbase_ids",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    die "Error invoking external_ids_to_kbase_ids: " . $result->error_message;
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
	die "Error invoking external_ids_to_kbase_ids: " . $self->{client}->status_line;
    }
}



=head2 $result = register_ids(prefix, db_name, ids)

Register a set of identifiers. All will be assigned identifiers with the given
prefix.

If an external ID has already been registered, the existing registration will be returned instead 
of a new ID being allocated.

=cut

sub register_ids
{
    my($self, @args) = @_;

    @args == 3 or die "Invalid argument count (expecting 3)";
    my $result = $self->{client}->call($self->{url}, {
	method => "IDServerAPI.register_ids",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    die "Error invoking register_ids: " . $result->error_message;
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
	die "Error invoking register_ids: " . $self->{client}->status_line;
    }
}



=head2 $result = allocate_id_range(kbase_id_prefix, count)

Allocate a set of identifiers. This allows efficient registration of a large
number of identifiers (e.g. several thousand features in a genome).

The return is the first identifier allocated.

=cut

sub allocate_id_range
{
    my($self, @args) = @_;

    @args == 2 or die "Invalid argument count (expecting 2)";
    my $result = $self->{client}->call($self->{url}, {
	method => "IDServerAPI.allocate_id_range",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    die "Error invoking allocate_id_range: " . $result->error_message;
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
	die "Error invoking allocate_id_range: " . $self->{client}->status_line;
    }
}



=head2 $result = register_allocated_ids(prefix, db_name, assignments)

Register the mappings for a set of external identifiers. The
KBase identifiers used here were previously allocated using allocate_id_range.

Does not return a value.

=cut

sub register_allocated_ids
{
    my($self, @args) = @_;

    @args == 3 or die "Invalid argument count (expecting 3)";
    my $result = $self->{client}->call($self->{url}, {
	method => "IDServerAPI.register_allocated_ids",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    die "Error invoking register_allocated_ids: " . $result->error_message;
	} else {
	    return;
	}
    } else {
	die "Error invoking register_allocated_ids: " . $self->{client}->status_line;
    }
}




1;
