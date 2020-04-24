package Test::Data::Str;

sub new {
  my ($self, $data) = @_;

  bless \$data, $self;
}

1;
