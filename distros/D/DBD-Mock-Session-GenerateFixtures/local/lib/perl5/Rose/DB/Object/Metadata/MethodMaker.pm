package Rose::DB::Object::Metadata::MethodMaker;

use strict;

use Carp();

use Clone();
use Rose::Object::MakeMethods::Generic;

use Rose::DB::Object::Metadata::Object;
our @ISA = qw(Rose::DB::Object::Metadata::Object);

our $VERSION = '0.769';

#
# Class data
#

use Rose::Class::MakeMethods::Set
(
  inherited_set => 
  [
    'common_method_maker_argument_name',
    'default_auto_method_type',
  ],
);

#
# Object data
#

Rose::Object::MakeMethods::Generic->make_methods
(
  { preserve_existing => 1 },
  scalar => 
  [
    'name',
    __PACKAGE__->common_method_maker_argument_names,
  ],

  array =>
  [
    'auto_method_types' => { interface => 'get_set_init' },
    'add_auto_method_types' => 
    {
      interface   => 'push',
      init_method => 'init_auto_method_types',
      hash_key    => 'auto_method_types' ,
    },
  ],
);

*method_types     = \&auto_method_types;
*add_method_types = \&add_auto_method_types;

#
# Class methods
#

our %Method_Maker_Info;

OVERRIDE:
{
  my $orig_add_method = \&add_common_method_maker_argument_names;

  no warnings 'redefine';
  *add_common_method_maker_argument_names = sub
  {
    my($class) = shift;

    if(@_ && $Method_Maker_Info{$class})
    {      
      foreach my $type (keys %{$Method_Maker_Info{$class}})
      {
        push(@{$Method_Maker_Info{$class}{$type}{'args'}}, @_);
      }
    }

    $orig_add_method->($class, @_);
  };

  my $orig_delete_method = \&delete_common_method_maker_argument_names;

  *delete_common_method_maker_argument_names = sub
  {
    my($class) = shift;

    if(@_ && $Method_Maker_Info{$class})
    {      
      foreach my $type (keys %{$Method_Maker_Info{$class}})
      {
        delete @{$Method_Maker_Info{$class}{$type}{'args'}}{@_};
      }
    }

    $orig_delete_method->($class, @_);
  };
}

sub init_auto_method_types { shift->default_auto_method_types }

# This is basically a Rose::Class::MakeMethods::Set::inherited_set
# but it's keyed.  I'm only implementing a one-time superclass copy
# here, instead of the more involved "inherited_set" version where
# values can be permanently deleted or re-inherited.
sub init_method_maker_info
{
  my($class) = shift;

  my $info = $Method_Maker_Info{$class};

  unless($info && %$info)
  {
    my @parents = ($class);

    while(my $parent = shift(@parents))
    {
      no strict 'refs';
      foreach my $subclass (@{$parent . '::ISA'})
      {
        push(@parents, $subclass);

        next  unless($subclass->can('init_method_maker_info'));

        my $subclass_info = $subclass->init_method_maker_info;

        $info ||= $Method_Maker_Info{$class} ||= {};

        foreach my $type ($subclass->available_method_types)
        {
          next  unless($subclass_info->{$type});

          foreach my $attr (qw(class type interface))
          {
            next  if(!$subclass_info->{$type}{$attr} ||
                     defined $info->{$type}{$attr});  

            $info->{$type}{$attr} = Clone::clone($subclass_info->{$type}{$attr});
          }

          # Args come from an already-inherited set
          $info->{$type}{'args'} = [ $class->common_method_maker_argument_names ];
        }
      }
    }
  }

  return $info;
}

sub method_maker_info
{
  my($class) = shift;

  $class = ref $class  if(ref $class);

  while(@_)
  {
    my $type = shift;
    my $info = shift;

    Carp::confess "Method maker info must be passed in type/hashref pairs"
      unless(defined $type && ref $info && ref $info eq 'HASH');

    my $mm_info = $Method_Maker_Info{$class}{$type} ||= {};

    while(my($key, $value) = each(%$info))
    {
      $mm_info->{$key} = $value;
    }
  }

  $class->init_method_maker_info;
  return $Method_Maker_Info{$class};
}

sub add_method_maker_argument_names
{
  my($class) = shift;

  $class = ref $class  if(ref $class);

  while(@_)
  {
    my $type      = shift;
    my $new_names = shift;

    Carp::confess "Method maker argument names must be passed in type/arrayref pairs"
      unless(defined $type && ref $new_names && ref $new_names eq 'ARRAY');

    my $names = $class->method_maker_argument_names($type);

    push(@$names, @$new_names);
  }

  return;
}

sub method_maker_argument_names
{
  my($class, $type) = (shift, shift);

  Carp::confess "Missing required type argument"  unless(defined $type);

  $class = ref $class  if(ref $class);
  $class->init_method_maker_info;

  my $mm_info = $Method_Maker_Info{$class}{$type} ||= {};

  if(@_)
  {
    if(@_ == 1 && ref $_[0] && ref $_[0] eq 'ARRAY')
    {
      $mm_info->{'args'} = $_[0];
    }
    else
    {
      $mm_info->{'args'} = [ @_ ];
    }
  }

  unless(defined $mm_info->{'args'})
  {
    $mm_info->{'args'} = $class->common_method_maker_argument_names || [];
  }

  return wantarray ? @{$mm_info->{'args'}} :
                     $mm_info->{'args'};
}

sub method_maker_class
{
  my($class, $type) = (shift, shift);

  Carp::confess "Missing required type argument"  unless(defined $type);

  $class = ref $class  if(ref $class);

  $class->init_method_maker_info;

  if(@_)
  {
    return $Method_Maker_Info{$class}{$type}{'class'} = shift;
  }

  return $Method_Maker_Info{$class}{$type}{'class'};
}

sub method_maker_type
{
  my($class, $type) = (shift, shift);

  Carp::confess "Missing required type argument"  unless(defined $type);

  $class = ref $class  if(ref $class);
  $class->init_method_maker_info;

  if(@_)
  {
    return $Method_Maker_Info{$class}{$type}{'type'} = shift;
  }

  return $Method_Maker_Info{$class}{$type}{'type'};
}

sub available_method_types
{
  my($class) = shift;
  $class = ref $class  if(ref $class);

  if($Method_Maker_Info{$class} && %{$Method_Maker_Info{$class}})
  {
    return sort keys %{$Method_Maker_Info{$class} ||= {}};
  }

  return;
}

# sub default_method_name
# {
#   my($class, $type) = (shift, shift);
# 
#   Carp::confess "Missing required type argument"  unless(defined $type);
# 
#   $class = ref $class  if(ref $class);
#   
#   if(@_)
#   {
#     return $Method_Maker_Info{$class}{$type}{'name'} = shift;
#   }
# 
#   return $Method_Maker_Info{$class}{$type}{'name'} ||=
#     $class->build_method_name_for_type($type);
# }

#
# Object methods
#

sub hash_key { shift->name }

sub methods
{
  my($self) = shift;

  my %args = (@_ == 1) ? %{$_[0]} : @_;

  $self->add_auto_method_types(keys %args);

  while(my($type, $name) = each(%args))
  {
    $self->method_name($type => $name)  if(defined $name);
  }

  return;
}

sub method_name
{
  my($self, $type) = (shift, shift);

  Carp::confess "Missing required type argument"  unless(defined $type);

  if(@_)
  {
    return $self->{'method_name'}{$type} = shift;
  }

  return $self->{'method_name'}{$type};
}

sub method_uses_formatted_key 
{
  my($self, $type) = @_;
  return 0;
}

sub method_should_set
{
  my($self, $type, $args) = @_;

  return 1  if($type eq 'set');
  return 0  if($type eq 'get');

  # $args is a reference to the method args *including* the invocant
  return @$args > 1 ? 1 : 0;
}

sub build_method_name_for_type { Carp::confess "Override in subclass" }

sub defined_method_types
{
  my($self) = shift;

  my @types = sort keys %{$self->{'method_name'} ||= {}};
  return wantarray ? @types : \@types;
}

sub method_maker_arguments
{
  my($self, $type) = @_;

  my $class = ref $self;

  Carp::confess "Missing required type argument"  unless(defined $type);

  my %opts = map { $_ => scalar $self->$_() } grep { defined scalar $self->$_() }
     $class->method_maker_argument_names($type);

  # This is done by method_maker_argument_names() above
  #$class->init_method_maker_info;

  my $mm_info = $Method_Maker_Info{$class}{$type} ||= {};

  $opts{'interface'} = $mm_info->{'interface'}  if(exists $mm_info->{'interface'});

  return wantarray ? %opts : \%opts;
}

sub make_methods
{
  my($self, %args) = @_;

  my $options = $args{'options'} || {};

  if(exists $args{'preserve_existing'})
  {
    $options->{'preserve_existing'} = $args{'preserve_existing'};
  }

  if(exists $args{'replace_existing'})
  {
    if($options->{'preserve_existing'})
    {
      Carp::croak "Cannot specify true values for both the ",
                  "'replace_existing' and 'preserve_existing' ",
                  "options";
    }

    $options->{'override_existing'} = $args{'replace_existing'};
  }

  $options->{'target_class'} ||= $args{'target_class'} || (caller)[0];

  my $types = $args{'types'} || [ $self->auto_method_types ];

  foreach my $type (@$types)
  {
    my $method_maker_class = $self->method_maker_class($type)
      or Carp::croak "No method maker class defined for method type '$type'";

    my $method_maker_type = $self->method_maker_type($type)
      or Carp::croak "No method maker type defined for method type '$type'";

    my $method_name = $self->method_name($type)
      or Carp::croak "No method name defined for method type '$type'";

    if(Rose::DB::Object->can($method_name))
    {
      Carp::croak "Cannot create method '$method_name' in class ",
        "$options->{'target_class'} - Rose::DB::Object defines a ",
        "method with the same name";
    }

    $method_maker_class->make_methods(
      $options,
      $method_maker_type => 
      [
        $method_name => { $self->method_maker_arguments($type) }
      ]);

    $self->made_method_type($type => $method_name);

    if($self->can('method_code'))
    {
      $self->method_code($type => undef);
    }
  }

  return;
}

sub made_method_type { }
sub made_method_types { }

1;
