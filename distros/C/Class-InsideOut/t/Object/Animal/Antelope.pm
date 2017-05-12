package t::Object::Animal::Antelope;

BEGIN {
    require t::Object::Animal;
    @t::Object::Animal::Antelope::ISA = 't::Object::Animal';
}

use Class::InsideOut qw( property public id );

# superclass is handling new()

Class::InsideOut::options( { privacy => 'private' } );

# should override default options above
property color => my %color, { privacy => 'public' };

# should revert back to defaults
property panicked => my %panicked;

# should override default 
public   points => my %points;

1;
