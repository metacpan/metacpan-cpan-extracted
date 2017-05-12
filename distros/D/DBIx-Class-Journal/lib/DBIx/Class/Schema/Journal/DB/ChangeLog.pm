package DBIx::Class::Schema::Journal::DB::ChangeLog;

use base 'DBIx::Class::Core';

sub journal_define_table {
    my ( $class, $schema_class, $prefix ) = @_;
    
    $class->load_components(qw/Ordered/);
    $class->table($prefix . 'changelog');
    
    $class->add_columns(
    	ID => {
    		data_type => 'integer',
    		is_auto_increment => 1,
    		is_primary_key => 1,
    		is_nullable => 0,
    	},
    		changeset_id => {
    		data_type => 'integer',
    		is_nullable => 0,
    		is_foreign_key => 1,
    	},
    	order_in => {
    		data_type => 'integer',
    		is_nullable => 0,
    	},
    );
    
    
    $class->set_primary_key('ID');
    $class->add_unique_constraint('setorder', [ qw/changeset_id order_in/ ]);
    $class->belongs_to('changeset', "${schema_class}::ChangeSet", 'changeset_id');
    
    $class->position_column('order_in');
    $class->grouping_column('changeset_id');
}

1;
