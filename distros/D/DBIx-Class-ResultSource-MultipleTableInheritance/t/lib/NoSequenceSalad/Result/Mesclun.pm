package    # hide from PAUSE
    NoSequenceSalad::Result::Mesclun;

use strict;
use warnings;
use parent 'NoSequenceSalad::Result::Salad';

require NoSequenceSalad::Result::Dressing;

__PACKAGE__->table('mesclun');
__PACKAGE__->result_source_instance->deploy_depends_on(
    ["NoSequenceSalad::Result::Salad"] );
__PACKAGE__->result_source_instance->add_additional_parent(
    NoSequenceSalad::Result::Dressing->result_source_instance );

__PACKAGE__->add_columns(
    spiciness => { data_type => "integer" },
);

1;
