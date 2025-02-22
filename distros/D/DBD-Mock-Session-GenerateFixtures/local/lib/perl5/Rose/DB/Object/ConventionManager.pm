package Rose::DB::Object::ConventionManager;

use strict;

use Carp();
use Scalar::Util();

use Rose::DB::Object::Metadata::ForeignKey;

use Rose::DB::Object::Metadata::Object;
our @ISA = qw(Rose::DB::Object::Metadata::Object);

our $VERSION = '0.795';

our $Debug = 0;

use Rose::Object::MakeMethods::Generic
(
  'scalar --get_set_init' =>
  [
    'singular_to_plural_function',
    'plural_to_singular_function',
  ],

  boolean => 
  [
    tables_are_singular => { default => 0 },
    force_lowercase     => { default => 0 },
    no_auto_sequences   => { default => 0 },
  ],
);

*meta = \&Rose::DB::Object::Metadata::Object::parent;

sub class_to_table_singular
{
  my($self, $class) = @_;

  $class ||= $self->meta->class;

  my $table = $self->class_suffix($class);
  $table =~ s/([a-z]\d*|^\d+)([A-Z])/$1_$2/g;
  return lc $table;
}

sub class_suffix
{
  my($self, $class) = @_;

  $class =~ /(\w+)$/;
  return $1;
}

sub class_to_table_plural
{
  my($self) = shift;
  $self->singular_to_plural($self->class_to_table_singular(@_));
}

sub table_to_class_plural 
{
  my($self, $table, $prefix) = @_;
  return $self->table_to_class($table, $prefix, 1);
}

sub table_to_class
{
  my($self, $table, $prefix, $plural) = @_;
  $table = lc $table if ($self->force_lowercase);
  $table = $self->plural_to_singular($table)  unless($plural);
  $table =~ s/_(.)/\U$1/g;
  $table =~ s/[^\w:]/_/g;
  return ($prefix || '') . ucfirst $table;
}

sub auto_manager_base_name
{
  my($self, $table, $object_class) = @_;

  $table ||= $self->class_to_table_plural;

  $table = lc $table  if($self->force_lowercase);

  return $self->tables_are_singular ? $self->singular_to_plural($table) : $table;
}

sub auto_manager_base_class { 'Rose::DB::Object::Manager' }

sub auto_manager_class_name
{
  my($self, $object_class) = @_;

  $object_class ||= $self->meta->class;

  return "${object_class}::Manager";
}

sub auto_manager_method_name
{
  my($self, $type, $base_name, $object_class) = @_;
  return undef; # rely on hard-coded defaults in Manager
}

sub class_prefix
{
  my($self, $class) = @_;
  $class =~ /^((?:\w+::)*)/;
  return $1 || '';
}

sub related_table_to_class
{
  my($self, $table, $local_class, $plural) = @_;
  return $self->table_to_class($table, $self->class_prefix($local_class), $plural);
}

sub table_singular
{
  my($self) = shift;

  my $table = $self->meta->table;

  if($self->tables_are_singular)
  {
    return $table;
  }

  return $self->plural_to_singular($table);
}

sub table_plural
{
  my($self) = shift;

  my $table = $self->meta->table;

  if($self->tables_are_singular)
  {
    return $self->singular_to_plural($table);
  }

  return $table;
}

sub auto_table_name 
{
  my($self) = shift;

  if($self->tables_are_singular)
  {
    return $self->class_to_table_singular;
  }
  else
  {
    return $self->class_to_table_plural;
  }
}

sub auto_primary_key_column_names
{
  my($self) = shift;

  my $meta = $self->meta;

  # 1. Column named "id"
  return [ 'id' ]  if($meta->column('id'));

  # 2. Column named <table singular>_id
  my $column = $self->class_to_table_singular . '_id';
  return [ $column ]  if($meta->column($column));

  # 3. The first serial column in the column list, alphabetically
  foreach my $column (sort { lc $a->name cmp lc $b->name } $meta->columns)
  {
    return [ $column->name ]  if($column->type =~ /^(?:big)?serial$/);
  }

  # 4. The first column
  if(my $column = $meta->first_column)
  {
    return [ $column->name ];
  }

  return;
}

sub auto_column_method_name
{
  my($self, $type, $column, $name, $object_class) = @_;
  return lc $name if ($self->force_lowercase);
  return undef; # rely on hard-coded defaults in Metadata
}

sub init_singular_to_plural_function { }
sub init_plural_to_singular_function { }

sub singular_to_plural
{
  my($self, $word) = @_;

  if(my $code = $self->singular_to_plural_function)
  {
    return $code->($word);
  }

  if($word =~ /(?:x|[se]s)$/i)
  {
    return $word . 'es';
  }
  else
  {
    $word =~ s/y$/ies/i;
  }

  return $word =~ /s$/i ? $word : ($word . 's');
}

sub plural_to_singular
{
  my($self, $word) = @_;

  if(my $code = $self->plural_to_singular_function)
  {
    return $code->($word);
  }

  $word =~ s/ies$/y/i;

  return $word  if($word =~ s/ses$/s/i);
  return $word  if($word =~ /[aeiouy]ss$/i);

  $word =~ s/s$//i;

  return $word;
}

sub method_name_conflicts
{
  my($self, $name) = @_;

  return 1  if(Rose::DB::Object->can($name));

  my $meta = $self->meta;

  foreach my $column ($meta->columns)
  {
    foreach my $type ($column->auto_method_types)
    {
      my $method = $column->method_name($type) || 
                   $meta->method_name_from_column_name($column->name, $type) || 
                   next;

      return 1  if($name eq $method);
    }
  }

  foreach my $foreign_key ($meta->foreign_keys)
  {
    foreach my $type ($foreign_key->auto_method_types)
    {
      my $method = 
        $foreign_key->method_name($type) || 
        $foreign_key->build_method_name_for_type($type) || next;

      return 1  if($name eq $method);
    }
  }

  foreach my $relationship ($meta->relationships)
  {
    foreach my $type ($relationship->auto_method_types)
    {
      my $method = 
        $relationship->method_name($type) || 
        $relationship->build_method_name_for_type($type) || next;

      return 1  if($name eq $method);
    }
  }

  return 0;
}

sub auto_column_sequence_name
{
  my($self, $table, $column, $db) = @_;
  my $name = join('_', $table, $column, 'seq');
  return uc $name  if($db && $db->likes_uppercase_sequence_names);
  return lc $name  if($db && $db->likes_lowercase_sequence_names);
  return $name;
}

sub auto_primary_key_column_sequence_name { shift->auto_column_sequence_name(@_) }

sub auto_foreign_key_name
{
  my($self, $f_class, $current_name, $key_columns, $used_names) = @_;

  if($self->force_lowercase)
  {
    $current_name = lc $current_name;
    $key_columns = { map { lc } %$key_columns };
  }

  my $f_meta = $f_class->meta or return $current_name;
  my $name = $self->plural_to_singular($f_meta->table) || $current_name;

  if(keys %$key_columns == 1)
  {
    my($local_column, $foreign_column) = %$key_columns;

    # Try to lop off foreign column name.  Example:
    # my_foreign_object_id -> my_foreign_object
    if($local_column =~ s/_$foreign_column$//i)
    {
      $name = $local_column;
    }
    else
    {
      $name = $self->plural_to_singular($f_meta->table) || $current_name;
    }
  }

  # Avoid method name conflicts
  if($self->method_name_conflicts($name) || $used_names->{$name})
  {
    foreach my $s ('_obj', '_object')
    {
      # Try the name with a suffix appended
      unless($self->method_name_conflicts($name . $s) ||
             $used_names->{$name . $s})
      {
        return $name . $s;
      }
    }

    my $i = 1;

    # Give up and go with numbers...
    $i++  while($self->method_name_conflicts($name . $i) ||
                $used_names->{$name . $i});

    return $name . $i;
  }

  return $name;
}

sub auto_table_to_relationship_name_plural
{
  my($self, $table) = @_;
  $table = lc $table if ($self->force_lowercase);
  return $self->tables_are_singular ? $self->singular_to_plural($table) : $table;
}

sub auto_class_to_relationship_name_plural
{
  my($self, $class) = @_;
  return $self->class_to_table_plural($class);
}

sub auto_foreign_key_to_relationship_name_plural
{
  my($self, $fk) = @_;
  my $name = $self->force_lowercase ? lc $fk->name : $fk->name;
  return $self->singular_to_plural($name);
}

sub auto_relationship_name_one_to_many
{
  my($self, $table, $class) = @_;
  #return $self->auto_class_to_relationship_name_plural($class);
  my $name = $self->auto_table_to_relationship_name_plural($table);

  # Avoid method name conflicts
  if($self->method_name_conflicts($name))
  {
    foreach my $s ('_objs', '_objects')
    {
      # Try the name with a suffix appended
      unless($self->method_name_conflicts($name . $s))
      {
        return $name . $s;
      }
    }

    my $i = 1;

    # Give up and go with numbers...
    $i++  while($self->method_name_conflicts($name . $i));

    return $name . $i;
  }

  return $name;
}

sub auto_relationship_name_many_to_many
{
  my($self, $fk, $map_class) = @_;
  my $name = $self->auto_foreign_key_to_relationship_name_plural($fk);

  # Avoid method name conflicts
  if($self->method_name_conflicts($name))
  {
    foreach my $s ('_objs', '_objects')
    {
      # Try the name with a suffix appended
      unless($self->method_name_conflicts($name . $s))
      {
        return $name . $s;
      }
    }

    my $i = 1;

    # Give up and go with numbers...
    $i++  while($self->method_name_conflicts($name . $i));

    return $name . $i;
  }

  return $name;
}

sub auto_relationship_name_one_to_one
{
  my($self, $table, $class) = @_;

  $table = lc $table if ($self->force_lowercase);

  my $name = $self->plural_to_singular($table);

  # Avoid method name conflicts
  if($self->method_name_conflicts($name))
  {
    foreach my $s ('_obj', '_object')
    {
      # Try the name with a suffix appended
      unless($self->method_name_conflicts($name . $s))
      {
        return $name . $s;
      }
    }

    my $i = 1;

    # Give up and go with numbers...
    $i++  while($self->method_name_conflicts($name . $i));

    return $name . $i;
  }

  return $name;
}

sub is_map_class
{
  my($self, $class) = @_;

  return 0  unless(UNIVERSAL::isa($class, 'Rose::DB::Object'));

  my $is_map_table = $self->looks_like_map_table($class->meta->table);
  my $is_map_class = $self->looks_like_map_class($class);

  return 1  if($is_map_table && (!defined $is_map_class || $is_map_class));
  return 0;
}

sub looks_like_map_class
{
  my($self, $class) = @_;

  unless(UNIVERSAL::isa($class, 'Rose::DB::Object'))
  {
    return undef;
  }

  my $meta = $class->meta;
  my @fks  = $meta->foreign_keys;

  return 1  if(@fks == 2);
  return 0  if(($meta->is_initialized || $meta->initialized_foreign_keys) && 
               !$meta->has_deferred_foreign_keys);
  return undef;
}

sub looks_like_map_table
{
  my($self, $table) = @_;

  if($table =~ m{^(?:
                    (?:\w+_){2,}map             # foo_bar_map
                  | (?:\w+_)*\w+_(?:\w+_)*\w+s  # foo_bars
                  | (?:\w+_)*\w+s_(?:\w+_)*\w+s # foos_bars
               )$}xi)
  {
    return 1;
  }

  return 0;
}

sub auto_foreign_key
{
  my($self, $name, $spec) = @_;

  $spec ||= {};

  my $meta = $self->meta;

  unless($spec->{'class'})
  {
    my $class = $meta->class;

    my $fk_class = $self->related_table_to_class($name, $class);

    LOAD:
    {
      # Try to load class
      no strict 'refs';
      unless(UNIVERSAL::isa($fk_class, 'Rose::DB::Object'))
      {
        local $@;
        eval "require $fk_class";
        return  if($@ || !UNIVERSAL::isa($fk_class, 'Rose::DB::Object'));
      }
    }

    #return  unless(UNIVERSAL::isa($fk_class, 'Rose::DB::Object'));

    $spec->{'class'} = $fk_class;
  }

  unless(defined $spec->{'key_columns'})
  {
    my @fpk_columns = UNIVERSAL::isa($spec->{'class'}, 'Rose::DB::Object') ?
      $spec->{'class'}->meta->primary_key_column_names : ();

    # Defer population of key columns until the foreign class is initialized
    unless(@fpk_columns == 1)
    {
      # If the foreign class has more than one primary key column, give up
      return  if(@fpk_columns);

      # If the foreign class is initialized and the foreign key spec still
      # has no key columns, then give up.
      if(UNIVERSAL::isa($spec->{'class'}, 'Rose::DB::Object') && 
         $spec->{'class'}->meta->is_initialized)
      {
        return;
      }

      my %spec = %$spec;

      $meta->add_deferred_task(
      {
        class  => $meta->class, 
        method => "foreign_key:$name",

        code   => sub
        {
          # Generate new foreign key, then grab the key columns from it
          my $new_fk   = $self->auto_foreign_key($name, \%spec) or return;
          my $fk       = $meta->foreign_key($name);
          my $key_cols = $new_fk->key_columns or return;

          $fk->key_columns($key_cols);
        },

        check  => sub
        {
          my $fk = $meta->foreign_key($name) or return 0;

          # If the foreign class is initialized and the foreign key still
          # has no key columns, then we should give up.
          if(UNIVERSAL::isa($fk->class, 'Rose::DB::Object') && 
             $fk->class->meta->is_initialized)
          {
            Carp::croak "Missing key columns for foreign key named ",
                        $fk->name, " in class ", $meta->class;
          }

          my $cols = $fk->key_columns or return 0;

          # Everything is okay if we have key columns
          return (ref($cols) && keys(%$cols) > 0) ? 1 : 0;
        }
      });

      return Rose::DB::Object::Metadata::ForeignKey->new(name => $name, %$spec);
    }

    my $aliases = $meta->column_aliases;

    if($meta->column($name) && $aliases->{$name} && $aliases->{$name} ne $name)
    {
      $spec->{'key_columns'} = { $name => $fpk_columns[0] };
    }
    elsif($meta->column("${name}_$fpk_columns[0]"))
    {
      $spec->{'key_columns'} = { "${name}_$fpk_columns[0]" => $fpk_columns[0] };
    }
    else { return }
  }

  return Rose::DB::Object::Metadata::ForeignKey->new(name => $name, %$spec);
}

sub auto_relationship
{
  my($self, $name, $rel_class, $spec) = @_;

  $spec ||= {};

  my $meta     = $self->meta;
  my $rel_type = $rel_class->type;

  unless($spec->{'class'})
  {
    if($rel_type eq 'one to many')
    {
      my $class = $meta->class;

      # Get class suffix from relationship name
      my $table   = $self->plural_to_singular($name);
      my $f_class = $self->related_table_to_class($table, $class);

      LOAD:
      {
        # Try to load class
        no strict 'refs';
        unless(UNIVERSAL::isa($f_class, 'Rose::DB::Object'))
        {
          local $@;
          eval "require $f_class";
          return  if($@ || !UNIVERSAL::isa($f_class, 'Rose::DB::Object'));
        }
      }

      #return  unless(UNIVERSAL::isa($f_class, 'Rose::DB::Object'));

      $spec->{'class'} = $f_class;
    }
    elsif($rel_type =~ /^(?:one|many) to one$/)
    {
      my $class = $meta->class;

      # Get class suffix from relationship name
      my $f_class = $self->related_table_to_class($name, $class);

      LOAD:
      {
        # Try to load class
        no strict 'refs';
        unless(UNIVERSAL::isa($f_class, 'Rose::DB::Object'))
        {
          local $@;
          eval "require $f_class";
          return  if($@ || !UNIVERSAL::isa($f_class, 'Rose::DB::Object'));
        }
      }

      #return  unless(UNIVERSAL::isa($f_class, 'Rose::DB::Object'));

      $spec->{'class'} = $f_class;
    }
  }

  # Make sure this class has its @ISA set up...
  unless(UNIVERSAL::isa($spec->{'class'}, 'Rose::DB::Object'))
  {
    # ...but allow many-to-many relationships to pass because they tend to
    # need more time before every piece of info is available.
    return unless($rel_type eq 'many to many');
  }

  if($rel_type eq 'one to one')
  {
    return $self->auto_relationship_one_to_one($name, $rel_class, $spec);
  }
  elsif($rel_type eq 'many to one')
  {
    return $self->auto_relationship_many_to_one($name, $rel_class, $spec);
  }
  elsif($rel_type eq 'one to many')
  {
    return $self->auto_relationship_one_to_many($name, $rel_class, $spec);
  }
  elsif($rel_type eq 'many to many')
  {
    return $self->auto_relationship_many_to_many($name, $rel_class, $spec);
  }

  return;
}

sub auto_relationship_one_to_one
{
  my($self, $name, $rel_class, $spec) = @_;

  $spec ||= {};

  my $meta = $self->meta;

  unless(defined $spec->{'column_map'})
  {
    my @fpk_columns = $spec->{'class'}->meta->primary_key_column_names;
    return  unless(@fpk_columns == 1);

    my $aliases = $meta->column_aliases;    

    if($meta->column($name) && $aliases->{$name} && $aliases->{$name} ne $name)
    {
      $spec->{'column_map'} = { $name => $fpk_columns[0] };
    }
    elsif($meta->column("${name}_$fpk_columns[0]"))
    {
      $spec->{'column_map'} = { "${name}_$fpk_columns[0]" => $fpk_columns[0] };
    }
    elsif($meta->column("${name}_id"))
    {
      $spec->{'column_map'} = { "${name}_id" => $fpk_columns[0] };
    }
    else { return }
  }

  return $rel_class->new(name => $name, %$spec);
}

*auto_relationship_many_to_one = \&auto_relationship_one_to_one;

sub auto_relationship_one_to_many
{
  my($self, $name, $rel_class, $spec) = @_;

  $spec ||= {};

  my $meta = $self->meta;
  my $l_col_name = $self->class_to_table_singular;

  unless(defined $spec->{'column_map'})
  {
    my @pk_columns = $meta->primary_key_column_names;
    return  unless(@pk_columns == 1);

    my @fpk_columns = $meta->primary_key_column_names;
    return  unless(@fpk_columns == 1);

    my $f_meta = $spec->{'class'}->meta;

    my $aliases = $f_meta->column_aliases;

    if($f_meta->column($l_col_name))
    {
      $spec->{'column_map'} = { $pk_columns[0] => $l_col_name };
    }
    elsif($f_meta->column("${l_col_name}_$pk_columns[0]"))
    {
      $spec->{'column_map'} = { $pk_columns[0] => "${l_col_name}_$pk_columns[0]" };
    }
    else { return }
  }

  return $rel_class->new(name => $name, %$spec);
}

sub auto_relationship_many_to_many
{
  my($self, $name, $rel_class, $spec) = @_;

  $spec ||= {};

  my $meta = $self->meta;

  unless($spec->{'map_class'})
  {
    my $class = $meta->class;

    # Given:
    #   Class: My::Object
    #   Rel name: other_objects
    #   Foreign class: My::OtherObject
    #
    # Consider map class names:
    #   My::ObjectsOtherObjectsMap
    #   My::ObjectOtherObjectMap
    #   My::OtherObjectsObjectsMap
    #   My::OtherObjectObjectMap
    #   My::ObjectsOtherObjects
    #   My::ObjectOtherObjects
    #   My::OtherObjectsObjects
    #   My::OtherObjectObjects
    #   My::OtherObjectMap
    #   My::OtherObjectsMap
    #   My::ObjectMap
    #   My::ObjectsMap

    my $prefix = $self->class_prefix($class);

    my @consider;

    my $f_class_suffix    = $self->table_to_class($name);
    my $f_class_suffix_pl = $self->table_to_class_plural($name);

    $class =~ /(\w+)$/;
    my $class_suffix = $1;
    my $class_suffix_pl = $self->singular_to_plural($class_suffix);

    push(@consider, map { "${prefix}$_" }
         $class_suffix_pl . $f_class_suffix_pl . 'Map',
         $class_suffix . $f_class_suffix . 'Map',

         $f_class_suffix_pl . $class_suffix_pl . 'Map',
         $f_class_suffix . $class_suffix . 'Map',

         $class_suffix_pl . $f_class_suffix_pl,
         $class_suffix . $f_class_suffix_pl,

         $f_class_suffix_pl . $class_suffix_pl,
         $f_class_suffix . $class_suffix_pl,

         $f_class_suffix . 'Map',
         $f_class_suffix_pl . 'Map',

         $class_suffix . 'Map',
         $class_suffix_pl . 'Map');

    my $map_class;

    CLASS: foreach my $class (@consider)
    {
      LOAD:
      {
        # Try to load class
        no strict 'refs';
        if(UNIVERSAL::isa($class, 'Rose::DB::Object'))
        {
          $map_class = $class;
          last CLASS;
        }
        else
        {
          local $@;
          eval "require $class";

          unless($@)
          {
            $map_class = $class;
            last CLASS  if(UNIVERSAL::isa($class, 'Rose::DB::Object'));
          }
        }
      }
    }

    return  unless($map_class && UNIVERSAL::isa($map_class, 'Rose::DB::Object'));

    $spec->{'map_class'} = $map_class;
  }

  return $rel_class->new(name => $name, %$spec);
}

1;

__END__

=head1 NAME

Rose::DB::Object::ConventionManager - Provide missing metadata by convention.

=head1 SYNOPSIS

  package My::Product;

  use base 'Rose::DB::Object';

  __PACKAGE__->meta->setup(columns => [ ... ]);

  # No table is set above, but look at this: the
  # convention manager provided one for us.
  print __PACKAGE__->meta->table; # "products"

  ##
  ## See the EXAMPLE section below for a more complete demonstration.
  ##

=head1 DESCRIPTION

Each L<Rose::DB::Object>-derived object has a L<convention manager|Rose::DB::Object::Metadata/convention_manager> that it uses to fill in missing L<metadata|Rose::DB::Object/meta>.  The convention manager encapsulates a set of rules (conventions) for generating various pieces of metadata in the absence of explicitly specified values: table names, column names, etc.

Each L<Rose::DB::Object>-derived class's convention manager object is stored in the L<convention_manager|Rose::DB::Object::Metadata/convention_manager> attribute of its L<Rose::DB::Object::Metadata> (L<meta|Rose::DB::Object/meta>) object.  L<Rose::DB::Object::ConventionManager> is the default convention manager class.

The object method documentation below describes both the purpose of each convention manager method and the particular rules that L<Rose::DB::Object::ConventionManager> follows to fulfill that purpose.  Subclasses must honor the purpose of each method, but are free to use any rules they choose.

B<Note well:> When reading the descriptions of the rules used by each convention manager method below, remember that only values that are I<missing> will be set by the convention manager.  Explicitly providing a value for a piece of metadata obviates the need for the convention manager to generate one.

If insufficient information is available, or if the convention manager simply declines to fulfill a request, undef may be returned from any metadata-generating method.

In the documentation, the adjectives "local" and "foreign" are used to distinguish between the things that belong to the convention manager's L<class|/class> and the class on "the other side" of the inter-table relationship, respectively.

=head1 SUMMARY OF DEFAULT CONVENTIONS

Although the object method documentation below includes all the information required to understand the default conventions, it's also quite spread out.  What follows is a summary of the default conventions.  Some details have necessarily been omitted or simplified for the sake of brevity, but this summary should give you a good starting point for further exploration.

Here's a brief summary of the default conventions as implemented in L<Rose::DB::Object::ConventionManager>.

=over 4

=item B<Table, column, foreign key, and relationship names are lowercase, with underscores separating words.>

Examples:  C<products>, C<street_address>, C<date_created>, C<vendor_id>.

=item B<Table names are plural.>

Examples: C<products>, C<vendors>, C<codes>, C<customer_details>, C<employee_addresses>.

(This convention can be overridden via the L<tables_are_singular|/tables_are_singular> method.)

=item B<Class names are singular, title-cased, with nothing separating words.>

Examples: C<Product>, C<Vendor>, C<Code>, C<CustomerDetail>, C<EmployeeAddress>.

=item B<Primary key column names do not contain the table name.>

For example, the primary key column name in the C<products> table might be C<id> or C<sku>, but should B<not> be C<product_id> or C<product_sku>.

=item B<Foreign key column names are made from the singular version of the foreign table's name joined (with an underscore) to the foreign table's key column name.>

Examples: C<product_sku>, C<vendor_id>, C<employee_address_id>.

=item B<One-to-one and many-to-one relationship names are singular.>

Examples: C<product>, C<vendor>, C<code>.  These relationships may point to zero or one foreign object.  The default method names generated from such relationships are based on the relationship names, so singular names make the most sense.

=item B<One-to-many and many-to-many relationship names are plural.>

Examples: C<colors>, C<prices>, C<customer_details>.  These relationships may point to more than one foreign object.  The default method names generated from such relationships are based on the relationship names, so plural names make the most sense.

=item B<Mapping tables and their associated classes that participate in many-to-many relationships are named according a formula that combines the names of the two classes/tables that are being linked.>

See the L<auto_relationship|/auto_relationship>, L<looks_like_map_class|/looks_like_map_class>, and L<looks_like_map_table|/looks_like_map_table> documentation for all the details. 

=back

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Constructs a new object based on PARAMS, where PARAMS are
name/value pairs.  Any object attribute is a valid parameter name.

=back

=head1 OBJECT METHODS

=over 4

=item B<auto_column_method_name TYPE, COLUMN, NAME, OBJECT_CLASS>

Given a L<Rose::DB::Object::Metadata::Column> column L<type|Rose::DB::Object::Metadata::Column/type>, a L<Rose::DB::Object::Metadata::Column> object or column name, a default method name, and a L<Rose::DB::Object>-derived class name, return an appropriate method name.  The default implementation simply returns undef, relying on the hard-coded default method-type-to-name mapping implemented in L<Rose::DB::Object::Metadata>'s  L<method_name_from_column|Rose::DB::Object::Metadata/method_name_from_column> method.

=item B<auto_foreign_key NAME [, SPEC]>

Given a L<foreign key|Rose::DB::Object::Metadata/foreign_key> name and an optional reference to a hash SPEC of the type passed to L<Rose::DB::Object::Metadata>'s L<add_foreign_keys|Rose::DB::Object::Metadata/add_foreign_keys> method, return an appropriately constructed L<Rose::DB::Object::Metadata::ForeignKey> object.  

The foreign key's L<class name|Rose::DB::Object::Metadata::ForeignKey/class> is generated by calling L<related_table_to_class|/related_table_to_class>, passing NAME and the convention manager's L<class|/class> as arguments.  An attempt is made is load the class.  If this fails, the foreign key's L<class name|Rose::DB::Object::Metadata::ForeignKey/class> is not set.

The foreign key's L<key_columns|Rose::DB::Object::Metadata::ForeignKey/key_columns> are only set if both the "local" and "foreign" tables have single-column primary keys.  The foreign class's primary key column name is used as the foreign column in the  L<key_columns|Rose::DB::Object::Metadata::ForeignKey/key_columns> map.  If there is a local column with the same name as the foreign key name, and if that column is aliased (making way for the foreign key method to use that name), then that is used as the local column.  If not, then the local column name is generated by joining the foreign key name and the foreign class's primary key column name with an underscore.  If no column by that name exists, then the search is abandoned.  Example:

Given these pieces:

    Name        Description                        Value
    ---------   --------------------------------   -------
    NAME        Foreign key name                   vendor
    FCLASS      Foreign class                      My::Vendor
    FPK         Foreign primary key column name    id

Consider column maps in this order:

    Value                   Formula                         
    ---------------------   ----------------------
    { vendor => 'id' }      { NAME => FPK }
    { vendor_id => 'id' }   { <NAME>_<FPK> => FPK }

=item B<auto_foreign_key_name FOREIGN_CLASS, CURRENT_NAME, KEY_COLUMNS, USED_NAMES>

Given the name of a foreign class, the current foreign key name (if any), a reference to a hash of L<key columns|Rose::DB::Object::Metadata::ForeignKey/key_columns>, and a reference to a hash whose keys are foreign key names already used in this class, return a L<name|Rose::DB::Object::Metadata::ForeignKey/name> for the foreign key.

If there is more than one pair of columns in KEY_COLUMNS, then the name is generated by calling L<plural_to_singular|/plural_to_singular>, passing the L<table|Rose::DB::Object::Metadata/table> name of the foreign class.  The CURRENT_NAME is used if the call to L<plural_to_singular|/plural_to_singular> does not return a true value.

If there is just one pair of columns in KEY_COLUMNS, and if the name of the local column ends with an underscore and the name of the referenced column, then that part of the column name is removed and the remaining string is used as the foreign key name.  For example, given the following tables:

    CREATE TABLE categories
    (
      id  SERIAL PRIMARY KEY,
      ...
    );

    CREATE TABLE products
    (
      category_id  INT REFERENCES categories (id),
      ...
    );

The foreign key name would be "category", which is the name of the referring column ("category_id") with an underscore and the name of the referenced column ("_id") removed from the end of it.

If the foreign key has only one column, but it does not meet the criteria described above, then the name is generated by calling L<plural_to_singular|/plural_to_singular>, passing the L<table|Rose::DB::Object::Metadata/table> name of the foreign class.  The CURRENT_NAME is used if the call to L<plural_to_singular|/plural_to_singular> does not return a true value.

If the name selected using the above techniques is in the USED_NAMES hash, or is the same as that of an existing or potential method in the target class, then the suffixes "_obj" and "_object" are tried in that order.  If neither of those suffixes resolves the situation, then ascending numeric suffixes starting with "1" are tried until a unique name is found.

=item B<auto_manager_base_name TABLE, CLASS>

Given a table name and the name of the L<Rose::DB::Object>-derived class that fronts it, return a base name suitable for use as the value of the C<base_name> parameter to L<Rose::DB::Object::Manager>'s L<make_manager_methods|Rose::DB::Object::Manager/make_manager_methods> method.  

If no table is specified then the table name is derived from the current class
name by calling L<class_to_table_plural|/class_to_table_plural>.

If L<tables_are_singular|/tables_are_singular> is true, then TABLE is passed to the L<singular_to_plural|/singular_to_plural> method and the result is returned.  Otherwise, TABLE is returned as-is.

=item B<auto_manager_base_class>

Return the class that all manager classes will default to inheriting from.  By
default this will be L<Rose::DB::Object::Manager>.

=item B<auto_manager_class_name CLASS>

Given the name of a L<Rose::DB::Object>-derived class, returns a class name for a L<Rose::DB::Object::Manager>-derived class to manage such objects.  The default implementation simply appends "::Manager" to the L<Rose::DB::Object>-derived class name.

=item B<auto_manager_method_name TYPE, BASE_NAME, OBJECT_CLASS>

Given the specified L<Rose::DB::Object::Manager> L<method type|Rose::DB::Object::Manager/make_manager_methods>,
L<base name|Rose::DB::Object::Manager/make_manager_methods>, and L<object class|Rose::DB::Object::Manager/object_class> return an appropriate L<manager|Rose::DB::Object::Manager> method name.  The default implementation simply returns undef, relying on the hard-coded default method-type-to-name mapping implemented in L<Rose::DB::Object::Manager>'s  L<make_manager_methods|Rose::DB::Object::Manager/make_manager_methods> method.

=item B<auto_relationship_name_many_to_many FK, MAPCLASS>

Return the name of a "many to many" relationship that fetches objects from the table pointed to by the L<Rose::DB::Object::Metadata::ForeignKey> object FK by going through the class MAPCLASS.

The default implementation passes the name of the table pointed to by FK through the L<singular_to_plural|/singular_to_plural> method in order to build the name.

If the selected name is the name of an existing or potential method in the target class, then the suffixes "_objs" and "_objects" are tried in that order.  If neither of those suffixes resolves the situation, then ascending numeric suffixes starting with "1" are tried until a unique name is found.

=item B<auto_relationship_name_one_to_many TABLE, CLASS>

Return the name of a "one to many" relationship that fetches objects from the specified TABLE and CLASS.

If L<tables_are_singular|/tables_are_singular> is true, then TABLE is passed to the L<singular_to_plural|/singular_to_plural> method and the result is used as the name.  Otherwise, TABLE is used as-is.

If the selected name is the name of an existing or potential method in the target class, then the suffixes "_objs" and "_objects" are tried in that order.  If neither of those suffixes resolves the situation, then ascending numeric suffixes starting with "1" are tried until a unique name is found.

=item B<auto_relationship_name_one_to_one TABLE, CLASS>

Return the name of a "one to one" relationship that fetches an object from the specified TABLE and CLASS.  The default implementation returns a singular version of the table name.

If the selected name is the name of an existing or potential method in the target class, then the suffixes "obj_" and "_object" are tried in that order.  If neither of those suffixes resolves the situation, then ascending numeric suffixes starting with "1" are tried until a unique name is found.

=item B<auto_primary_key_column_names>

Returns a reference to an array of primary key column names.

If a column named "id" exists, it is selected as the sole primary key column name.  If not, the column name generated by joining the return value of L<class_to_table_singular|/class_to_table_singular> with "_id" is considered.  If no column with that name exists, then the first column (sorted alphabetically) whose L<type|Rose::DB::Object::Metadata::Column/type> is "serial" is selected.  If all of the above fails, then the L<first column|Rose::DB::Object::Metadata/first_column> is selected as the primary key column (assuming one exists).

Examples:

    My::A->meta->columns(qw(a a_id id));
    print My::A->meta->primary_key_columns; # "id"

    My::B->meta->columns(qw(b b_id foo));
    print My::B->meta->primary_key_columns; # "a_id"

    My::D->meta->columns
    (
      cnt  => { type => 'int' }, 
      dub  => { type => 'serial' }, 
      foo  => { type => 'serial'},
      a_id => { type => 'int' }
    )

    print My::D->meta->primary_key_columns; # "dub"

    My::C->meta->columns(qw(foo bar baz));
    print My::C->meta->primary_key_columns; # "foo"

=item B<auto_relationship NAME, RELATIONSHIP_CLASS [, SPEC]>

Given a L<relationship|Rose::DB::Object::Metadata/relationship> name, a L<Rose::DB::Object::Metadata::Relationship>-derived class name, and an optional reference to a hash SPEC of the type passed to L<Rose::DB::Object::Metadata>'s L<add_relationships|Rose::DB::Object::Metadata/add_relationships> method, return an appropriately constructed L<Rose::DB::Object::Metadata::Relationship>-derived object.  

If the relationship's L<type|Rose::DB::Object::Metadata::Relationship/type> is "one to one" or "many to one", then the relationship's L<class name|Rose::DB::Object::Metadata::Relationship/class> is generated by calling L<related_table_to_class|/related_table_to_class>, passing NAME and the convention manager's L<class|/class> as arguments.  An attempt is made is load the class.  If this fails, the relationship's L<class name|Rose::DB::Object::Metadata::Relationship/class> is not set.

The L<column map|Rose::DB::Object::Metadata::Relationship::OneToOne/column_map> for "one to one" and "many to one" relationships is generated using the same rules used to generate L<key_columns|Rose::DB::Object::Metadata::ForeignKey/key_columns> in the L<auto_foreign_key|/auto_foreign_key> method.

If the relationship's L<type|Rose::DB::Object::Metadata::Relationship/type> is "one to many" then the relationship's L<class name|Rose::DB::Object::Metadata::Relationship/class> is generated by calling L<plural_to_singular|/plural_to_singular> on NAME, then passing that value along with the convention manager's L<class|/class> to the L<related_table_to_class|/related_table_to_class> method.  An attempt is made is load the class.  If this fails, the relationship's L<class name|Rose::DB::Object::Metadata::Relationship/class> is not set.

The L<column map|Rose::DB::Object::Metadata::Relationship::OneToMany/column_map> for a "one to many" relationship is only set if both the "local" and "foreign" tables have single-column primary keys.  The following ordered list of combinations is considered.

Given:

   Local class:   My::Product
   Foreign class: My::Price
   Relationship:  prices

Generate these pieces:

    Name        Description                         Value
    ---------   ---------------------------------   -------
    LTABLE_S    Local class_to_table_singular()     product
    LPK         Local primary key column name       id
    FPK         Foreign primary key column name     id

Consider column maps in this order:

    Value                     Formula                         
    ----------------------    --------------------------
    { id => 'product' }       { LPK => LTABLE_S }
    { id => 'product_id' }    { LPK => <LTABLE_S>_<PK> }

The first value whose foreign column actually exists in the foreign table is chosen.

If the relationship's L<type|Rose::DB::Object::Metadata::Relationship/type> is "many to many" then the relationship's L<map_class|Rose::DB::Object::Metadata::Relationship/map_class> is chosen from a list of possibilities.  This list is generated by constructing singular and plural versions of the local and foreign class names (sans prefixes) and then joining them in various ways, all re-prefixed by the L<class prefix|/class_prefix> of the convention manager's L<class|/class>.  Example:

Given:

   Local class:   My::Product
   Foreign class: My::Color
   Relationship:  colors

Generate these pieces:

    Name        Description                         Value
    ---------   ---------------------------------   -------
    PREFIX      Local class prefix                  My::
    LCLASS_S    Unprefixed local class, singular    Product
    LCLASS_P    Unprefixed local class, plural      Products
    FCLASS_S    Unprefixed foreign class, singular  Color
    FCLASS_P    Unprefixed foreign class, plural    Colors

Consider map class names in this order:

    Value                   Formula                         
    ---------------         ---------------------           
    My::ProductsColorsMap   <PREFIX><LCLASS_P><FCLASS_P>Map 
    My::ProductColorMap     <PREFIX><LCLASS_S><FCLASS_S>Map 
    My::ColorsProductsMap   <PREFIX><FCLASS_P><LCLASS_P>Map 
    My::ColorProductMap     <PREFIX><FCLASS_S><LCLASS_S>Map 
    My::ProductsColors      <PREFIX><LCLASS_P><FCLASS_P>
    My::ProductColors       <PREFIX><LCLASS_S><FCLASS_P>
    My::ColorsProducts      <PREFIX><FCLASS_P><LCLASS_P>
    My::ColorProducts       <PREFIX><FCLASS_S><LCLASS_P>
    My::ColorMap            <PREFIX><FCLASS_S>Map 
    My::ColorsMap           <PREFIX><FCLASS_P>Map 
    My::ProductMap          <PREFIX><LCLASS_S>Map 
    My::ProductsMap         <PREFIX><LCLASS_P>Map 

The first class found that inherits from L<Rose::DB::Object> and is loaded successfully will be chosen as the relationship's L<map_class|Rose::DB::Object::Metadata::Relationship/map_class>.

=item B<auto_table_name>

Returns a table name for the convention manager's L<class|/class>.

Class names are singular and table names are plural.  To build the table name, the L<class prefix|/class_prefix> is removed from the L<class name|/class>, transitions from lowercase letters or digits to uppercase letters have underscores inserted, and the whole thing is converted to lowercase.

Examples:

    Class         Table
    -----------   --------
    Product       products
    My::Product   products
    My::BigBox    big_boxes
    My5HatPig     my5_hat_pig

=item B<class [CLASS]>

Get or set the L<Rose::DB::Object>-derived class that this convention manager belongs to.

=item B<class_prefix CLASS>

Given a class name, return the prefix, if any, before the last component of the namespace, including the final "::".  If there is no prefix, an empty string is returned.

Examples:

    Class         Prefix
    -----------   --------------
    Product       <empty string>
    My::Product   My::
    A::B::C::D    A::B::C::

=item B<class_to_table_plural [CLASS]>

Given a class name, or the convention manager's L<class|/class> if omitted, return a plural version of the corresponding table name.

To do this, the output of the L<class_to_table_singular|/class_to_table_singular> method is passed to a call to the L<singular_to_plural|/singular_to_plural> method.  (The CLASS argument, if any, is passed to the call to L<class_to_table_singular|/class_to_table_singular>.)

Examples:

    Class         Table
    -----------   --------
    Product       products
    My::Product   products
    My::Box       boxes

=item B<class_to_table_singular [CLASS]>

Given a class name, or the convention manager's L<class|/class> if omitted, return a singular version of the corresponding table name.

Examples:

    Class         Table
    -----------   --------
    Product       product
    My::Product   product
    My::Box       box

=item B<force_lowercase [BOOL]>

Get or set a boolean value that indicates whether or not L<metadata|Rose::DB::Object::Metadata> entity names should be forced to lowercase even when the related entity is uppercase or mixed case.  ("Metadata entities" are thing like L<columns|Rose::DB::Object::Metadata/columns>, L<relationships|Rose::DB::Object::Metadata/relationships>, and L<foreign keys|Rose::DB::Object::Metadata/foreign_keys>.)  The default value is false.

=item B<is_map_class CLASS>

Returns true if CLASS is a L<map class|Rose::DB::Object::Metadata::Relationship::ManyToMany/map_class> used as part of a L<many to many|Rose::DB::Object::Metadata::Relationship::ManyToMany> relationship, false if it does not.

The default implementations returns true if CLASS is derived from L<Rose::DB::Object> and its L<table|Rose::DB::Object::Metadata/table> name looks like a map table name according to the L<looks_like_map_table|/looks_like_map_table> method and the L<looks_like_map_class|/looks_like_map_class> method returns either true or undef.

Override this method to control which classes are considered map classes.  Note that it may be called several times on the same class at various stages of that class's construction.

=item B<looks_like_map_class CLASS>

Given the class name CLASS, returns true if it looks like the name of a L<map class|Rose::DB::Object::Metadata::Relationship::ManyToMany/map_class> used as part of a L<many to many|Rose::DB::Object::Metadata::Relationship::ManyToMany> relationship, false (but defined) if it does not, and undef if it's unsure.

The default implementation returns true if CLASS is derived from L<Rose::DB::Object> and has exactly two foreign keys.  It returns false (but defined) if CLASS is derived from L<Rose::DB::Object> and has been L<initialized|Rose::DB::Object/initialize> (or if the foreign keys have been L<auto-initialized|Rose::DB::Object/auto_init_foreign_keys>) and the CLASS has no deferred foreign keys.  It returns undef otherwise.

=item B<looks_like_map_table TABLE>

Returns true if TABLE looks like the name of a mapping table used as part of a L<many to many|Rose::DB::Object::Metadata::Relationship::ManyToMany> relationship, false (but defined) if it does not, and undef if it's unsure.

The default implementation returns true if TABLE is in one of these forms:

    Regex                     Examples
    -----------------------   -----------------------------
    (\w+_){2,}map             pig_toe_map, pig_skin_toe_map
    (\w+_)*\w+_(\w+_)*\w+s    pig_toes, pig_skin_toe_jams
    (\w+_)*\w+s_(\w+_)*\w+s   pigs_toes, pig_skins_toe_jams

It returns false otherwise.

=item B<meta [META]>

Get or set the L<Rose::DB::Object::Metadata> object associated with the class that this convention manager belongs to.

=item B<plural_to_singular STRING>

Returns the singular version of STRING.  If a L<plural_to_singular_function|/plural_to_singular_function> is defined, then this method simply passes STRING to that function.

Otherwise, the following rules are applied, case-insensitively.  

* If STRING ends in "ies", then the "ies" is replaced with "y".

* If STRING ends in "ses" then the "ses" is replaced with "s".

* If STRING matches C</[aeiouy]ss$/i>, it is returned unmodified.

For all other cases, the letter "s" is removed from the end of STRING and the result is returned.

=item B<plural_to_singular_function [CODEREF]>

Get or set a reference to the function used to convert strings to singular.  The function should take a single string as an argument and return a singular version of the string.  This function is undefined by default.

=item B<related_table_to_class TABLE, LOCAL_CLASS>

Given a table name and a local class name, return the name of the related class that fronts the table.

To do this, L<table_to_class|/table_to_class> is called with TABLE and the L<class_prefix|/class_prefix> of LOCAL_CLASS passed as arguments.

Examples:

    Table         Local Class     Related Class
    -----------   ------------    ----------------
    prices        My::Product     My::Price
    big_hats      A::B::FooBar    A::B::BigHat
    a1_steaks     Meat            A1Steak

=item B<singular_to_plural STRING>

Returns the plural version of STRING.  If a L<singular_to_plural_function|/singular_to_plural_function> is defined, then this method simply passes STRING to that function.  Otherwise, the following rules are applied, case-insensitively, to form the plural.

* If STRING ends in "x", "ss", or "es", then "es" is appended.

* If STRING ends in "y" then the "y" is replaced with "ies".

* If STRING ends in "s" then it is returned as-is.

* Otherwise, "s" is appended.

=item B<singular_to_plural_function [CODEREF]>

Get or set a reference to the function used to convert strings to plural.  The function should take a single string as an argument and return a plural version of the string.  This function is undefined by default.

=item B<table_singular>

Let TABLE be the return value of the L<table|Rose::DB::Object::Metadata/table> method called on the L<meta|/meta> attribute of this object.

If L<tables_are_singular|/tables_are_singular> is true, then TABLE is returned as-is.  Otherwise, TABLE is passed to the L<plural_to_singular|/plural_to_singular> method and the result is returned.  Otherwise, TABLE is returned as-is.

=item B<table_plural>

Let TABLE be the return value of the L<table|Rose::DB::Object::Metadata/table> method called on the L<meta|/meta> attribute of this object.

If L<tables_are_singular|/tables_are_singular> is true, then TABLE is passed to the L<singular_to_plural|/singular_to_plural> method and the result is returned.  Otherwise, TABLE is returned as-is.

=item B<table_to_class TABLE [, PREFIX]>

Given a table name and an optional class prefix, return the corresponding class name.  The prefix will be appended to the class name, if present.  The prefix should end in "::".

To do this, any letter that follows an underscore ("_") in the table name is replaced with an uppercase version of itself, and the underscore is removed.

Examples:

    Table         Prefix   Class
    -----------   ------   -----------
    products      My::     My::Product
    products      <none>   Product
    big_hats      My::     My::BigHat
    my5_hat_pig   <none>   My5HatPig

=item B<tables_are_singular [BOOL]>

Get or set a boolean value that indicates whether or not table names are expected to be singular.  The default value is false, meaning that table names are expected to be plural.

=back

=head1 PROTECTED API

These methods are not part of the public interface, but are supported for use by subclasses.  Put another way, given an unknown object that "isa" L<Rose::DB::Object::Metadata::ConventionManager>, there should be no expectation that the following methods exist.  But subclasses, which know the exact class from which they inherit, are free to use these methods in order to implement the public API described above.

=over 4

=item B<init_plural_to_singular_function>

Override this method and return a reference to a function that takes a single string as an argument and returns a singular version of that string.

=item B<init_singular_to_plural_function>

Override this method and return a reference to a function that takes a single string as an argument and returns a plural version of that string.

=back

=head1 TIPS AND TRICKS

Much of the richness of a convention manager relies upon the quality of the L<singular_to_plural|/singular_to_plural> and L<plural_to_singular|/plural_to_singular> methods.  The default implementations are primitive at best.  For example,  L<singular_to_plural|/singular_to_plural> will not correctly form the plural of the word "alumnus".

One easy way to improve this is by setting a custom L<singular_to_plural_function|/singular_to_plural_function>.  Here's an example using the handy L<Lingua::EN::Inflect> module:

    package My::Product;
    ...
    use Lingua::EN::Inflect;
    $cm = __PACKAGE__->meta->convention_manager;

    $cm->singular_to_plural_function(\&Lingua::EN::Inflect::PL);

    print $cm->singular_to_plural('person'); # "people"

But that's a bit of a pain to do in every single class.  An easier way to do it for all of your classes is to make a new L<Rose::DB::Object::Metadata> subclass that overrides the L<init_convention_manager|Rose::DB::Object::Metadata/init_convention_manager> method, then make a L<Rose::DB::Object>-derived base class that uses your new metadata class.  Example:

    package My::DB::Metadata;

    use Rose::DB::Object::Metadata;
    our @ISA = qw(Rose::DB::Object::Metadata);

    use Lingua::EN::Inflect;

    sub init_convention_manager
    {
      my $self = shift;

      # Let the base class make ths convention manager object
      my $cm = $self->SUPER::init_convention_manager(@_);

      # Set the new singular-to-plural function
      $cm->singular_to_plural_function(\&Lingua::EN::Inflect::PL);

      # Return the modified convention manager
      return $cm;
    }

    ...

    package My::DB::Object;

    use My::DB::Metadata;

    use Rose::DB::Object;
    our @ISA = qw(Rose::DB::Object); 

    sub meta_class { 'My::DB::Metadata' }

    ...

    package My::Person;

    use My::DB::Object;
    our @ISA = qw(My::DB::Object); 

    # The big pay-off: smart plurals!
    print __PACKAGE__->meta->table; # "people"

You might wonder why I don't use L<Lingua::EN::Inflect> in L<Rose::DB::Object::ConventionManager> to save you this effort.  The answer is that the L<Lingua::EN::Inflect> module adds almost a megabyte of memory overhead on my system.  I'd rather not incur that overhead just for the sake of being more clever about naming conventions.  Furthermore, as primitive as the default plural-forming is, at least it's deterministic.  Guessing what L<Lingua::EN::Inflect> will return is not always easy, and the results can change depending on which version L<Lingua::EN::Inflect> you have installed.

=head1 EXAMPLE

Here's a complete example of nearly all of the major features of L<Rose::DB::Object::ConventionManager>.  Let's start with the database schema.  (This example uses PostgreSQL, but any L<supported database|Rose::DB/"DATABASE SUPPORT"> with native foreign key support will work.)

  CREATE TABLE vendors
  (
    id    SERIAL NOT NULL PRIMARY KEY,
    name  VARCHAR(255)
  );

  CREATE TABLE colors
  (
    code  CHAR(3) NOT NULL PRIMARY KEY,
    name  VARCHAR(255)
  );

  CREATE TABLE products
  (
    id        SERIAL NOT NULL PRIMARY KEY,
    name      VARCHAR(255),
    vendor_id INT NOT NULL REFERENCES vendors (id)
  );

  CREATE TABLE prices
  (
    price_id    SERIAL NOT NULL PRIMARY KEY,
    product_id  INT NOT NULL REFERENCES products (id),
    region      CHAR(2) NOT NULL DEFAULT 'US',
    price       DECIMAL(10,2) NOT NULL
  );

  CREATE TABLE product_colors
  (
    id           SERIAL NOT NULL PRIMARY KEY,
    product_id   INT NOT NULL REFERENCES products (id),
    color_code   CHAR(3) NOT NULL REFERENCES colors (code)
  );

Now the classes:

  # Rose::DB subclass to handle the db connection
  package My::DB;

  use base 'Rose::DB';

  My::DB->register_db
  (
    type     => 'default',
    domain   => 'default',
    driver   => 'Pg',
    database => 'test',
    username => 'postgres',
  );

  ...

  # Common Rose::DB::Object-derived base class for the other objects
  package My::Object;

  use My::DB;

  use base 'Rose::DB::Object';

  sub init_db { My::DB->new }

  ...

  package My::Price;

  use base 'My::Object';

  __PACKAGE__->meta->setup
  (
    columns =>
    [
      price_id   => { type => 'serial', not_null => 1 },
      product_id => { type => 'int' },
      region     => { type => 'char', length => 2, default => 'US' },
      price      => { type => 'decimal', precision => 10, scale => 2 },
    ],

    foreign_keys => [ 'product' ],
  );

  ...

  package My::Vendor;

  use base 'My::Object';

  __PACKAGE__->meta->setup
  (
    columns =>
    [
      id    => { type => 'serial', not_null => 1 },
      name  => { type => 'varchar', length => 255 },
    ],
  );

  ...

  package My::Color;

  use base 'My::Object';

  __PACKAGE__->meta->setup
  (
    columns =>
    [
      code => { type => 'char', length => 3, not_null => 1 },
      name => { type => 'varchar', length => 255 },
    ],
  );

  ...

  package My::Product;

  use base 'My::Object';

  __PACKAGE__->meta->setup
  (
    columns =>
    [
      id        => { type => 'serial', not_null => 1 },
      name      => { type => 'varchar', length => 255 },
      vendor_id => { type => 'int' },
    ],

    foreign_keys => [ 'vendor' ],

    relationships =>
    [
      prices => { type => 'one to many' },
      colors => { type => 'many to many' },
    ],
  );

  ...

  package My::ProductColors;

  use base 'My::Object';

  __PACKAGE__->meta->setup
  (
    columns      => [ qw(id product_id color_code) ],
    foreign_keys => [ 'product', 'color' ],
  );

Let's add some data:

  INSERT INTO vendors (id, name) VALUES (1, 'V1');
  INSERT INTO vendors (id, name) VALUES (2, 'V2');

  INSERT INTO products (id, name, vendor_id) VALUES (1, 'A', 1);
  INSERT INTO products (id, name, vendor_id) VALUES (2, 'B', 2);
  INSERT INTO products (id, name, vendor_id) VALUES (3, 'C', 1);

  INSERT INTO prices (product_id, region, price) VALUES (1, 'US', 1.23);
  INSERT INTO prices (product_id, region, price) VALUES (1, 'DE', 4.56);
  INSERT INTO prices (product_id, region, price) VALUES (2, 'US', 5.55);
  INSERT INTO prices (product_id, region, price) VALUES (3, 'US', 5.78);
  INSERT INTO prices (product_id, region, price) VALUES (3, 'US', 9.99);

  INSERT INTO colors (code, name) VALUES ('CC1', 'red');
  INSERT INTO colors (code, name) VALUES ('CC2', 'green');
  INSERT INTO colors (code, name) VALUES ('CC3', 'blue');
  INSERT INTO colors (code, name) VALUES ('CC4', 'pink');

  INSERT INTO product_colors (product_id, color_code) VALUES (1, 'CC1');
  INSERT INTO product_colors (product_id, color_code) VALUES (1, 'CC2');

  INSERT INTO product_colors (product_id, color_code) VALUES (2, 'CC4');

  INSERT INTO product_colors (product_id, color_code) VALUES (3, 'CC2');
  INSERT INTO product_colors (product_id, color_code) VALUES (3, 'CC3');

(Be aware that not all databases are smart enough to track explicitly setting serial column values as shown in the INSERT statements above.  Subsequent auto-generated serial values may conflict with the explicitly set serial column values already in the table.  Values are set explicitly here to make the examples easier to follow.  In "real" code, you should let the serial columns populate automatically.) 

Finally, the classes in action:

  $p = My::Product->new(id => 1)->load;

  print $p->vendor->name, "\n"; # "V1"

  # "US: 1.23, DE: 4.56"
  print join(', ', map { $_->region .': '. $_->price } $p->prices), "\n";

  # "red, green"
  print join(', ', map { $_->name } $p->colors), "\n";

=head1 AUTO-INIT EXAMPLE

Using L<Rose::DB::Object>'s L<auto-initialization|Rose::DB::Object::Metadata/"AUTO-INITIALIZATION"> feature, the Perl code can be reduced to an  absurd degree.  Given the same database schema and data shown in the L<example|/EXAMPLE> above, consider the following classes:

  package My::Auto::Color;
  use base 'My::Object';
  __PACKAGE__->meta->auto_initialize;
  ...

  package My::Auto::Price;
  use base 'My::Object';
  __PACKAGE__->meta->auto_initialize;
  ...

  package My::Auto::ProductColors;
  use base 'My::Object';
  __PACKAGE__->meta->auto_initialize;
  ...

  package My::Auto::Vendor;
  use base 'My::Object';
  __PACKAGE__->meta->auto_initialize;
  ...

  package My::Auto::Product;
  use base 'My::Object';
  __PACKAGE__->meta->auto_initialize;

Not a single table, column, foreign key, or relationship is specified, yet everything still works:

  $p = My::Auto::Product->new(id => 1)->load;

  print $p->vendor->name, "\n"; # "V1"

  # "US: 1.23, DE: 4.56"
  print join(', ', map { $_->region .': '. $_->price } $p->prices), "\n";

  # "red, green"
  print join(', ', map { $_->name } $p->colors), "\n";

More precisely, everything still works I<provided> that you load all the of the related modules.  For example, if you load C<My::Auto::Product> but don't load C<My::Auto::Price> (either from within the C<My::Auto::Product> class or in your program itself), then the C<My::Auto::Product> will not have a C<prices()> method (since your program will have no knowledge of the C<My::Auto::Price> class).  Use the L<loader|Rose::DB::Object::Loader> if you want to set up a bunch of related classes automatically without worrying about this kind of thing.

Anyway, I don't recommend this kind of extreme approach, but it is an effective demonstration of the power of the convention manager.

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
