package Schema::Nested::Result::Meeting::Attendee;

use base 'Schema::Result';

__PACKAGE__->table('attendee');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
    },
    meeting_id => {
        data_type      => 'integer',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    role => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0,
    },
    background => {
        data_type   => 'text',
        is_nullable => 0,
    },
    desired_outcome => {
        data_type   => 'text',
        is_nullable => 0,
    },
    personality => {
        data_type   => 'text',
        is_nullable => 0,
    },
    motivation => {
        data_type   => 'text',
        is_nullable => 0,
    },
    extra_instructions => {
        data_type   => 'text',
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
  meeting =>
  'Schema::Nested::Result::Meeting',
  { 'foreign.id' => 'self.meeting_id' }
);

__PACKAGE__->validates(role => (length => [2, 48]));
__PACKAGE__->validates(background => (length => [2, 1000]));
__PACKAGE__->validates(desired_outcome => (length => [2, 1000]));
__PACKAGE__->validates(personality => (length => [2, 1000]));
__PACKAGE__->validates(motivation => (length => [2, 1000]));
__PACKAGE__->validates(extra_instructions => (length => [0, 1000]));

1;
