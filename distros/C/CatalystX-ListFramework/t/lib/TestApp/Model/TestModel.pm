package TestApp::Model::TestModel;

use strict;
use warnings;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
                    schema_class => 'TestApp::Schema',
                    connect_info => [ "dbi:SQLite2:dbname=/tmp/__listframework_testapp.sqlite","","" ],  # when running tests
                   );

1;

# Remember SQLite seems buggy when doing updates in the interactive app ("too many rows updated", but 2nd attempts work),
# though our tests work ok


