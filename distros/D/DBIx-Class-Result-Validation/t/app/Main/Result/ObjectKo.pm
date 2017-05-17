package t::app::Main::Result::ObjectKo;
use base qw/DBIx::Class::Core/;
__PACKAGE__->table('object_ko');
__PACKAGE__->add_columns('object_ko_id',
                         { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
                         'label',
                         {data_type => 'varchar', is_nullable => 0},
                         'my_enum', 
                         {data_type => "enum", extra => { list => [ "val1", "val2", "val3"] }, is_nullable => 1 , default_value => "val1" , validation  => "fake"},
                         );
__PACKAGE__->set_primary_key('object_ko_id');
__PACKAGE__->load_components(qw/ Result::Validation /);

sub _validate
{
  my $self = shift;
  my @other = $self->result_source->resultset->search({label => $self->label, object_ko_id => { "!=", $self->objectid} });
  if (scalar @other)
  {
    $self->add_result_error('label', 'label must be unique');
  }
  return $self->next::method(@_);
}
1;
