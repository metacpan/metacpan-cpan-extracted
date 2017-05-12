use CatalystX::Declare;

controller RenderViewTestApp::Controller::Root {

    $CLASS->config(namespace => '');


    action base as '' under '/';

    final action foo under base {
        $ctx->stash(current_view => 'Test');
    }

    action end is private isa RenderView;
}
