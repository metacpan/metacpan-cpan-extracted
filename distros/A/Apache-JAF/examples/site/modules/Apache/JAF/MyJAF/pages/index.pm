sub do_index {
  my ($self) = @_;
  # page handler must fill $self->{res} hash that process with template
  $self->{res}{test} = __PACKAGE__ . 'test';
  # and return Apache constant according it's logic
  return OK;
}
