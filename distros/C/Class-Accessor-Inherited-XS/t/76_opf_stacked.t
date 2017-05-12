use Test::More;
use Class::Accessor::Inherited::XS inherited => [qw/foo/];

__PACKAGE__->foo(42);
my $cref = __PACKAGE__->can("foo");

for (1..3) {
    is sub {
        &$cref;
    }->(__PACKAGE__), 42;
};

done_testing;