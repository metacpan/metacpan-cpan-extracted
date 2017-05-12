use Test::Dependencies
    exclude => [
    qw/Test::Dependencies Test::Base Test::Perl::Critic Catalyst::Model::MultiAdaptor::Base Catalyst::Model::MultiAdaptor Catalyst::Model TestApp::Web::BaseController::MultiAdaptor ok/
    ],
    style => 'light';
ok_dependencies();
