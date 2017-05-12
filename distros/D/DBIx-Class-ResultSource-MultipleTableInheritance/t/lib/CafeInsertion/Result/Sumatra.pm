package    # hide from PAUSE
    CafeInsertion::Result::Sumatra;

use strict;
use warnings;
use parent 'CafeInsertion::Result::Coffee';

require CafeInsertion::Result::Sugar;

__PACKAGE__->table('sumatra');
__PACKAGE__->result_source_instance->deploy_depends_on(["CafeInsertion::Result::Coffee"]);
__PACKAGE__->result_source_instance->add_additional_parents(
    "CafeInsertion::Result::Sugar","CafeInsertion::Result::Cream");
__PACKAGE__->add_columns( "aroma", { data_type => "text" } );

__PACKAGE__->has_many(
    'coffees',
    'CafeInsertion::Result::Coffee',
    { 'foreign.id' => 'self.id' }
);

1;
