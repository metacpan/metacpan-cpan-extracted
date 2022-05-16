package TestSchema::Result::Human;
use Modern::Perl;

use DBIx::Class::Candy -components => [qw/TemporalRelations/];

__PACKAGE__->table('human');
__PACKAGE__->add_columns(qw(id name));
__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(
    'contraptions' => 'TestSchema::Result::Contraption',
    'purchased_by'
);

__PACKAGE__->has_many(  
    'doodads' => 'TestSchema::Result::Doodad',
    'created_by'
);
__PACKAGE__->has_many(  
    'doodads_modified_rel' => 'TestSchema::Result::Doodad',
    'modified_by'
);
__PACKAGE__->has_many(
    'doohickies_modified_rel' => 'TestSchema::Result::Doohickey',
    'modified_by'
);
__PACKAGE__->has_many(
    'doohickies_purchased_rel' => 'TestSchema::Result::Doohickey',
    'purchased_by'
);

__PACKAGE__->load_components('TemporalRelations');

# Normally, you would choose one way of doing this, for the entire table.
# But we're doing this to show (and test) that you can do it any way you like.

# Test direct injection in source info
__PACKAGE__->source_info(
    {
        temporal_relationships =>
            { 'contraptions' => [ { verb => 'purchased', temporal_column => 'purchase_dt' } ] }
    }
);

# Test direct single relationship method
__PACKAGE__->make_temporal_relationship( 'created', 'doodads', 'created_dt' );

# Test multiple relationship method
__PACKAGE__->make_temporal_relationships(
    'modified'  => [ [ 'doodads_modified_rel', 'modified_dt' ], [ 'doohickies_modified_rel', 'modified_dt', 'doohickey' ], ],
    'purchased' => [ 'doohickies_purchased_rel',       'purchase_dt', 'doohickey', 'doohickees' ],
);

1;
