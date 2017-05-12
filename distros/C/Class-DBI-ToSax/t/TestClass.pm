#!/usr/bin/perl -w
# @(#) $Id: TestClass.pm,v 1.3 2003/07/16 16:26:41 dom Exp $
package TestClass::Base;

use strict;

use base qw( Class::DBI::ToSax Class::Data::Inheritable Class::Accessor );

use vars qw( %cache );

# This class is a simulation of a Class::DBI generated class.  It
# contains similiar enough methods to test Class::DBI::ToSax.

__PACKAGE__->mk_classdata( 'table' );
__PACKAGE__->mk_classdata( '_columns' );

sub columns {
    my $class = shift;
    $class->_columns( [@_] ) if @_;
    return @{ $class->_columns };
}

sub primary_column {
    my $class = shift;
    return ( $class->columns )[0];
}

sub id {
    my $self = shift;
    my $pk = $self->primary_column;
    return $self->$pk;
}

# All so we can support has_many()...
sub new {
    my $class = shift;
    my $self = $class->SUPER::new;
    my %args = @_;
    foreach my $method ( keys %args ) {
	$self->$method( $args{ $method } ) 
    }
    $cache{ $class }{ $self->id } = $self;
    return $self;
}

sub has_many {
    my $class = shift;

    # Ensure Class::DBI::ToSax gets to see it too.
    $class->SUPER::has_many( @_ );

    # And now set up ourselves.
    my ( $method, $otherclass ) = @_;
    no strict 'refs';
    *{ "${class}::$method" } = sub {
        my $self = shift;
        my $pk   = $self->primary_column;
        my $id   = $self->$pk;
        return
            grep { $_->$pk && $_->$pk->id == $id }
            values %{ $cache{ $otherclass } };
    };
}

#---------------------------------------------------------------------

# Our main testing vehicle.
package TestClass::Foo;

use strict;
use warnings;

use base qw( TestClass::Base );

__PACKAGE__->table( 'foo' );
__PACKAGE__->columns( qw( foo_id foo_name bar_id ) );
__PACKAGE__->has_a( bar_id => 'TestClass::Bar' );
__PACKAGE__->has_many( bazza => 'TestClass::Baz' );

__PACKAGE__->mk_accessors( __PACKAGE__->columns );

#---------------------------------------------------------------------

package TestClass::Bar;

use strict;
use warnings;

use base qw( TestClass::Base );

__PACKAGE__->table( 'bar' );
__PACKAGE__->columns( qw( bar_id bar_name ) );

__PACKAGE__->mk_accessors( __PACKAGE__->columns );

#---------------------------------------------------------------------

package TestClass::Baz;

use strict;
use warnings;

use base qw( TestClass::Base );

__PACKAGE__->table( 'baz' );
__PACKAGE__->columns( qw( baz_id baz_name foo_id ) );
__PACKAGE__->has_a( foo_id => 'TestClass::Foo' );

__PACKAGE__->mk_accessors( __PACKAGE__->columns );

package TestClass::MCPK;

use strict;
use warnings;

use base qw( TestClass::Base );

__PACKAGE__->table( 'mcpk' );
__PACKAGE__->columns( qw( id_a id_b ) );

__PACKAGE__->mk_accessors( __PACKAGE__->columns );

sub primary_column { qw( id_a id_b ) }

1;
__END__
