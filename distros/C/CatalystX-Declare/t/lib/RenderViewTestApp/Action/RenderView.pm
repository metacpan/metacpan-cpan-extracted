use MooseX::Declare;

class RenderViewTestApp::Action::RenderView extends Catalyst::Action {

    after execute ($, Object $ctx, @) {

        $ctx->forward($ctx->view);
    }
}
