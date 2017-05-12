use Test::More;

{
    package object_with_keyed_role;
    use Bubblegum::Class 'with';
    with 'Bubblegum::Object::Role::Keyed';
    use Test::More;

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

    ok(object_with_keyed_role->new);
}

done_testing;
