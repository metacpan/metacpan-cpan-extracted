use CatalystX::Declare;

view TestApp::View::TestView
    with TestApp::ViewRole::TestRole {

    method render (Object $ctx) {
        return 'view rendered';
    }

    method process (Object $ctx) {
        $ctx->response->body( $self->render($ctx) );
    }
}
