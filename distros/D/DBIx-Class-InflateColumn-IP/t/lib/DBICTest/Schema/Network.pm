package # hide from PAUSE
    DBICTest::Schema::Network;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/InflateColumn::IP Core/);
__PACKAGE__->table('network');

__PACKAGE__->add_columns(
    netname => {
        data_type   => 'text',
        is_nullable => 0,
    },
    address => {
        data_type   => 'varchar',
        size        => '18',
        is_nullable => 0,
        is_ip       => 1,
        ip_format   => 'cidr',
    }
);

__PACKAGE__->set_primary_key('netname');
__PACKAGE__->add_unique_constraint(address => [ qw/address/ ]);

1;
