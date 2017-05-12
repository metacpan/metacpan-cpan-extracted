use Test::Pod::Coverage tests => 1;

pod_coverage_ok(
    'CGI::Application::URIMapping',
    {
        also_private => [
            qw/dispatch_args/,
        ],
    },
);
