package Business::NAB::Role::AttributeContainer;
$Business::NAB::Role::AttributeContainer::VERSION = '0.02';
# undocument role

use strict;
use warnings;
use feature qw/ signatures /;

use Moose::Role;
use Moose::Util::TypeConstraints;
no warnings qw/ experimental::signatures /;

use Module::Load;
use Business::NAB::Types qw/ decamelize /;

sub load_attributes (
    $self,
    $parent,
    @subclasses,
) {
    foreach my $record_type ( @subclasses ) {

        load( $parent . "::$record_type" );

        my $attr  = decamelize( $record_type );
        my $class = "${parent}::$record_type";

        subtype $record_type
            => as "ArrayRef[$class]";

        coerce $record_type
            => from "ArrayRef[HashRef|$class]"
            => via {

            # when a new thing is pushed onto the array we need to coerce
            # it from a HashRef to the instance of the class, but if it's
            # already an instance of the class then pass it straight through
            my @objects = map {
                ref $_ eq $class
                    ? $_
                    : $class->new( $_ )
            } @{ $_ };

            [ @objects ];
        }
        => from "ArrayRef[Any]"
            => via {
            [ $class->new( $_->@* ) ]
        }
        ;

        $parent->meta->add_attribute(
            $attr,
            {
                traits  => [ 'Array' ],
                is      => 'rw',
                isa     => $record_type,
                coerce  => 1,
                default => sub { [] },
                handles => {
                    "add_${attr}" => 'push',
                },
            },
        );
    }
}

1;
