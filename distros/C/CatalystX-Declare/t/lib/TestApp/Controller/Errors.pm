use CatalystX::Declare;

controller TestApp::Controller::Errors {

    use TestApp::Types qw( NotFoo NotBar );


    action base under '/' as 'errors';


    #
    #   makes sure the right signature error is caught
    #

    method signature_error_on_bar (Object $ctx, NotBar $str) {
        $ctx->response->body(join ' ', $ctx->response->body, 'BAR');
    }

    final action signature_error_on_foo (NotFoo $str) under base {
        $ctx->response->body('FOO');
        $self->signature_error_on_bar($ctx, $str);
    }

    final action signature_error_on_foo_modify (NotFoo $str) under base {
        $ctx->response->body('FOO_MODIFY');
        $self->signature_error_on_bar($ctx, $str);
    }
}

