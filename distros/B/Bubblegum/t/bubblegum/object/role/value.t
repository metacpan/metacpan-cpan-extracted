use Test::More;

{
    package object_with_value_role;
    use Bubblegum::Class 'with';
    with 'Bubblegum::Object::Role::Value';
    use Test::More;

    ok(my $obj = object_with_value_role->new);

    # inherited
    can_ok $obj, 'defined';
    can_ok $obj, 'do';
}

done_testing;
