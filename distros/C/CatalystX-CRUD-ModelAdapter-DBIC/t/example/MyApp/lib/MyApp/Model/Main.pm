package MyApp::Model::Main;
use base qw( Catalyst::Model::DBIC::Schema );

__PACKAGE__->config(
    schema_class => 'MyCRUD::Main',
    connect_info => [ 'dbi:SQLite:' . MyApp->path_to('mycrud.db') ],
);

1;
