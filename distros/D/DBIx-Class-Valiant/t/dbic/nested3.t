use Test::Most;
use Test::Lib;
use Test::DBIx::Class
  -schema_class => 'Schema::Nested';

# Create a person as a fixture

Schema->resultset("State")->populate([
  [ qw( name abbreviation ) ],
  [ 'Texas', 'TX' ],
  [ 'New York', 'NY' ],
  [ 'California', 'CA' ],
]);

ok my $person = Schema
  ->resultset('Person')
  ->create({
    username => 'jjn',
    last_name => 'napiorkowski',
    first_name => 'john',
    state => { abbreviation => 'TX' },
  });

ok $person->valid;
ok $person->in_storage;

# Find it like as in a web session
ok my $person_for_meeting = Schema->resultset('Person')->find($person->id);
ok my $meetings_nested_attendees = $person_for_meeting->meetings->search({},{prefetch=>'attendees'});
ok my $new_meeting = $meetings_nested_attendees->new_result(+{});

ok $new_meeting->set_columns_recursively({
    title=>'first meeting',
    purpose=>'test this',
    attendees=>[
      {
        role => 'one',
        background => 'back1',
        desired_outcome => 'misery',
        personality => 'hateful',
        motivation => 'much',
      },
      {
        role => 'two',
        background => 'back2',
        desired_outcome => 'happy',
        personality => 'lawful evil',
        motivation => 'slacker',
      },
    ],
  });

ok exists $new_meeting->{related_resultsets}{attendees};
ok $new_meeting->insert_or_update;
ok !exists $new_meeting->{related_resultsets}{attendees};

ok $new_meeting->valid;

{

  # Find it like as in a web session
  ok my $person_for_meeting = Schema->resultset('Person')->find($person->id);
  ok my $meetings_nested_attendees = $person_for_meeting->meetings->search({},{prefetch=>'attendees'});
  ok my $new_meeting = $meetings_nested_attendees->new_result(+{});

  ok $new_meeting->set_columns_recursively({
      title=>'first meeting',
      purpose=>'test this',
      attendees=>[
        {
          role => 'o',
          background => 'back1',
          desired_outcome => 'misery',
          personality => 'hateful',
          motivation => 'much',
        },
        {
          role => 't',
          background => 'back2',
          desired_outcome => 'happy',
          personality => 'lawful evil',
          motivation => 'slacker',
        },
      ],
    });

  $new_meeting->insert_or_update;

  # This test is mostly about checking the pluralization of the error message
  # for attendees.
  is_deeply +{$new_meeting->errors->to_hash(full_messages=>1)}, {
    "attendees[0].role"
    => [
      "Attendees Role is too short (minimum is 2 characters)",
    ],
    "attendees"
    => [
      "Attendees Are Invalid",
    ],
    "attendees[1].role"
    => [
      "Attendees Role is too short (minimum is 2 characters)",
    ],
  };

  $new_meeting->errors->add(undef, 'testerror');
  is_deeply $new_meeting->errors->as_rfc_7807, {
    fields => {
      attendees => [
        "Attendees Are Invalid",
      ],
      "attendees[0].role" => [
        "Attendees Role is too short (minimum is 2 characters)",
      ],
      "attendees[1].role" => [
        "Attendees Role is too short (minimum is 2 characters)",
      ],
    },
    general => [
      "testerror",
    ],
  }
}

done_testing;
