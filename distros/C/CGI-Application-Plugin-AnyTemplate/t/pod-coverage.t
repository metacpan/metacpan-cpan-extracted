#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
if ($@) {
    plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage";
}
else {
    plan 'no_plan';
}

# The 'template' sub is not documented separately.  Instead it's documented in
# the calling syntax of every other sub.
pod_coverage_ok(
        "CGI::Application::Plugin::AnyTemplate",
        { also_private => [ qr/^(template)$/ ], },
        "CAP::AnyTemplate, POD coverage, but marking the 'template' sub as private",
);

pod_coverage_ok(
        "CGI::Application::Plugin::AnyTemplate::ComponentHandler",
        { also_private => [ qr/^(dispatch)|(dispatch_direct)$/ ], },
        "CAP::AnyTemplate::Base POD coverage",
);
pod_coverage_ok(
        "CGI::Application::Plugin::AnyTemplate::Base",
        {},
        "CAP::AnyTemplate::Base POD coverage",
);


# In the driver modules, default_driver_config and driver_config_keys
# are documented in the CONFIGURATION section

pod_coverage_ok(
        "CGI::Application::Plugin::AnyTemplate::Driver::HTMLTemplate",
        { also_private => [ qr/^(default_driver_config)|(driver_config_keys)|(clear_params)$/ ], },
        "CAP::AnyTemplate::Driver::HTMLTemplate POD coverage",
);

pod_coverage_ok(
        "CGI::Application::Plugin::AnyTemplate::Driver::HTMLTemplateExpr",
        { also_private => [ qr/^(default_driver_config)|(driver_config_keys)|(clear_params)$/ ], },
        "CAP::AnyTemplate::Driver::HTMLTemplate POD coverage",
);

pod_coverage_ok(
        "CGI::Application::Plugin::AnyTemplate::Driver::HTMLTemplatePluggable",
        { also_private => [ qr/^(default_driver_config)|(driver_config_keys)|(clear_params)$/ ], },
        "CAP::AnyTemplate::Driver::HTMLTemplate POD coverage",
);

pod_coverage_ok(
        "CGI::Application::Plugin::AnyTemplate::Driver::TemplateToolkit",
        { also_private => [ qr/^(default_driver_config)|(driver_config_keys)$/ ], },
        "CAP::AnyTemplate::Driver::TemplateToolkit POD coverage",
);

pod_coverage_ok(
        "CGI::Application::Plugin::AnyTemplate::Driver::Petal",
        { also_private => [ qr/^(default_driver_config)|(driver_config_keys)$/ ], },
        "CAP::AnyTemplate::Driver::Petal POD coverage",
);


