use Test2::V0;
use lib 't/lib';
use TestHelper;

my $pkg = make_pkg({
    requires => [qw(autobox::Core autobox::Camelize autobox::Transform)],
    parts => [qw(Autobox)],
    body => q{ sub foo { return $_[1]->sort } },
});

is(
    $pkg->foo([3,2,1]),
    [1,2,3],
    'autobox should be imported',
);

done_testing;
