package DBIx::NoSQL::Store::Manager::StoreModel;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: trait for attributes linking to store objects.
$DBIx::NoSQL::Store::Manager::StoreModel::VERSION = '1.0.0';

use Log::Any qw/ $log /;

use Moose::Role;
use Scalar::Util qw/ blessed /;

Moose::Util::meta_attribute_alias('StoreModel');

use experimental 'signatures';

has store_model => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    predicate => 'has_store_model',
);

has cascade_model => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { 0 },
);

has cascade_save => (
    is      => 'ro',
    isa     => 'Bool',
    lazy => 1,
    default => sub { $_[0]->cascade_model },
);

has cascade_delete => (
    is      => 'ro',
    isa     => 'Bool',
    lazy => 1,
    default => sub { $_[0]->cascade_model },
);

use Types::Standard qw/ InstanceOf Str HashRef ArrayRef ConsumerOf /;

before _process_options => sub ( $meta, $name, $options ) {
    my $type = InstanceOf[ $options->{store_model } ] | Str | HashRef;
    if ( grep { $_ eq 'Moose::Meta::Attribute::Native::Trait::Array' } @{ $options->{traits} || [] } ) {
        $type = 'ArrayRef';
    }
    $options->{isa} ||= $type;
    push @{ $options->{traits} }, 'DoNotSerialize';
};

use experimental 'postderef';

sub _expand_to_object($self,$value,$main_object) {
    return $value if blessed $value;

    return $self->store_model->new($value) if ref $value;

    my $class = $self->store_model;
    $class =~ s/^.*::Model:://;
    $class =~ s/::/_/g;

    return $main_object->store_db->get( $class => $value )
        || die "'$class' object with key '$value' not found\n";
}

after install_accessors => sub { 
    my $attr = shift;

    my $array_context = grep { $_ eq 'Moose::Meta::Attribute::Native::Trait::Array'  } @{ $attr->applied_traits };

    my $reader = $attr->get_read_method;
    # class that has the attribute
    my $main_class = $attr->associated_class;

    $main_class->add_before_method_modifier( delete => sub ( $self, @) {
        my $obj = $self->$reader or return;

        $_->delete for $array_context ? @$obj : $obj;
    }) if $attr->cascade_delete;

    $main_class->add_before_method_modifier( $attr->get_read_method => sub ( $self, @rest ) {
        return if @rest;

        my $value = $attr->get_value( $self );
        return unless grep { defined $_ and not blessed $_ } $array_context ? @$value : $value;

        if( $array_context ) {
            $attr->set_raw_value( $self, [ map {
                    $attr->_expand_to_object( $_, $self ) } @$value ] );
        }
        else {
            $attr->set_raw_value( $self, $attr->_expand_to_object( $value, $self ) );
        }

    });

    $main_class->add_around_method_modifier( pack => sub($orig,$self) {
            my $packed = $orig->($self);
            my $val = $self->$reader;
            if ( $val ) {
                $packed->{ $attr->name } = $array_context ? [ 
                    map { $_->store_key } @$val
                ] : $val->store_key;
            }
            return $packed;
    } );

    if( $attr->cascade_save ) {
        $main_class->add_before_method_modifier( 'save' => sub ( $self, $store=undef ) {
                # TODO bug if we remove the value altogether
                my $value = $self->$reader or return;
                
                if ( $attr->cascade_delete ) {
                    my $priors = eval { $self->store_db->get( $self->store_model, $self->store_key )->$reader };

                    if ( $array_context ) {
                        my %priors = map { $_->store_key => $_ } @$priors;
                        for ( @$value ) {
                            delete $priors{ $_->store_key };
                        }
                        $_->delete for values %priors;
                    }
                    else {
                        if ( $priors ) { $priors->delete; }
                    }
                }

                $store ||= $self->store_db;

                for ( $array_context ? @$value : $value ) {
                    $_->store_db( $store );
                    $_->save;
                }
        });
    }
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::NoSQL::Store::Manager::StoreModel - trait for attributes linking to store objects.

=head1 VERSION

version 1.0.0

=head1 SYNOPSIS

    package Blog::Model::Entry;

    has author => (
        traits => [ 'StoreModel' ],
        store_model =>  'Blog::Model::Author',
        cascade_save => 1,
        cascade_delete => 0,
        is => 'rw',
    );

=head1 DESCRIPTION

I<DBIx::NoSQL::Store::Manager::StoreModel> (also aliased to I<StoreModel>)

This trait ties the value of the attribute to a model of the store.

The value of the attribute can be set via either a model object, a hashref, or 
the store key of an object already existing in the store. The getter always
returns the inflated model object.

    my $blog_entry = $store->create( 'Entry', 
        author => 'yanick',
    );

    # or
    $blog_entry = $store->create( 'Entry', 
        author => Blog::Model::Author->new( name => 'yanick' )
    );

    # or
    $blog_entry = $store->create( 'Entry', 
        author => { name => 'yanick' }
    );

    my $author_object = $blog_entry->author; # will be a Blog::Model::Author object

If the C<Array> trait is also applied to the attribute, the attribute is assumed to contain
a collection of objects. The same logic applies as above, only wrapped in an arrayref.

=head1 ATTRIBUTES

=head2 store_model => $model_class

Required. Takes in the model associated with the target attribute.
Will automatically populate the C<isa> attribute to 
C<$model_class|Str_HashRef>.

=head2 cascade_model => $boolean

Sets the default of C<cascade_save> and C<cascade_delete>.
Defaults to C<false>.

=head2 cascade_save => $boolean

If C<true> the object associated with the attribute is automatically saved 
to the store when the main object is C<save()>d.

=head2 cascade_delete => $boolean

If C<true>, deletes the attribute object (if there is any)
from the store when the main object is C<delete()>d.

If both C<cascade_delete> and C<cascade_save> are C<true>,
then when saving the main object, if the attribute object has been
modified, its previous value will be deleted from the store.

    # assuming the author attribute has `cascade_model => 1`...

    my $blog_entry = $store->create( 'Entry', 
        author => Blog::Model::Author->new( 
            name => 'yanick',
            bio  => 'necrohacker',
        ),
    );

    # store now has yanick as an author

    my $pseudonym = $store->create( Author => 
        name => 'yenzie', bio => 'neo-necrohacker' 
    );

    # store has both 'yanick' and 'yenzie'

    # does not modify the store
    $blog_entry->author( $pseudonym );

    # removes 'yanick'
    $blog_entry->save;

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2013, 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
