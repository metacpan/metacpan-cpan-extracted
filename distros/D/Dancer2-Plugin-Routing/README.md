# Dancer2-Plugin-Routing
Routing plugin for Perl Dancer2 using Dancer2::Plugin::RootURIFor

# SYNOPSIS

Configuration:

    plugins:
        Routing:
            template_key: routing
            routes:
                main:
                  route: '/'
                  package: MyApp
                api:
                  route: '/api'
                  package: MyApp::API
                moderation:
                  route: '/mod'
                  package: MyApp::Moderation
                admin: '/~admin'
                assets:
                  route: '/assets'
                  package:  MyApp::Assets
Code:

    use Dancer2;
    use Dancer2::Plugin::Routing;
    use Plack::Builder;
    use MyApp;
    ...
    builder {
        mount routing_for('main')       => MyApp->to_app             if mount routing_for('main');
        mount routing_for('api')        => MyApp::API->to_app        if mount routing_for('api');
        mount routing_for('moderation') => MyApp::Moderation->to_app if mount routing_for('moderation');
        mount routing_for('admin')      => MyApp::Admin->to_app      if mount routing_for('admin');
        mount routing_for('assets')     => MyApp::Assets->to_app     if mount routing_for('assets');
    };

    ...

    use Dancer2;
    use Dancer2::Plugin::Routing;

    get '/do/stuff' => sub {
        return root_redirect '/';
    };

Template:

    <a href="[% routing.admin %]/page">To some admin page</a>
