package # hide from PAUSE
   RestrictByUserTest::Schema::Users;

use base 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('test_users');
__PACKAGE__->add_columns(
  'id' => {
    data_type => 'int',
    is_nullable => 0,
    is_auto_increment => 1,
  },
  'name' => {
    data_type => 'varchar',
    size      => 40,
  }
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many("notes", "Notes", { "foreign.user_id" => "self.id" });

sub restrict_Notes_resultset {
  my $self = shift; #the User object
  my $unrestricted_rs = shift;

  return $self->related_resultset('notes');
}

sub restrict_MY_Notes_resultset {
  my $self = shift; #the User object
  my $unrestricted_rs = shift;

  return $unrestricted_rs->search_rs( { user_id => $self->id } );
}

1;
