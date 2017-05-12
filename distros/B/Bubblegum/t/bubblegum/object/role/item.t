use Test::More;

{
    package object_with_item_role;
    use Bubblegum::Class 'with';
    with 'Bubblegum::Object::Role::Item';
    use Test::More;

    sub defined {}

    ok(my $obj = object_with_item_role->new);

    # inherited
    can_ok $obj, 'class';
    can_ok $obj, 'of';
    can_ok $obj, 'type';
    can_ok $obj, 'typeof';
}

done_testing;
