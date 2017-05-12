use CatalystX::Declare;

controller PlainTestApp::Controller::Root {

    final action foo under '/' { $ctx->response->body('foo') }
}
