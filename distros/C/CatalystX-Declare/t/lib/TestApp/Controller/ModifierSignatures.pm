use CatalystX::Declare;

controller TestApp::Controller::ModifierSignatures 
    with TestApp::ControllerRole::ModifierSignatures {

    action base as 'modsig' under '/';

    final action foo (Int $x, Int $y) under base {
        $ctx->response->body( $ctx->action->reverse );
    }

    final action not_found (@) under base as '' {
        $ctx->response->body( 'Page Not Found' );
    }
}
