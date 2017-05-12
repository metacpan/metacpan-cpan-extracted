package t::Object::WithNew::Inherited;

BEGIN {
    require t::Object::WithNew;
    @t::Object::WithNew::Inherited::ISA = 't::Object::WithNew';
}

use Class::InsideOut qw/ :std /;

private age => my %age;

sub reveal_age {
    return $age{ id shift };
}

1;
