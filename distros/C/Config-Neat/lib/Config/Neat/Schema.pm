=head1 NAME

Config::Neat::Schema - Validate Config::Neat files against schema

=head1 SYNOPSIS

File 01.nconf:

    foo {
        bar         baz etc

        etc {
            pwd     1 2
        }
    }
    abc             def

File schema.nconf:

    foo
    {
        bar         ARRAY
        etc
        {
            *       ARRAY
            pwd     STRING
        }
    }
    data            DATA

if file 01.nconf is validated against schema.nconf, it will:
1) convert arrays to strings for the known nodes with 'STRING' type
2) die or warn (depending on the settings) when an unknown node is found
   (in the example above, 'abc').

'*' as the name of the node means 'node with any name'. If such catch-all rule
is not specified, all possible node values need to be specified explicitly.

Possible type specifiers are: HASH (this is default if not specified),
ARRAY, STRING, ARRAY_OR_HASH, STRING_OR_HASH, or DATA. 'DATA' nodes may contain
any arbitrary data structure and are not validated.

=head1 COPYRIGHT

Copyright (C) 2012-2015 Igor Afanasyev <igor.afanasyev@gmail.com>

=head1 SEE ALSO

L<https://github.com/iafan/Config-Neat>

=cut

package Config::Neat::Schema;

our $VERSION = '1.401';

use strict;

use Config::Neat::Array;
use Config::Neat::Inheritable;
use Config::Neat::Util qw(new_ixhash is_hash is_any_hash is_any_array is_simple_array is_neat_array hash_has_sequential_keys);
use File::Spec::Functions qw(rel2abs);
use File::Basename qw(dirname);
use Tie::IxHash;

#
# Initialize object
#
sub new {
    my ($class, $data) = @_;

    my $self = {
        schema => $data
    };

    bless $self, $class;
    return $self;
}

# Given file name, will read and store the schema file
sub load {
    my ($self, $filename, $binmode) = @_;
    my $c = Config::Neat::Inheritable->new();
    return $self->{schema} = $c->parse_file($filename, $binmode);
}

# Store loaded data as current schema
sub set {
    my ($self, $data) = @_;
    $self->{schema} = $data;
}

# Validates provided data structure (parsed config file) against the previously loaded schema
# with expanded '@inherit' blocks
sub validate {
    my ($self, $data) = @_;
    die "Schema should be loaded prior to validation" unless defined $self->{schema};
    return $self->validate_node($self->{schema}, $data, undef, undef, []);
}

sub validate_node {
    my ($self, $schema_node, $data_node, $parent_data, $parent_data_key, $path) = @_;

    my $pathstr = '/'.join('/', @$path);

    if (!$schema_node) {
        die "Node '$pathstr' is not defined in the schema";
    }

    my $schema_type = $self->get_node_type($schema_node);
    my $data_type = $self->get_node_type($data_node);

    #print "::[$pathstr] schema_type=[$schema_type], data_type=[$data_type]\n";
    #use Data::Dumper; print Dumper($data_node);

    if ($schema_type eq 'STRING') {
        # the node itself is already a scalar and contains the type definition
        $schema_type = $schema_node;
    } elsif ($schema_type eq 'ARRAY') {
        # the string representation of the node contains the type definition
        $schema_type = $schema_node->as_string;
    } elsif ($schema_type eq 'HASH' and defined $schema_node->{''}) {
        # if it's a hash, the the string representation of the node's default parameter
        # may contain the type definition override
        my $val = $schema_node->{''};
        $schema_type = $schema_node->{''}->as_string if is_neat_array($val);
        $schema_type = $schema_node->{''} if ref(\$val) eq 'SCALAR';
    }

    # disambiguate fuzzy node schema types
    if ($schema_type eq 'ARRAY_OR_HASH') {
        $schema_type = ($data_type eq 'HASH') ? 'HASH' : 'ARRAY';
    }

    if ($schema_type eq 'STRING_OR_HASH') {
        $schema_type = ($data_type eq 'HASH') ? 'HASH' : 'STRING';
    }

    # automatic casting from ARRAY to STRING
    if ($schema_type eq 'STRING' and $data_type eq 'ARRAY') {
        $parent_data->{$parent_data_key} = $data_node = $data_node->as_string;
        $data_type = $schema_type;
    }

    # automatic casting from ARRAY to BOOLEAN
    if ($schema_type eq 'BOOLEAN' and $data_type eq 'ARRAY') {
        die "'".$data_node->as_string."' is not a valid boolean number\n" unless $data_node->is_boolean;
        $parent_data->{$parent_data_key} = $data_node = $data_node->as_boolean;
        $data_type = $schema_type;
    }

    # skip (don't validate) DATA nodes
    return 1 if ($schema_type eq 'DATA');

    if ($schema_type eq 'LIST') {
        # if this is not a simple array of scalars, wrap as an array
        if (is_simple_array($data_node) or !is_any_array($data_node)) {
            $data_node = [$data_node];
        }
        # then, convert an array to an ixhash with sequential keys
        my $h = new_ixhash;
        my $i = 0;
        map { $h->{$i++} = $_ } @$data_node;
        $parent_data->{$parent_data_key} = $data_node = $h;

        $data_type = 'HASH';
        $schema_type = 'ARRAY';
    }

    # see if automatic casting from HASH to ARRAY is possible
    my $cast_to_array;

    if ($schema_type eq 'ARRAY' and $data_type eq 'HASH') {
        die "Can't cast '$pathstr' to ARRAY, since it is a HASH containing non-sequential keys" unless hash_has_sequential_keys($data_node);
        $cast_to_array = 1;
    }

    if ($schema_type ne $data_type && !$cast_to_array) {
        die "'$pathstr' is $data_type, while it is expected to be $schema_type";
    }

    if ($data_type eq 'ARRAY') {
        # flatten the array
        $parent_data->{$parent_data_key} = $data_node->as_flat_array;
    }

    if ($data_type eq 'HASH') {
        foreach my $key (keys %$data_node) {
            my @a = @$path;
            push @a, $key;
            if ($key eq '') {
                # TODO: check if the default parameter for the hash is allowed, and if it is a string or array
            } else {
                die "Can't validate '/", join('/', @a), "', because schema contains no definition for it" if !is_hash($schema_node);
                my $schema_subnode = $schema_node->{$key} || $schema_node->{'*'};
                $self->validate_node($schema_subnode, $data_node->{$key}, $data_node, $key, \@a);
            }
        }
    }

    if ($cast_to_array) {
        my @a = values %$data_node;
        $parent_data->{$parent_data_key} = Config::Neat::Array->new(\@a);
    }

    return 1;
}

sub get_node_type {
    my ($self, $node) = @_;
    return 'HASH' if ref($node) eq 'HASH';
    return 'ARRAY' if is_any_array($node);
    return 'STRING' if ref(\$node) eq 'SCALAR';
    return 'UNKNOWN';
}

1;