package MadeUp::Class::WeirdConstructor;
sub foo { shift->{foo} }

sub makeme {
  my $class = shift;
  bless shift, $class;
}
1;
