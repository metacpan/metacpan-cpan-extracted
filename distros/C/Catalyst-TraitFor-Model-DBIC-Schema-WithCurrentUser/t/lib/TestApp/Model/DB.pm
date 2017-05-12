package    # hide from PAUSE
    TestApp::Model::DB;

use Moose;
extends qw/Catalyst::Model::DBIC::Schema/;
with 'Catalyst::TraitFor::Model::DBIC::Schema::WithCurrentUser';

__PACKAGE__->config(
    {   schema_class => 'TestApp::Schema',
        connect_info => { dsn => 'dbi:SQLite:dbname=:memory:' },
    }
);

1;
