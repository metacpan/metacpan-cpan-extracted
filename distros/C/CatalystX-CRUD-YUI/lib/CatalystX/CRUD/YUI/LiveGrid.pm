package CatalystX::CRUD::YUI::LiveGrid;

use warnings;
use strict;
use Carp;
use Data::Dump qw( dump );
use MRO::Compat;
use mro "c3";
use base qw( Class::Accessor::Fast );
use JSON::XS ();
use Scalar::Util qw( blessed );
use CatalystX::CRUD::YUI::Serializer;

our $VERSION = '0.031';

__PACKAGE__->mk_accessors(
    qw( yui results controller form c
        method_name pk columns show_related_values
        col_filter text_columns col_names url count counter
        sort_by show_remove_button
        serializer_class serializer
        hide_pk_columns sort_dir title excel_url
        )
);

=head1 NAME

CatalystX::CRUD::YUI::LiveGrid - ExtJS LiveGrid objects

=head1 SYNOPSIS

 my $livegrid = $yui->livegrid( 
            results     => $results,    # CX::CRUD::Results or CX::CRUD::Object
            controller  => $controller, 
            form        => $form,
            method_name => $rel_info->{method},
            col_names   => $form->metadata->field_methods,
            c           => $c,          # Catalyst context object
 );
  
 $livegrid->serialize;  # returns serialized results
 $livegrid->count;      # returns number of rows

=head1 DESCRIPTION

This class represents the data necessary to support
the ExtJS-base LiveGrid component http://www.siteartwork.de/livegrid/.

=head1 METHODS

=head2 new( I<opts> )

Create a YUI LiveGrid object.
You usually call this via CatalystX::CRUD::YUI->livegrid( I<opts> ).

I<opts> should include:

=over

=item results

The I<results> object passed in. May be either
a CatalystX::CRUD::Results instance or CatalystX::CRUD::Object
instance.

If a Results instance, each object in the Results set will
be serialized.

If a Object instance, each object returned by I<method_name>
will be serialized.

=item form

The I<form> object should be an instance of the Form
class that corresponds to the data being serialized.
In the case where I<results> isa CatalystX::CRUD::Results
object, I<form> should be a Form corresponding
to the object class in CatalystX::CRUD::Results->results().
In the case where I<results> isa CatalystX::CRUD::Object,
I<form> should be a Form corresponding to the foreign
object class represented by I<method_name>.

=item controller

The I<controller> object should be the governing controller for
the objects being serialized, i.e., the controller governing I<form>.

=back

The new LiveGrid has the following accessors available:

=over

=item pk

The primary key of the table that I<results> represents.

=item columns

An arrayref of column hashrefs. YUI LiveGrid API requires these.

=item url

The url for fetching JSON results.

=item show_related_values

A hashref of foreign key information.

=item col_filter

An arrayref of column names. Used for filtering table by specific column
values.

=item col_names

An arrayref of column names. Defaults to I<form>->metadata->field_methods.

=item data

An arrayref of hashrefs. These are serialized from I<results>.

=item count

The number of items in I<data>.

=item counter

User-level accessor. You can get/set this to whatever you want.

=back

B<NOTE:> If you pass a CatalystX::CRUD::Object instance as I<results>
to new(), the object must implement a primary_key_uri_escaped() method
that conforms to the syntax defined by CatalystX::CRUD::Controller
make_primary_key_string(). See Rose::DBx::Object::MoreHelpers for one
example.

=cut

sub new {
    my $self = shift->next::method( ref $_[0] ? @_ : {@_} );
    $self->{serializer_class} ||= 'CatalystX::CRUD::YUI::Serializer';
    $self->_init;
    return $self;
}

sub _init {
    my $self       = shift;
    my $results    = $self->{results} or croak "results required";
    my $controller = $self->{controller}
        or croak "controller required";
    my $form = $self->{form} or croak "form required";
    my $app = ( $self->{c} || $form->app ) or croak "\$c object required";

    $self->{hide_pk_columns} = $controller->hide_pk_columns;

    # may be undef. this is the method we call on the the parent object,
    # where parent $results isa RDBO and we are creating a livegrid out
    # of its related objects.
    my $method_name = $self->{method_name};

    my @col_names = @{ $self->{col_names} || $form->metadata->field_methods };

    $self->pk(
        ref $controller->primary_key
        ? $controller->primary_key
        : [ $controller->primary_key ]
    );
    $self->columns( [] );
    $self->show_related_values( {} );
    $self->col_filter( [] );

    #carp "col_names for $results: " . dump $self->col_names;

    #carp dump $results;

    #Carp::cluck();

    if ( $results->isa('CatalystX::CRUD::Results')
        && defined $results->query )
    {
        $self->url(
            $app->uri_for(
                $controller->action_for('livegrid'),
                $results->query->{plain_query} || {}
            )
        );

        $self->sort_by( $form->metadata->default_sort_by || $self->pk->[0] );
    }
    else {

        #carp "results isa " . $results->delegate;
        #carp "controller isa " . $controller;

        if ( !$method_name ) {
            croak "method_name required for CatalystX::CRUD::Object livegrid";
        }
        $self->url(
            $app->uri_for(
                $controller->action_for(
                    $results->primary_key_uri_escaped, 'livegrid_related',
                    $method_name,
                )
            )
        );

        $self->sort_by( $form->metadata->default_related_sort_by
                || $self->pk->[0] );
    }

    $self->{url} .= '?' unless $self->{url} =~ m/\?/;

    my @filtered_col_names;

    for my $field_name (@col_names) {

        # we include PKs specially at the end.
        # exclude them here if they are single-col
        # (since those are often autoincrem)
        # but we turn on the 'hide' flag so that even
        # though they are rendered, they are invisible to user
        if ( @{ $self->{pk} } == 1
            and $self->{pk}->[0] eq $field_name )
        {
            $self->{hide_pk_columns} = 1
                unless defined $self->{hide_pk_columns};
            next;
        }

        push( @filtered_col_names, $field_name );

        my $isa_field = $form->field($field_name);
        my $isa_chain = $field_name =~ m/\./;
        my $col_def   = {
            key => $field_name,

            # must force label object to stringify
            label => defined($isa_field)
            ? $isa_field->label . ''
            : ( $form->metadata->labels->{$field_name} || $field_name ),

            sortable => ( $isa_field || $isa_chain )
            ? JSON::XS::true()
            : JSON::XS::false(),

            sort_prefix =>
                ( $form->metadata->sort_prefix->{$field_name} || '' ),

            type => $isa_field
            ? $self->_get_col_type( $isa_field->class )
            : 'string',

            # per-column click
            url => $app->uri_for( $form->metadata->field_uri($field_name) ),

        };
        push( @{ $self->{columns} }, $col_def );

        push(
            @{ $self->{col_filter} },
            { dataIndex => $col_def->{key}, type => $col_def->{type} }
        );

        if ( ( $isa_field and $col_def->{type} eq 'string' )
            or $isa_chain )
        {
            push( @{ $self->{text_columns} }, $field_name );
        }

        next unless $form->metadata->show_related_values;
        next unless $form->metadata->is_related_field($field_name);

        my $rel_info = $form->metadata->related_field($field_name);
        my $ffield   = $form->metadata->show_related_field_using(
            $rel_info->{foreign_class}, $field_name, );
        $self->{show_related_values}->{$field_name} = {
            method        => $rel_info->{method},
            foreign_field => $ffield,
        };

        next;

        # TODO allow for non-local column names to be filtered on

        if (    $isa_field
            and $col_def->{type} ne 'string' )
        {
            push( @{ $self->{text_columns} }, $rel_info->{method} );
        }

    }

    # always include pk since that's what is used for links
    my $pk_name = join( ';;', @{ $self->{pk} } );
    my $col_def = {
        key => $pk_name,

        # must force label object to stringify
        label => (
            $form->metadata->labels->{$pk_name}
                || join( ' ', map { ucfirst($_) } split( m/\_/, $pk_name ) )
        ),

        sortable => $pk_name =~ m/;;/
        ? JSON::XS::false()
        : JSON::XS::true(),

        type => 'pk',

        # per-column click
        url => $app->uri_for( $form->metadata->field_uri($pk_name) ),
    };
    push( @{ $self->{columns} }, $col_def );
    push(
        @{ $self->{col_filter} },
        { dataIndex => $col_def->{key}, type => $col_def->{type} }
    );

    push( @filtered_col_names, $self->pk );

    $self->col_names( \@filtered_col_names );

    if ( $self->{sort_by} =~ s/ (ASC|DESC)$//i ) {
        $self->{sort_dir} = $1;
    }
    else {
        $self->{sort_dir} = 'ASC';
    }

    my $moniker;
    my $object_class = $form->metadata->object_class;
    if ( $object_class->can('moniker') ) {
        $moniker = $object_class->moniker;
    }
    else {
        $moniker = $object_class;
    }
    $moniker =~ s/^.+:://;
    $self->{title} = 'Results for ' . $moniker;

    return $self;
}

=head2 column( I<field_name> )

Return the column hashref meta for I<field_name>.
The hashref has 3 keys: key, label, and sortable.

=cut

sub column {
    my $self       = shift;
    my $field_name = shift;
    for my $col ( @{ $self->columns } ) {
        return $col if $col->{key} eq $field_name;
    }
    return undef;
}

=head2 serialize 

Returns LiveGrid as array ref of hash refs, suitable
for conversion to JSON or other transport type.

=cut

sub serialize {
    my $self = shift;
    my $serializer = $self->serializer || $self->serializer_class->new;
    return $serializer->serialize_livegrid($self);
}

sub _get_col_type {
    my ( $self, $class ) = @_;

    #warn "class = $class\n";

    $class ||= 'text';

    if ( $class =~ m/text|char|autocomplete/ ) {
        return 'string';
    }
    elsif ( $class =~ m/int|num|radio|serial/ ) {
        return 'numeric';
    }
    elsif ( $class eq 'boolean' ) {
        return 'boolean';
    }
    elsif ( $class =~ m/date|time/ ) {
        return 'date';
    }
    else {
        return 'string';
    }

}

=head2 json_reader_opts

Returns hash ref suitable for JSON-ifying and passing to
the LiveGrid JsonReader constructor.

=cut

sub json_reader_opts {
    my $self = shift;

    return {
        restful         => JSON::XS::true(),
        root            => 'response.value.items',
        versionProperty => 'response.value.version',
        totalProperty   => 'response.value.total_count',
        id              => join( ';;', @{ $self->pk } ),
        }

}

=head2 json_reader_columns

Returns array ref suitable for JSON-ifying and passing
to the LiveGrid JsonReader constructor.

=cut

sub json_reader_columns {
    my $self = shift;
    my $cols = $self->{columns};

    my @new;
    for my $col (@$cols) {
        my $hash = { name => $col->{key} };
        if ( $col->{sortable} ) {
            $hash->{sortType}
                = ( $col->{type} eq 'string' )
                ? 'string'
                : 'int';
        }
        push( @new, $hash );
    }
    return \@new;
}

=head2 column_defs

Returns array ref suitable for JSON-ifying for LiveGrid JS.

=cut

sub column_defs {
    my $self = shift;
    my @defs;
    for my $col ( @{ $self->columns } ) {
        my $def = {
            header     => $col->{label},
            align      => 'left',
            sortable   => $col->{sortable},
            sortPrefix => $col->{sort_prefix},
            dataIndex  => $col->{key},
            type       => $col->{type},
        };
        if ( $def->{type} eq 'pk' && $self->{hide_pk_columns} ) {
            $def->{hidden} = JSON::XS::true();
            $def->{type}   = 'string';
        }
        if ( $col->{key} =~ m/\./ ) {
            $def->{type} = 'string';
        }
        push( @defs, $def );
    }
    return \@defs;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-crud-yui@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
and NALD C<< http://www.nald.ca/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

