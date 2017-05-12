use CatalystX::Declare;

# this "calculator" (mind the quotes) is extendable by the model
controller MyApp::Web::Controller::Calc {

    # we base of the common base in the root controller
    action base as calc under '/base';

    # we fetch our operator from the model in an action attached to the base
    action operator <- base (Str $op) as '' {
        $ctx->stash(operator => $ctx->model('Calc')->op($op));
    }

    # here we know we have an operator and run it against the integers we got
    final action evaluate <- operator (Int @nums) as '' {
        $ctx->response->body($ctx->stash->{operator}->(@nums));
    }
}
