use Test::More;

{
    package object_with_defined_role;
    use Bubblegum::Class 'with';
    with 'Bubblegum::Object::Role::Defined';
    use Test::More;

    ok(my $obj = object_with_defined_role->new);

    # inherited
    can_ok $obj, 'defined';
}

done_testing;
