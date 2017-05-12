package autoclass_039::trio::t11;
use base qw(Class::AutoClass);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(auto_t11 dflt_t11);
@OTHER_ATTRIBUTES=qw(other_t11);
@CLASS_ATTRIBUTES=qw(class_t11);
%DEFAULTS=(dflt_t11=>'t11');
%SYNONYMS=(syn_t11=>'auto_t11');
Class::AutoClass::declare;

our @attr_groups=qw(auto other class syn dflt);
sub _init_self {
  my($self,$class,$args)=@_;
  my($base)=$class=~/::(\w+)$/;
  push(@{$self->{init_self_history}},$base);
  my @base_attrs=@{$args->attrs};
  my @attrs;
  for my $group (@attr_groups) {
    push(@attrs,map {$group.'_'.$_} @base_attrs);
  }
  push(@{$self->{init_self_state}},[$self->get(@attrs)]);
}
sub other_t11 {
  my $self=shift;
  @_? $self->{other_t11}=$_[0]: $self->{other_t11};
}
1;
