use Test2::V0;
use lib 't/lib';
use TestHelper;

my $role = make_pkg({
    requires => [qw(Mojo::Base)],
    parts => [qw(Mojo)],
    options => [qw(role)],
    body => 'sub c { 1 }'
});

my $class = make_pkg({
    # 7.55 was the first version to support roles; we can't test the
    # version of Mojo::Base because it doesn't declare it (!), so we
    # look at Mojolicious which is in the same distribution and does
    # declare a version
    requires => [qw(Mojo::Base Mojolicious)],
    min_versions => { 'Mojolicious' => '7.55' },
    parts => [qw(Mojo)],
    options => [qw(class)],
    body => "use Role::Tiny::With; with '$role';",
});

ok($class->can('new'),'the class should be a class');
ok($class->c,'the role should applied');

done_testing;
