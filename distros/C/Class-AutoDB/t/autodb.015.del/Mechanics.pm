package Mechanics;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
use autodbUtil;			# to get norm_counts
@AUTO_ATTRIBUTES=qw(id name
		    string_key integer_key float_key object_key
		    string_list integer_list float_list object_list);
%AUTODB=
  (collections=>
   {Mechanics=>
    qq(id integer, name string,
       string_key string, integer_key integer, float_key float, object_key object,
       string_list list(string), integer_list list(integer), float_list list(float), 
       object_list list(object))});
Class::AutoClass::declare;

# use same base values for all keys. list values are base values repeated list_count times
sub _init_self {
  my($self,$class,$args)=@_;
  my($num_objects,$list_count)=@$args{qw(num_objects list_count)};
#   $self->name("mechanics $num_objects+$list_count");
#   $self->id(id_next());
  # base values are fixed
  $self->string_key('string');
  $self->integer_key(123);
  $self->float_key(123.456);
  $self->object_key($self);
  # list values are base values x $list_count
  $self->string_list([($self->string_key)x$list_count]);
  $self->integer_list([($self->integer_key)x$list_count]);
  $self->float_list([($self->float_key)x$list_count]);
  $self->object_list([($self->object_key)x$list_count]);
}

sub correct_diffs {
  my($class,$list_count)=@_;
  my $correct_diffs=norm_counts
    {Mechanics=>1,
       map {'Mechanics_'.$_=>$list_count} 
	 qw(string_list integer_list float_list object_list)};

  # $correct_diffs;
}

1;
