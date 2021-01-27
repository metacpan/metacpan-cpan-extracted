package Example;

use Catalyst;

__PACKAGE__->setup_plugins([qw/Errors/]);
__PACKAGE__->setup();
__PACKAGE__->meta->make_immutable();

