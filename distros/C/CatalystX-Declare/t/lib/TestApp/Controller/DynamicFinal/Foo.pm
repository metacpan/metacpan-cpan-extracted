use CatalystX::Declare;

controller TestApp::Controller::DynamicFinal::Foo {
    with 'TestApp::ControllerRole::DynamicFinal' => {
        is_final    => 1,
        base        => 'base',
        body        => 'foo',
        counters    => [qw( x y )],
    };

    action base as df_foo under '/';
}
