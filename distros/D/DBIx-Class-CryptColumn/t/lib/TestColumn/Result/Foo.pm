use strict;
use warnings;

package TestColumn::Result::Foo;

use parent 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(CryptColumn Core));
__PACKAGE__->table('foo');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
    },
    passphrase => {
        data_type          => 'text',
        inflate_passphrase => {
			encoder                   => 'Reversed',
			validators                => [ 'SHA1::Hex' ],
			verify_method             => 'verify_passphrase',
			rehash_method             => 'passphrase_needs_rehash',
			verify_and_rehash_method  => 'verify_and_rehash_password',
		},
    },
);

__PACKAGE__->set_primary_key('id');

1;
