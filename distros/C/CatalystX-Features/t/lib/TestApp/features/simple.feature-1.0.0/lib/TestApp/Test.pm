package TestApp::Test;
use base 'CatalystX::Features::Main';
use Moose;

# the feature init module

__PACKAGE__->config( 'testy' => 99 );

1;
