package MyMouseB;
use Mouse;

has foo => (
    is      => 'ro',
    default => 42,
);

sub my_load {
    my($self, $mod) = @_;
    if(!Mouse::Util::is_class_loaded($mod)){
        Mouse::Util::load_class($mod);
        return 1;
    }
    return 0;
}

sub is_metaclass {
    my($self, $thing) = @_;

    return blessed($thing) && $thing->isa('Mouse::Meta::Class');
}

sub get_metaclass{
    my($self, $thing) = @_;
    return Mouse::Util::get_metaclass_by_name($thing);
}

no Moose;
1;
