package Test4;

use Class::LazyLoad;

use overload
    '+' => 'add';

sub new {
    bless \my ($x), shift;
}

sub add {
    return 42;
}

1;
__END__
