package DBIx::NoSQL::Store::Manager::Model;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: Role for classes to be handled by DBIx::NoSQL::Store::Manager
$DBIx::NoSQL::Store::Manager::Model::VERSION = '1.0.0';
use 5.20.0;

use strict;
use warnings;

use Moose::Role;

use MooseX::ClassAttribute;
use MooseX::Storage 0.31;
use MooseX::SetOnce;

use Scalar::Util qw/ refaddr /;

with Storage;

use DBIx::NoSQL::Store::Manager::StoreKey;
use DBIx::NoSQL::Store::Manager::StoreIndex;
use DBIx::NoSQL::Store::Manager::StoreModel;

use experimental 'signatures';

# TODO: ad-hoc model registration



has store_db => (
    traits => [ 'DoNotSerialize', 'SetOnce' ],
    is       => 'rw',
    predicate =>  'has_store_db',
);

around store_db => sub ( $orig, $self, @rest ) {
    if ( @rest and $self->has_store_db ) {
        shift @rest if refaddr $self->store_db == refaddr $rest[0];
    }

    return $orig->($self,@rest);
};


class_has store_model => (
    isa => 'Str',
    is => 'rw',
    default => sub ($self) {
        # TODO probably over-complicated
       my( $class ) = $self->class_precedence_list;

       $class =~ s/^.*::Model:://;
       $class =~ s/::/_/g;
       return $class;
    },
);


has store_key => (
    traits => [ 'DoNotSerialize' ],
    is => 'ro',
    lazy => 1,
    default => sub($self) {
        no warnings 'uninitialized';
       return join( '-', map { $self->$_ } sort map {
        $_->get_read_method
       } grep { $_->does('DBIx::NoSQL::Store::Manager::StoreKey') }
         $self->meta->get_all_attributes )
         // die "no store key set for $self";
    },
);


sub store($self) {
    # TODO put deprecation notice
    $self->save;
}


sub delete($self) {
    $self->store_db->delete( $self->store_model => $self->store_key );
}

sub _entity($self) {
   return $self->pack; 
}

around pack => sub($orig,$self) {
    local $DBIx::NoSQL::Store::Manager::Model::INNER_PACKING = $DBIx::NoSQL::Store::Manager::Model::INNER_PACKING;

    return $DBIx::NoSQL::Store::Manager::Model::INNER_PACKING++ ? $self->store_key : $orig->($self);
};

sub indexes($self) {
    return map  { [ $_->name, ( isa => $_->store_isa ) x $_->has_store_isa ] }
           grep { $_->does('DBIx::NoSQL::Store::Manager::StoreIndex') } 
                $self->meta->get_all_attributes;
}


sub save($self,$store=undef) {
    $self->store_db( $store ) if $store;

    $self->store_db->set($self);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::NoSQL::Store::Manager::Model - Role for classes to be handled by DBIx::NoSQL::Store::Manager

=head1 VERSION

version 1.0.0

=head1 SYNOPSIS

    package MyComics::Model::Comic;

    use strict;
    use warnings;

    use Moose;

    with 'DBIx::NoSQL::Store::Manager::Model';

    has series => (
        traits => [ 'StoreKey' ],
        is => 'ro',
    );

    has issue =>  (
        traits => [ 'StoreKey' ],
        is => 'ro',
        isa => 'Int',
    );

    has penciller => (
        traits => [ 'StoreIndex' ],
        is => 'ro',
    );

    has writer => (
        is => 'ro',
    );

    __PACKAGE__->meta->make_immutable;

    1;

=head1 DESCRIPTION

Role for classes to be stashed in a L<DBIx::NoSQL::Store::Manager> store.

The only hard-requirement for a class consuming this role is to define a
key to be used as the unique id of the object in the store. This can be done
by applying the L<DBIx::NoSQL::Store::Manager::StoreIndex> trait to one or
more attributes (the key will be the concatenation of those attributes). Or,
if the generation of the key is more complicated, it can be done by playing
with the C<store_key> attribute directly:

    has '+store_key' => (
        default => sub {
            my $self = shift;

            return $self->generate_arcane_key;
        },
    );

Attributes of the class can be marked for indexed by giving them
the L<DBIx::NoSQL::Store::Manager::StoreIndex> trait.

=head1 ATTRIBUTES

=head2 store_db

The L<DBIx::NoSQL::Store::Manager> store to which the object belongs
to. 

=head2 store_model

Class-level attribute holding the model name of the class.
If not given, defaults to the class name with everything up
to a C<*::Model::> truncated (e.g., C<MyStore::Model::Thingy>
would become C<Thingy>).

Not that as it's a class-level attribute, it can't be passed to
C<new()>, but has to be set via C<class_has>:

    class_has '+store_model' => (
        default => 'SomethingElse',
    );

=head2 store_key

The store id of the object. Defaults to the concatenation of the value of all
attributes having the L<DBIx::NoSQL::Store::Manager::StoreKey> trait.

=head1 METHODS

=head2 store_db

Returns the L<DBIx::NoSQL::Store::Manager> store to which the object belongs
to.

=head2 store()

DEPRECATED - use C<save()> instead.

Serializes the object into the store. 

=head2 delete()

Deletes the object from the store.

=head2 save( $store )

Saves the object in the store. The C<$store> object can be given as an argument if 
the object was not created via a master C<DBIx::NoSQL::Store::Manager> object
and C<store_db> was not already provided via the constructor.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2013, 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
