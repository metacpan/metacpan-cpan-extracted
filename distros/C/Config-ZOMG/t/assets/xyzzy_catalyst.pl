{   name              => 'TestApp',
    view              => 'View::TT',
    'Controller::Foo' => { foo => 'bar' },
    'Model::Baz'      => { qux => 'xyzzy' },
    foo_sub           => '__foo(x,y)__',
    literal_macro     => '__literal(__DATA__)__',
}
