use CatalystX::Declare;

controller_role TestApp::ControllerRole::ModifierSignatures {

    around foo (@args) {
        $self->$orig(@args);
        $args[0]->response->body( $args[0]->response->body . ' modified' );
    }
}
