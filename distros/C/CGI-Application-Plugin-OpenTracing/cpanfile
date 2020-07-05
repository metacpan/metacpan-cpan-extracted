requires        'OpenTracing::Constants::CarrierFormat';
requires        'OpenTracing::GlobalTracer';
requires        'OpenTracing::Implementation';
requires        'HTTP::Request';
requires        'Time::HiRes';

on 'develop' => sub {
    requires    "ExtUtils::MakeMaker::CPANfile";
};

on 'test' => sub {
    requires    'CGI::Application';
    requires    "Test::Most";
    requires    "Test::OpenTracing::Integration", '>= v0.101.2';
    requires    "Test::MockObject";
}

# on 'examples' => sub {
#     
#     requires    'CGI::Application::Server';
# };