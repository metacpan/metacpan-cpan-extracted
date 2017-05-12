package AllTypes;
use Scalar::Util qw(looks_like_number);
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name
		    string_key integer_key float_key object_key
		    string_list integer_list float_list object_list);
%AUTODB=
  (collections=>
   {AllTypes=>
    qq(string_key string, integer_key integer, float_key float, object_key object,
       string_list list(string), integer_list list(integer), float_list list(float), 
       object_list list(object)),
    HasName=>qq(id integer, name string)});
Class::AutoClass::declare;

use autodbUtil;			# to get norm_counts
sub correct_diffs {
  my $self=shift;
  my $correct_diffs=norm_counts
    {AllTypes=>1,HasName=>1,
       map {'AllTypes_'.$_=>scalar @{$self->$_}} 
	 qw(integer_list string_list float_list object_list)};

  # $correct_diffs;
}

# this method used by some (not all) tests
# base values are $i mod 2,3,5,inf (ie, last one is unique). ) converted to undef
sub init_base_mods {
  my($self,$i,@objects)=@_;
  # return unless $i>0;		# object 0 all undef
  $self->string_key(($i%2)? ('string '.($i%2)): undef);
  $self->integer_key($i%3 || undef);
  $self->float_key(($i%5)? ($i%5+(($i%5)/10)): undef);
  $self->object_key($i? $objects[$i]: undef);
#  $self->set(base_mods($i,@objects));
  $self;
}
# this method used by some (not all) tests
# list values are base values x $list_count
sub init_lists {
  my $self=shift;
  my $list_count=@_? shift: 3;
  $self->string_list([($self->string_key)x$list_count]);
  $self->integer_list([($self->integer_key)x$list_count]);
  $self->float_list([($self->float_key)x$list_count]);
  $self->object_list([($self->object_key)x$list_count]);
  $self;
}
# # function used in some tests
# sub base_mods {
#   my($i,@objects)=@_;
#   (string_key=>($i%2)? ('string '.($i%2)): undef,
#    integer_key=>$i%3 || undef,
#    float_key=>($i%5)? ($i%5+(($i%5)/10)): undef,
#    object_key=>$i? $objects[$i]: undef,);
# }

package Persistent;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name id);
%AUTODB=(collection=>'Persistent',keys=>qq(id integer, name string));
Class::AutoClass::declare;

sub correct_diffs {1};		# so 'put' loop will work

1;
