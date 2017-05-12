package TestApp;

use strict;
use Catalyst;

__PACKAGE__->config( 
    name => 'TestApp',
    'Model::File' => {
        root_dir => $ENV{MODEL_FILE_DIR},
    },
);

__PACKAGE__->setup;

1;
        
