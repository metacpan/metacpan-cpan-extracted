use constant HAS_LEAKTRACE => eval{ require Test::LeakTrace };
use Test::More HAS_LEAKTRACE ? ('no_plan') : (skip_all => 'requires Test::LeakTrace');
use Test::LeakTrace;

use Class::Accessor::Inherited::XS constructor => 'new';

no_leaks_ok {
    my $foo = __PACKAGE__->new;
};

no_leaks_ok {
    my $foo = __PACKAGE__->new(1..4);
};

no_leaks_ok {
    my $foo = __PACKAGE__->new({1..4});
};

no_leaks_ok {
    my @list = (__PACKAGE__->new(1..4), __PACKAGE__->new(1..4));
};

no_leaks_ok {
    my %args = (1..4);
    my $foo = __PACKAGE__->new(\%args);
};
