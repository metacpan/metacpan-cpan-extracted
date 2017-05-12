use strict;
use warnings;

package TestSchema::Result::Foo;

use parent 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(PassphraseColumn));
__PACKAGE__->table('foo');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
    },
    passphrase_rfc2307 => {
        data_type        => 'text',
        passphrase       => 'rfc2307',
        passphrase_class => 'SaltedDigest',
        passphrase_args  => {
            algorithm   => 'SHA-1',
            salt_random => 20,
        },
        passphrase_check_method => 'check_passphrase_rfc2307',
    },
    passphrase_crypt => {
        data_type        => 'text',
        passphrase       => 'crypt',
        passphrase_class => 'BlowfishCrypt',
        passphrase_args  => {
            cost        => 8,
            salt_random => 1,
        },
        passphrase_check_method => 'check_passphrase_crypt',
    },
);

__PACKAGE__->set_primary_key('id');

1;
