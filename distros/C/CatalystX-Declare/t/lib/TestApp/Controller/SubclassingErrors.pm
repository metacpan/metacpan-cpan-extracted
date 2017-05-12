use CatalystX::Declare;

controller TestApp::Controller::SubclassingErrors
   extends TestApp::Controller::Errors {

    action base under '/' as 'sub_errors';

    around signature_error_on_foo_modify ($ctx, $str) {
        $self->$orig($ctx, $str);
    }
}
