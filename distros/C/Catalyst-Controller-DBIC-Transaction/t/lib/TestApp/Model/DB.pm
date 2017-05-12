package TestApp::Model::DB;

use base 'Catalyst::Model';

sub schema {
    return bless {}, 'MyTestSchemaReplacer';
}

1;
