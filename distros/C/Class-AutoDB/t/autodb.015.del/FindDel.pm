############################################################
# used by 040 series which tests del while cursor active. 
# these tests vary 3 params
# 1) the items being deleted can start as objects or Oids
# 2) the active cursor can be 'open' or 'running' 
#    open means 'find' executed but no get or get_next
#    running means 'find' and 1 or more 'get_next', but cursor not exhausted
# 3) post-del, the cursor can be accessed via 'get' (ie, get all) or 'get_next'
#
# this file defines classes and collections for each case, and a 'holder'
# class that organizes them
############################################################
package FindDel;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %DEFAULTS %AUTODB);
use delUtil;			# to get id_next
@AUTO_ATTRIBUTES=qw(id name testcase case2objects num_objects);
%DEFAULTS=(testcase=>'top',case2objects=>{},num_objects=>5);
%AUTODB=(collection=>'FindDel',keys=>qq(id integer, name string, testcase string));
Class::AutoClass::declare;

# num_objects - number of objects per case. default 5
sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__;    # to prevent subclasses from re-running this
  my $case2objects=$self->case2objects;
  my $num_objects=$self->num_objects;
  for my $param1 (qw(obj oid)) {
    for my $param2 (qw(open running)) {
      for my $param3 (qw(get getnext)) {
	my $case=join('_',$param1,$param2,$param3);
	# my $class=__PACKAGE__."_$case";
	$case2objects->{$case}=
	  [map 
	   {new FindDel_case(name=>$case.'_'.sprintf('%02d',$_),id=>id_next(),testcase=>$case)}
	   (0..$num_objects-1)];
      }}}
}
# return self and all component objects
sub objects {
  my $self=shift;
  my @objects=($self,map {@$_} values %{$self->case2objects});
  wantarray? @objects: \@objects;
}

package FindDel_case;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name testcase);
%AUTODB=(collection=>'FindDel',keys=>qq(id integer, name string, testcase string));
Class::AutoClass::declare;

# package FindDel_obj_open_get;
# use base qw(FindDel_base);
# use vars qw(%AUTODB);
# %AUTODB=(collection=>__PACKAGE__,keys=>qq(id integer, name string));
# Class::AutoClass::declare;

# package FindDel_obj_open_getnext;
# use base qw(FindDel_base);
# use vars qw(%AUTODB);
# %AUTODB=(collection=>__PACKAGE__,keys=>qq(id integer, name string));
# Class::AutoClass::declare;

# package FindDel_obj_running_get;
# use base qw(FindDel_base);
# use vars qw(%AUTODB);
# %AUTODB=(collection=>__PACKAGE__,keys=>qq(id integer, name string));
# Class::AutoClass::declare;

# package FindDel_obj_running_getnext;
# use base qw(FindDel_base);
# use vars qw(%AUTODB);
# %AUTODB=(collection=>__PACKAGE__,keys=>qq(id integer, name string));
# Class::AutoClass::declare;

# package FindDel_oid_open_get;
# use base qw(FindDel_base);
# use vars qw(%AUTODB);
# %AUTODB=(collection=>__PACKAGE__,keys=>qq(id integer, name string));
# Class::AutoClass::declare;

# package FindDel_oid_open_getnext;
# use base qw(FindDel_base);
# use vars qw(%AUTODB);
# %AUTODB=(collection=>__PACKAGE__,keys=>qq(id integer, name string));
# Class::AutoClass::declare;

# package FindDel_oid_running_get;
# use base qw(FindDel_base);
# use vars qw(%AUTODB);
# %AUTODB=(collection=>__PACKAGE__,keys=>qq(id integer, name string));
# Class::AutoClass::declare;

# package FindDel_oid_running_getnext;
# use base qw(FindDel_base);
# use vars qw(%AUTODB);
# %AUTODB=(collection=>__PACKAGE__,keys=>qq(id integer, name string));
# Class::AutoClass::declare;

1;
