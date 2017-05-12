package TestDB::User;

use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ Core /);
__PACKAGE__->table( 'user' );
__PACKAGE__->resultset_class( 'TestDB::RS::User' );
__PACKAGE__->add_columns( qw/id username password session_data / );
__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->has_many(
    map_user_role => 'TestDB::UserRole' => 'user' );

eval { require Storable; require MIME::Base64 };
unless ($@) {
    __PACKAGE__->inflate_column(
        session_data => {
            inflate => sub { Storable::thaw(MIME::Base64::decode_base64(shift)) },
            deflate => sub { MIME::Base64::encode_base64(Storable::freeze(shift)) },
        }
    );
}

1;
