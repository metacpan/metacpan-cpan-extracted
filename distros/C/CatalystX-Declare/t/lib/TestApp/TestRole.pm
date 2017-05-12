use CatalystX::Declare;

controller_role TestApp::TestRole {

    method something_from_the_role { 23 }

    final action action_from_ctrl_role under base {
        $ctx->response->body($ctx->action->reverse);
    }

    after modifier_target (Object $ctx) {
        $ctx->response->body(join ' ', $ctx->response->body, 'modified');
    }

    around surrounded_target (Object $ctx) {
        $ctx->response->body('surrounded');
        $self->$orig($ctx);
    }
}
