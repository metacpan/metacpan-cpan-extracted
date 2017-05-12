use CatalystX::Declare;

controller TestApp::Controller::DynamicFinal::Bar {

    with 'TestApp::ControllerRole::DynamicFinal' => {
        is_final    => 0,
        base        => 'base',
        body        => 'bar',
        counters    => [qw( y z )],
    };

    action base as df_bar under '/';

    final action wrapped under msg {
        $ctx->response->body(sprintf 'wrapped[%s]', $ctx->response->body);
    }
}

