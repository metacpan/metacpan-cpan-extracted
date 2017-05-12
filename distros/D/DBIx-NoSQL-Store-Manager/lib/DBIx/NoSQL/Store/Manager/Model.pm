package DBIx::NoSQL::Store::Manager::Model;
BEGIN {
  $DBIx::NoSQL::Store::Manager::Model::AUTHORITY = 'cpan:YANICK';
}
{
  $DBIx::NoSQL::Store::Manager::Model::VERSION = '0.2.2';
}
#ABSTRACT: Role for classes to be handled by DBIx::NoSQL::Store::Manager

use 5.10.0;

use strict;
use warnings;

use Moose::Role;

use Method::Signatures;
use MooseX::ClassAttribute;
use MooseX::Storage 0.31;

with Storage;
with 'DBIx::NoSQL::Store::Manager::StoreKey',
     'DBIx::NoSQL::Store::Manager::StoreIndex';




has store_db => (
    traits => [ 'DoNotSerialize' ],
    is       => 'ro',
    required => 1,
);


class_has store_model => (
    isa => 'Str',
    is => 'rw',
    default => method {
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
    default => method {
       return join( '-', map {
        my $m = $_->get_read_method;
        $self->$m;
       } grep { $_->does('DBIx::NoSQL::Store::Manager::StoreKey') }
         $self->meta->get_all_attributes )
         // die "no store key set for $self";
    },
);


method store {
    $self->store_db->set( 
        $self->store_model =>
            $self->store_key => $self,
    );
}


method delete {
    $self->store_db->delete( $self->store_model => $self->store_key );
}

method _entity {
   return $self->pack; 
}

method indexes {
    return map  { [ $_->name, ( isa => $_->store_isa ) x $_->has_store_isa ] }
           grep { $_->does('DBIx::NoSQL::Store::Manager::StoreIndex') } 
                $self->meta->get_all_attributes;
}

1;

__END__

=pod

=head1 NAME

DBIx::NoSQL::Store::Manager::Model - Role for classes to be handled by DBIx::NoSQL::Store::Manager

=head1 VERSION

version 0.2.2

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
to. Required.

=head2 store_model

Class-level attribute holding the model name of the class.
If not given, defaults to the class name with everything up
to a C<*::Model::> truncated (e.g., C<MyStore::Model::Thingy>
would become C<Thingy>).

Not that as it's a class-level attribute, it can't be passed to
C<new()>, but has to be set via C<class_has>:

    class_has +store_model => (
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

Serializes the object into the store.

=head2 delete()

Deletes the object from the store.

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
