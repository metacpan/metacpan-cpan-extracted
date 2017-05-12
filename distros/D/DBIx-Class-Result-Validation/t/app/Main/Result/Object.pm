package t::app::Main::Result::Object;
use base qw/DBIx::Class::Core/;
__PACKAGE__->table('object');
__PACKAGE__->add_columns('objectid',
                         { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
                         'name',
                         {data_type => "varchar", is_nullable => 0, validation  => ["defined","not_empty"]},
                         'my_enum', 
                         {data_type => "enum", extra => { list => [ "val1", "val2", "val3"] }, is_nullable => 1 , default_value => "val1" , validation  => "enum"},
                         'my_enum_def', 
                         {data_type => "enum", extra => { list => [ "val1", "val2", "val3"] }, is_nullable => 0 , validation  => ["enum","defined"]},
                         'attribute',
                         {data_type => "varchar", is_nullable => 0, validation  => "defined"},
                         'ref_id',
                         {data_type => "integer", is_nullable => 0, validation  => "not_null_or_not_zero"},
                         );
__PACKAGE__->set_primary_key('objectid');
__PACKAGE__->load_components(qw/ Result::Validation /);

sub _validate
{
  my $self = shift;
  my @other = $self->result_source->resultset->search({name => $self->name, objectid => { "!=", $self->objectid} });
  if (scalar @other)
  {
    $self->add_result_error('name', 'name must be unique');
  }
  if ($self->name && $self->name eq 'error')
  {
    $self->add_result_error('name', "name can not be 'error'");
  }
  return $self->next::method(@_);
}
1;
