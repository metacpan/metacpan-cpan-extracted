package AuthServer::Controller::OAuth2::ProviderInherited;
use Moose;

# this is here just to ensure that inherited classes load with the
# correct configuration propagated from the parent class. If something
# is wrong with the configuration, the app will throw an error similar
# to this:

# Couldn't instantiate component
# "AuthServer::Controller::OAuth2::ProviderInherited",
# "`CatalystX::OAuth2::Store::' is not a module name"Compilation
# failed in require at t/unit/700-client.t line 8.

BEGIN { extends 'AuthServer::Controller::OAuth2::Provider' }

sub base :Chained('/') PathPart('inherited') CaptureArgs(0) {}

1;
