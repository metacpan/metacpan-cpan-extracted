# Connector::Proxy::Net::LDAP::DN
#
# Proxy class for accessing LDAP directories
# The class is designed to find and return one to many matching records
# in an ldap repository and return their DNs.
# Using the set function you can create and delete entries.
#
# Written by Oliver Welter for the OpenXPKI project 2012
#

# FIXME - we need to find a syntax to pass multiple arguments in by
# all possible allowed path specs which is a problematic with
# Search Strings having the delimiter as character.....
# For now we just take is as it comes and assume a string as
# the one and only argument

package Connector::Proxy::Net::LDAP::DN;

use strict;
use warnings;
use English;
use Net::LDAP;

use Moose;
extends 'Connector::Proxy::Net::LDAP';

sub get_list {

    my $self = shift;
    my @args = $self->_build_path( shift );

    my $mesg = $self->_run_search( { ARGS => \@args } );

    if ($mesg->is_error()) {
        $self->log()->error("LDAP search failed error code " . $mesg->code() . " (error: " . $mesg->error_desc() .")" );
        return $self->_node_not_exists( \@args );
    }

    my @list;

    if ($mesg->count() == 0) {
        $self->_node_not_exists( \@args );
        return @list;
    }

     foreach my $loop_entry ( $mesg->entries()) {
        push @list, $loop_entry->dn();
     }

     return @list;

}

sub get_size {

    my $self = shift;
    my @args = $self->_build_path( shift );

    my $mesg = $self->_run_search( { ARGS => \@args } );
    return $mesg->count();
}

sub get_meta {
    my $self = shift;

    # If we have no path, we tell the caller that we are a connector
    my @path = $self->_build_path( shift );
    if (scalar @path == 0) {
        return { TYPE  => "connector" };
    }

    return { TYPE  => "list" };
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
        $val = $self->get_size( \@path ) > 0;
    };
    return (defined $val && $val > 0);

}


sub set {

    my $self = shift;
    my $args = shift;
    my $value = shift;
    my $params = shift;

    my @args = $self->_build_path( $args );

    if (!$params->{pkey}) {
        $self->_log_and_die('You must pass the pkey as parameter to delete an entry.');
    }

    my $mesg = $self->_run_search( { ARGS => \@args }, { noattrs => 1} );

    if ($mesg->is_error()) {
        $self->_log_and_die("LDAP search failed error code " . $mesg->code() . " (error: " . $mesg->error_desc() .")" );
    }

    if ($mesg->count() == 0) {
        return $self->_node_not_exists( \@args );
    }

    my $match_dn = lc($params->{pkey});
    foreach my $entry ( $mesg->entries()) {
        if (lc($entry->dn()) eq $match_dn) {
            $entry->delete();
            my $mesg = $entry->update( $self->ldap() );
            if ($mesg->is_error()) {
                $self->_log_and_die("LDAP update failed error code " . $mesg->code() . " (error: " . $mesg->error_desc() . ")");
            }
            $self->log()->debug('Delete LDAP entry by DN: '.$params->{pkey});
            return 1;
        }
    }

    $self->log()->warn('DN to delete not found in result: '.$params->{pkey});
    return $self->_node_not_exists( \@args );

}

1;
__END__

=head1 NAME

Connector::Proxy::Net::LDAP::DN

=head1 DESCRIPTION

The class is designed to find and return the dn of matching records.
It is possible to delete entries from the repository using the set method.

see Connector::Proxy::Net::LDAP for basic configuration options

=head1 accessor methods

=head2 get

Not supported.

=head2 get_list

Return the list of DNs, that match the filter (configuration + path value).

=head2 get_size

Return the number of entries in the list of I<get_list>.

=head2 get_hash / get_keys

Not supported.

=head2 set

This method can be used to remove entire nodes from the ldap repository.
For security reasons, you can remove only entries that are matched by the
filter. To remove an entry, use the same path as used with I<get_list>,
pass I<undef> as value and pass the DN to delete with the pkey attribute.

    $conn->set('John*', undef, { pkey => 'cn=John Doe,ou=people...'})

