use strict;
use warnings;

package TestSchema::Result::Foo;

use parent 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(InflateColumn::Authen::Passphrase));
__PACKAGE__->table('foo');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
    },
    passphrase_rfc2307 => {
        data_type          => 'text',
        inflate_passphrase => 'rfc2307',
    },
    passphrase_crypt => {
        data_type          => 'text',
        inflate_passphrase => 'crypt',
    },
);

__PACKAGE__->set_primary_key('id');

1;
