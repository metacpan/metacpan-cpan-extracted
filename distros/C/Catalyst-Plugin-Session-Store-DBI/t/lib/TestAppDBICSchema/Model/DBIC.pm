package TestAppDBICSchema::Model::DBIC;

use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'TestAppDBICSchema::Schema',
);

1;
