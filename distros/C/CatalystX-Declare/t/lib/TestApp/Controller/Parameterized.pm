use CatalystX::Declare;

controller TestApp::Controller::Parameterized {
    with 'TestApp::ControllerRole::Parameterized' => { 
        message => 'foo',
        base    => 'somebase',
        part    => 'somepart',
        action  => 'someaction',
    };

    action base under '/' as 'param';

    action somebase under base;
}
