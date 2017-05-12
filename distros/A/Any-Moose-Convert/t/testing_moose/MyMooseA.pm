package MyMooseA;
use Moose;
use Class::MOP;

has foo => (
    is      => 'ro',
    default => 42,
);

sub my_load {
    my($self, $mod) = @_;
    if(!Class::MOP::is_class_loaded($mod)){
        Class::MOP::load_class($mod);
        return 1;
    }
    return 0;
}

sub is_metaclass {
    my($self, $thing) = @_;

    return blessed($thing) && $thing->isa('Class::MOP::Class');
}

sub get_metaclass{
    my($self, $thing) = @_;
    return Class::MOP::get_metaclass_by_name($thing);
}

no Moose;
1;
