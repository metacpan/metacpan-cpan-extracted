package t10;
use base qw(Class::AutoClass);
use autodbUtil;
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(id name auto_t10 dflt_t10);
@OTHER_ATTRIBUTES=qw(other_t10);
@CLASS_ATTRIBUTES=qw(class_t10);
%DEFAULTS=(dflt_t10=>'t10');
%SYNONYMS=(syn_t10=>'auto_t10');
%AUTODB=(collection=>t10,keys=>qq(id,name,id,name,auto_t10,dflt_t10,other_t10,class_t10,syn_t10));
Class::AutoClass::declare;

our @attr_groups=qw(auto other class syn dflt);
sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__;
  my $base=$class;
  push(@{$self->{init_self_history}},$base);
  my @base_attrs=@{$args->attrs};
  my @attrs;
  for my $group (@attr_groups) {
    push(@attrs,map {$group.'_'.$_} @base_attrs);
  }
  push(@{$self->{init_self_state}},[$self->get(@attrs)]);
  $self->name(ref $self);
  $self->id(id_next());
}
sub other_t10 {
  my $self=shift;
  @_? $self->{other_t10}=$_[0]: $self->{other_t10};
}
1;
package t11;
use base qw(Class::AutoClass);
use autodbUtil;

use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(id name auto_t11 dflt_t11);
@OTHER_ATTRIBUTES=qw(other_t11);
@CLASS_ATTRIBUTES=qw(class_t11);
%DEFAULTS=(dflt_t11=>'t11');
%SYNONYMS=(syn_t11=>'auto_t11');
%AUTODB=(collection=>t11,keys=>qq(id,name,id,name,auto_t11,dflt_t11,other_t11,class_t11,syn_t11));
Class::AutoClass::declare;

our @attr_groups=qw(auto other class syn dflt);
sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__;
  my $base=$class;
  push(@{$self->{init_self_history}},$base);
  my @base_attrs=@{$args->attrs};
  my @attrs;
  for my $group (@attr_groups) {
    push(@attrs,map {$group.'_'.$_} @base_attrs);
  }
  push(@{$self->{init_self_state}},[$self->get(@attrs)]);
  $self->name(ref $self);
  $self->id(id_next());
}
sub other_t11 {
  my $self=shift;
  @_? $self->{other_t11}=$_[0]: $self->{other_t11};
}
1;
package t2;
use base qw(t10 t11);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(auto_t2 dflt_t2);
@OTHER_ATTRIBUTES=qw(other_t2);
@CLASS_ATTRIBUTES=qw(class_t2);
%DEFAULTS=(dflt_t2=>'t2');
%SYNONYMS=(syn_t2=>'auto_t2');
%AUTODB=(collection=>t2,keys=>qq(id,name,id,name,auto_t2,dflt_t2,other_t2,class_t2,syn_t2));

Class::AutoClass::declare;

sub other_t2 {
  my $self=shift;
  @_? $self->{other_t2}=$_[0]: $self->{other_t2};
}
1;
package t3;
use base qw(t2);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(auto_t3 dflt_t3);
@OTHER_ATTRIBUTES=qw(other_t3);
@CLASS_ATTRIBUTES=qw(class_t3);
%DEFAULTS=(dflt_t3=>'t3');
%SYNONYMS=(syn_t3=>'auto_t3');
%AUTODB=(collection=>t3,keys=>qq(id,name,id,name,auto_t3,dflt_t3,other_t3,class_t3,syn_t3));
Class::AutoClass::declare;

sub other_t3 {
  my $self=shift;
  @_? $self->{other_t3}=$_[0]: $self->{other_t3};
}
1;
