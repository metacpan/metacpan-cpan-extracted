requires        'OpenTracing::GlobalTracer';
requires        'OpenTracing::Implementation', 'v0.33.2';
requires        'HTTP::Headers';
requires        'HTTP::Status';
requires        'Syntax::Feature::Maybe';
requires        'Time::HiRes';
requires		'syntax';

on 'develop' => sub {
    requires    "ExtUtils::MakeMaker::CPANfile";
};

on 'test' => sub {
    requires    'CGI::Application';
	requires	"Ref::Util";
    requires    "Test::Most";
    requires    "Test::OpenTracing::Integration", 'v0.102.0';
    requires    "Test::MockObject";
    requires    "Test::WWW::Mechanize::CGIApp";
    requires    "LWP::UserAgent", '6.42';
}

# on 'examples' => sub {
#     
#     requires    'CGI::Application::Server';
# };
