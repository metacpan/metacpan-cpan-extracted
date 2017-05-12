package MyClass::Foo;

# MyClass::Foo derives from  Class::Root
use Class::Root "isa";

# switch to our "LOCAL" namespace 
package MyClass::Foo::LOCAL;

use strict;
use warnings;

# declare class attribute with default value		
declare class_attribute cname => "Foo";

# private attribute names always begin with "_"
declare private class_attribute _ID => 0;   

# declaring a readonly attribute also generates a corresponding writable private attribute (_population in this case)
declare readonly class_attribute population => 0;

# class constructor should be called after all declarations of class attributes
# here all class attributes get there default values

class_initialize;	

# declare instance attribute with default value
declare attribute foos => "FOOS";

# declare instance attribute with out default value
declare favorite_color => attribute;

# declare readonly instance attribute
declare id => readonly attribute;

# and again corresponding private writable attribute "_id" will be generated 

my $foo_population = 0;

# declare class method
declare foo_population => class_method {
    return $foo_population;
};

# Class::Root provides a constructor "new"
# Customizable "init" method may be used to add additional construction code 

declare overwrite init => method {
    my $self = shift;
    
    # "base_init" method should be used in place of SUPER::init
    # it cares of multiple inheritance and initial values

    $self->base_init( 
	_id => $self->_ID++,
	@_,
    );

    # all attribute accessors are lvalue subroutines
    $self->_population++;

    $foo_population++;
};

# declare instance destructor 
declare DESTROY => method {
    my $self = shift;

    $self->_population--;
    $foo_population--;

    # base_destroy method calls DESTROY methods from all parent classes 
    # in case of single parent it is equivalent to SUPER::DESTROY

    $self->base_destroy;
};

# class_verify checks the class schema last time ( Are all virtual methods implemented? )
# we use it in the last code line and it returns true value if no errors were found, so
# we don't need "1;" at the end of our module.    

class_verify;
