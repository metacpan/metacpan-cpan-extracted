use CatalystX::Declare;

controller_role TestApp::ControllerRole::DynamicFinal (
        Bool            :$is_final, 
        Str             :$body, 
        Str             :$base = "base",
        ArrayRef[Str]   :$counters = []
    ) {

    method set_body (Object $ctx) {
        $ctx->response->body($body);
    }

    if ($is_final) {

        final action msg under $base { $self->set_body($ctx) }
    }

    else {

        action msg under $base { $self->set_body($ctx) }
    }

    for my $counter (@$counters) {
        my $count = 0;

        final action "count_$counter" under $base as "counter/$counter" {
            $ctx->response->body($count++);
        }
    }
}
