use strict;
use warnings;

package TestInflate::Result::Foo;

use parent 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(InflateColumn::Crypt::Passphrase));
__PACKAGE__->table('foo');

my $crypt_passphrase = Crypt::Passphrase->new(encoder => 'Reversed');

sub crypt_passphrase {
	return $crypt_passphrase;
}

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
    },
    passphrase => {
        data_type          => 'text',
        inflate_passphrase => {
			encoder => 'Reversed',
		},
    },
);

__PACKAGE__->set_primary_key('id');

1;
