# Connector::Proxy::Net::LDAP
#
# Proxy class for accessing LDAP directories
#
# Written by Scott Hardin,  Martin Bartosch and Oliver Welter for the OpenXPKI project 2012
#
package Connector::Proxy::Net::LDAP;

use strict;
use warnings;
use English;
use Net::LDAP;
use Template;
use Data::Dumper;

use Moose;
extends 'Connector::Proxy';

has base => (
    is  => 'rw',
    isa => 'Str',
    required => 1,
    );

has binddn => (
    is  => 'rw',
    isa => 'Str',
    );

has password => (
    is  => 'rw',
    isa => 'Str',
    );

has filter => (
    is  => 'rw',
    # TODO: this does not work (currently); NB: do we need that?
#    isa => 'Str|Net::LDAP::Filter',
    isa => 'Str',
    required => 1,
    );

has attrs => (
    is  => 'rw',
    isa => 'ArrayRef|Str',
    trigger => \&_convert_attrs
    );

has scope => (
    is  => 'rw',
    isa => 'Str',
    );

has timeout => (
    is  => 'rw',
    isa => 'Int',
    );

has keepalive => (
    is  => 'rw',
    isa => 'Int',
    );

has timelimit => (
    is  => 'rw',
    isa => 'Int',
    );

has sizelimit => (
    is  => 'rw',
    isa => 'Int',
    );

# ssl options
has verify => (
    is  => 'rw',
    isa => 'Str',
    );

has capath => (
    is  => 'rw',
    isa => 'Str',
    );


has bind => (
    is  => 'ro',
    isa => 'Net::LDAP',
    reader => '_bind',
    builder => '_init_bind',
    clearer   => '_purge_bind',
    lazy => 1,
);

has action => (
    is  => 'rw',
    isa => 'Str',
    lazy => 1,
    default => 'replace',
);

sub _build_config {
    my $self = shift;

}

sub _build_options {
    my $self = shift;

    my %options;
    foreach my $key (@_) {
    if (defined $self->$key()) {
        $options{$key} = $self->$key();
    }
    }
    return %options;
}

sub _build_new_options {
    my $self = shift;
    return $self->_build_options(qw( timeout verify capath keepalive ));
}

sub _build_bind_options {
    my $self = shift;
    return $self->_build_options(qw( password ));
}

# the argument passed to this method will be used as template parameters
# in the expansion of the filter attribute
sub _build_search_options {
    my $self = shift;
    my $arg = shift;
    my $params = shift;

    my %options = $self->_build_options(qw( base scope sizelimit timelimit ));

    my $filter = $self->filter();

    # template expansion is performed on filter strings only, not
    # on Net::LDAP::Filter objects
    my $value;
    if (ref $filter eq '') {
    my $template = Template->new(
        {
        });

    $template->process(\$filter, $arg, \$value) || die "Error processing argument template.";
       $options{filter} = $value;
    } else {
        $options{filter} = $filter;
    }


    # Add the attributes to the query to return only the ones we are asked for
    # Will not work if we allow Filters
    $options{attrs} = $self->attrs unless( $params->{noattrs} );

    $self->log()->debug('LDAP Search options ' . Dumper %options);

    return %options;
}

# If the attr property is set using a string (necessary atm for Config::Std)
# its converted to an arrayref. Might be removed if Config::* improves
# This might create indefinite loops if something goes wrong on the conversion!
sub _convert_attrs {
    my ( $self, $new, $old ) = @_;

    # Test if the given value is a non empty scalar
    if ($new && !ref $new && (!$old || $new ne $old)) {
        my @attrs = split(" ", $new);
        $self->attrs( \@attrs )
    }

}

sub _init_bind {

    my $self = shift;

    $self->log()->debug('Open bind to to ' . $self->LOCATION());

    my $ldap = Net::LDAP->new(
        $self->LOCATION(),
        onerror => undef,
        $self->_build_new_options(),
    );

    if (! $ldap) {
       die "Could not instantiate ldap object ($@)";
    }

    my $mesg;
    if (defined $self->binddn()) {
        $mesg = $ldap->bind(
            $self->binddn(),
            $self->_build_bind_options(),
        );
    } else {
        # anonymous bind
        $mesg = $ldap->bind(
            $self->_build_bind_options(),
        );
    }

    if ($mesg->is_error()) {
        die "LDAP bind failed with error code " . $mesg->code() . " (error: " . $mesg->error_desc() . ")";
    }
    return $ldap;
}

sub ldap {
    # ToDo - check if still bound
    my $self = shift;
    return $self->_bind;
}



sub _getbyDN {

    my $self = shift;
    my $dn = shift;
    my $params = shift;

    my $ldap = $self->ldap();

    my $mesg = $ldap->search( base => $dn, scope  => 'base', filter => '(objectclass=*)');

    # Check reconnet - same as in run_search
    if ($mesg->is_error() && ($mesg->code() == 81 || $mesg->code() == 1)) {
        $self->log()->debug('Connection lost - try rebind and rerun query');
        $self->_purge_bind();
        $mesg = $ldap->search( base => $dn, scope  => 'base', filter => '(objectclass=*)');
    }


    if ( $mesg->count() == 1) {

        my $entry = $mesg->entry(0);
        # For testing
        if (lc($entry->dn()) ne lc($dn)) {
            $self->log()->warn('Search by DN with result looks fishy. Request: '.$dn.' - Entry: '.$entry->dn());
        }
        return $entry;
    }

    # Query is ambigous - can this happen ?
    if ( $mesg->count() > 1) {
        $self->log()->error('Search by DN got multiple ('.$mesg->count().') results: '.$dn);
        die "There is more than one matching node.";
    }

    # If autocreation is not requested, return undef
    if (!$params->{create}) {
        return;
    }

    # No match, so split up the DN and walk upwards
    my $base_dn = $self->base;

    # Strip the base from the dn and tokenize the rest
    my $path = $dn;
    $path =~ s/\,?$base_dn$//;

    #my $dn_parser = OpenXPKI::DN->new($path);
    my @dn_attributes = $self->_splitDN( $path );

    my $currentPath = $base_dn;
    my @nextComponent;
    my $i;
    for ($i = scalar(@dn_attributes)-1; $i >= 0; $i--) {

        # For the moment we just implement single value components
        my $nextComponentKey = lc $dn_attributes[$i][0];
        my $nextComponentValue = $dn_attributes[$i][1];

        my $nextComponent = $nextComponentKey.'='.$nextComponentValue;

        # Search for the next node
        #print "Probe $currentPath - $nextComponent: ";
        $mesg = $ldap->search( base => $currentPath, scope  => 'one', filter => '('.$nextComponent.')' );

        # found, push to path and test next
        if ( $mesg->count() == 1) {
            #print "Found\n";
            $currentPath = $nextComponent.','.$currentPath;
            next;
        }

        #print Dumper( $mesg );
        #print "not Found - i: $i\n\n";

        # Reuse counter and list to build the missing nodes
        while ($i >= 0) {
            $nextComponentKey = lc $dn_attributes[$i][0];
            $nextComponentValue = $dn_attributes[$i][1];
            $currentPath = $self->_createPathItem($currentPath, $nextComponentKey, $nextComponentValue);
            $i--;
        }
    }

    return $self->_getbyDN( $dn );
}

sub _createPathItem {

    my $self = shift;
    my ($currentPath, $nextComponentKey, $nextComponentValue) = @_;

    my @objectclass = split " ", $self->conn()->get([ 'schema', $nextComponentKey , 'objectclass']);

    my $attrib = [
        objectclass => \@objectclass,
        $nextComponentKey => $nextComponentValue,
    ];

    # Default Values to push
    my $values = $self->conn()->get_hash( [ 'schema', $nextComponentKey , 'values'] );

    foreach my $key ( keys %{$values}) {
        push @{$attrib}, $key;
        my $val = $values->{$key};
        $val = $nextComponentValue if ($val eq 'copy:self');
        push @{$attrib}, $val;
    }

    my $newDN = sprintf '%s=%s,%s', $nextComponentKey, $nextComponentValue, $currentPath;

    #print "Create Node $newDN \n";
    #print Dumper( $attrib );

    $self->log()->debug("Create Node $newDN  with attributes " . Dumper $attrib);


    my $result = $self->ldap()->add( $newDN, attr => $attrib );
    if ($result->is_error()) {
        die $result->error_desc;
    }

    return $newDN;

}

sub _triggerAutoCreate {

    my $self = shift;
    my $args = shift;

    my $create_info = $self->conn()->get_hash('create');
    if (!$create_info) {
        $self->log()->warn('Auto-Create not configured');
        return;
    }

    my $value;
    # build create value from template
    if ($create_info->{value}) {
        my $template = Template->new({});
        $template->process(\$create_info->{value}, $args, \$value) || die "Error processing argument template.";
    } else {
        # Fallback to first argument = legacy config
        $value = $args->[0];
    }

    my $nodeDN = sprintf '%s=%s,%s', $create_info->{rdnkey}, $value, $create_info->{basedn};
    $self->log()->debug('Start Auto-Create for: '.$nodeDN);
    return $self->_getbyDN( $nodeDN, { create => 1} );

}

sub _splitDN {

    my $self = shift;
    my $dn = shift;

    my @parsed;
    while ($dn =~ /(([^=]+)=(.*?[^\\])\s*,)(.*)/) {
        push @parsed, [ $2, $3 ];
        $self->log()->debug(sprintf 'Split-Result: Key: %s, Value: %s, Remainder: %s ', $2, $3, $4);
        $dn = $4;
    };

    # Split last remainder at =
    my @last = split ("=", $dn);
    push @parsed, \@last;

    return @parsed;
}

sub _run_search {

    my $self = shift;
    my $arg = shift;
    my $params = shift;

    my %option = $self->_build_search_options( $arg, $params );

    my $mesg = $self->ldap()->search( %option );

    # Lost connection, try to rebind and rerun query
    # It looks like a half closed connection (server gone / load balancer etc)
    # causes an operational error and not a connection error
    # so the list of codes to use this reconnect foo is somewhat experimental
    # When changing this code please also check in _getByDN
    if ($mesg->is_error() && ($mesg->code() == 81 || $mesg->code() == 1)) {
        $self->log()->debug('Connection lost - try rebind and rerun query ' . $mesg->code());
        $self->_purge_bind();
        $mesg = $self->ldap()->search( %option );
    }

    return $mesg;

}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Connector::Proxy::Net::LDAP

=head1 DESCRIPTION

This is the base class for all LDAP Proxy modules. It does not offer any
external functionality but bundles common configuration options.

=head1 USAGE

=head2 minimal setup

    my $conn = Connector::Proxy::Net::LDAP->new({
       LOCATION  => 'ldap://localhost:389',
       base      => 'dc=example,dc=org',
       filter  => '(cn=[% ARGS.0 %])',
    });

    $conn->get('John Doe');

Above code will run a query of C<cn=test@example.org against the server>
using an anonymous bind.

=head2 using bind credentials

    my $conn = Connector::Proxy::Net::LDAP->new( {
        LOCATION  => 'ldap://localhost:389',
        base      => 'dc=example,dc=org',
        filter  => '(cn=[% ARGS.0 %])',
        binddn    => 'cn=admin,dc=openxpki,dc=org',
        password  => 'admin',
        attrs => ['usercertificate;binary','usercertificate'],
    });

Uses bind credentials and queries for entries having (at least) one of the
mentioned attributes.

=head2 setting values

You can control how existing attributes in the node are treated setting the
I<action> parameter in the connectors base configuration.

    connector:
        LOCATION:...
        ....
        action: replace

=over

=item replace

This is the default (the action parameter may be omitted). The passed value is
set as the only value in the attribute. Any values (even if there are more
than one) are removed. If undef is passed, the whole attribute is removed
from the node.

=item append

The given value is appended to exisiting attributes. If undef is passed, the request is ignored.

=item delete

The given value is deleted from the attribute entry. If there are more items in the attribute,
the remaining values are left untouched. If the value is not present or undef is passed,
the request is ignored.

=back


=head2 autocreation of missing nodes

If you want the connector to autocreate missing nodes, you need to provide the
ldap properties of each node-class.

    create:
        objectclass: inetOrgPerson pkiUser
        values:
            sn: copy:self
            ou: IT Department

You can specify multiple objectclass entries seperated by space.

The objects attribute is always set, you can use the special word C<copy:self>
to copy the attribute value within the object. The values section is optional.

=head2 Full example using Connector::Multi

    [ca1]
    myrepo@ = connector:connectors.ldap

    [connectors]

    [connectors.ldap]
    class = Connector::Proxy::Net::LDAP
    LOCATION = ldap://ldaphost:389
    base     = dc=openxpki,dc=org
    filter   = (cn=[% ARGS.0 %])
    attrs    = userCertificate;binary
    binddn   = cn=admin,dc=openxpki,dc=org
    password = admin
    action = replace

    [connectors.ldap.create]
    basedn: ou=Webservers,ou=Server CA3,dc=openxpki,dc=org
    rdnkey: cn
    value: [% ARGS.0 %]

    [connectors.ldap.schema.cn]
    objectclass: inetOrgPerson

    [connectors.ldap.schema.cn.values]
    sn: copy:self

    [connectors.ldap.schema.ou]
    objectclass: organizationalUnit

=head1 internal methods

=head2 _getByDN

Search a node by DN.

    $self->_getByDN( 'cn=John Doe,ou=people,dc=openxpki,dc=org' );

Returns the ldap entry object or undef if not found. Pass C<{create => 1}> and
configure your connector to auto create a new node if none is found.

=head2 _createPathItem

Used internally by _getByDN to create new nodes.

=head2 _triggerAutoCreate

Used internally to assemble the DN for a missing node.
Returns the ldap entry or undef if autocreation is not possible.

=head2 _splitDN

Very simple approch to split a DN path into its components.
Please B<do not> use quoting of path components, as this is
not supported. RDNs must be split by a Comma, Comma inside a value
must be escaped using a backslash character. Multivalued RDNs are not supported.

=head2 _run_search

This is a wrapper for

  my $mesg = $ldap->search( $self->_build_search_options( $args, $param ) );

that will take care of stale/lost connections to the server. The result
object is returned by the method, the ldap object is taken from the class.
