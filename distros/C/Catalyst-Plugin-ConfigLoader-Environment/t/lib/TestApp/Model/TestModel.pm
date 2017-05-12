package TestApp::Model::TestModel;
use base 'Catalyst::Model';

__PACKAGE__->config( foo => 'bar',
                     bar => 'quux' );

1;
