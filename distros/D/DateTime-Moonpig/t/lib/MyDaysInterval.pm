package MyDaysInterval;                 # Silly example
sub new {
  my ($class, $days) = @_;
  bless { days => $days } => $class;
}

sub as_seconds { $_[0]{days} * 86400 }

1;
