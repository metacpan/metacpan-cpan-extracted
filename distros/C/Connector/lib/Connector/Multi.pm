# Connector::Multi
#
# Connector class capable of dealing with multiple personalities.
#
# Written by Scott Hardin and Martin Bartosch for the OpenXPKI project 2012
#
package Connector::Multi;

use strict;
use warnings;
use English;
use Moose;
use Connector::Wrapper;

extends 'Connector';

has 'BASECONNECTOR' => ( is => 'ro', required => 1 );

has '+LOCATION' => ( required => 0 );

has '_cache' => ( is => 'rw', required => 0, isa => 'HashRef',  builder => '_init_cache' );

sub _init_cache {
    my $self = shift;

    $self->_cache( { 'node' => {} } );
}

sub _build_config {
    my $self = shift;

    # Our config is merely a hash of connector instances
    my $config = {};
    my $baseconn = $self->BASECONNECTOR();
    my $baseref;

    if ( ref($baseconn) ) { # if it's a ref, assume that it's a Connector
        $baseref = $baseconn;
    } else {
        eval "use $baseconn;1" or die "Error use'ing $baseconn: $@";
        $baseref = $baseconn->new({ LOCATION => $self->LOCATION() });
    }
    $config->{''} = $baseref;
    $self->_config($config);
}

# Proxy calls
sub get {
    my $self = shift;
    unshift @_, 'get';
    return $self->_route_call( @_ );
}

sub get_list {
    my $self = shift;
    unshift @_, 'get_list';

    return $self->_route_call( @_ );
}

sub get_size {
    my $self = shift;
    unshift @_, 'get_size';
    return $self->_route_call( @_ );
}

sub get_hash {
    my $self = shift;
    my @args = @_;
    unshift @_, 'get_hash';
    my $hash = $self->_route_call( @_ );
    return $hash unless (ref $hash); # undef

    # This assumes that all connectors that can handle references
    # use the symlink syntax introduced with Config::Versioned!
    my @path;
    foreach my $key (keys %{$hash}) {
        # Connector in leaf - resolv it!
        if (ref $hash->{$key} eq 'SCALAR') {
            @path = $self->_build_path(  $args[0] ) unless(@path);
            $hash->{$key} = $self->get( [ @path , $key ] );
        }
    }
    return $hash;
}

sub get_keys {
    my $self = shift;
    unshift @_, 'get_keys';

    return $self->_route_call( @_ );
}

sub set {
    my $self = shift;
    unshift @_, 'set';
    return $self->_route_call( @_ );
}

sub get_meta {
    my $self = shift;
    unshift @_, 'get_meta';
    return $self->_route_call( @_ );
}

sub exists {
    my $self = shift;
    unshift @_, 'exists';
    return $self->_route_call( @_ );
}

sub _route_call {

    my $self = shift;
    my $call = shift;
    my $location = shift;
    my @args = @_;

    my $delim = $self->DELIMITER();

    my $conn = $self->_config()->{''};

    if ( ! $conn ) {
        die "ERR: no default connector for Connector::Multi";
    }

    my @prefix = ();
    my @suffix = $self->_build_path_with_prefix( $location );
    my $ptr_cache = $self->_cache()->{node};

    $self->log()->debug('Call '.$call.' in Multi to '. join('.', @suffix));

    while ( @suffix > 0 ) {
        my $node = shift @suffix;
        push @prefix, $node;

        # Easy Cache - skip all inner nodes, that are not a connector
        # that might fail if you mix real path and complex path items
        my $path = join($delim, @prefix);
        if (exists $ptr_cache->{$path}) {
            next;
        }

        my $meta = $conn->get_meta($path);

        if ( $meta && $meta->{TYPE} eq 'reference' ) {
            if (  $meta->{VALUE} =~ m/^([^:]+):(.+)$/ ) {
                my $schema = $1;
                my $target = $2;
                if ( $schema eq 'connector' ) {
                    $conn = $self->get_connector($target);
                    if ( ! $conn ) {
                        die "Connector::Multi: error creating connector for '$target': $@";
                    }
                    $self->log()->debug("Dispatch to connector at $target");
                    # Push path on top of the argument array
                    unshift @args, \@suffix;
                    return $conn->$call( @args );
                } else {
                    die "Connector::Multi: unsupported schema for symlink: $schema";
                }
            } else {
                # redirect
                @prefix = ();
                @suffix = split(/[$delim]/, $meta->{VALUE});
                $self->log()->debug("Plain redirect to " . join ".", @suffix);
            }
        } else {
            $ptr_cache->{$path} = 1;
        }
    }

    # Push path on top of the argument array
    unshift @args, [ @prefix, @suffix ];
    return $conn->$call( @args );
}

sub get_wrapper() {
    my $self = shift;
    my $location = shift;
    return Connector::Wrapper->new({ BASECONNECTOR => $self, TARGET => $location });
}

# getWrapper() is deprecated - use get_wrapper() instead
sub getWrapper() {
    my $self = shift;
    warn "using deprecated call to getWrapper - use get_wrapper instead";
    $self->get_wrapper(@_);
}

sub get_connector {
    my $self = shift;
    my $target = shift;

    my $conn = $self->_config()->{$target};
    if ( ! $conn ) {
        # use the 'root' connector instance
        my @path = $self->_build_path_with_prefix( $target );
        my $class = $self->get( [ @path, 'class' ] );
        if (!$class) { die "Nested connector without class ($target)"; }
        eval "use $class;1" or die "Error use'ing $class: $@";
        $self->log()->debug("Initialize connector $class at $target");
        $conn = $class->new( { CONNECTOR => $self, TARGET => $target } );
        $self->_config()->{$target} = $conn;
    }
    return $conn;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Connector::Multi

=head1 DESCRIPTION

This class implements a Connector that is capable of dealing with dynamically
configured Connector implementations and symlinks.

The underlying concept is that there is a primary (i.e.: boot) configuration
source that Multi accesses for get() requests. If the request returns a reference
to a SCALAR, Multi interprets this as a symbolic link. The content of the
link contains an alias and a target key.

=head1 Example

In this example, we will be using a YAML configuration file that is accessed
via the connector Connector::Proxy::YAML.

From the programmer's view, the configuration should look something like this:

  smartcards:
    tokens:
        token_1:
            status: ACTIVATED
        token_2:
            status: DEACTIVATED
    owners:
        joe:
            tokenid: token_1
        bob:
            tokenid: token_2

In the above example, calling get('smartcards.tokens.token_1.status') returns
the string 'ACTIVATED'.

To have the data fetched from an LDAP server, we can redirect the
'smartcards.tokens' key to the LDAP connector using '@' to indicate symlinks.
Our primary configuration source for both tokens and owners would contain
the following entries:

  smartcards:
    @tokens: connector:connectors.ldap-query-token
    @owners: connector:connectors.ldap-query-owners

With the symlink now in the key, Multi must walk down each level itself and
handle the symlink. When 'smartcards.tokens' is reached, it reads the contents
of the symlink, which is an alias to a connector 'ldap-query-token'. The
connector configuration is in the 'connectors' namespace of our primary data source.

  connectors:
    ldap-query-tokens:
        class: Connector::Proxy::Net::LDAP
        basedn: ou=smartcards,dc=example,dc=org
        server:
            uri: ldaps://example.org
            bind_dn: uid=user,ou=Directory Users,dc=example,dc=org
            password: secret

  connectors:
    ldap-query-owners:
        class: Connector::Proxy::Net::LDAP
        basedn: ou=people,dc=example,dc=org
        server:
            uri: ldaps://example.org
            bind_dn: uid=user,ou=Directory Users,dc=example,dc=org
            password: secret

B<NOTE: The following is not implemented yet.>

Having two queries with duplicate server information could also be simplified.
In this case, we define that the server information is found when the
connector accesses 'connectors.ldap-query-token.server.<param>'. The
resulting LDAP configuration would then be:

  connectors:
    ldap-query-token:
        class: Connector::Proxy::Net::LDAP
        basedn: ou=smartcards,dc=example,dc=org
        @ldap-server: redirect:connectors.ldap-example-org
    ldap-query-owners:
        class: Connector::Proxy::Net::LDAP
        basedn: ou=people,dc=example,dc=org
        @ldap-server: redirect:connectors.ldap-example-org
    ldap-example-org:
        uri: ldaps://example.org
        bind_dn: uid=user,ou=Directory Users,dc=example,dc=org
        password: secret


The alias 'connectors.ldap-example-org' contains the definition needed by the LDAP
connector. In this case, we don't need a special connector object.
Instead, all we need is a simple redirect that allows two different
entries (in this case, the other two connectors) to share a common
entry in the tree.

=head1 SYNOPSIS

The parameter BASECONNECTOR may either be a class instance or
the name of the class, in which case the additional arguments
(e.g.: LOCATION) are passed to the base connector.

  use Connector::Proxy::Config::Versioned;
  use Connector::Multi;

  my $base = Connector::Proxy::Config::Versioned->new({
    LOCATION => $path_to_internal_config_git_repo,
  });

  my $multi = Connector::Multi->new( {
    BASECONNECTOR => $base,
  });

  my $tok = $multi->get('smartcard.owners.bob.tokenid');

or...

  use Connector::Multi;

  my $multi = Connector::Multi->new( {
    BASECONNECTOR => 'Connector::Proxy::Config::Versioned',
    LOCATION => $path_to_internal_config_git_repo,
  });

  my $tok = $multi->get('smartcard.owners.bob.tokenid');

You can also pass the path as an arrayref, where each element can be a path itself

  my $tok = $multi->get( [ 'smartcard.owners', 'bob.tokenid' ]);

=head1 OPTIONS

When creating a new instance, the C<new()> constructor accepts the
following options:

=over 8

=item BASECONNECTOR

This is a reference to the Connector instance that Connector::Multi
uses at the base of all get() requests.

=back

=head1 Supported methods

=head2 get, get_list, get_size, get_hash, get_keys, set, get_meta
Those are routed to the appropriate connector.

=head2 get_connector
Return the instance of the connector at this node

=head2 get_wrapper
Return a wrapper around this node. This is like setting a prefix for all
subsequent queries.

   my $wrapper = $conn->get_wrapper('test.node');
   $val = $wrapper->get('foo');

Is the same as
    $val = $conn->get_wrapper('test.node.foo');
