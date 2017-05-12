package MyApp::Model::File;
use strict;
use base qw(
    CatalystX::CRUD::Model::File
);
use MyApp::File;
__PACKAGE__->config( object_class => 'MyApp::File' );

1;

