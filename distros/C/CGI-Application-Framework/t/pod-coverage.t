#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
eval "use Test::Pod::Coverage 1.04";
if ($@) {
    plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage";
}
else {
    plan 'no_plan';
}

pod_coverage_ok(
    "CGI::Application::Framework",
    { also_private => [
        qr/^
            (session)         # documented implicitly in SESSIONS
            |(get_session_id) # documented implicitly in SESSIONS
            |(run_app)        # documented implicitly in STARTUP
            |(template_pre_process)  # documented in TEMPLATES Pre- and Post- process
            |(template_post_process) # documented in TEMPLATES Pre- and Post- process
        $/x
    ], },
    "CAP::AnyTemplate::Driver::HTMLTemplate POD coverage",
);


