use CatalystX::Declare;

controller TestApp::Controller::ModelTest {

    method find_model (Object $ctx) {
        return $ctx->model('TestModel');
    }


    action base as 'model_test' under '/';

    under base {

        final action next {
            $ctx->response->body( $self->find_model($ctx)->next );
        }

        final action reset {
            $ctx->response->body( $self->find_model($ctx)->reset );
        }
    }
}
