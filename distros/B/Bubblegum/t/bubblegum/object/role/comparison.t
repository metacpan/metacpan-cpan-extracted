use Test::More;

{
    package object_with_comparison_role;
    use Bubblegum::Class 'with';
    with 'Bubblegum::Object::Role::Comparison';
    use Test::More;

    sub eq {}
    sub eqtv {}
    sub gt {}
    sub gte {}
    sub lt {}
    sub lte {}
    sub ne {}

    # inherited
    sub defined {}

    ok(my $obj = object_with_comparison_role->new);
    can_ok $obj, 'equal';
    can_ok $obj, 'equal_type_and_value';
    can_ok $obj, 'greater';
    can_ok $obj, 'greater_or_equal';
    can_ok $obj, 'lesser';
    can_ok $obj, 'lesser_or_equal';
    can_ok $obj, 'not_equal';

    # inherited
    can_ok $obj, 'defined';
}

done_testing;
