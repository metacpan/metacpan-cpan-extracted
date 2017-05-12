package MyClass::Bar;

# MyClass::Bar derives from MyClass::Foo
use MyClass::Foo "isa";

# switch to Bar's "LOCAL" namespace 
package MyClass::Bar::LOCAL;

use strict;
use warnings;

# change initial value for class attribute "cname" declared in Foo  
declare setvalue cname => "Bar";

# call class constructor
class_initialize;

# declare instance attribute
declare attribute bars => "BARS";

# declare private attribute
declare _bars_secret => private attribute;

# declare instance method
declare get_bars_secret => method {
    my $self = shift;
    return $self->_bars_secret;
};

my $bar_population = 0;

# declare class method
declare bar_population => class_method {
    return $bar_population;
};

declare overwrite init => method {
    my $self = shift;
    $self->base_init( @_ );
    
    $bar_population++;
    
    $self =~ /0x([0-9a-f]+)/;
    $self->_bars_secret = "BAR:$1";
};

declare overwrite DESTROY => method {
    my $self = shift;    
    $bar_population--;
    $self->base_destroy;
};

class_verify;
