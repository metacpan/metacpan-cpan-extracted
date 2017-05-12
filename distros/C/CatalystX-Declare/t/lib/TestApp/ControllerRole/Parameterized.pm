use CatalystX::Declare;

controller_role TestApp::ControllerRole::Parameterized (Str :$message, Str :$base, Str :$part, Str :$action) {

    method get_message { $message }

    final action greet under base {
        $ctx->response->body( join ':', $self->get_message, $message );
    }

    final action dynabase under "$base" {
        $ctx->response->body( "under $base" );
    }

    final action dynapart under "$base" as $part {
        $ctx->response->body( "under $base as $part" );
    }

    under $base {

        final action scoped {
            $ctx->response->body( "scoped under $base" );
        }

        final action complex as "$part/deep" {
            $ctx->response->body( "$part/deep under $base" );
        }

        final action $action {
            $ctx->response->body( "$action action" );
        }

        final action actionalias {
            $self->$action($ctx);
        }
    }

    my $upper_part = uc $part;

    final action upper as $upper_part under $base {
        $ctx->response->body("upper as $upper_part under $base");
    }

    final action short <- $base (Str $x) {
        $ctx->response->body('short ' . $x);
    }
}
