use Test::More;

{
    package object_with_output_role;
    use Bubblegum::Class 'with';
    with 'Bubblegum::Object::Role::Output';
    use Test::More;

    # inherited
    sub print {}
    sub say {}

    ok(my $obj = object_with_output_role->new);

    # inherited
    can_ok $obj, 'print';
    can_ok $obj, 'say';
}

done_testing;
