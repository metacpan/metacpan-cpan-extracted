package Rose::DB::Object::Metadata::Column;

use strict;

use Carp();
use Scalar::Util();

use Rose::DB::Object::Metadata::Util qw(:all);

use Rose::DB::Object::Metadata::MethodMaker;
our @ISA = qw(Rose::DB::Object::Metadata::MethodMaker);

use Rose::DB::Object::Util 
  qw(column_value_formatted_key column_value_is_inflated_key
    lazy_column_values_loaded_key);

use Rose::DB::Object::Constants 
  qw(STATE_IN_DB STATE_LOADING STATE_SAVING SAVING_FOR_LOAD);

use Rose::Object::MakeMethods::Generic;
use Rose::DB::Object::MakeMethods::Generic;

our $Triggers_Key      = 'triggers';
our $Trigger_Index_Key = 'trigger_index';

our $VERSION = '0.791';

use overload
(
  '""' => sub { shift->name },
   fallback => 1,
);

__PACKAGE__->add_default_auto_method_types('get_set');

__PACKAGE__->add_common_method_maker_argument_names(qw(column default type db_type hash_key smart_modification undef_overrides_default));

use Rose::Class::MakeMethods::Generic
(
  inheritable_scalar =>
  [
    'default_undef_overrides_default'
  ],

  inheritable_hash =>
  [
    event_method_type  => { hash_key => 'event_method_types' },
    event_method_types => { interface => 'get_set_all' },
    delete_event_method_type => { interface => 'delete', hash_key => 'event_method_types' },
  ],
);

__PACKAGE__->event_method_types
(
  inflate   => [ qw(get_set get) ],
  deflate   => [ qw(get_set get) ],
  on_load   => [ qw(get_set set) ],
  on_save   => [ qw(get_set get) ],
  on_set    => [ qw(get_set set) ],
  on_get    => [ qw(get_set get) ],
  lazy_load => [ qw(get_set get) ],
);

Rose::Object::MakeMethods::Generic->make_methods
(
  { preserve_existing => 1 },
  boolean => 
  [
    'manager_uses_method',
    'is_primary_key_member',
    'not_null',
    'triggers_disabled',
    'smart_modification',
    'nonpersistent',
  ],

  scalar => 
  [
    'alias',
    'error',
    'ordinal_position',
    'parse_error',
    'remarks',
    __PACKAGE__->common_method_maker_argument_names,
  ],
);

*sequence    = \&default_value_sequence_name;
*primary_key = \&is_primary_key_member;

__PACKAGE__->method_maker_info
(
  get_set => 
  {
    class => 'Rose::DB::Object::MakeMethods::Generic',
    type  => 'scalar',
  },

  get =>
  {
    class => 'Rose::DB::Object::MakeMethods::Generic',
    type  => 'scalar',
  },

  set =>
  {
    class => 'Rose::DB::Object::MakeMethods::Generic',
    type  => 'scalar',
  },
);

sub undef_overrides_default
{
  my($self) = shift;

  if(@_)
  {
    return $self->{'undef_overrides_default'} = $_[0] ? 1 : 0;
  }

  return $self->{'undef_overrides_default'}
    if(defined $self->{'undef_overrides_default'});

  my $parent_default = $self->parent ? $self->parent->column_undef_overrides_default : undef;

  return defined $parent_default ? $parent_default :  ref($self)->default_undef_overrides_default;
}

sub validate_specification
{
  my($self) = shift;

  if($self->not_null && $self->{'undef_overrides_default'})
  {
    $self->error('True value for not_null attribute conflicts with true value for undef_overrides_default attribute.');
    return 0;
  }

  return 1;
}

use constant ANY_DB => "\0ANY_DB\0";

sub default_value_sequence_name
{
  my($self) = shift;

  my $db;
  $db = shift  if(UNIVERSAL::isa($_[0], 'Rose::DB'));
  my $parent = $self->parent;
  my ($db_id, $error);

  # Sometimes data source are not set up yet when this method
  # is called.  Allow for failure, falling back to ANY_DB
  TRY:
  {
    local $@;
    eval { $db_id = $db ? $db->id : $parent ? $parent->init_db_id : ANY_DB };
    $error = $@;
  }

  $db_id = ANY_DB if ($error);

  return $self->{'default_value_sequence_name'}{$db_id}  unless(@_);

  $self->{'default_value_sequence_name'}{$db_id} = shift;

  if($parent && $self->is_primary_key_member)
  {
    $parent->refresh_primary_key_sequence_names($db || $db_id);
  }

  return $self->{'default_value_sequence_name'}{$db_id};
}

# These methods rely on knowledge of the hash key used to make the
# methods for the common_method_maker_argument_names in the base
# class, Rose::DB::Object::Metadata::MethodMaker.  Luckily, it's just
# the attribute name by default.
sub default_exists { exists $_[0]->{'default'} }
sub delete_default { delete $_[0]->{'default'} }

sub db_value_hash_key
{
  my($self) = shift;

  my $type = $self->method_name('set') ? 'set' : 'get_set';

  if($self->method_uses_formatted_key($type))
  {
    return column_value_formatted_key($self->hash_key);
  }

  return $self->hash_key;
}

sub available_method_types
{
  my($class) = shift;

  my @types = $class->SUPER::available_method_types;

  @types = qw(get_set get set)  unless(@types);

  return @types;
}

sub accessor_method_name
{
  return $_[0]->{'accessor_method_name'} ||= 
    $_[0]->method_name('get') || $_[0]->method_name('get_set')
}

sub mutator_method_name
{
  return $_[0]->{'mutator_method_name'} ||= 
    $_[0]->method_name('set') || $_[0]->method_name('get_set')
}

sub rw_method_name
{
  return $_[0]->{'rw_method_name'} ||= $_[0]->method_name('get_set')
}

sub build_method_name_for_type
{
  my($self, $type) = @_;

  my $name = $self->alias || $self->name;
  $name =~ s/\W/_/g;

  if($type eq 'get_set')
  {
    return $name
  }
  elsif($type eq 'set')
  {
    return "set_$name";
  }
  elsif($type eq 'get')
  {
    return "get_$name";
  }

  return undef;
}

sub made_method_type
{
  my($self, $type, $name) = @_;

  if($type eq 'get_set')
  {
    $self->{'accessor_method_name'} = $name;  
    $self->{'mutator_method_name'}  = $name;
    $self->{'rw_method_name'}       = $name;
  }  
  elsif($type eq 'get')
  {
    $self->{'accessor_method_name'} = $name;
  }
  elsif($type eq 'set')
  {
    $self->{'mutator_method_name'} = $name;
  }

  $self->{'made_method_types'}{$type} = 1;
}

sub defined_method_types
{
  my($self) = shift;
  my @types = sort keys %{$self->{'made_method_types'} ||= {}};
  return wantarray ? @types : \@types;
}

sub method_maker_arguments
{
  my($self, $type) = @_;

  my $args = $self->SUPER::method_maker_arguments($type);

  $args->{'interface'} ||= $type;

  return wantarray ? %$args : $args;
}

sub type   { 'scalar' }
sub column { $_[0] }

sub should_inline_value { 0 }
sub inline_value_sql { $_[1] }

sub name
{
  my($self) = shift;

  if(@_)
  {
    $self->name_sql(undef);
    $self->select_sql(undef);
    return $self->{'name'} = shift;
  }

  return $self->{'name'};
}

sub hash_key { $_[0]->alias || $_[0]->name }

sub name_sql
{
  my($self) = shift;

  if(my $db = shift)
  {
    return $self->{'name_sql'}{$db->{'driver'}} ||= $db->auto_quote_column_name($self->{'name'});
  }
  else
  {
    return $self->{'name'};
  }
}

# XXX: Still need a way to format `table`.`column`
sub select_sql
{
  my($self, $db, $table) = @_;

  if($db)
  {
    if(defined $table)
    {
      $db->auto_quote_column_with_table($self->{'name'}, $table);
    }
    else
    {
      return $self->{'select_sql'}{$db->{'driver'}} ||= $db->auto_quote_column_name($self->{'name'});
    }
  }
  else
  {
    return $self->{'name'};
  }
}

sub insert_placeholder_sql { '?' }
sub update_placeholder_sql { '?' }
sub query_placeholder_sql  { '?' }

# sub dbi_data_type { () }

sub parse_value  { $_[2] }
sub format_value { $_[2] }

sub primary_key_position
{
  my($self) = shift;

  $self->{'primary_key_position'} = shift  if(@_);

  unless($self->is_primary_key_member)
  {
    return $self->{'primary_key_position'} = undef;
  }

  return $self->{'primary_key_position'};
}

# These constants are from the DBI documentation.  Is there somewhere 
# I can load these from?
use constant SQL_NO_NULLS => 0;
use constant SQL_NULLABLE => 1;

sub init_with_dbi_column_info
{
  my($self, $col_info) = @_;

  # We're doing this in Rose::DB::Object::Metadata::Auto now
  #$self->parent->db->refine_dbi_column_info($col_info);

  if(defined $col_info->{'COLUMN_DEF'})
  {
    $self->default($col_info->{'COLUMN_DEF'});
  }

  if($col_info->{'NULLABLE'} == SQL_NO_NULLS)
  {
    $self->not_null(1);
  }
  elsif($col_info->{'NULLABLE'} == SQL_NULLABLE)
  {
    $self->not_null(0);
  }

  # DB-native type, if applicable
  if(my $db_type = $col_info->{'RDBO_DB_TYPE'})
  {
    $self->db_type($db_type);
  }

  if($col_info->{'REMARKS'})
  {
    $self->remarks($col_info->{'REMARKS'});
  }

  $self->ordinal_position($col_info->{'ORDINAL_POSITION'} || 0);

  $self->default_value_sequence_name($col_info->{'rdbo_default_value_sequence_name'});

  return;
}

sub perl_column_definition_attributes
{
  my($self) = shift;

  my @attrs;

  ATTR: foreach my $attr ('type', sort keys %$self)
  {
    if($attr =~ /^(?: name(?:_sql)? | is_primary_key_member | 
                  primary_key_position | method_name | method_code |
                  made_method_types | ordinal_position | select_sql |
                  undef_overrides_default | (?:builtin_)?triggers | 
                  (?:builtin_)?trigger_index )$/x)
    {
      next ATTR;
    }

    my $val = $self->can($attr) ? $self->$attr() : next ATTR;

    no warnings 'uninitialized';
    if(($attr eq 'check_in' || $attr eq 'values') &&
       ref $val && ref $val eq 'ARRAY')
    {
      if($self->type eq 'set')
      {
        $val = perl_arrayref(array => $val, inline => 1);
        $attr = 'values';      
      }
      else
      {
        $val = perl_arrayref(array => $val, inline => 1);
        $attr = 'check_in';
      }
    }
    elsif($attr eq 'smart_modification' && 
          (($self->smart_modification == ref($self)->new->smart_modification) ||
           ($self->parent && $self->smart_modification == $self->parent->default_smart_modification)))
    {
      next ATTR;
    }
    elsif($attr eq 'undef_overrides_default' && 
          (($self->undef_overrides_default == ref($self)->new->undef_overrides_default) ||
           ($self->parent && $self->undef_overrides_default == $self->parent->column_undef_overrides_default)))
    {
      next ATTR;
    }
    elsif(!defined $val || ref $val || ($attr eq 'not_null' && !$self->not_null))
    {
      next ATTR;
    }

    if($attr eq 'alias' && (!defined $val || $val eq $self->name))
    {
      next ATTR;
    }

    if($attr eq 'overflow' && $val eq $self->init_overflow)
    {
      next ATTR;
    }

    # Use shorter "sequence" hash key name for this attr
    if($attr eq 'default_value_sequence_name')
    {
      # Only list an explicit sequence for serial columns if the sequence
      # name differs from the default auto-generated sequence name.
      if($self->type =~ /^(?:big)?serial$/)
      {
        my $seq = $self->default_value_sequence_name;

        my $meta = $self->parent;
        my $db   = $meta->db;

        my $auto_seq = $db->auto_sequence_name(table  => $meta->table,
                                               column => $self);

        # Use schema prefix on auto-generated name if necessary
        if($seq =~ /^[^.]+\./)
        {
          my $schema = $meta->select_schema($db);
          $auto_seq = "$schema.$auto_seq"  if($schema);
        }

        no warnings 'uninitialized';
        if(lc $seq ne lc $auto_seq)
        {
          push(@attrs, 'sequence');
        }
      }
      else
      {
        push(@attrs, 'sequence');
      }

      next;
    }

    if($attr =~ /_method_name$/)
    {
      my $method = $self->$attr();

      my $skip = 1;

      foreach my $type ($self->auto_method_types)
      {
        $skip = 0  if($method ne $self->build_method_name_for_type($type));
      }

      next ATTR  if($skip);
    }

    push(@attrs, $attr);
  }

  return @attrs;
}

sub perl_hash_definition
{
  my($self, %args) = @_;

  my $meta = $self->parent;

  my $name_padding = $args{'name_padding'};

  my $indent = defined $args{'indent'} ? $args{'indent'} : 
                 ($meta ? $meta->default_perl_indent : undef);

  my $inline = defined $args{'inline'} ? $args{'inline'} : 1;

  my %hash;

  foreach my $attr ($self->perl_column_definition_attributes)
  {
    $hash{$attr} = $self->$attr();
  }

  if(defined $name_padding && $name_padding > 0)
  {
    return sprintf('%-*s => ', $name_padding, perl_quote_key($self->name)) .
           perl_hashref(hash      => \%hash, 
                        inline    => $inline, 
                        indent    => $indent, 
                        sort_keys => \&_sort_keys);
  }
  else
  {
    return perl_quote_key($self->name) . ' => ' .
           perl_hashref(hash      => \%hash, 
                        inline    => $inline, 
                        indent    => $indent, 
                        sort_keys => \&_sort_keys);
  }
}

sub _sort_keys 
{
  if($_[0] eq 'type')
  {
    return -1;
  }
  elsif($_[1] eq 'type')
  {
    return 1;
  }

  return lc $_[0] cmp lc $_[1];
}

sub lazy
{
  my($self) = shift;

  return $self->{'lazy'}  unless(@_);

  if($_[0])
  {
    if($self->is_primary_key_member)
    {
      Carp::croak "The column '", $self->name, "' cannot be loaded on demand ",
                  "because it's part of the primary key";
    }

    $self->{'lazy'} = 1;
    $self->add_builtin_trigger(event => 'lazy_load',
                               name  => 'load_on_demand',
                               code  => $self->load_on_demand_on_get_code);

    $self->add_builtin_trigger(event => 'on_load',
                               name  => 'load_on_demand',
                               code  => $self->load_on_demand_on_set_code);

    $self->add_builtin_trigger(event => 'on_set',
                               name  => 'load_on_demand',
                               code  => $self->load_on_demand_on_set_code);
  }
  else
  {
    $self->{'lazy'} = 0;
    $self->delete_builtin_trigger(event => 'on_get',
                                  name  => 'load_on_demand');

    $self->delete_builtin_trigger(event => 'on_load',
                                  name  => 'load_on_demand');

    $self->delete_builtin_trigger(event => 'on_set',
                                  name  => 'load_on_demand');
  }

  if(my $meta = $self->parent)
  {
    $meta->refresh_lazy_column_tracking;
  }

  return $self->{'lazy'};
}

*is_lazy        = \&lazy;
*load_on_demand = \&lazy;

use constant LAZY_LOADED_KEY => lazy_column_values_loaded_key();

sub load_on_demand_on_get_code
{
  my($column) = shift;

  my($name, $mutator);

  return sub
  {
    my($self) = shift;

    $name ||= $column->name;
    return  if(!$self->{STATE_IN_DB()} || $self->{LAZY_LOADED_KEY()}{$name});

    $mutator ||= $column->mutator_method_name;
    $self->$mutator($self->meta->get_column_value($self, $column));

    $self->{LAZY_LOADED_KEY()}{$name} = 1;
  };
}

sub load_on_demand_on_set_code
{
  my($column) = shift;

  my $name;

  return sub
  {
    my($self) = shift;
    $name ||= $column->name;
    $self->{LAZY_LOADED_KEY()}{$name} = 1;
  };
}

our %Trigger_Events =
(
  inflate   => 1,
  deflate   => 1,
  on_load   => 1,
  on_save   => 1,
  on_set    => 1,
  on_get    => 1,
  lazy_load => 1,
);

sub trigger_events { keys %Trigger_Events }
sub trigger_event_exists { exists $Trigger_Events{$_[1]} }

sub builtin_triggers
{
  # So evil...
  local $Triggers_Key = 'builtin_triggers';
  shift->triggers(@_);
}

sub triggers
{
  my($self, $event) = (shift, shift);

  Carp::croak "Invalid event: $event"  
    unless($self->trigger_event_exists($event));

  if(@_)
  {
    my $codes = (@_ > 1) ? [ @_ ] : $_[0];

    unless(ref $codes eq 'ARRAY')
    {
      Carp::croak "Expected code reference or a reference to an array ",
                  "of code references, but got: $codes";
    }

    foreach my $code (@$codes)
    {
      unless((ref($code) || '') eq 'CODE')
      {
        Carp::croak "Not a code reference: $code";
      }
    }

    $self->{$Triggers_Key}{$event} = @$codes ? $codes : undef;
    $self->reapply_triggers($event);
    return;
  }

  return $self->{$Triggers_Key}{$event};
}

sub delete_builtin_triggers
{
  # So evil...
  local $Triggers_Key      = 'builtin_triggers';
  local $Trigger_Index_Key = 'builtin_trigger_index';
  shift->delete_triggers(@_);
}

sub delete_triggers
{
  my($self, $event) = @_;

  my @events = $event ? $event : $self->trigger_events;

  foreach my $event (@events)
  {
    Carp::croak "Invalid event: $event" 
      unless($self->trigger_event_exists($event));

    $self->{$Triggers_Key}{$event} = undef;
    $self->{$Trigger_Index_Key}{$event} = undef;
  }

  return;
}

sub disable_triggers { shift->triggers_disabled(1) }
sub enable_triggers  { shift->triggers_disabled(0) }

sub add_builtin_trigger
{
  my($self, %args) = @_;

  if(@_ == 3 && $self->trigger_event_exists($_[1]))
  {
    my $event = $_[1];
    my $code  = $_[2];

    return $self->add_trigger(event => $event, 
                              code  => $code, 
                              builtin => 1);
  }

  return $self->add_trigger(%args, builtin => 1);
}

sub add_trigger
{
  my($self, %args) = @_;

  my($event, $position, $code, $name);

  if(@_ == 3 && $self->trigger_event_exists($_[1]))
  {
    $event = $_[1];
    $code  = $_[2];
  }
  else
  {
    $event = $args{'event'};
    $code  = $args{'code'};
  }

  $name     = $args{'name'} || $self->generate_trigger_name;
  $position = $args{'position'} || 'end';

  my $builtin = $args{'builtin'} || 0;
  my $builtin_prefix = $builtin ? 'builtin_' : '';

  Carp::croak "Invalid event: '$event'"  
    unless($self->trigger_event_exists($event));

  unless((ref($code) || '') eq 'CODE')
  {
    Carp::croak "Not a code reference: $code";
  }

  if($position =~ /^(?:end|last|push)$/)
  {
    push(@{$self->{$builtin_prefix . 'triggers'}{$event}}, $code);

    if($builtin)
    {
      $self->builtin_trigger_index($event, $name, $#{$self->{'builtin_triggers'}{$event}});
    }
    else
    {
      $self->trigger_index($event, $name, $#{$self->{'triggers'}{$event}});
    }
  }
  elsif($position =~ /^(?:start|first|unshift)$/)
  {
    unshift(@{$self->{$builtin_prefix . 'triggers'}{$event}}, $code);

    # Shift all the other trigger positions
    my $indexes = $builtin? $self->builtin_trigger_indexes($event) :
                            $self->trigger_indexes($event);

    foreach my $name (keys(%$indexes))
    {
      $indexes->{$name}++;
    }

    # Set new position
    if($builtin)
    {
      $self->builtin_trigger_index($event, $name, 0);
    }
    else
    {
      $self->trigger_index($event, $name, 0);
    }
  }
  else { Carp::croak "Invalid trigger position: '$position'" }

  $self->reapply_triggers($event);
  return;
}

my $Trigger_Num = 0;

sub generate_trigger_name { "dyntrig_${$}_" . ++$Trigger_Num }

sub trigger_indexes { $_[0]->{'trigger_index'}{$_[1]} || {} }
sub builtin_trigger_indexes { $_[0]->{'builtin_trigger_index'}{$_[1]} || {} }

sub trigger_index
{
  my($self, $event, $name) = (shift, shift, shift);

  if(@_)
  {
    return $self->{'trigger_index'}{$event}{$name} = shift;
  }

  return $self->{'trigger_index'}{$event}{$name};
}

sub builtin_trigger_index
{
  my($self, $event, $name) = (shift, shift, shift);

  if(@_)
  {
    return $self->{'builtin_trigger_index'}{$event}{$name} = shift;
  }

  return $self->{'builtin_trigger_index'}{$event}{$name};
}

sub delete_builtin_trigger { shift->delete_trigger(@_, builtin => 1) }

sub delete_trigger
{
  my($self, %args) = @_;

  my $name  = $args{'name'} or Carp::croak "Missing name parameter";
  my $event = $args{'event'};
  my $builtin = $args{'builtin'} || 0;

  my $builtin_text   = $builtin ? ' builtin' : '';
  my $builtin_prefix = $builtin ? 'builtin_' : '';

  Carp::croak "Invalid event: '$event'"  
    unless($self->trigger_event_exists($event));

  my $index = $builtin ? $self->builtin_trigger_index($event, $name) :
                         $self->trigger_index($event, $name);

  unless(defined $index)
  {
    Carp::croak "No$builtin_text trigger named '$name' for event '$event'";
  }

  my $triggers = $self->{$builtin_prefix . 'triggers'}{$event};

  # Remove the trigger
  splice(@$triggers, $index, 1);

  my $indexes = $builtin? $self->builtin_trigger_indexes($event) :
                          $self->trigger_indexes($event);

  # Remove its index
  delete $indexes->{$name};

  # Shift all trigger indexes greater than $index
  foreach my $name (keys(%$indexes))
  {
    $indexes->{$name}--  if($indexes->{$name} > $index);
  }

  $self->reapply_triggers($event);
}

sub apply_triggers
{
  my($self, $event) = @_;

  my $method_types;

  if(defined $event)
  {
    $method_types = $self->event_method_type($event) 
      or Carp::croak "Invalid event: '$event'";

    my %defined = map { $_ => 1 } $self->defined_method_types;

    $method_types = [ grep { $defined{$_} } @$method_types ];
  }
  else
  {
    $method_types =  $self->defined_method_types;
  }

  foreach my $method_type (@$method_types)
  {
    $self->apply_method_triggers($method_type);
  }

  return;
}

sub reapply_triggers { shift->apply_triggers(@_) }

sub apply_method_triggers
{
  my($self, $type) = @_;

  my $column = $self; # $self masked in a deeper context below

  my $class = $self->parent->class;

  my $method_name = $self->method_name($type) or
    Carp::confess "No method name for method type '$type'";

  my $method_code = $self->method_code($type);

  # Save the original method code
  unless($method_code)
  {
    $method_code = $class->can($method_name);
    $self->method_code($type, $method_code);
  }

  # Copying out into scalars to avoid method calls in the sub itself
  my $inflate_code = $self->triggers('inflate') || 0;
  my $deflate_code = $self->triggers('deflate') || 0;
  my $on_load_code = $self->triggers('on_load') || 0;
  my $on_save_code = $self->triggers('on_save') || 0;
  my $on_set_code  = $self->triggers('on_set')  || 0;
  my $on_get_code  = $self->triggers('on_get')  || 0;

  my $builtins;

  # Add built-ins, if any
  unshift(@{$inflate_code ||= []}, @$builtins)
    if($builtins = $self->builtin_triggers('inflate'));

  unshift(@{$deflate_code ||= []}, @$builtins)
    if($builtins = $self->builtin_triggers('deflate'));  

  unshift(@{$on_load_code ||= []}, @$builtins)
    if($builtins = $self->builtin_triggers('on_load'));  

  unshift(@{$on_save_code ||= []}, @$builtins)
    if($builtins = $self->builtin_triggers('on_save'));  

  unshift(@{$on_set_code ||= []}, @$builtins)
    if($builtins = $self->builtin_triggers('on_set'));  

  unshift(@{$on_get_code ||= []}, @$builtins)
    if($builtins = $self->builtin_triggers('on_get'));  

  my $lazy_load_code = $self->builtin_triggers('lazy_load');

  my $key             = $self->hash_key;
  my $formatted_key   = column_value_formatted_key($key);
  my $is_inflated_key = column_value_is_inflated_key($key);

  my $uses_formatted_key = $self->method_uses_formatted_key($type);

  if($type eq 'get_set')
  {
    if($inflate_code || $deflate_code || 
       $on_load_code || $on_save_code ||
       $on_set_code  || $on_get_code  ||
       $lazy_load_code)
    {
      my $method = sub
      {
        my($self) = $_[0];

        if($column->method_should_set('get_set', \@_))
        {
          # This is a duplication of the 'set' code below.  Yes, it's
          # duplicated to save one measly function call.  So sue me.
          if($self->{STATE_LOADING()})
          {
            $self->{$is_inflated_key} = 0  unless($uses_formatted_key);

            my @ret;

            if(wantarray)
            {            
              @ret = &$method_code; # magic call using current @_
            }
            else
            {
              $ret[0] = &$method_code; # magic call using current @_
            }

            unless($column->{'triggers_disabled'} || $self->{'triggers_disabled'})
            {
              local $self->{'triggers_disabled'} = 1;

              if($on_load_code)
              {
                foreach my $code (@$on_load_code)
                {
                  $code->($self);
                }
              }
            }

            return wantarray ? @ret : $ret[0];
          }
          else
          {
            $self->{$is_inflated_key} = 0  unless($uses_formatted_key);

            my @ret;

            if(wantarray)
            {            
              @ret = &$method_code; # magic call using current @_
            }
            else
            {
              $ret[0] = &$method_code; # magic call using current @_
            }

            unless($column->{'triggers_disabled'} || $self->{'triggers_disabled'})
            {
              local $self->{'triggers_disabled'} = 1;

              if($on_set_code)
              {
                foreach my $code (@$on_set_code)
                {
                  $code->($self);
                }
              }
            }

            return wantarray ? @ret : $ret[0];
          }
        }
        else # getting
        {
          # This is a duplication of the 'get' code below.  Yes, it's
          # duplicated to save one measly function call.  So sue me.
          if($self->{STATE_SAVING()})
          {
            unless($column->{'triggers_disabled'} || $self->{'triggers_disabled'})
            {
              local $self->{'triggers_disabled'} = 1;

              if($deflate_code)
              {
                if($uses_formatted_key)
                {
                  my $db = $self->db or die "Missing Rose::DB object attribute";
                  my $driver = $db->driver || 'unknown';

                  unless(defined $self->{$formatted_key,$driver})
                  {      
                    my $value = $self->{$key};

                    # Call method to get default value
                    $value = $method_code->($self)  unless(defined $value);

                    foreach my $code (@$deflate_code)
                    {
                      $value = $code->($self, $value);
                    }

                    $self->{$formatted_key,$driver} = $value;
                  }
                }
                else
                {
                  my $value = $self->{$key};

                  # Call method to get default value
                  $value = $method_code->($self)  unless(defined $value);

                  foreach my $code (@$deflate_code)
                  {
                    $value = $code->($self, $value);
                  }

                  $self->{$key} = $value;
                  $self->{$is_inflated_key} = 0;
                }
              }

              if($on_save_code && !$self->{SAVING_FOR_LOAD()})
              {
                foreach my $code (@$on_save_code)
                {
                  $code->($self);
                }
              }
            }

            &$method_code; # magic call using current @_
          }
          else
          {
            unless($column->{'triggers_disabled'} || $self->{'triggers_disabled'})
            {
              local $self->{'triggers_disabled'} = 1;

              if($lazy_load_code)
              {
                foreach my $code (@$lazy_load_code)
                {
                  $code->($self);
                }
              }

              if($inflate_code)
              {
                my $value;
                my $key_was_defined;

                if(defined $self->{$key})
                {
                  $value = $self->{$key};
                  $key_was_defined = 1;
                }
                else
                {
                  $key_was_defined = 0;
                  # Invoke built-in default and inflation code
                  # (The call must not be in void context)
                  $value = $method_code->($self, @_[1 .. $#_]);
                }

                unless($self->{$is_inflated_key} && $key_was_defined)
                {
                  if($uses_formatted_key)
                  {
                    foreach my $code (@$inflate_code)
                    {
                      $value = $code->($self, $value);
                    }

                    my $db = $self->db or die "Missing Rose::DB object attribute";
                    my $driver = $db->driver || 'unknown';

                    # Invalidate deflated value
                    $self->{$formatted_key,$driver} = undef;

                    # Set new inflated value
                    $self->{$key} = $value;
                  }
                  else
                  {    
                    foreach my $code (@$inflate_code)
                    {
                      $value = $code->($self, $value);
                    }

                    $self->{$is_inflated_key} = 1;
                    $self->{$key} = $value;
                  }

                  $self->{$is_inflated_key} = 1;
                }
              }

              if($on_get_code)
              {
                foreach my $code (@$on_get_code)
                {
                  $code->($self);
                }
              }
            }

            &$method_code; # magic call using current @_
          }
        }
      };

      no warnings;
      no strict 'refs';
      *{"${class}::$method_name"} = $method;
    }
    else # no applicable triggers for 'get'
    {
      no warnings;
      no strict 'refs';
      *{"${class}::$method_name"} = $method_code;
    }
  }
  elsif($type eq 'get')
  {
    if($inflate_code || $deflate_code || $on_save_code || $on_get_code || $lazy_load_code)
    {
      my $method = sub
      {
        my($self) = $_[0];

        if($self->{STATE_SAVING()})
        {
          unless($column->{'triggers_disabled'} || $self->{'triggers_disabled'})
          {
            local $self->{'triggers_disabled'} = 1;

            if($deflate_code)
            {
              if($uses_formatted_key)
              {
                my $db = $self->db or die "Missing Rose::DB object attribute";
                my $driver = $db->driver || 'unknown';

                unless(defined $self->{$formatted_key,$driver})
                {    
                  my $value = $self->{$key};

                  # Call method to get default value
                  $value = $method_code->($self)  unless(defined $value);

                  foreach my $code (@$deflate_code)
                  {
                    $value = $code->($self, $value);
                  }

                  $self->{$formatted_key,$driver} = $value;
                }
              }
              else
              {
                my $value = $self->{$key};

                # Call method to get default value
                $value = $method_code->($self)  unless(defined $value);

                foreach my $code (@$deflate_code)
                {
                  $value = $code->($self, $value);
                }

                $self->{$key} = $value;
                $self->{$is_inflated_key} = 0;
              }
            }

            if($on_save_code && !$self->{SAVING_FOR_LOAD()})
            {
              foreach my $code (@$on_save_code)
              {
                $code->($self);
              }
            }
          }

          &$method_code; # magic call using current @_
        }
        else
        {
          unless($column->{'triggers_disabled'} || $self->{'triggers_disabled'})
          {
            local $self->{'triggers_disabled'} = 1;

            if($lazy_load_code)
            {
              foreach my $code (@$lazy_load_code)
              {
                $code->($self);
              }
            }

            if($inflate_code)
            {
              my $value;
              my $key_was_defined;

              if(defined $self->{$key})
              {
                $value = $self->{$key};
                $key_was_defined = 1;
              }
              else
              {
                $key_was_defined = 0;
                # Invoke built-in default and inflation code
                # (The call must not be in void context)
                $value = $method_code->($self, @_[1 .. $#_]);
              }

              unless($self->{$is_inflated_key} && $key_was_defined)
              {
                if($uses_formatted_key)
                {
                  foreach my $code (@$inflate_code)
                  {
                    $value = $code->($self, $value);
                  }

                  my $db = $self->db or die "Missing Rose::DB object attribute";
                  my $driver = $db->driver || 'unknown';

                  # Invalidate deflated value
                  $self->{$formatted_key,$driver} = undef;

                  # Set new inflated value
                  $self->{$key} = $value;
                }
                else
                {    
                  foreach my $code (@$inflate_code)
                  {
                    $value = $code->($self, $value);
                  }

                  $self->{$is_inflated_key} = 1;
                  $self->{$key} = $value;
                }

                $self->{$is_inflated_key} = 1;
              }
            }

            if($on_get_code)
            {
              foreach my $code (@$on_get_code)
              {
                $code->($self);
              }
            }
          }

          &$method_code; # magic call using current @_
        }
      };

      no warnings;
      no strict 'refs';
      *{"${class}::$method_name"} = $method;
    }
    else # no applicable triggers for 'get'
    {
      no warnings;
      no strict 'refs';
      *{"${class}::$method_name"} = $method_code;
    }
  }
  elsif($type eq 'set')
  {
    if($on_load_code || $on_set_code)
    {
      my $method = sub
      {
        my($self) = $_[0];

        if($self->{STATE_LOADING()})
        {
          $self->{$is_inflated_key} = 0  unless($uses_formatted_key);

          my @ret;

          if(wantarray)
          {            
            @ret = &$method_code; # magic call using current @_
          }
          else
          {
            $ret[0] = &$method_code; # magic call using current @_
          }

          unless($column->{'triggers_disabled'} || $self->{'triggers_disabled'})
          {
            local $self->{'triggers_disabled'} = 1;

            if($on_load_code)
            {
              foreach my $code (@$on_load_code)
              {
                $code->($self);
              }
            }
          }

          return wantarray ? @ret : $ret[0];
        }
        else
        {
          $self->{$is_inflated_key} = 0  unless($uses_formatted_key);

          my @ret;

          if(wantarray)
          {            
            @ret = &$method_code; # magic call using current @_
          }
          else
          {
            $ret[0] = &$method_code; # magic call using current @_
          }

          unless($column->{'triggers_disabled'} || $self->{'triggers_disabled'})
          {
            local $self->{'triggers_disabled'} = 1;

            if($on_set_code)
            {
              foreach my $code (@$on_set_code)
              {
                $code->($self);
              }
            }
          }

          return wantarray ? @ret : $ret[0];
        }
      };

      no warnings;
      no strict 'refs';
      *{"${class}::$method_name"} = $method;
    }
    else # no applicable triggers for 'set'
    {
      no warnings;
      no strict 'refs';
      *{"${class}::$method_name"} = $method_code;
    }
  }
}

sub method_code
{
  my($self, $type) = (shift, shift);

  Carp::confess "Missing or undefined type argument"  unless(defined $type);

  if(@_)
  {
    Scalar::Util::weaken($self->{'method_code'}{$type} = shift);
  }

  return $self->{'method_code'}{$type};
}

sub make_methods
{
  my($self) = shift;

  $self->SUPER::make_methods(@_);

  # Check if we can fold all method type name attributes
  # into an alias attribute.  We can do this if the accessor,
  # mutator, and rw method names are all the same and are not
  # the same as the column name.
  no warnings 'uninitialized';
  if(($self->accessor_method_name eq $self->mutator_method_name &&
      $self->mutator_method_name eq $self->rw_method_name &&
      $self->rw_method_name ne $self->name))
  {
    $self->alias($self->rw_method_name);
  }

  $self->apply_triggers;
}

sub dbi_requires_bind_param { 0 }

# It's important to return undef or a hashref, not an empty list
sub dbi_bind_param_attrs { undef } 

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::Column - Base class for database column metadata objects.

=head1 SYNOPSIS

  package MyColumnType;

  use Rose::DB::Object::Metadata::Column;
  our @ISA = qw(Rose::DB::Object::Metadata::Column);
  ...

=head1 DESCRIPTION

This is the base class for objects that store and manipulate database column metadata.  Column metadata objects store information about columns (data type, size, etc.) and are responsible for parsing, formatting, and creating object methods that manipulate column values.

L<Rose::DB::Object::Metadata::Column> objects stringify to the value returned by the L<name|/name> method.  This allows full-blown column objects to be used in place of column name strings in most situations.

=head2 MAKING METHODS

A L<Rose::DB::Object::Metadata::Column>-derived object is responsible for creating object methods that manipulate column values.  Each column object can make zero or more methods for each available column method type.  A column method type describes the purpose of a method.  The default column method types are:

=over 4

=item C<get_set>

A method that can both get and set the column value.  If an argument is passed, then the column value is set.  In either case, the current column value is returned.

=item C<get>

A method that returns the current column value.

=item C<set>

A method that sets the column value.

=back

Methods are created by calling L<make_methods|/make_methods>.  A list of method types can be passed to the call to L<make_methods|/make_methods>.  If absent, the list of method types is determined by the L<auto_method_types|/auto_method_types> method.  A list of all possible method types is available through the L<available_method_types|/available_method_types> method.

These methods make up the "public" interface to column method creation.  There are, however, several "protected" methods which are used internally to implement the methods described above.  (The word "protected" is used here in a vaguely C++ sense, meaning "accessible to subclasses, but not to the public.")  Subclasses will probably find it easier to override and/or call these protected methods in order to influence the behavior of the "public" method maker methods.

A L<Rose::DB::Object::Metadata::Column> object delegates method creation to a  L<Rose::Object::MakeMethods>-derived class.  Each L<Rose::Object::MakeMethods>-derived class has its own set of method types, each of which takes it own set of arguments.

Using this system, four pieces of information are needed to create a method on behalf of a L<Rose::DB::Object::Metadata::Column>-derived object:

=over 4

=item * The B<column method type> (e.g., C<get_set>, C<get>, C<set>)

=item * The B<method maker class> (e.g., L<Rose::DB::Object::MakeMethods::Generic>)

=item * The B<method maker method type> (e.g., L<scalar|Rose::DB::Object::MakeMethods::Generic/scalar>)

=item * The B<method maker arguments> (e.g., C<interface =E<gt> 'get_set_init'>)

=back

This information can be organized conceptually into a "method map" that connects a column method type to a method maker class and, finally, to one particular method type within that class, and its arguments.

The default method map is:

=over 4

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<scalar|Rose::DB::Object::MakeMethods::Generic/scalar>, C<interface =E<gt> 'get_set', ...>

=item C<get>

L<Rose::DB::Object::MakeMethods::Generic>, L<scalar|Rose::DB::Object::MakeMethods::Generic/scalar>, C<interface =E<gt> 'get', ...>

=item C<set>

L<Rose::DB::Object::MakeMethods::Generic>, L<scalar|Rose::DB::Object::MakeMethods::Generic/scalar>, C<interface =E<gt> 'set', ...>

=back

Each item in the map is a column method type.  For each column method type, the method maker class, the method maker method type, and the "interesting" method maker arguments are listed, in that order.

The "..." in the method maker arguments is meant to indicate that other arguments have been omitted.  For example, the column object's L<default|/default> value is passed as part of the arguments for all method types.  These arguments that are common to all column method types are routinely omitted from the method map for the sake of brevity.  If there are no "interesting" method maker arguments, then "..." may appear by itself.

The purpose of documenting the method map is to answer the question, "What kind of method(s) will be created by this column object for a given method type?"  Given the method map, it's possible to read the documentation for each method maker class to determine how methods of the specified type behave when passed the listed arguments.

To this end, each L<Rose::DB::Object::Metadata::Column>-derived class in the L<Rose::DB::Object> module distribution will list its method map in its documentation.  This is a concise way to document the behavior that is specific to each column class, while omitting the common functionality (which is documented here, in the column base class).

Remember, the existence and behavior of the method map is really implementation detail.  A column object is free to implement the public method-making interface however it wants, without regard to any conceptual or actual method map.  It must then, of course, document what kinds of methods it makes for each of its method types, but it does not have to use a method map to do so.

=head2 TRIGGERS

Triggers allow code to run in response to certain column-related events.  An event may trigger zero or more pieces of code.  The names and behaviors of the various kinds of events are as follows.

=over 4

=item B<on_get>

Triggered when a column value is retrieved for some purpose I<other than> storage in the database.  For example, when end-user code retrieves a column value by calling an accessor method, this event is triggered.  This event is I<not> triggered when a column value is retrieved while the object is being L<save|Rose::DB::Object/save>d into the database.

Each piece of code responding to an C<on_get> event will be passed a single argument: a reference to the object itself.  The return value is not used.

=item B<on_set>

Triggered when a column value is set to a value that came from somewhere I<other than>  the database.  For example, when end-user code sets a column value by calling a mutator method, this event is triggered.  This event is I<not> triggered when a column value is set while the object is being L<load|Rose::DB::Object/load>ed from the database.

The C<on_set> event occurs I<after> the column value has been set.  Each piece of code responding to an C<on_set> event will be passed a single argument: a reference to the object itself.  The return value is not used.

=item B<on_load>

Triggered when a column value is set while an object is being L<load|Rose::DB::Object/load>ed from the database.

The C<on_load> event occurs I<after> the column value has been loaded.  Each piece of code responding to an C<on_load> event will be passed a single argument: a reference to the object itself.  The return value is not used.

=item B<on_save>

Triggered when a column value is retrieved while an object is being L<save|Rose::DB::Object/save>d into the database.

Each piece of code responding to an C<on_save> event will be passed a single argument: a reference to the object itself.  The return value is not used.

=item B<inflate>

Triggered when a column value is retrieved for some purpose I<other than> storage in the database.  For example, when end-user code retrieves a column value by calling an accessor method, and that value came directly from the database, this event is triggered.

Inflation will only happen "as needed."  That is, a value that has already been inflated will not be inflated again, and a value that comes from the database and goes back into it without ever being retrieved by end-user code will never be inflated at all.

Each piece of code responding to an C<inflate> event will be passed two arguments: a reference to the object itself and the value to be inflated.  It should return an inflated version of that value.  Note that the value to be inflated may have come from the database, or from end-user code.  Be prepared to handle almost anything.

=item B<deflate>

Triggered when a column value that did not come directly from the database needs to be put into the database.  For example, when a column value set by end-user code needs to be saved into the database, this event is triggered.

Deflation will only happen "as needed."  That is, a value that has already been deflated will not be deflated again, and a value that comes from the database and goes back into it without ever being retrieved by end-user code will never need to be deflated at all.

Each piece of code responding to a C<deflate> event will be passed two arguments: a reference to the object itself and the value to be deflated.  It should return a deflated version of that value suitable for saving into the currently connected database.  Note that the value to be deflated may have come from the database, or from end-user code.  Be prepared to handle almost anything.

=back

All triggers are L<disabled|/disable_triggers> while inside code called in response to a trigger event.  Such code may call any other column methods, including methods that belong to its own column, without fear of infinite recursion into trigger service subroutines.  Alternately, triggers may be explicitly L<enabled|/enable_triggers> if desired.  Just watch out for infinite loops.

For performance reasons, none of the column classes bundled with L<Rose::DB::Object> use triggers by default.  Some of them do inflate and deflate values, but they do so internally (inside the accessor and mutator methods created by the L<Rose::Object::MakeMethods>-derived classes that service those column types).  You can still add triggers to these column types, but the interaction between the internal inflate/deflate actions and the triggers for those same events can become a bit "non-obvious."

=head1 CLASS METHODS

=over 4

=item B<default_auto_method_types [TYPES]>

Get or set the default list of L<auto_method_types|/auto_method_types>.  TYPES should be a list of column method types.  Returns the list of default column method types (in list context) or a reference to an array of the default column method types (in scalar context).  The default list contains only the "get_set" column method type.

=item B<default_undef_overrides_default [BOOL]>

Get or set the default value of the L<undef_overrides_default|/undef_overrides_default> attribute.  The default value is undef.

This default only applies when the column does not have a parent metadata object or if the metadata object's L<column_undef_overrides_default|Rose::DB::Object::Metadata/column_undef_overrides_default> method returns undef.

=back

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Constructs a new object based on PARAMS, where PARAMS are
name/value pairs.  Any object method is a valid parameter name.

=back

=head1 OBJECT METHODS

=over 4

=item B<accessor_method_name>

Returns the name of the method used to get the column value.  This is a convenient shortcut for:

    $column->method_name('get') || $column->method_name('get_set');

=item B<add_trigger [ EVENT, CODEREF | PARAMS ]>

Add a trigger, as specified by either an event and a code reference, or a set of named parameters that include an event, a code reference, and an optional name and position for the trigger.

If there are only two arguments, and the first is a valid event name, then the second must be a code reference.  Otherwise, the arguments are taken as named parameters.

Valid parameters are:

=over 4

=item C<code CODEREF>

A reference to a subroutine that will be called in response to a trigger event.  This parameter is required.  See the L<triggers|/TRIGGERS> section of this documentation for a description of the arguments to and return values expected from these routines for each type of event.

=item C<event EVENT>

The name of the event that activates this trigger.  This parameter is required.  Valid event names are C<on_get>, C<on_set>, C<on_load>, C<on_save>, C<inflate>, and C<deflate>.  See the L<triggers|/TRIGGERS> section of this documentation for more information on these event types.

=item C<name NAME>

An optional name mapped to the triggered subroutine.  If a name is not supplied, one will be generated.  A known name is necessary if you ever want to L<delete|/delete_trigger> a particular subroutine from the list of triggered subroutine for a given event.

=item C<position POS>

The position in the list of triggered subroutines to add this new code.  Triggered subroutines are kept in an ordered list.  By default, new triggers are added to the end of the list, which means they run last.  Valid position arguments are:

=over

=item C<end>, C<last>, or C<push>

Add to the end of the list.

=item C<start>, C<first>, or C<unshift>

Add to the beginning of the list.

=back

If omitted, the position defaults to "end."

=back

Examples:

    # Add trigger using an event name and a code reference
    $column->add_trigger(on_set => sub { print "set!\n" });

    # Same as above, but using named parameters
    $column->add_trigger(event => 'on_set',
                         code  => sub { print "set!\n" });

    # Same as the above, but with a custom name and explicit position
    $column->add_trigger(event    => 'on_set',
                         code     => sub { print "set!\n" },
                         name     => 'debugging',
                         position => 'end');

=item B<alias [NAME]>

Get or set an alternate L<name|/name> for this column.

=item B<available_method_types>

Returns the full list of column method types supported by this class.

=item B<auto_method_types [TYPES]>

Get or set the list of column method types that are automatically created when L<make_methods|/make_methods> is called without an explicit list of column method types.  The default list is determined by the L<default_auto_method_types|/default_auto_method_types> class method.

=item B<build_method_name_for_type TYPE>

Return a method name for the column method type TYPE.  The default implementation returns the column's L<alias|/alias> (if defined) or L<name|/name> for the method type "get_set", and the same thing with a "get_" or "set_" prefix for the "get" and "set" column method types, respectively.

=item B<default [VALUE]>

Get or set the default value of the column.

=item B<default_exists>

Returns true if a default value exists for this column (even if it is undef), false otherwise.

=item B<delete_default>

Deletes the default value for this column.

=item B<delete_trigger PARAMS>

Delete a triggered subroutine from the list of triggered subroutines for a given event.  You must know the name applied to the triggered subroutine when it was L<added|/add_trigger> in order to delete it.  PARAMS are name/value pairs.

=over 4

=item C<name NAME>

The name applied to the triggered subroutine when it was added via the L<added|/add_trigger> method.  This parameter is required.

=item C<event EVENT>

The name of the event that activates this trigger.  This parameter is required.  Valid event names are C<on_get>, C<on_set>, C<on_load>, C<on_save>, C<inflate>, and C<deflate>.  See the L<triggers|/TRIGGERS> section of this documentation for more information on these event types.

=back

A fatal error will occur if a matching trigger cannot be found.

Examples:

    # Add two named triggers
    $column->add_trigger(event => 'on_set',
                         code  => sub { print "set!\n" },
                         name  => 'debugging');

    $column->add_trigger(event => 'on_set',
                         code  => sub { shift->do_something() },
                         name  => 'side_effect');

    # Delete the side_effect trigger
    $column->delete_trigger(event => 'on_set',
                            name  => 'side_effect');

    # Fatal error: no trigger subroutine for this column
    # named "nonesuch" for the event type "on_set"
    $column->delete_trigger(event => 'on_set',
                            name  => 'nonesuch');

=item B<delete_triggers [EVENT]>

Delete all triggers for EVENT.  If EVENT is omitted, delete all triggers for all events for this column.

Valid event names are C<on_get>, C<on_set>, C<on_load>, C<on_save>, C<inflate>, and C<deflate>.  See the L<triggers|/TRIGGERS> section of this documentation for more information on these event types.

=item B<disable_triggers>

Disable all triggers for this column.

=item B<enable_triggers>

Enable all triggers for this column.

=item B<format_value DB, VALUE>

Convert VALUE into a string suitable for the database column of this type.  VALUE is expected to be like the return value of the L<parse_value|/parse_value> method.  DB is a L<Rose::DB> object that may be used as part of the parsing process.  Both arguments are required.

=item B<is_primary_key_member [BOOL]>

Get or set the boolean flag that indicates whether or not this column is part of the primary key for its table.

=item B<load_on_demand [BOOL]>

Get or set a boolean value that indicates whether or not a column's value should be loaded only when needed.  If true, then the column's value will not automatically be fetched from the database when an object is L<loaded|Rose::DB::Object/load>.  It will be fetched only if the column value is subsequently requested through its L<accessor method|/accessor_method_name>.  (This is often referred to as "lazy loading.")  The default value is false.

Note: a column that is part of a primary key cannot be loaded on demand.

=item B<lazy [BOOL]>

This is an alias for the L<load_on_demand|/load_on_demand> method.  It exists to allow this common usage scenario:

    __PACKAGE__->meta->columns
    (
      ...
      notes => { type => 'text', length => 1024, lazy => 1 },
    );

without requiring the longer C<load_on_demand> parameter name to be used.

=item B<make_methods PARAMS>

Create object method used to manipulate column values.  PARAMS are name/value pairs.  Valid PARAMS are:

=over 4

=item C<preserve_existing BOOL>

Boolean flag that indicates whether or not to preserve existing methods in the case of a name conflict.

=item C<replace_existing BOOL>

Boolean flag that indicates whether or not to replace existing methods in the case of a name conflict.

=item C<target_class CLASS>

The class in which to make the method(s).  If omitted, it defaults to the calling class.

=item C<types ARRAYREF>

A reference to an array of column method types to be created.  If omitted, it defaults to the list of column method types returned by L<auto_method_types|/auto_method_types>.

=back

If any of the methods could not be created for any reason, a fatal error will occur.

=item B<manager_uses_method [BOOL]>

If true, then L<Rose::DB::Object::QueryBuilder> will pass column values through the object method(s) associated with this column when composing SQL queries where C<query_is_sql> is not set.  The default value is false.  See the L<Rose::DB::Object::QueryBuilder> documentation for more information.

Note: the method is named "manager_uses_method" instead of, say, "query_builder_uses_method" because L<Rose::DB::Object::QueryBuilder> is rarely used directly.  Instead, it's mostly used indirectly through the L<Rose::DB::Object::Manager> class.

=item B<method_name TYPE [, NAME]>

Get or set the name of the column method of type TYPE.

=item B<mutator_method_name>

Returns the name of the method used to set the column value.  This is a convenient shortcut for:

    $column->method_name('set') || $column->method_name('get_set');

=item B<name [NAME]>

Get or set the name of the column, not including the table name, username, schema, or any other qualifier.

=item B<nonpersistent [BOOL]>

Get or set a boolean flag that indicates whether or not the column 
is L<non-persistent|Rose::DB::Object::Metadata/nonpersistent_columns>.

=item B<not_null [BOOL]>

Get or set a boolean flag that indicates whether or not the column 
value can be null.

=item B<parse_value DB, VALUE>

Parse and return a convenient Perl representation of VALUE.  What form this value will take is up to the column subclass.  If VALUE is a keyword or otherwise has special meaning to the underlying database, it may be returned unmodified.  DB is a L<Rose::DB> object that may be used as part of the parsing process.  Both arguments are required.

=item B<primary_key_position [INT]>

Get or set the column's ordinal position in the primary key.  Returns undef if the column is not part of the primary key.  Position numbering starts from 1.

=item B<remarks [TEXT]>

Get or set a text description of the column.

=item B<rw_method_name>

Returns the name of the method used to get or set the column value.  This is a convenient shortcut for:

    $column->method_name('get_set');

=item B<should_inline_value DB, VALUE>

Given the L<Rose::DB>-derived object DB and the column value VALUE, return true of the value should be "inlined" (i.e., not bound to a "?" placeholder and passed as an argument to L<DBI>'s L<execute|DBI/execute> method), false otherwise.  The default implementation always returns false.

This method is necessary because some L<DBI> drivers do not (or cannot) always do the right thing when binding values to placeholders in SQL statements.  For example, consider the following SQL for the Informix database:

    CREATE TABLE test (d DATETIME YEAR TO SECOND);
    INSERT INTO test (d) VALUES (CURRENT);

This is valid Informix SQL and will insert a row with the current date and time into the "test" table. 

Now consider the following attempt to do the same thing using L<DBI> placeholders (assume the table was already created as per the CREATE TABLE statement above):

    $sth = $dbh->prepare('INSERT INTO test (d) VALUES (?)');
    $sth->execute('CURRENT'); # Error!

What you'll end up with is an error like this:

    DBD::Informix::st execute failed: SQL: -1262: Non-numeric 
    character in datetime or interval.

In other words, L<DBD::Informix> has tried to quote the string "CURRENT", which has special meaning to Informix only when it is not quoted. 

In order to make this work, the value "CURRENT" must be "inlined" rather than bound to a placeholder when it is the value of a "DATETIME YEAR TO SECOND" column in an Informix database.

All of the information needed to make this decision is available to the call to L<should_inline_value|/should_inline_value>.  It gets passed a L<Rose::DB>-derived object, from which it can determine the database driver, and it gets passed the actual value, which it can check to see if it matches C</^current$/i>.

This is just one example.  Each subclass of L<Rose::DB::Object::Metadata::Column> must determine for itself when a value needs to be inlined.

=item B<triggers EVENT [, CODEREF | ARRAYREF ]>

Get or set the list of trigger subroutines for EVENT.  Valid event names are C<on_get>, C<on_set>, C<on_load>, C<on_save>, C<inflate>, and C<deflate>.  See the L<triggers|/TRIGGERS> section of this documentation for more information on these event types.

If passed a code ref or a reference to an array of code refs, then the list of trigger subroutines for EVENT is replaced with those code ref(s).

Returns a reference to an array of trigger subroutines for the event type EVENT.  If there are no triggers for EVENT, undef will be returned.

=item B<triggers_disabled>

Returns true if L<triggers|/TRIGGERS> are disabled for this column, false otherwise.

=item B<type>

Returns the (possibly abstract) data type of the column.  The default implementation returns "scalar".

=item B<undef_overrides_default [BOOL]>

Get or set a boolean value that indicates whether or not setting the column to an undef value overrides the column's L<default|/default> value.

The default value of this attribute is determined by the parent L<metadata|Rose::DB::Object::Metadata> object's L<column_undef_overrides_default|Rose::DB::Object::Metadata/column_undef_overrides_default> method, or the column's L<default_undef_overrides_default|/default_undef_overrides_default> class method id the metadata object's L<column_undef_overrides_default|Rose::DB::Object::Metadata/column_undef_overrides_default> method returns undef, or if the column has no parent metadata object.

Example: consider a L<Rose::DB::Object>-derived C<Person> class with a C<name> column set up like this:

    package Person;
    ...
       columns =>
       [
         name => { type => 'varchar', default => 'John Doe' },
         ...
       ],
    ...

The following behavior is the same regardless of the setting of the L<undef_overrides_default|/undef_overrides_default> attribute for the C<name> column:

    $p = Person->new;
    print $p->name; # John Doe

    $p->name('Larry Wall');
    print $p->name; # Larry Wall

If L<undef_overrides_default|/undef_overrides_default> is B<false> for the C<name> column, then this is the behavior of explicitly setting the column to undef:

    $p->name(undef);
    print $p->name; # John Doe

If L<undef_overrides_default|/undef_overrides_default> is B<true> for the C<name> column, then this is the behavior of explicitly setting the column to undef:

    $p->name(undef);
    print $p->name; # undef

The L<undef_overrides_default|/undef_overrides_default> attribute can be set directly on the column:

    name => { type => 'varchar', default => 'John Doe', 
              undef_overrides_default => 1 },

or it can be set class-wide using the L<meta|Rose::DB::Object/meta> object's L<column_undef_overrides_default|Rose::DB::Object::Metadata/column_undef_overrides_default> attribute:

    Person->meta->column_undef_overrides_default(1);

or it can be set for all classes that use a given L<Rose::DB::Object::Metadata>-derived class using the L<default_column_undef_overrides_default|Rose::DB::Object::Metadata/default_column_undef_overrides_default> class method:

    My::DB::Object::Metadata->default_column_undef_overrides_default(1);

=back

=head1 PROTECTED API

These methods are not part of the public interface, but are supported for use by subclasses.  Put another way, given an unknown object that "isa" L<Rose::DB::Object::Metadata::Column>, there should be no expectation that the following methods exist.  But subclasses, which know the exact class from which they inherit, are free to use these methods in order to implement the public API described above.

=over 4 

=item B<method_maker_arguments TYPE>

Returns a hash (in list context) or reference to a hash (in scalar context) of name/value arguments that will be passed to the L<method_maker_class|/method_maker_class> when making the column method type TYPE.

=item B<method_maker_class TYPE [, CLASS]>

If CLASS is passed, the name of the L<Rose::Object::MakeMethods>-derived class used to create the object method of type TYPE is set to CLASS.

Returns the name of the L<Rose::Object::MakeMethods>-derived class used to create the object method of type TYPE.

=item B<method_maker_type TYPE [, NAME]>

If NAME is passed, the name of the method maker method type for the column method type TYPE is set to NAME.

Returns the method maker method type for the column method type TYPE.  

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
