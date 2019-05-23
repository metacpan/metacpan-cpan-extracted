use Test2::V0;
use lib 't/lib';
use TestHelper;

my $role = make_pkg({
    requires => [qw(Moo::Role Type::Params Types::Standard)],
    parts => [qw(Moo Types)],
    options => [qw(role)],
    body => 'sub c { \&compile }'
});

my $class = make_pkg({
    requires => [qw(Moo Type::Params Types::Standard)],
    parts => [qw(Moo Types)],
    options => [qw(class)],
    body => "with '$role'; sub i { \\&Int }",
});

ok($class->can('new'),'the class should be a class');
ok($class->c,'Type::Params should be imported, and role applied');
ok($class->i,'Types::Standard should be imported');

my $class_no_types = make_pkg({
    requires => [qw(Moo)],
    parts => [qw(Moo)],
    options => [qw(class)],
});
ok($class_no_types->can('new'),'::Parts::Moo should work without any "types" feature');

done_testing;
