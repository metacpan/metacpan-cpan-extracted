# Connector::Proxy::Net::LDAP::Simple
#
# Proxy class for accessing LDAP directories
# The class is designed to find and return a single attribute
# value. It also supports set for a scalar value.
#
# Written by Oliver Welter for the OpenXPKI project 2012
#

# FIXME - we need to find a syntax to pass multiple arguments in by
# all possible allowed path specs which is a problematic with
# Search Strings having the delimiter as character.....
# For now we just take is as it comes and assume a string as
# the one and only argument

package Connector::Proxy::Net::LDAP::Simple;

use strict;
use warnings;
use English;
use Net::LDAP;

use Moose;
extends 'Connector::Proxy::Net::LDAP';

sub get {
    my $self = shift;
    my @args = $self->_build_path( shift );

    if (!$self->attrs || @{$self->attrs} != 1) {
        $self->log()->error("The attribute list must contain at least one entry");
        die "The attribute list must contain at least one entry"
    }

    my $mesg = $self->_run_search( { ARGS => \@args } );

    if ($mesg->is_error()) {
        $self->log()->error("LDAP search failed error code " . $mesg->code() . " (error: " . $mesg->error_desc() .")" );
        return $self->_node_not_exists( \@args );
    }

    if ($mesg->count() == 0) {
        return $self->_node_not_exists( \@args );
    }

    if ($mesg->count() > 1) {
        die "More than one entry found - result is not unique."
    }

    my $entry = $mesg->entry(0);

    # Check for all attributes and return the first one
    foreach my $attr (@{$self->attrs}) {
        my $ref = $entry->get_value ( $self->attrs->[0], asref => 1 );
        return $ref->[0] if ($ref);
    }

    # No Attribute has a valid value
    return $self->_node_not_exists( \@args );
}

sub set {

    my $self = shift;
    my $args = shift;
    my $value = shift;

    my @args = $self->_build_path( $args );

    if (!$self->attrs || @{$self->attrs} != 1) {
        $self->log()->error("The attribute list must contain exactly one entry");
        die "The attribute list must contain exactly one entry"
    }

    my $entry;

    # Try to find the entry
    my $mesg = $self->_run_search( { ARGS => \@args }, { noattrs => 1} );

    if ($mesg->is_error()) {
        $self->log()->error("LDAP search failed error code " . $mesg->code() . " (error: " . $mesg->error_desc() .")" );
        return $self->_node_not_exists( \@args );
    }

    if ($mesg->count() > 1) {
        $self->log()->error('Set by filter had multiple results: ' . join '|', @args);
        die "More than one entry found - result is not unique."
    }

    if ($mesg->count() == 1) {
        $entry = $mesg->entry(0);
        $self->log()->debug('Entry found ' . $entry->dn());
    } else {
        # Check if autocreate is configured
        $entry = $self->_triggerAutoCreate( \@args );
        return $self->_node_not_exists(\@args) if (!$entry);
    }

    my $action = $self->action();
    my $attribute = $self->attrs->[0];

    if ($action eq "append") {
        $self->log()->debug('Append '.$value.' to Attribute '.$attribute);
        $entry->add( $attribute => $value );
    } elsif($action eq "delete") {
        $self->log()->debug('Delete '.$value.' from Attribute '.$attribute);
        $entry->delete( $attribute => $value ) if ($value);
    } elsif (defined $value) {
        $self->log()->debug('Replace Attribute '.$attribute.' with '.$value);
        $entry->replace( $attribute => $value );
    } else { # Implicit delete - replace with an undef value
        $self->log()->debug('Remove Attribute '.$attribute);
        $entry->delete( $attribute => undef );
    }

    $mesg = $entry->update( $self->ldap() );
    if ($mesg->is_error()) {
        $self->log()->error("LDAP update failed error code " . $mesg->code() . " (error: " . $mesg->error_desc() .")" );
        return $self->_node_not_exists( \@args );
    }

    return 1;

}

sub get_meta {

    my $self = shift;

    # If we have no path, we tell the caller that we are a connector
    my @path = $self->_build_path( shift );
    if (scalar @path == 0) {
        return { TYPE  => "connector" };
    }

    return { TYPE  => "scalar" };

}

sub exists {

    my $self = shift;

    # No path = connector root which always exists
    my @path = $self->_build_path( shift );
    if (scalar @path == 0) {
        return 1;
    }
    my $val;
    eval {
        $val = $self->get( \@path );
    };
    return defined $val;

}

1;
__END__

=head1 NAME

Connector::Proxy::Net::LDAP::Simple

=head1 DESCRIPTION

Get/Set scalar values on unique ldap entries.
The connector will die if multiple entries are found.

=head1 configuration options

See Connector::Proxy::Net::LDAP for basic configuration options

 connector:
    LOCATION:...
    ....
    attrs: Str|Array

The class needs one or more attribtues to look for. You can pass them either as
space delimited string or array ref in the I<attrs> parameter.

=head1 accessor methods

=head2 get

The attrs list must contain at least one argument. You can specify multiple
attributes but you will receive only the first non undef value which is found.
If the attribute itself is multivalued, only the first value is returned.

=head2 get_meta

If called with an empty path, returns { TYPE => "connector" }.
Otherwise calls get internally and returns undef if not found
or the value accompanied with TYPE => scalar.


=head2 get_list / get_size / get_hash / get_keys

Not supported.

=head2 set

If you want to use the set method, your attribute map must contain exactly
one value that denotes the attribute to which the value is written. You can
set only a scalar value.

You can control how existing attributes in the node are treated and if missing
nodes are created on the fly. See I<Connector::Proxy::Net::LDAP> for details.
