package Data::RuledValidator::Filter::X;

sub x{
  my($self, $v) = @_;
  # warn join "-", caller;
  $$v = ('x' x length($$v));
}

1;

