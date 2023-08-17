package MyApp::Schema::Artist;

use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->table('artist');
__PACKAGE__->add_columns(
    artistid => {
        data_type         => 'INTEGER',
        is_nullable       => 0,
        is_auto_increment => 1,
    },
    name => {
        data_type   => 'VARCHAR',
        size        => 100,
        is_nullable => 1,
    },
    rank => {
        data_type     => 'INTEGER',
        default_value => 13,
    },
    charfield => {
        data_type   => 'CHAR',
        size        => 10,
        is_nullable => 1,
    },
);
__PACKAGE__->set_primary_key('artistid');
__PACKAGE__->add_unique_constraint( ['name'] );
__PACKAGE__->add_unique_constraint( artist     => ['artistid'] );
__PACKAGE__->add_unique_constraint( u_nullable => [qw/charfield rank/] );

__PACKAGE__->mk_classdata(
    'field_name_for',
    {
        artistid => 'primary key',
        name     => 'artist name',
    }
);

__PACKAGE__->has_many(
    cds => 'MyApp::Schema::CD',
    undef,
    { order_by => { -asc => 'year' } },
);

package MyApp::Schema::CD;

use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->table('cd');
__PACKAGE__->add_columns(
    cdid => {
        data_type         => 'INTEGER',
        is_nullable       => 0,
        is_auto_increment => 1,
    },
    artist => {
        data_type => 'INTEGER',
    },
    title => {
        data_type => 'VARCHAR',
        size      => 100,
    },
    year => {
        data_type => 'VARCHAR',
        size      => 100,
    }
);
__PACKAGE__->set_primary_key('cdid');
__PACKAGE__->add_unique_constraint( [qw/artist title/] );

__PACKAGE__->belongs_to(
    artist => 'MyApp::Schema::Artist',
    undef,
    {
        is_deferrable => 1,
        proxy         => { artist_name => 'name' },
    }
);
__PACKAGE__->has_many(
    cd_to_producer => 'MyApp::Schema::CDToProducer' => 'cd' );
__PACKAGE__->many_to_many( producers => cd_to_producer => 'producer' );

package MyApp::Schema::CDToProducer;

use warnings;
use strict;
use base 'DBIx::Class::Core';

__PACKAGE__->table('cd_to_producer');
__PACKAGE__->add_columns(
    cd        => { data_type => 'INTEGER' },
    producer  => { data_type => 'INTEGER' },
);
__PACKAGE__->set_primary_key(qw/cd producer/);

__PACKAGE__->belongs_to( 'cd', 'MyApp::Schema::CD' );
__PACKAGE__->belongs_to(
    'producer', 'MyApp::Schema::Producer',
    { 'foreign.producerid' => 'self.producer' },
    { on_delete            => undef, on_update => undef },
);

package MyApp::Schema::Owner;

use warnings;
use strict;
use base 'DBIx::Class::Core';

__PACKAGE__->table('owner');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'INTEGER',
        is_nullable       => 0,
        is_auto_increment => 1,
    },
    name => {
        data_type => 'VARCHAR',
        size      => 100,
    },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( ['name'] );
__PACKAGE__->has_many( books => 'MyApp::Schema::BooksInLibrary', 'owner' );

package MyApp::Schema::BooksInLibrary;

use warnings;
use strict;
use base 'DBIx::Class::Core';

__PACKAGE__->table('book');
__PACKAGE__->add_columns(
    id => {
        data_type => 'INTEGER',

        # part of test, auto-retrieval of PK regardless of autoinc status
        # is_auto_increment => 1,
    },
    source => {
        data_type => 'VARCHAR',
        size      => 100,
    },
    owner => {
        data_type => 'INTEGER',
    },
    title => {
        data_type => 'VARCHAR',
        size      => 100,
    },
    price => {
        data_type   => 'INTEGER',
        is_nullable => 1,
    },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( ['title'] );
__PACKAGE__->resultset_attributes( { where => { source => "Library" } } );
__PACKAGE__->belongs_to( owner => 'MyApp::Schema::Owner', 'owner' );

package MyApp::Schema::Producer;

use warnings;
use strict;
use base 'DBIx::Class::Core';

__PACKAGE__->table('producer');
__PACKAGE__->add_columns(
    producerid => {
        data_type         => 'INTEGER',
        is_auto_increment => 1,
    },
    name => {
        data_type => 'VARCHAR',
        size      => 100,
    },
);
__PACKAGE__->set_primary_key('producerid');
__PACKAGE__->add_unique_constraint( prod_name => [qw/name/] );

package MyApp::Schema;

use strict;
use warnings;
use base 'DBIx::Class::Schema';

__PACKAGE__->register_class( 'Artist',       'MyApp::Schema::Artist' );
__PACKAGE__->register_class( 'CD',           'MyApp::Schema::CD' );
__PACKAGE__->register_class( 'Owner',        'MyApp::Schema::Owner' );
__PACKAGE__->register_class( 'Producer',     'MyApp::Schema::Producer' );
__PACKAGE__->register_class( 'CDToProducer', 'MyApp::Schema::CDToProducer' );
__PACKAGE__->register_class( 'BooksInLibrary',
    'MyApp::Schema::BooksInLibrary' );
__PACKAGE__->ensure_class_loaded('DBIx::Class::Storage::DBI::MariaDB');

1;
