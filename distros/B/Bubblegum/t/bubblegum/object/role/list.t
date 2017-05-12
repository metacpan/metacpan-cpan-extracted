use Test::More;

{
    package object_with_list_role;
    use Bubblegum::Class 'with';
    with 'Bubblegum::Object::Role::List';
    use Test::More;

    sub defined {}
    sub grep {}
    sub head {}
    sub join {}
    sub length {}
    sub map {}
    sub reverse {}
    sub sort {}
    sub tail {}

    ok(my $obj = object_with_list_role->new);

    # inherited
    can_ok $obj, 'reduce';
    can_ok $obj, 'zip';
}

done_testing;
