#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
if ($@) {
    plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage";
}
else {
    plan tests => 1;
}

# The 'form_state' sub is not documented separately.  Instead it's documented in
# the calling syntax of every other sub.
pod_coverage_ok(
        "CGI::Application::Plugin::FormState",
        { also_private => [ qr/^(form_state)|(init)$/ ], },
        "CAP::FormState, POD coverage, but marking the 'form_state' and 'init' subs as private",
);

