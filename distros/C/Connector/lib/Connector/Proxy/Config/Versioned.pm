# Connector::Proxy::Config::Versioned
#
# Proxy class for reading Config::Versioned configuration
#
# Written by Scott Hardin, Martin Bartosch and Oliver Welter
# for the OpenXPKI project 2012

# Todo - need some more checks on value types

package Connector::Proxy::Config::Versioned;

use strict;
use warnings;
use English;
use Config::Versioned;
use Data::Dumper;

use Moose;
extends 'Connector::Proxy';

has '+_config' => (
    lazy => 1,
);

has 'version' => (
    is => 'rw',
    isa => 'Str',
    required => 0,
    builder => 'fetch_head_commit',
);

sub _build_config {
    my $self = shift;

    my $config = Config::Versioned->new( { dbpath => $self->LOCATION(), } );

    if ( not defined $config ) {
        return; # try to throw exception
    }
    $self->version( $config->version() );
    return $config;
}


sub fetch_head_commit {
    my $self = shift;
    return $self->_config()->version();
}

sub get {
    my $self = shift;
    my $path = $self->_build_delimited_cv_path( shift );

    # We need a change to C:V backend to check if this is a node or not
    my $val = $self->_config()->get( $path, $self->version() );

    $self->_node_not_exists( $path ) unless (defined $val);

    return $val;
}

sub get_size {

    my $self = shift;
    my $path = $self->_build_delimited_cv_path( shift );

    # We check if the value is an integer to see if this looks like
    # an array - This is not bullet proof but should do

    my $val = $self->_config()->get( $path, $self->version() );

    return 0 unless( $val );

    die "requested path looks not like a list" unless( $val =~ /^\d+$/);

    return $val;

};

sub get_list {

    my $self = shift;
    my $path = $self->_build_delimited_cv_path( shift );

    # C::V uses an array with numeric keys internally - we use this to check if this is an array
    my @keys = $self->_config()->get( $path, $self->version() );
    my @list;

    if (!@keys) {
        $self->_node_not_exists( $path ) ;
        return @list;
    };

    foreach my $key (@keys) {
        if ($key !~ /^\d+$/) {
            die "requested path looks not like a list";
        }
        push @list, $self->_config()->get( $path.$self->DELIMITER().$key, $self->version() );
    }
    return @list;
};

sub get_keys {

    my $self = shift;
    my $path = $self->_build_delimited_cv_path( shift );

    my @keys = $self->_config()->get( $path, $self->version() );

    return @{[]} unless(@keys);

    return @keys;

};

sub get_hash {

    my $self = shift;
    my $path = $self->_build_delimited_cv_path( shift );

    my @keys = $self->_config()->get( $path, $self->version() );

    return $self->_node_not_exists( $path ) unless(@keys);
    my $data = {};
    foreach my $key (@keys) {
        $data->{$key} = $self->_config()->get( $path.$self->DELIMITER().$key, $self->version() );
    }
    return $data;
};


sub get_reference {
    my $self = shift;
    my $path = $self->_build_delimited_cv_path( shift );

    # We need a change to C:V backend to check if this is a node or not
    my $val = $self->_config()->get( $path, $self->version() );

    $self->_node_not_exists( $path ) unless (defined $val);

    if (ref $val ne "SCALAR") {
        die "requested path looks not like a reference";
    }

    return $$val;
};


# This can be a very expensive method and includes some guessing
sub get_meta {

    my $self = shift;
    my $path = $self->_build_delimited_cv_path( shift );

    my @keys = $self->_config()->get( $path, $self->version() );

    return $self->_node_not_exists( $path ) unless( @keys );

    my $meta = {
        TYPE => "hash"
    };

    # Do some guessing
    if (@keys == 1) {
        # a redirector reference
        if (ref $keys[0] eq "SCALAR") {
            $meta->{TYPE} = "reference";
            $meta->{VALUE} = ${$keys[0]};

        # Node with empty value
        } elsif ($keys[0] eq "") {
            $meta->{TYPE} = "scalar";
            $meta->{VALUE} = "";
        } else {
            # probe if there is something "below"
            my $val = $self->_config()->get(  $path . $self->DELIMITER() . $keys[0], $self->version() );
            if (!defined $val) {
                $meta->{TYPE} = "scalar";
                $meta->{VALUE} = $keys[0];
            } elsif( $keys[0] =~ /^\d+$/) {
                $meta->{TYPE} = "list";
            }
        }
    } elsif( $keys[0] =~ /^\d+$/) {
        $meta->{TYPE} = "list";
    }

    return $meta;
}


sub exists {

    my $self = shift;
    my $path = $self->_build_delimited_cv_path( shift );
    my $node;
    eval {
        $node = $self->_config()->get( $path, $self->version() );
    };
    return defined $node;

}

# return the path as string as used in C::V using the delimiter of C::V!
sub _build_delimited_cv_path {

    my $self = shift;
    my @path = $self->_build_path_with_prefix( shift );
    return join ( $self->_config()->delimiter(), @path );

}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 Name

Connector::Proxy::Config::Versioned

=head 1 Description

Fetch values ftom the underlying Config::Versioned repository.
On init, the commit id of the head is written into the local
version property and all further queries are done against this
commit id. You can set the version to be used at any time by passing
the commit id (sha1 hash) to C<version>.

To advance to the head commit of the underlying repository, use
C<fetch_head_commit> to get the id of the head and set it using
C<version>

=head1 methods

=head2 fetch_head_commit

Receive the sha1 commit id of the topmost commit of the underlying repository.

=head2 version
get/set the value of the version used for all get* requests.

