requires        'OpenTracing::GlobalTracer';
requires        'OpenTracing::Implementation';
requires        'HTTP::Headers';
requires        'HTTP::Status';
requires        "Syntax::Feature::Maybe";
requires        'Time::HiRes';

on 'develop' => sub {
    requires    "ExtUtils::MakeMaker::CPANfile";
};

on 'test' => sub {
    requires    'CGI::Application';
    requires    "Test::Most";
    requires    "Test::OpenTracing::Integration", 'v0.102.0';
    requires    "Test::MockObject";
    requires    "Test::WWW::Mechanize::CGIApp";
}

# on 'examples' => sub {
#     
#     requires    'CGI::Application::Server';
# };
