package autoclass_034::external::ext;
 
sub new {
  my $class=shift;
  my $self=bless {},$class;
  push(@{$self->{ext_history}},'ext');
  $self;
 }

1;
