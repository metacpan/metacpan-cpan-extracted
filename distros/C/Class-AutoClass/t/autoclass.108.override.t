use strict;
use Test::More;
use Test::Deep;

# this is a regression test covering a bug wherein __OVERRIDE__
# doesn't work in base classes.
# setting __OVERRIDE__ causes Class::AutoClass::new to return the
# desired thing, but subsequent calls to _init_self continue to
# operate on original $self !
# sigh!  how did this survive so long??

my $old_self={iam=>'old self'};

package Parent;
use base qw(Class::AutoClass);
Class::AutoClass::declare;
sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  $self=$self->{__OVERRIDE__}=bless($old_self,ref $self); # return old
  $self->{iam}=__PACKAGE__;
  my $log=$self->{log}=[];
  push(@$log,__PACKAGE__);
}
package Child;
use base qw(Parent);
Class::AutoClass::declare;
sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  $self->{iam}=__PACKAGE__;
  my $log=$self->{log}||($self->{log}=[]);
  push(@$log,__PACKAGE__);
}

package main;
my $parent=new Parent;
is($parent,$old_self,'parent is old_self');
cmp_deeply($parent,bless({iam=>'Parent',log=>['Parent']},'Parent'),'parent content');
my $child=new Child;
is($child,$old_self,'child is old_self');
cmp_deeply($child,bless({iam=>'Child',log=>['Parent','Child']},'Child'),'child content');

done_testing();


