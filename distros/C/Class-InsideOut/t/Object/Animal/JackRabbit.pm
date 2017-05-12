package t::Object::Animal::JackRabbit;

BEGIN {
    require t::Object::Animal;
    @t::Object::Animal::JackRabbit::ISA = 't::Object::Animal';
}

use Class::InsideOut qw( property id );

# superclass is handling new()

property speed => my %speed, { privacy => "public" };

1;
