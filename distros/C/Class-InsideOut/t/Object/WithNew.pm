package t::Object::WithNew;

use Class::InsideOut qw/ :std new /;

public name => my %name;
private age => my %age;

sub reveal_age {
    return $age{ id shift };
}

1;
