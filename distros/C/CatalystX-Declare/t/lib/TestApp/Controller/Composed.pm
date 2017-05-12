use CatalystX::Declare;

controller_role TestApp::ControllerRole::Composed {
    method composed_method { }
    action composed_action;
}

controller TestApp::ControllerBase::Composed {
    method inherited_method { }
    action inherited_action;
}

controller TestApp::Controller::Composed
    extends TestApp::ControllerBase::Composed
    with    TestApp::ControllerRole::Composed {

    method original_method { }
    action original_action;
}
