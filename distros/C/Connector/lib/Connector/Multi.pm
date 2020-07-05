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
                        $self->_log_and_die("Connector::Multi: error creating connector for '$target': $@");
                    }
                    $self->log()->debug("Dispatch to connector at $target");
                    # Push path on top of the argument array
                    unshift @args, \@suffix;
                    return $conn->$call( @args );
                } elsif ( $schema eq 'env' ) {

                    $self->log()->debug("Fetch from ENV with key $target");
                    # warn if the path is not empty
                    $self->log()->warn(sprintf("Call redirected to ENV but path is not final (%s)!", join(".",@suffix))) if (@suffix > 0);
                    if (!exists $ENV{$target}) {
                        return $self->_node_not_exists();
                    }
                    return $ENV{$target};

                } else {
                    $self->_log_and_die("Connector::Multi: unsupported schema for symlink: $schema");
                }
            } else {
                # redirect
                my @target = split(/[$delim]/, $meta->{VALUE});
                # relative path - shift one item from prefix for each dot
                if ($target[0] eq '') {
                    $self->log()->debug("Relative redirect at prefix " . join ".", @prefix);
                    while ($target[0] eq '') {
                        $self->_log_and_die("Relative path length exceeds prefix length") unless (scalar @prefix);
                        pop @prefix;
                        shift @target;
                    }
                } else {
                    $self->log()->debug(sprintf("Plain redirect at prefix %s to %s", join(".", @prefix), $meta->{VALUE}));
                    @prefix = ();
                }
                unshift @suffix, @target;
                $self->log()->debug("Final redirect target " . join ".", @suffix);
                unshift @args, [ @prefix, @suffix ];
                return $self->$call( @args );
            }
        } elsif ( $meta && $meta->{TYPE} eq 'connector' ) {

            my $conn = $meta->{VALUE};
            $self->log()->debug("Got conncetor reference of type ". ref $conn);
            $self->log()->debug("Dispatch to connector at " . join(".", @prefix));
            # Push path on top of the argument array
            unshift @args, \@suffix;
            return $conn->$call( @args );

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

    # the cache needs to store the absolute path including the prefix
    my @path = $self->_build_path( $target );
    my $cache_id = join($self->DELIMITER(), $self->_build_path_with_prefix( \@path ));
    my $conn = $self->_config()->{$cache_id};
    if ( ! $conn ) {
        # Note - we will use ourselves to read the connectors instance information
        # this allows to put other connectors inside a connector definition but
        # also lets connector definition paths depend on PREFIX!
        my $class = $self->get( [ @path, 'class' ] );
        if (!$class) {
            my $prefix = $self->_get_prefix() || '-';
            $self->_log_and_die("Nested connector without class ($target/$prefix)");
        }
        $self->log()->debug("Initialize connector $class at $target");
        eval "use $class;1" or $self->_log_and_die("Error use'ing $class: $@");
        $conn = $class->new( { CONNECTOR => $self, TARGET => $target } );
        $self->_config()->{$cache_id} = $conn;
        $self->log()->trace("Add connector to cache: $cache_id") if ($self->log()->is_trace());
    } elsif ($self->log()->is_trace()) {
        $self->log()->trace("Got connector for $target from cache $cache_id");
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

=head1 Examples

=head2 Connector References

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
    tokens@: connector:connectors.ldap-query-token
    owners@: connector:connectors.ldap-query-owners

With the symlink now in the key, Multi must walk down each level itself and
handle the symlink. When 'smartcards.tokens' is reached, it reads the contents
of the symlink, which is an alias to a connector 'ldap-query-token'. The
connector configuration is in the 'connectors' namespace of our primary data source.

  connectors:
    ldap-query-tokens:
      class: Connector::Proxy::Net::LDAP
      basedn: ou=smartcards,dc=example,dc=org
      uri: ldaps://example.org
      bind_dn: uid=user,ou=Directory Users,dc=example,dc=org
      password: secret

  connectors:
    ldap-query-owners:
      class: Connector::Proxy::Net::LDAP
      basedn: ou=people,dc=example,dc=org
      uri: ldaps://example.org
      bind_dn: uid=user,ou=Directory Users,dc=example,dc=org
      password: secret


=head2 Builtin Environment Connector

Similar to connector you can define a redirect to read a value from the
environment.

    node1:
        key@: env:OPENPKI_KEY_FROM_ENV

calling get('node1.key') will return the value of the environment variable
`OPENPKI_KEY_FROM_ENV`.

If the environment variable is not set, undef is returned. Walking over such a
node raises a warning but will silently swallow the remaining path components
and return the value of the node.

=head2 Inline Redirects

It is also possible to reference other parts of the configuration using a
kind of redirect/symlink.

    node1:
       node2:
          key@: shared.key1

    shared:
       key1: secret

The '@' sign indicates a symlink similar to the example given above but
there is no additional keyword in front of the value and the remainder of
the line is treated as an absolute path to read the value from.

If the path value starts with the path separator (default 'dot'), then the
path is treated as a relative link and each dot means "one level up".

    node1:
       node2:
          key2@: ..node2a.key

       node2a:
          key1@: .key
          key: secret

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

*Preset Connector References*

If you create your config inside your code you and have a baseconnector that
can handle object references (e.g. Connector::Builtin::Memory), you can
directly set the value of a node to a blessed reference of a Connector class.

    my $sub = Connector::Proxy::Net::LDAP->new( {
        basedn => "ou=smartcards,dc=example,dc=org"
    });

    $base->set('smartcard.tokens',  $sub )

=head1 OPTIONS

When creating a new instance, the C<new()> constructor accepts the
following options:

=over 8

=item BASECONNECTOR

This is a reference to the Connector instance that Connector::Multi
uses at the base of all get() requests.

=item PREFIX

You can set a PREFIX that is prepended to all path. There is one important
caveat to mention: Any redirects made are relative to the prefix set so you can
use PREFIX only if the configuration was prepared to work with it (e.g. to split
differnet domains and switch between them using a PREFIX).

    Example:

      branch:
        foo@: connector:foobar

        foobar:
          class: ....

Without a PREFIX set, this will return "undef" as the connector is not defined
at "foobar".

    my $bar = $multi->get( [ 'branch', 'foo', 'bar' ]);

This will work and return the result from the connector call using "bar" as key:

    my $multi = Connector::Multi->new( {
      BASECONNECTOR => $base,
      PREFIX => "branch",
    });
    my $bar = $multi->get( [ 'branch', 'foo', 'bar' ]);

Note: It is B<DANGEROUS> to use a dynamic PREFIX in the BASECONNECTOR as
Connector::Multi stores created sub-connectors in a cache using the path as key.
It is possible to change the prefix of the class itself during runtime.

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
