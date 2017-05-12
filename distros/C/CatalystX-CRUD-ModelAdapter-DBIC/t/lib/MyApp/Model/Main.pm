package MyApp::Model::Main;
use base qw( Catalyst::Model::DBIC::Schema );

__PACKAGE__->config(
    schema_class => 'MyDB::Main',
    connect_info => [
        'dbi:SQLite:' . MyApp->path_to() . '/../../example.db',
        quote_names => 1,  # RT 81079
    ],

);

1;
