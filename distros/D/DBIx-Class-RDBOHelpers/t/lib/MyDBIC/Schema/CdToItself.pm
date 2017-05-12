package MyDBIC::Schema::CdToItself;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/ RDBOHelpers Core /);
__PACKAGE__->table('cdtoitself');
__PACKAGE__->add_columns(

    cdid_one => {
        data_type      => 'bigint',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    cdid_two => {
        data_type      => 'bigint',
        is_foreign_key => 1,
        is_nullable    => 0,
    },

);
__PACKAGE__->set_primary_key(qw( cdid_one cdid_two ));
__PACKAGE__->belongs_to( 'cd'      => 'MyDBIC::Schema::Cd' => 'cdid_one' );
__PACKAGE__->belongs_to( 'related' => 'MyDBIC::Schema::Cd' => 'cdid_two' );

1;
