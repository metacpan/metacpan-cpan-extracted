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
    requires => [qw(Mojo::Base)],
    parts => [qw(Mojo)],
    options => [qw(class)],
    body => "use Role::Tiny::With; with '$role';",
});

ok($class->can('new'),'the class should be a class');
ok($class->c,'the role should applied');

done_testing;
