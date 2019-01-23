package MyApp::Dummy2;

sub new {
  my ($class, %args) = @_;
  return bless \%args, $class;
}

1
