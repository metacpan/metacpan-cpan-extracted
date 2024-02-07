package TestEncrypt::Result::Foo;

use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(FilterColumn::Encrypt));
__PACKAGE__->table('foo');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
    },
    data => {
        data_type          => 'text',
		encrypt            => {
			keys => {
				1 => '1234567890ABCDEF',
			}
		},
    },
);

__PACKAGE__->set_primary_key('id');

1;
