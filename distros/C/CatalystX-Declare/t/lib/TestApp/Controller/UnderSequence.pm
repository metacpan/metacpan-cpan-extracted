use CatalystX::Declare;

controller TestApp::Controller::UnderSequence {

    action base under '/' as 'under_seq';

    under base {

        final action foo { $ctx->response->body('foo') }

        action bar;

        under bar { final action test_bar { $ctx->response->body('bar') } }

        action baz;

        under baz { final action test_baz { $ctx->response->body('baz') } }
    }
}
