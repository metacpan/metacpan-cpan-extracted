package MyClass::Baz;

# MyClass::Baz also derives from MyClass::Foo
use MyClass::Foo "isa";

# switch to Bar's "LOCAL" namespace 
package MyClass::Baz::LOCAL;

use strict;
use warnings;

# change initial value for class attribute "cname" declared in Foo  
declare setvalue cname => "Baz";

# call class constructor
class_initialize;

# declare instance attribute
declare attribute bazs => "BAZS";

# declare private attribute
declare _bazs_secret => private attribute;

# declare instance method
declare get_bazs_secret => method {
    my $self = shift;
    return $self->_bazs_secret;
};

my $baz_population = 0;

# declare instance method
declare baz_population => method {
    return $baz_population;
};

declare overwrite init => method {
    my $self = shift;
    $self->base_init( @_ );
    
    $baz_population++;
    
    $self->_bazs_secret = "BAZ:" . (int( rand(1000) )+1000);
};

declare overwrite DESTROY => method {
    my $self = shift;    
    $baz_population--;
    $self->base_destroy;
};

class_verify;
