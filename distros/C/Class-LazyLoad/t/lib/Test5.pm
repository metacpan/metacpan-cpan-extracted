package Test5;

use Class::LazyLoad;

use overload
    '""' => 'stringy';

sub new {
    bless \my ($x), shift;
}

sub stringy {
    return 42;
}

1;
__END__
