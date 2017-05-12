use CatalystX::Declare;

controller TestApp::Controller::ViewTest {

    action base as 'view_test' under '/';

    under base {

        final action normal;

        final action role_test {
            $ctx->stash(role_tag => 'modified');
        }
    }

    action end { 
        $ctx->forward( 'View::TestView' );
    }
}
