package MyApp::DispatchPSGI;
use base 'CGI::Application::Dispatch::PSGI';

sub translate_module_name {
    my $self = shift;
    return 'MyApp::Module::Name';
}

sub get_runmode {
    return 'rm2';
}

1;
