package c1;
use base qw(Class::AutoClass);
use autodbUtil;
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(id name auto_c1 dflt_c1);
@OTHER_ATTRIBUTES=qw(other_c1);
@CLASS_ATTRIBUTES=qw(class_c1);
%DEFAULTS=(dflt_c1=>'c1');
%SYNONYMS=(syn_c1=>'auto_c1');
%AUTODB=(collection=>'c1',keys=>qq(id,name,auto_c1,dflt_c1,other_c1,class_c1,syn_c1));
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
sub other_c1 {
  my $self=shift;
  @_? $self->{other_c1}=$_[0]: $self->{other_c1};
}
1;
package c2;
use base qw(c1);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(auto_c2 dflt_c2);
@OTHER_ATTRIBUTES=qw(other_c2);
@CLASS_ATTRIBUTES=qw(class_c2);
%DEFAULTS=(dflt_c2=>'c2');
%SYNONYMS=(syn_c2=>'auto_c2');
%AUTODB=(collection=>'c2',keys=>qq(id,name,auto_c2,dflt_c2,other_c2,class_c2,syn_c2));
Class::AutoClass::declare;

sub other_c2 {
  my $self=shift;
  @_? $self->{other_c2}=$_[0]: $self->{other_c2};
}
1;
package c3;
use base qw(c2);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(auto_c3 dflt_c3);
@OTHER_ATTRIBUTES=qw(other_c3);
@CLASS_ATTRIBUTES=qw(class_c3);
%DEFAULTS=(dflt_c3=>'c3');
%SYNONYMS=(syn_c3=>'auto_c3');
%AUTODB=(collection=>'c3',keys=>qq(id,name,auto_c3,dflt_c3,other_c3,class_c3,syn_c3));
Class::AutoClass::declare;

sub other_c3 {
  my $self=shift;
  @_? $self->{other_c3}=$_[0]: $self->{other_c3};
}
1;
