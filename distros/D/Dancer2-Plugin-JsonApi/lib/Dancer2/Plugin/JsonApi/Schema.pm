use 5.32.0;

package Dancer2::Plugin::JsonApi::Schema;
our $AUTHORITY = 'cpan:YANICK';
$Dancer2::Plugin::JsonApi::Schema::VERSION = '0.0.1';
use Moo;

use experimental   qw/ signatures /;
use List::AllUtils qw/ pairmap pairgrep /;

use Set::Object qw/set/;

has registry => ( is => 'ro' );

has type => (
    required => 1,
    is       => 'ro',
);

has id => (
    is      => 'ro',
    default => 'id'
);

has links           => ( is => 'ro' );
has top_level_links => ( is => 'ro' );
has top_level_meta  => ( is => 'ro' );
has relationships   => ( is => 'ro', default => sub { +{} } );

has allowed_attributes => ( is => 'ro' );
has before_serialize   => ( is => 'ro' );

sub serialize ( $self, $data, $extra_data = {} ) {

    my $serial = {};

    $serial->{jsonapi} = { version => '1.0' };

    my @included;

    if ( defined $data ) {
        $serial->{data} =
          $self->serialize_data( $data, $extra_data, \@included );
    }

    $serial->{links} = gen_links( $self->top_level_links, $data, $extra_data )
      if $self->top_level_links;

    if ( $self->registry and $self->registry->app ) {
        $serial->{links}{self} = $self->registry->app->request->path;
    }

    $serial->{meta} = gen_links( $self->top_level_meta, $data, $extra_data )
      if $self->top_level_meta;

    $serial->{included} = [ dedupe_included(@included) ] if @included;

    return $serial;
}

sub dedupe_included {
    my %seen;
    return grep { not $seen{ $_->{type} }{ $_->{id} }++ } @_;
}

has attributes => (
    is      => 'ro',
    default => sub {
        my $self = shift;
        return sub {
            my ( $data, $extra_data ) = @_;
            return {} if ref $data ne 'HASH';
            my @keys = grep { not $self->relationships->{$_} }
              grep { $_ ne $self->id } keys %$data;
            return { $data->%{@keys} };
        }
    }
);

sub serialize_data ( $self, $data, $extra_data = {}, $included = undef ) {

    return [ map { $self->serialize_data( $_, $extra_data, $included ) }
          @$data ]
      if ref $data eq 'ARRAY';

    if ( $self->before_serialize ) {
        $data = $self->before_serialize->( $data, $extra_data );
    }

    # it's a scalar? it's the id
    return { id => $data, type => $self->type } unless ref $data;

    my $s = {
        type => $self->type,
        id   => $self->gen_id( $data, $extra_data )
    };

    if ( $self->links ) {
        $s->{links} = gen_links( $self->links, $data, $extra_data );
    }

    $s->{attributes} = gen_links( $self->attributes, $data, $extra_data );

    my %relationships = $self->relationships->%*;

    for my $key ( keys %relationships ) {
        my $attr = $data->{$key};

        my @inc;

        my $t = $self->registry->serialize( $relationships{$key}{type},
            $attr, \@inc );

        if ( my $data = obj_ref( $t->{data}, \@inc ) ) {
            $s->{relationships}{$key}{data} = $data;
        }

        if ( my $links = $relationships{$key}{links} ) {
            $s->{relationships}{$key}{links} =
              gen_links( $links, $data, $extra_data );
        }

        push @$included, @inc if $included;
    }

    delete $s->{attributes} unless $s->{attributes}->%*;

    if ( $self->allowed_attributes ) {
        delete $s->{attributes}{$_}
          for ( set( keys $s->{attributes}->%* ) -
            set( $self->allowed_attributes->@* ) )->@*;
    }

    return $s;

}

sub obj_ref ( $data, $included ) {
    return [ map { obj_ref( $_, $included ) } @$data ]
      if ref $data eq 'ARRAY';

    return $data if keys %$data == 2;

    return unless keys %$data;

    push @$included, $data;

    return +{ $data->%{qw/ id type/} };
}

sub gen_id ( $self, $data, $xtra ) {
    my $id = $self->id;

    return ref $id ? $id->( $data, $xtra ) : $data->{$id};
}

sub gen_links ( $links, $data, $extra_data = {} ) {

    return $links->( $data, $extra_data ) if ref $links eq 'CODE';

    return { pairmap { $a => gen_item( $b, $data, $extra_data ) } %$links };
}

sub gen_item ( $item, $data, $extra_data ) {
    return $item unless ref $item;

    return $item->( $data, $extra_data );
}

sub deserialize ( $self, $serialized, $included = [] ) {

    my $data     = $serialized->{data};
    my @included = ( ( $serialized->{included} // [] )->@*, @$included );

    return $self->deserialize_data( $data, \@included );
}

sub expand_object ( $obj, $included ) {

    if ( ref $obj eq 'ARRAY' ) {
        return [ map { expand_object( $_, $included ) } @$obj ];
    }

    for (@$included) {
        return $_ if $_->{type} eq $obj->{type} and $_->{id} eq $obj->{id};
    }

    return $obj;
}

sub deserialize_data ( $self, $data, $included ) {

    if ( ref $data eq 'ARRAY' ) {
        return [ map { $self->deserialize_data( $_, $included ) } @$data ];
    }

    my %obj = (
        ( $data->{attributes} // {} )->%*,
        pairmap {
            $a =>
              $self->registry->type( $self->relationships->{$a}{type} )
              ->deserialize_data( $b, $included )
          } pairmap { $a => expand_object( $b, $included ) }
          pairmap { $a => $b->{data} } ( $data->{relationships} // {} )->%*
    );

    my $id_key = $self->id;
    if ( !ref $id_key ) {
        $obj{$id_key} = $data->{id};
    }

    if ( $data->{type} eq 'photo' ) {

        #        die keys %$data;
    }

    if ( 1 == keys %obj and exists $obj{id} ) {
        return $data->{id};
    }

    return \%obj;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::JsonApi::Schema

=head1 VERSION

version 0.0.1

=head1 DESCRIPTION

Defines a type of object to serialize/deserialize from/to the 
JSON:API format.

=head1 ATTRIBUTES

=head2 registry

L<Dancer2::Plugin::JsonApi::Registry> to use to find the definition of
other object types.

=head2 before_serialize

Accepts a function, which will be called on the original C<$data> to serialize
to groom it.

    before_serialize => sub($data,$xtra) {
       # lowercase all keys
       return +{ pairmap { lc($a) => $b } %$data } 
    }

=head2 type

The JSON:API object type. Read-only, required.

=head2 id

Key to use as a reference to the object. Can be a string,
or a function that will be passed the original data object.
Read-only, defaults to the string C<id>. 

=head2 links 

Links to include as part of the object. 

=head2 top_level_links

Links to include to the serialized top level, if the top level object 
is of the type defined by this class.

=head2 top_level_meta

Meta information to include to the serialized top level, if the top level object 
is of the type defined by this class.

=head2 relationships

Relationships for the object type.

=head2 allowed_attributes

List of attributes that can be serialized/deserialized.

=head1 METHODS

=head2 top_level_serialize($data,$extra_data = {})

Serializes C<$data> as a top-level JSON:API object. 

=head2 serialize_data($data,$extra_data)

Serializes the inner C<$data>. 

=head1 AUTHOR

Yanick Champoux <yanick@babyl.ca>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
