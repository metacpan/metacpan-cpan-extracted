package d1;
use base qw(Class::AutoClass);
use autodbUtil;
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(id name auto_d1 dflt_d1);
@OTHER_ATTRIBUTES=qw(other_d1);
@CLASS_ATTRIBUTES=qw(class_d1);
%DEFAULTS=(dflt_d1=>'d1');
%SYNONYMS=(syn_d1=>'auto_d1');
%AUTODB=(collection=>d1,keys=>qq(id,name,id,name,auto_d1,dflt_d1,other_d1,class_d1,syn_d1));
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
sub other_d1 {
  my $self=shift;
  @_? $self->{other_d1}=$_[0]: $self->{other_d1};
}
1;
package d20;
use base qw(d1);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(auto_d20 dflt_d20);
@OTHER_ATTRIBUTES=qw(other_d20);
@CLASS_ATTRIBUTES=qw(class_d20);
%DEFAULTS=(dflt_d20=>'d20');
%SYNONYMS=(syn_d20=>'auto_d20');
%AUTODB=(collection=>d20,keys=>qq(id,name,id,name,auto_d20,dflt_d20,other_d20,class_d20,syn_d20));
Class::AutoClass::declare;

sub other_d20 {
  my $self=shift;
  @_? $self->{other_d20}=$_[0]: $self->{other_d20};
}
1;
package d21;
use base qw(d1);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(auto_d21 dflt_d21);
@OTHER_ATTRIBUTES=qw(other_d21);
@CLASS_ATTRIBUTES=qw(class_d21);
%DEFAULTS=(dflt_d21=>'d21');
%SYNONYMS=(syn_d21=>'auto_d21');
%AUTODB=(collection=>d21,keys=>qq(id,name,id,name,auto_d21,dflt_d21,other_d21,class_d21,syn_d21));
Class::AutoClass::declare;

sub other_d21 {
  my $self=shift;
  @_? $self->{other_d21}=$_[0]: $self->{other_d21};
}
1;
package d3;
use base qw(d20 d21);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(auto_d3 dflt_d3);
@OTHER_ATTRIBUTES=qw(other_d3);
@CLASS_ATTRIBUTES=qw(class_d3);
%DEFAULTS=(dflt_d3=>'d3');
%SYNONYMS=(syn_d3=>'auto_d3');
%AUTODB=(collection=>d3,keys=>qq(id,name,id,name,auto_d3,dflt_d3,other_d3,class_d3,syn_d3));
Class::AutoClass::declare;

sub other_d3 {
  my $self=shift;
  @_? $self->{other_d3}=$_[0]: $self->{other_d3};
}
1;
package d4;
use base qw(d3);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(auto_d4 dflt_d4);
@OTHER_ATTRIBUTES=qw(other_d4);
@CLASS_ATTRIBUTES=qw(class_d4);
%DEFAULTS=(dflt_d4=>'d4');
%SYNONYMS=(syn_d4=>'auto_d4');
%AUTODB=(collection=>d4,keys=>qq(id,name,id,name,auto_d4,dflt_d4,other_d4,class_d4,syn_d4));
Class::AutoClass::declare;

sub other_d4 {
  my $self=shift;
  @_? $self->{other_d4}=$_[0]: $self->{other_d4};
}
1;
package d50;
use base qw(d4);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(auto_d50 dflt_d50);
@OTHER_ATTRIBUTES=qw(other_d50);
@CLASS_ATTRIBUTES=qw(class_d50);
%DEFAULTS=(dflt_d50=>'d50');
%SYNONYMS=(syn_d50=>'auto_d50');
%AUTODB=(collection=>d50,keys=>qq(id,name,id,name,auto_d50,dflt_d50,other_d50,class_d50,syn_d50));
Class::AutoClass::declare;

sub other_d50 {
  my $self=shift;
  @_? $self->{other_d50}=$_[0]: $self->{other_d50};
}
1;
package d51;
use base qw(d4);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(auto_d51 dflt_d51);
@OTHER_ATTRIBUTES=qw(other_d51);
@CLASS_ATTRIBUTES=qw(class_d51);
%DEFAULTS=(dflt_d51=>'d51');
%SYNONYMS=(syn_d51=>'auto_d51');
%AUTODB=(collection=>d51,keys=>qq(id,name,id,name,auto_d51,dflt_d51,other_d51,class_d51,syn_d51));
Class::AutoClass::declare;

sub other_d51 {
  my $self=shift;
  @_? $self->{other_d51}=$_[0]: $self->{other_d51};
}
1;
package d6;
use base qw(d50 d51);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(auto_d6 dflt_d6);
@OTHER_ATTRIBUTES=qw(other_d6);
@CLASS_ATTRIBUTES=qw(class_d6);
%DEFAULTS=(dflt_d6=>'d6');
%SYNONYMS=(syn_d6=>'auto_d6');
%AUTODB=(collection=>d6,keys=>qq(id,name,id,name,auto_d6,dflt_d6,other_d6,class_d6,syn_d6));
Class::AutoClass::declare;

sub other_d6 {
  my $self=shift;
  @_? $self->{other_d6}=$_[0]: $self->{other_d6};
}
1;
package d7;
use base qw(d6);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(auto_d7 dflt_d7);
@OTHER_ATTRIBUTES=qw(other_d7);
@CLASS_ATTRIBUTES=qw(class_d7);
%DEFAULTS=(dflt_d7=>'d7');
%SYNONYMS=(syn_d7=>'auto_d7');
%AUTODB=(collection=>d7,keys=>qq(id,name,id,name,auto_d7,dflt_d7,other_d7,class_d7,syn_d7));
Class::AutoClass::declare;

sub other_d7 {
  my $self=shift;
  @_? $self->{other_d7}=$_[0]: $self->{other_d7};
}
1;
