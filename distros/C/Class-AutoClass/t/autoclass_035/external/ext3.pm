package autoclass_035::external::ext3;
 
# there is one ext class per layer. 
# probably better to have one per internal class, but that was too much work

sub new {
  my $class=shift;
  my $self=bless {},$class;
  push(@{$self->{ext_history}},'ext3');
  $self;
 }

1;
