package Data::RuledValidator::Filter::X2;

sub x2{
  my($self, $v) = @_;
  $$v = 'x' x (length($$v) * 2);
}

1;

