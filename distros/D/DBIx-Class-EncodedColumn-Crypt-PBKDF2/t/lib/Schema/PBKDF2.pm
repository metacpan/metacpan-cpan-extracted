use strict;
use warnings;
 
package # hide from PAUSE
    Schema::PBKDF2;
use base qw(DBIx::Class);
 
__PACKAGE__->load_components(qw/EncodedColumn Core/);
__PACKAGE__->table('test');
__PACKAGE__->add_columns(
    id => {
        data_type => 'int',
        is_nullable => 0,
        is_auto_increment => 1
    },
    hash_defaults => {
        data_type => 'text',
        is_nullable => 1,
        size => 254,
        encode_column => 1,
        encode_class => 'Crypt::PBKDF2',
        encode_check_method => 'hash_defaults_check'
    },
    hash_custom => {
        data_type => 'text',
        is_nullable => 1,
        size => 254,
        encode_column => 1,
        encode_class => 'Crypt::PBKDF2',
        encode_args  => {
            hash_class  => 'HMACSHA3',
            hash_args   => { sha_size => 512 },
            iterations  => 2000,
        },
        encode_check_method => 'hash_custom_check'
    },
);
__PACKAGE__->set_primary_key('id');
 
1;
