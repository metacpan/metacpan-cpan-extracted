package autoclass_039::ragged::r1;
use base qw(Class::AutoClass);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(auto_r1 dflt_r1);
@OTHER_ATTRIBUTES=qw(other_r1);
@CLASS_ATTRIBUTES=qw(class_r1);
%DEFAULTS=(dflt_r1=>'r1');
%SYNONYMS=(syn_r1=>'auto_r1');
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
sub other_r1 {
  my $self=shift;
  @_? $self->{other_r1}=$_[0]: $self->{other_r1};
}
1;
