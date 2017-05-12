# Copyright 2008-2010 Tim Rayner
# 
# This file is part of Bio::MAGETAB.
# 
# Bio::MAGETAB is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
# 
# Bio::MAGETAB is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Bio::MAGETAB.  If not, see <http://www.gnu.org/licenses/>.
#
# $Id: DBLoader.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::Util::DBLoader;

use Moose;
use MooseX::FollowPBP;

use Bio::MAGETAB;
use Carp;
use DBI;
use List::Util qw( first );
use English qw( -no_match_vars );

extends 'Bio::MAGETAB::Util::Builder';

has 'database'            => ( is         => 'rw',
                               isa        => 'Bio::MAGETAB::Util::Persistence',
                               required   => 1,
                               handles    => [ qw( insert
                                                   update
                                                   select
                                                   id
                                                   count
                                                   remote ) ], );

sub _manage_namespace_authority {

    my ( $self, $data, $class ) = @_;

    # Add authority, namespace to everything _except_ DBEntries with
    # defined term source, or TermSource itself.
    if ( UNIVERSAL::isa( $class, 'Bio::MAGETAB::TermSource' ) ) {
        $data->{'namespace'} ||= q{};
        $data->{'authority'} ||= q{};
    }
    elsif ( defined $data->{'termSource'} ) {
        $data->{'namespace'} ||= q{};
        $data->{'authority'} ||= $data->{'termSource'}->get_name();
    }
    else {
        $data->{'namespace'} ||= $self->get_namespace();
        $data->{'authority'} ||= $self->get_authority();
    }
}

sub _query_database {

    my ( $self, $class, $data, $id_fields ) = @_;

    unless ( first { defined $data->{ $_ } } @{ $id_fields } ) {
        my $allowed = join(', ', @{ $id_fields });
        confess(qq{Error: No identifying attributes for $class.}
              . qq{ Must use at least one of the following: $allowed.\n});
    }

    my $remote = $self->remote( $class );

    my ( $clean_data, $aggregators )
        = $self->_strip_aggregator_info( $class, $data );

    # Add authority, namespace to $id_fields unless $data has a
    # termSource.  Also, TermSources themselves are *always* treated
    # as global in this way.
    my %tmp_fields = map { $_ => 1 } @{ $id_fields }, qw( namespace authority );
    $id_fields = [ keys %tmp_fields ];
    $self->_manage_namespace_authority( $data, $class );

    my $filter;
    FIELD:
    foreach my $field ( @{ $id_fields } ) {

        my $value = $data->{ $field };

        # Don't add aggregator fields to the query (the schema doesn't
        # know about them).
        next FIELD if ( first { $field eq $_ } @{ $aggregators } );

        # Skip the field if it's looking for a dummy object not in the
        # database yet.
        next FIELD if ( UNIVERSAL::isa( $value, 'Bio::MAGETAB::BaseClass' )
            && ! $self->id( $value ) );

        # Another special case - URI can change in the model
        # between input and output (specifically, a file: prefix
        # may be added). This is copied from
        # Bio::MAGETAB::Types. FIXME date will need the same
        # treatment.
        if ( defined $value && $field eq 'uri' ) {
            use URI;
            $value = URI->new( $value );

            # We assume here that thet default URI scheme is "file".
            unless ( $value->scheme() ) {
                $value->scheme('file');
            }
        }

        # Warn the user about a known Tangram bug.
        if ( $value && $value =~ /\%/ ) {
            warn("Warning: ID fields containing the percent character (%) may"
                ." lead to problems with object retrieval. See the documentation for "
                .__PACKAGE__." for a discussion of this bug.\n");
        }

        {
            # Tangram::Expr treats undef as IS NULL.
            no warnings qw( uninitialized );

            # Much operator overloading means that we have to be
            # careful here.
            eval {
                my $expr;
                if ( blessed $value ) {
                    $expr = ( $remote->{ $field } == $value );
                }
                else {
                    $expr = ( $remote->{ $field } eq $value );
                }

                if ( $filter ) {
                    $filter &= ( $expr );
                }
                else {
                    $filter  = ( $expr );
                }
            };
            if ( $EVAL_ERROR ) {
                croak("Error constructing filter for $field == $value: $EVAL_ERROR")
            }

            # End of 'no warnings' pragma.
        }
    }

    # Find objects matching the ID fields.
    my @objects = $self->select( $remote, $filter );

    # We deal with aggregators in a second select at this point. Not
    # terribly efficient, but the model limits us here.
    foreach my $agg_field ( @{ $aggregators } ) {
        my $agg = $data->{ $agg_field };
        unless ( defined $agg ) {
            confess("Error: Undefined aggregator field for class $class.");
        }
        my @attr = $agg->meta()->get_all_attributes();
        my %map = map { $_->type_constraint()->name() => $_->name() } @attr;

        my ( $is_list, $target, $method );
        ATTR:
        while ( my ( $constraint, $attr ) = each %map ) {
            ( $is_list, $target ) = ( $constraint =~ /\A (ArrayRef)? \[? ([^\[\]]+) \]? \z/xms );

            unless ( $target ) {
                confess("Error: Moose type constraint name not parseable");
            }
            if ( UNIVERSAL::isa( $class, $target ) ) {
                $method = $attr;
                last ATTR;
            }
        }
        unless ( defined $method ) {
            confess("Error: Unable to parse type constraint to identify the aggregate attribute.");
        }

        my $agg_remote = $self->remote( $agg->meta()->name() );
        if ( $is_list ) {
            my @new = grep {
                my @c = $self->get_database()
                             ->select( $agg_remote, $agg_remote->{$method}->includes( $_ ) );
                first { $self->id( $agg ) == $self->id( $_ ) } @c;
            } @objects;
            @objects = @new;
        }
        else {
            my @new = grep {
                my @c = $self->get_database()
                             ->select( $agg_remote, $agg_remote->{$method} eq $_ );
                first { $self->id( $agg ) == $self->id( $_ ) } @c;
            } @objects;
            @objects = @new;
        }
    }

    # Brief sanity check; identity means identity, i.e. only one object returned.
    if ( scalar @objects > 1 ) {
        my $id = $self->_create_id( $class, $data, $id_fields );
        confess(qq{Error: multiple $class objects found in database. Internal ID was "$id".});
    }

    return $objects[0];
}

sub _get_object {

    my ( $self, $class, $data, $id_fields ) = @_;

    if ( my $retval = $self->_query_database( $class, $data, $id_fields ) ) {
        return $retval;
    }
    elsif ( $self->get_relaxed_parser() ) {

        # If we're relaxing constraints, try and create an
        # empty object (in most cases this will probably fail
        # anyway).
        my $retval;
        eval {
            $retval = $self->_find_or_create_object( $class, $data, $id_fields );
        };
        if ( $EVAL_ERROR ) {
            croak(qq{Error: Unable to autogenerate $class object: $EVAL_ERROR\n});
        }
        return $retval;
    }
    else {
        croak(qq{Error: $class object not found in database.\n});
    }
}

sub _create_object {

    my ( $self, $class, $data, $id_fields ) = @_;

    # Strip out aggregator identifier components
    $data = $self->_strip_aggregator_info( $class, $data );

    # Make sure our authority and namespace attributes are
    # appropriately managed.
    $self->_manage_namespace_authority( $data, $class );

    # Strip out any undefined values, which will only create problems
    # during object instantiation.
    my %cleaned_data;
    while ( my ( $key, $value ) = each %{ $data } ) {
        if ( defined $value ) {
            $cleaned_data{ $key } = $value;
        }
    }

    # Initial object creation.
    my $obj = $class->new( %cleaned_data );

    # Store object in cache for later retrieval.
    $self->insert( $obj );

    return $obj;
}

sub _find_or_create_object {

    my ( $self, $class, $data, $id_fields ) = @_;

    my $obj = $self->_query_database( $class, $data, $id_fields );

    # Strip out aggregator identifier components
    $data = $self->_strip_aggregator_info( $class, $data );

    if ( $obj ) {

        # Update the old object as appropriate.
        $self->_update_object_attributes( $obj, $data );

        # Write the changes to the database.
        $self->update( $obj );
    }
    else {

        # Not found; we create a new object.
        $obj = $self->_create_object( $class, $data, $id_fields );
    }

    return $obj;
}

# Make the classes immutable. In theory this speeds up object
# instantiation for a small compilation time cost.
__PACKAGE__->meta->make_immutable();

no Moose;

=head1 NAME

Bio::MAGETAB::Util::DBLoader - A persistent storage class used to
track Bio::MAGETAB object creation and insertion into a relational
database.

=head1 SYNOPSIS

 require Bio::MAGETAB::Util::Reader;
 require Bio::MAGETAB::Util::Persistence;
 require Bio::MAGETAB::Util::DBLoader;
 
 my $reader = Bio::MAGETAB::Util::Reader->new({
     idf => $idf
 });
 
 my $db = Bio::MAGETAB::Util::Persistence->new({
     dbparams => ["dbi:SQLite:$db_file"],
 });
 
 # If this is a new database, deploy the schema.
 unless ( -e $db_file ) {
     $db->deploy();
 }
 
 # Connect to the database.
 $db->connect();
 
 my $builder = Bio::MAGETAB::Util::DBLoader->new({
     database => $db,
 });
 
 $reader->set_builder( $builder );
 
 # Read objects into the database.
 $reader->parse();

=head1 DESCRIPTION

DBLoader is a Builder subclass which uses a relational database
backend to track object creation, rather than the simple hash
reference mechanism used by Builder. See the
L<Persistence|Bio::MAGETAB::Util::Persistence> class and the Tangram module
documentation for more information on supported database engines.

=head1 ATTRIBUTES

See the L<Builder|Bio::MAGETAB::Util::Builder> class for documentation on the superclass
attributes.

=over 2

=item database

The internal store to use for object lookups. This must be a
Bio::MAGETAB::Util::Persistence object.

=back

=head1 METHODS

See the L<Builder|Bio::MAGETAB::Util::Builder> class for documentation on the superclass
methods.

=head1 CAVEATS

Objects when modified are not automatically updated in the
database. You should use the C<update> method to do this (see
L<METHODS|Bio::MAGETAB::Util::Builder/METHODS> in the Builder class). In particular, it is
important to bear in mind that there are places in the Bio::MAGETAB
model where relationships between objects are being maintained behind
the scenes (this allows certain relationships to be navigable in both
directions). When modifying these objects, you must also call
C<update> on their target objects to ensure the database is kept
synchronized with the objects held in memory. For example:

 # SDRFRow to Nodes is a reciprocal relationship:
 my $row = $loader->create_sdrf_row({
    nodes => \@nodes,
 });
 
 # @nodes now know about $row, but the database doesn't know this:
 $loader->update( @nodes );

 # Similarly, with Edges and Nodes:
 my $edge = $loader->find_or_create_edge({
    inputNode  => $in,
    outputNode => $out,
 });
 
 # Again, $in and $out know about $edge, but the database does not:
 $loader->update( $in, $out );

=head1 KNOWN BUGS

When used with SQLite or MySQL (and possibly others), the Tangram
modules incorrectly modify any C<select> statements containing the '%'
character, so that this character is replaced with '%%'. This means
that while values are correctly inserted into the database they are
not retrieved correctly, and this may result in errors or duplicate
entries when working with objects whose identifying fields contains a
'%' character. See the L<Builder|Bio::MAGETAB::Util::Builder> class for a discussion on
object identity, and
L<http://rt.cpan.org/Public/Bug/Display.html?id=29133> for a possible
quick fix for this Tangram bug.

=head1 SEE ALSO

L<Bio::MAGETAB::Util::Reader>
L<Bio::MAGETAB::Util::Builder>
L<Bio::MAGETAB::Util::Persistence>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 LICENSE

This library is released under version 2 of the GNU General Public
License (GPL).

=cut

1;
