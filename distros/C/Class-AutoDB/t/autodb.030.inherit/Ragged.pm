package r1;
use base qw(Class::AutoClass);
use autodbUtil;
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(id name auto_r1 dflt_r1);
@OTHER_ATTRIBUTES=qw(other_r1);
@CLASS_ATTRIBUTES=qw(class_r1);
%DEFAULTS=(dflt_r1=>'r1');
%SYNONYMS=(syn_r1=>'auto_r1');
%AUTODB=(collection=>r1,keys=>qq(id,name,id,name,auto_r1,dflt_r1,other_r1,class_r1,syn_r1));
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
sub other_r1 {
  my $self=shift;
  @_? $self->{other_r1}=$_[0]: $self->{other_r1};
}
1;
package r20;
use base qw(r1);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(auto_r20 dflt_r20);
@OTHER_ATTRIBUTES=qw(other_r20);
@CLASS_ATTRIBUTES=qw(class_r20);
%DEFAULTS=(dflt_r20=>'r20');
%SYNONYMS=(syn_r20=>'auto_r20');
%AUTODB=(collection=>r20,keys=>qq(id,name,id,name,auto_r20,dflt_r20,other_r20,class_r20,syn_r20));
Class::AutoClass::declare;

sub other_r20 {
  my $self=shift;
  @_? $self->{other_r20}=$_[0]: $self->{other_r20};
}
1;
package r21;
use base qw(r1);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(auto_r21 dflt_r21);
@OTHER_ATTRIBUTES=qw(other_r21);
@CLASS_ATTRIBUTES=qw(class_r21);
%DEFAULTS=(dflt_r21=>'r21');
%SYNONYMS=(syn_r21=>'auto_r21');
%AUTODB=(collection=>r21,keys=>qq(id,name,id,name,auto_r21,dflt_r21,other_r21,class_r21,syn_r21));
Class::AutoClass::declare;

sub other_r21 {
  my $self=shift;
  @_? $self->{other_r21}=$_[0]: $self->{other_r21};
}
1;
package r22;
use base qw(r1);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(auto_r22 dflt_r22);
@OTHER_ATTRIBUTES=qw(other_r22);
@CLASS_ATTRIBUTES=qw(class_r22);
%DEFAULTS=(dflt_r22=>'r22');
%SYNONYMS=(syn_r22=>'auto_r22');
%AUTODB=(collection=>r22,keys=>qq(id,name,id,name,auto_r22,dflt_r22,other_r22,class_r22,syn_r22));
Class::AutoClass::declare;

sub other_r22 {
  my $self=shift;
  @_? $self->{other_r22}=$_[0]: $self->{other_r22};
}
1;
package r30;
use base qw(r20);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(auto_r30 dflt_r30);
@OTHER_ATTRIBUTES=qw(other_r30);
@CLASS_ATTRIBUTES=qw(class_r30);
%DEFAULTS=(dflt_r30=>'r30');
%SYNONYMS=(syn_r30=>'auto_r30');
%AUTODB=(collection=>r30,keys=>qq(id,name,id,name,auto_r30,dflt_r30,other_r30,class_r30,syn_r30));
Class::AutoClass::declare;

sub other_r30 {
  my $self=shift;
  @_? $self->{other_r30}=$_[0]: $self->{other_r30};
}
1;
package r31;
use base qw(r21);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(auto_r31 dflt_r31);
@OTHER_ATTRIBUTES=qw(other_r31);
@CLASS_ATTRIBUTES=qw(class_r31);
%DEFAULTS=(dflt_r31=>'r31');
%SYNONYMS=(syn_r31=>'auto_r31');
%AUTODB=(collection=>r31,keys=>qq(id,name,id,name,auto_r31,dflt_r31,other_r31,class_r31,syn_r31));
Class::AutoClass::declare;

sub other_r31 {
  my $self=shift;
  @_? $self->{other_r31}=$_[0]: $self->{other_r31};
}
1;
package r32;
use base qw(r22);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(auto_r32 dflt_r32);
@OTHER_ATTRIBUTES=qw(other_r32);
@CLASS_ATTRIBUTES=qw(class_r32);
%DEFAULTS=(dflt_r32=>'r32');
%SYNONYMS=(syn_r32=>'auto_r32');
%AUTODB=(collection=>r32,keys=>qq(id,name,id,name,auto_r32,dflt_r32,other_r32,class_r32,syn_r32));
Class::AutoClass::declare;

sub other_r32 {
  my $self=shift;
  @_? $self->{other_r32}=$_[0]: $self->{other_r32};
}
1;
package r4;
use base qw(r20 r21 r22 r30 r31 r32);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(auto_r4 dflt_r4);
@OTHER_ATTRIBUTES=qw(other_r4);
@CLASS_ATTRIBUTES=qw(class_r4);
%DEFAULTS=(dflt_r4=>'r4');
%SYNONYMS=(syn_r4=>'auto_r4');
%AUTODB=(collection=>r4,keys=>qq(id,name,id,name,auto_r4,dflt_r4,other_r4,class_r4,syn_r4));
Class::AutoClass::declare;

sub other_r4 {
  my $self=shift;
  @_? $self->{other_r4}=$_[0]: $self->{other_r4};
}
1;
package r5;
use base qw(r1 r20 r4);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(auto_r5 dflt_r5);
@OTHER_ATTRIBUTES=qw(other_r5);
@CLASS_ATTRIBUTES=qw(class_r5);
%DEFAULTS=(dflt_r5=>'r5');
%SYNONYMS=(syn_r5=>'auto_r5');
%AUTODB=(collection=>r5,keys=>qq(id,name,id,name,auto_r5,dflt_r5,other_r5,class_r5,syn_r5));
Class::AutoClass::declare;

sub other_r5 {
  my $self=shift;
  @_? $self->{other_r5}=$_[0]: $self->{other_r5};
}
1;
