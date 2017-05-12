package MyApp::Model::S3;

use base qw/ Catalyst::Model::S3 /;

__PACKAGE__->config(
    aws_access_key_id     => 'your_access_key_id',
    aws_secret_access_key => 'your_secret_access_key',
    secure                => 0,  # optional: default 0  (false)
    timeout               => 30, # optional: default 30 (seconds)
);


1;
