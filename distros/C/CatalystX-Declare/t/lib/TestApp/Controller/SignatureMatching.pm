use CatalystX::Declare;

controller TestApp::Controller::SignatureMatching {

    method mark (Catalyst $ctx) { 
        $ctx->response->body( $ctx->action->reverse );
    }


    action base as 'sigmatch' under '/';

    under base {

        final action int (Int $x) 
            as test { $self->mark($ctx) }

        final action str (Str $x where { /^[a-z]+$/ }) 
            as test { $self->mark($ctx) }

        final action rest (@) 
            as '' { $self->mark($ctx) }


        final action opt_param (Int :$page?) {
            $ctx->response->body("page $page");
        }


        final action req_param (Int :$page!) {
            $ctx->response->body("page $page");
        }

        final action req_param_none as req_param {
            $ctx->response->body('no page');
        }


        # TODO
        action mid_with_param (Int :$page!) as '';
        action mid_no_param as '';
        final action end_with_param under mid_with_param as mid { $self->mark($ctx) }
        final action end_no_param under mid_no_param as mid { $self->mark($ctx) }


        final action with_list (ArrayRef[Int] :$filter) {
            $ctx->response->body(join ', ', sort @$filter);
        }


        final action getpost (Int :$id) {
            $ctx->response->body($id);
        }
    }
}
