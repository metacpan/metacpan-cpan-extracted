use strict;
use warnings;

package DCQWTestSchema::Result::Hlagh;
use base qw(DBIx::Class::Core);
__PACKAGE__->table('hlagh');
__PACKAGE__->add_columns(qw(pk somedata));
__PACKAGE__->set_primary_key('pk');

1;
