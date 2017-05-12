use CatalystX::Declare;

view RenderViewTestApp::View::Test {

    method process (Catalyst $ctx) {
        $ctx->response->body( $CLASS );
    }
}
