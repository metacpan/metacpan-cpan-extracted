use Test::More;

{
    package object_with_ref_role;
    use Bubblegum::Class 'with';
    with 'Bubblegum::Object::Role::Ref';
    use Test::More;

    # inherited
    sub defined {}

    ok(my $obj = object_with_ref_role->new);

    # inherited
    can_ok $obj, 'refaddr';
    can_ok $obj, 'reftype';
}

done_testing;
