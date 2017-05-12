use Test::More;

{
    package object_with_indexed_role;
    use Bubblegum::Class 'with';
    with 'Bubblegum::Object::Role::Indexed';
    use Test::More;

    sub slice {}

    # inherited
    sub defined       { }
    sub each          { }
    sub each_key      { }
    sub each_n_values { }
    sub each_value    { }
    sub exists        { }
    sub iterator      { }
    sub list          { }
    sub keys          { }
    sub get           { }
    sub set           { }
    sub values        { }

    ok(my $obj = object_with_indexed_role->new);

    # inherited
    can_ok $obj, 'defined';
    can_ok $obj, 'each';
    can_ok $obj, 'each_key';
    can_ok $obj, 'each_n_values';
    can_ok $obj, 'each_value';
    can_ok $obj, 'exists';
    can_ok $obj, 'iterator';
    can_ok $obj, 'list';
    can_ok $obj, 'keys';
    can_ok $obj, 'get';
    can_ok $obj, 'set';
    can_ok $obj, 'values';
}

done_testing;
