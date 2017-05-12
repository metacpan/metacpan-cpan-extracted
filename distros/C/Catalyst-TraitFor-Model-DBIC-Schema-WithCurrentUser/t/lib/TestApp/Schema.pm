package    # hide from PAUSE
    TestApp::Schema;

use Moose;
extends qw/DBIx::Class::Schema/;

has 'current_user' => ( is => 'rw', );

__PACKAGE__->load_namespaces;

1;
