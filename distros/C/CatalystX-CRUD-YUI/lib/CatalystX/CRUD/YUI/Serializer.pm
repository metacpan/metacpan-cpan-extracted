package CatalystX::CRUD::YUI::Serializer;

use warnings;
use strict;
use Carp;
use base 'Class::Accessor::Fast';
use MRO::Compat;
use mro "c3";
use Scalar::Util qw( blessed );
use JSON::XS ();
use Data::Dump qw( dump );

__PACKAGE__->mk_accessors(qw( datetime_format yui html_escape ));

our $VERSION = '0.031';

# html escaping
my %Ents = (
    '>' => '&gt;',
    '<' => '&lt;',
    '&' => '&amp;',
    '"' => '&quot;',
    "'" => '&apos;'
);
my $ToEscape = join( '', keys %Ents );

=head1 NAME

CatalystX::CRUD::YUI::Serializer - flatten CatalystX::CRUD::Object instances

=head1 SYNOPSIS

 use CatalystX::CRUD::YUI::Serializer;
 
 my $serializer = CatalystX::CRUD::YUI::Serializer->new(
                    datetime_format => '%Y-%m-%d %H:%M:%S',
                    html_escape     => 1,
                    );
                    
 my $hashref = $serializer->serialize_object( 
                    object      => $my_object,
                    col_names   => [qw( id name email )],  
                    cat_context => $c,
                    rel_info    => $rel_info,
                );
 

=head1 DESCRIPTION

CatalystX::CRUD::YUI::Serializer turns objects into hashrefs,
typically for rendering as JSON.
 
=head1 METHODS

Only new or overridden method are documented here.

=cut

=head2 new

Instantiate new Serializer.

=cut

sub new {
    my $class = shift;
    my $self = $class->next::method( ref $_[0] ? @_ : {@_} );
    $self->{datetime_format} ||= '%Y-%m-%d %H:%M:%S';
    $self->{html_escape} = 1 unless defined $self->{html_escape};
    return $self;
}

=head2 datetime_format

Set strftime-style DateTime format string. Default is '%Y-%m-%d %H:%M:%S'.
Used in serialize_object().

=cut

=head2 html_escape

serialize_object() will escape all special HTML characters by default.
Set html_escape to false (0) if turn that feature off.

=cut

=head2 serialize_object( I<params> )

Serialize a CatalystX::CRUD::Object instance, or an object that acts like one. 
I<params> should be a hash or hashref of key/value pairs.
The "object" key pair and "col_names" key pair are required.

I<params> include:

=over

=item

I<object> is the CRUD object to be serialized. B<Required>

=item

I<rel_info> is a
Rose::HTMLx::Form::Related::RelInfo object.

=item

I<col_names> is the list of column names to include in the serialized hashref.
B<Required>

=item

I<parent_object> is the originating object, in the case 
where you are serializing related objects.

=item

I<cat_context> is a $c object.

=item

I<show_related_values> is a hash ref of methods and foreign fields,
as defined by Rose::HTMLx::Form::Related.

=item

I<takes_object_as_argument> is a hashref of method names where I<parent_object>
is expected as a single argument.

=back

Returns a hashref of key/value pairs representing the object.

=cut

sub serialize_object {
    my $self         = shift;
    my %opts         = ref( $_[0] ) ? %{ $_[0] } : @_;
    my $object       = delete $opts{object} or croak "CRUD object required";
    my $show_related = delete $opts{show_related_values};
    my $takes_object = delete $opts{takes_object_as_argument};
    my $col_names    = delete $opts{col_names} or croak "col_names required";

    if ( defined $show_related
        and ref($show_related) ne 'HASH' )
    {
        croak "show_related_values should be a hashref";
    }
    if ( defined $takes_object
        and ref($takes_object) ne 'HASH' )
    {
        croak "takes_object_as_argument should be a hashref";
    }
    if ( ref($col_names) ne 'ARRAY' ) {
        croak "col_names array ref required";
    }

    my $flat = {};
    if ( defined $opts{livegrid} and $opts{livegrid}->show_remove_button ) {
        $flat->{'_remove'} = ' X ';
    }

    #carp "calling col_names on $object : " . dump $col_names;

    #carp dump $takes_object;

    for my $col (@$col_names) {

        # if $col is array ref, then it is PK.
        # however, value may not always be primary_key_uri_escaped()
        # since the controller may define an alternate primary_key.
        # so use the controller to get the value.
        if ( ref($col) eq 'ARRAY' ) {
            $flat->{ join( ';;', @$col ) } = $opts{livegrid}
                ->controller->make_primary_key_string($object);
            next;
        }

        # if $col has a . (dot) then it is a chained string of methods
        my @methods = split( m/\./, $col );
        my $first_method = shift @methods;

        # sanity check
        if ( !$object->can($first_method) ) {
            croak "no such method '$first_method' for object $object";
        }

        # non-accessor methods. these are NOT FK methods.
        # see below for $show_related_values.
        if ( exists $takes_object->{$col} and exists $opts{parent} ) {

            # TODO revisit this api
            # right now we only pass parent if it isa class
            # designated in the $takes_object hash

            #warn "FOUND takes_object $col => $opts{parent}";

            if ( my $parent_class = blessed( $opts{parent} ) ) {
                my $obj_to_pass;
                if ( $opts{parent}->can('delegate')
                    and blessed( $opts{parent}->delegate ) )
                {

                    #warn " obj with delegate = " . $opts{parent}->delegate;
                    if ( $opts{parent}->delegate->isa( $takes_object->{$col} )
                        )
                    {
                        $obj_to_pass = $opts{parent}->delegate;
                    }
                }
                elsif ( $opts{parent}->isa( $takes_object->{$col} ) ) {
                    $obj_to_pass = $opts{parent};
                }

                if ($obj_to_pass) {
                    eval {
                        $flat->{$col}
                            = $object->$first_method( $opts{parent} );
                    };
                    if ($@) {
                        $flat->{$col} = '[not available]';
                    }
                }
                else {
                    $flat->{$col} = $object->$first_method;
                }

            }
            else {
                eval {
                    $flat->{$col} = $object->$first_method( $opts{parent} );
                };
                if ($@) {
                    $flat->{$col} = '[not available]';
                }
            }

            next;

        }

        # get end value
        my $value = $object->$first_method;
        if ( defined $value ) {
            for my $m (@methods) {
                my $v = $value->$m;
                if ( defined $v ) {
                    $value = $v;
                }
            }
        }

        # DateTime objects
        if ( blessed($value) && $value->isa('DateTime') ) {
            if ( defined $value->epoch ) {
                $flat->{$col} = $value->strftime( $self->datetime_format );
            }
            else {
                $flat->{$col} = '';
            }
        }

        # FKs
        elsif ( defined $show_related
            and exists $show_related->{$col} )
        {
            my $srv    = $show_related->{$col};
            my $method = $srv->{method};
            my $ff     = $srv->{foreign_field};

            #warn "col: $col  rdbo: $rdbo  method: $method  ff: $ff";
            if ( defined $object->$method && defined $ff ) {
                $flat->{$col} = $object->$method->$ff;
            }
            else {
                $flat->{$col} = $value;
            }
        }

        # booleans
        elsif ( $object->can('column_is_boolean')
            and $object->column_is_boolean($col) )
        {
            $flat->{$col} = $value ? 'true' : 'false';
        }

        # default
        else {
            $flat->{$col} = $value;

        }

    }

    # if results were passed in, treat them as child list
    if ( $opts{results} ) {
        my @data;
        my $relname = delete $opts{relname}
            or croak "relname required if results defined";
        my $relname_fields = delete $opts{relname_fields}
            or croak "relname_fields required if results defined";
        $flat->{$relname} = [];

        #warn 'results=' . $opts{results};
        if ( ref $opts{results} eq 'ARRAY' ) {
            for my $r ( @{ $opts{results} } ) {
                push @{ $flat->{$relname} },
                    $self->serialize_object(
                    object    => $r,
                    col_names => $relname_fields,
                    );
            }
        }
        else {
            while ( my $r = $opts{results}->next ) {
                push @{ $flat->{$relname} },
                    $self->serialize_object(
                    object    => $r,
                    col_names => $relname_fields,
                    );
            }
        }
    }

    # html escape
    if ( $self->html_escape ) {
        for ( keys %$flat ) {
            next if !defined $flat->{$_};
            next if ref $flat->{$_};
            $flat->{$_} =~ s/([$ToEscape])/$Ents{$1}/og;
        }
    }

    return $flat;

}

=head2 serialize_livegrid( I<livegrid_object> )

Returns array ref of hash refs as passed through serialize_object().

=cut

sub serialize_livegrid {
    my $self     = shift;
    my $livegrid = shift or croak "LiveGrid object required";
    my $results  = $livegrid->results
        or croak "no results in LiveGrid object";
    my $method_name = $livegrid->method_name || '';
    my $params = $livegrid->c->req->params;
    my $max_loops;
    if ( $results->query->{limit} ) {
        $max_loops = 0;    # db handled the limit
    }
    else {
        $max_loops
            = $params->{'cxc-no_page'}
            ? 0
            : (    $params->{'cxc-page_size'}
                || $livegrid->controller->page_size );
    }

    my $counter = 0;
    my @data;
    my $iterator;

    if ( $results->isa('CatalystX::CRUD::Results') ) {
        $iterator = $results;
    }
    else {
        if ( !$method_name ) {
            croak
                "method_name required for non-CatalystX::CRUD::Results object with 'results' key";
        }
        my $method = $method_name . '_iterator';
        $iterator = $results->$method;
    }

    while ( my $object = $iterator->next ) {
        push(
            @data,
            $self->serialize_object(
                {   object              => $object,
                    method_name         => $method_name,
                    col_names           => $livegrid->col_names,
                    parent              => $livegrid->c->stash->{object},
                    c                   => $livegrid->c,
                    show_related_values => $livegrid->show_related_values,
                    takes_object_as_argument =>
                        $livegrid->form->metadata->takes_object_as_argument,
                    livegrid => $livegrid,
                }
            )
        );
        last if $max_loops > 0 && ++$counter > $max_loops;
    }

    $livegrid->{count} = $counter;

    return \@data;
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
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.


This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

