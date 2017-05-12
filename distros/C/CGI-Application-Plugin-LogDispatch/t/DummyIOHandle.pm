package DummyIOHandle;

# Very simple IO module that handles standard print statements, and 
# stores any printed statements in $self.
# This is used as a Handle that Log::Dispatch::Handle can use, giving
# us an in-memory buffer for collecting and testing log messages

sub new {
  my $class = shift;
  my $string = '';
  my $self = \$string;
  bless $self, $class;
  return $self;
}

sub print {
  my $self= shift;

  $$self .= join('', @_);
}

1;
