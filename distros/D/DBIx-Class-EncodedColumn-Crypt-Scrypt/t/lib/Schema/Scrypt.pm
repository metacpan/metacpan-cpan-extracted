use strict;
use warnings;

package # hide from PAUSE
    Schema::Scrypt;
use base qw(DBIx::Class);

__PACKAGE__->load_components(qw/EncodedColumn Core/);
__PACKAGE__->table('test');
__PACKAGE__->add_columns(
    id => {
        data_type => 'int',
        is_nullable => 0,
        is_auto_increment => 1
    },
    hash => {
        data_type => 'text',
        is_nullable => 1,
        size => 60,
        encode_column => 1,
        encode_class => 'Crypt::Scrypt',
        encode_check_method => 'scrypt_check'
    }
);
__PACKAGE__->set_primary_key('id');

1;
