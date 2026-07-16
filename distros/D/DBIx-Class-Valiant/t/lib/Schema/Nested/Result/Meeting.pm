package Schema::Nested::Result::Meeting;

use base 'Schema::Result';

__PACKAGE__->table("meeting");

__PACKAGE__->add_columns(
    id => {
        data_type => 'integer',
        is_auto_increment => 1,
    },
    person_id => {
        data_type      => 'bigint',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    title => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0,
    },
    purpose => {
        data_type   => 'text',
        is_nullable => 0,
    },
    transcript => {
        data_type   => 'text',
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  person =>
  'Schema::Nested::Result::Person',
  { 'foreign.id' => 'self.person_id' }
);

__PACKAGE__->has_many(
  attendees =>
  'Schema::Nested::Result::Meeting::Attendee',
  { 'foreign.meeting_id' => 'self.id' }
);


__PACKAGE__->validates(title => (length=>[3,48]));
__PACKAGE__->validates(purpose => (length=>[2,1000]));

__PACKAGE__->validates(attendees => (set_size=>{min=>2, max=>8} ));
__PACKAGE__->accept_nested_for('attendees', +{allow_destroy=>1});


1;
