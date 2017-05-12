package # hide from PAUSE
    DigestTest::Schema::WithTimeStampChild;

use strict;
use warnings;
use base qw/DigestTest::Schema::WithTimeStampParent/;

__PACKAGE__->table('test_timestamp_order');
__PACKAGE__->add_columns(
    id => {
        data_type => 'int',
        is_nullable => 0,
        is_auto_increment => 1
    },
    username => {
        data_type => 'text',
        is_nullable => 0
    },
    password => {
        data_type           => "text",
        encode_args         => { algorithm => "SHA-1", format => "hex", salt_length => 10 },
        encode_check_method => "check_password",
        encode_class        => "Digest",
        encode_column       => 1,
        is_nullable         => 0,
    },
    created => {
        data_type => 'datetime',
        set_on_create => 1
    },
    updated => {
        data_type => 'datetime',
        set_on_update => 1
    }
);

__PACKAGE__->set_primary_key('id');

1;
