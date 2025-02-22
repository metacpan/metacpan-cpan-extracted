package Rose::DB::Object::Loader;

use strict;

use Cwd;
use File::Path;
use File::Spec;
use DBI;
use Carp;

use Rose::DB;
use Rose::DB::Object;
use Rose::DB::Object::ConventionManager;
use Rose::DB::Object::Metadata::Util qw(perl_hashref);
use Rose::DB::Object::Metadata::Auto;

use Rose::Object;
our @ISA = qw(Rose::Object);

our $VERSION = '0.799';

our $Debug = 0;

use Rose::Object::MakeMethods::Generic
(
  scalar =>
  [
    'db_catalog',
    'db_database',
    'db_schema',
    'db_username',
    'db_password',
    'db_options',
    'include_tables',
    'exclude_tables',
    'filter_tables',
    'pre_init_hook',
    'post_init_hook',
    'module_dir',
    'module_preamble',
    'module_postamble',
  ],

  'scalar --get_set_init' =>
  [
    'with_relationships',
  ],

  boolean => 
  [
    'using_default_base_class',
    'require_primary_key' => { default => 1 },
    'include_views'       => { default => 0 },
    'with_managers'       => { default => 1 },
    'with_foreign_keys'   => { default => 1 },
    'with_unique_keys'    => { default => 1 },
    'convention_manager_was_set'        => { default => 0 },
    'include_predicated_unique_indexes' => { default => 0 },
    'warn_on_missing_primary_key',
    'no_auto_sequences' => { default => 0 },
  ],
);

sub warn_on_missing_pk { shift->warn_on_missing_primary_key(@_) }

CHOOSE_CLONE:
{
  local $@;

  # Get the best available clone method
  eval 
  {
    require Scalar::Util::Clone;
    *clone = \&Scalar::Util::Clone::clone;
  };

  if($@)
  {
    require Clone;
    *clone = \&Clone::clone;
  }
}

sub init_with_relationships { 1 }

my $Base_Class_Counter = 1;

sub generate_object_base_class_name
{
  my($self) = shift;

  return ($self->class_prefix ?
          ($self->class_prefix . 'DB::Object::AutoBase') : 
          'Rose::DB::Object::LoaderGenerated::AutoBase') .
         $Base_Class_Counter++;
}

sub generate_db_base_class_name
{
  my($self) = shift;

  return ($self->class_prefix ?
          ($self->class_prefix . 'DB::AutoBase') : 
          'Rose::DB::LoaderGenerated::AutoBase') .
         $Base_Class_Counter++;
}

sub generate_manager_class_name
{
  my($self, $object_class, $cm) = @_;
  return $cm ? $cm->auto_manager_class_name($object_class) :
    $self->convention_manager->auto_manager_class_name($object_class);
}

sub base_classes
{
  my($self) = shift;

  unless(@_)
  {
    if(my $bc = $self->{'base_classes'})
    {
      return wantarray ? @$bc : $bc;
    }

    # Make new base class
    my $bc = $self->{'base_classes'} = [ $self->generate_object_base_class_name ];

    $self->using_default_base_class(1);

    no strict 'refs';
    @{"$bc->[0]::ISA"} = qw(Rose::DB::Object);

    return wantarray ? @$bc : $bc;
  }

  my $bc = shift;

  unless(ref $bc)
  {
    $bc = [ $bc ];
  }

  #my $found_rdbo = 0;

  foreach my $class (@$bc)
  {
    unless($class =~ /^(?:\w+::)*\w+$/)
    {
      croak "Illegal base class name: $class";
    }

    #$found_rdbo = 1  if(UNIVERSAL::isa($class, 'Rose::DB::Object'));
  }

  #unless($found_rdbo)
  #{
  #  croak "None of the base classes inherit from Rose::DB::Object";
  #}

  $self->using_default_base_class(0);
  $self->{'base_classes'} = $bc;

  return wantarray ? @$bc : $bc;
}

sub base_class { shift->base_classes(@_) }

use constant DEFAULT_MANAGER_BASE_CLASS => 'Rose::DB::Object::Manager';

sub manager_base_classes
{
  my($self) = shift;

  if(my $bc = shift)
  {
    unless(ref $bc)
    {
      $bc = [ $bc ];
    }

    #my $found_base = 0;

    foreach my $class (@$bc)
    {
      unless($class =~ /^(?:\w+::)*\w+$/)
      {
        croak "Illegal manager base class name: $class";
      }

      #$found_base = 1  if(UNIVERSAL::isa($class, 'Rose::DB::Object::Manager'));
    }

    #unless($found_base)
    #{
    #  croak "None of the manager base classes inherit from ",
    #        "Rose::DB::Object::Manager";
    #}

    $self->{'manager_base_classes'} = $bc;
  }

  my $bc = $self->{'manager_base_classes'};

  unless(defined $bc && @$bc)
  {
    return wantarray ? DEFAULT_MANAGER_BASE_CLASS : [ DEFAULT_MANAGER_BASE_CLASS ];
  }

  return wantarray ? @{$self->{'manager_base_classes'}} :
                     $self->{'manager_base_classes'}
}

sub manager_base_class { shift->manager_base_classes(@_) }

sub convention_manager
{
  my($self) = shift;

  if(@_)
  {
    my $cm = shift;

    if(ref $cm)
    {
      unless(UNIVERSAL::isa($cm, 'Rose::DB::Object::ConventionManager'))
      {
        croak "Not a Rose::DB::Object::ConventionManager-derived object: $cm";
      }

      $self->{'convention_manager'} = $cm;
    }
    else
    {
      unless(UNIVERSAL::isa($cm, 'Rose::DB::Object::ConventionManager'))
      {
        croak "Not a Rose::DB::Object::ConventionManager-derived class: $cm";
      }

      $self->{'convention_manager'} = $cm->new;
    }

    $self->convention_manager_was_set(1);
  }

  return $self->{'convention_manager'} ||= Rose::DB::Object::ConventionManager->new;
}

sub class_prefix
{
  my($self) = shift;

  return $self->{'class_prefix'}  unless(@_);

  my $class_prefix = shift;

  if(length $class_prefix)
  {
    unless($class_prefix =~ /^(?:\w+::)*\w+(?:::)?$/)
    {
      croak "Illegal class prefix: $class_prefix";
    }

    $class_prefix .= '::'  unless($class_prefix =~ /::$/);
  }

  return $self->{'class_prefix'} = $class_prefix;
}

sub force_lowercase
{
  my($self) = shift;

  if(@_)
  {
    my $value = shift;
    # Important: allow this attribute to be set to undef, unlike
    # most "normal" boolean attributes.
    return $self->{'force_lowercase'} = undef unless(defined $value);
    return $self->{'force_lowercase'} = $value ? 1 : 0;
  }

  return $self->{'force_lowercase'};
}

sub db
{
  my($self) = shift;

  return $self->{'db'}  unless(@_);

  my $db = shift;

  unless(UNIVERSAL::isa($db, 'Rose::DB'))
  {
    croak "Not a Rose::DB-derived object: $db";
  }

  if(defined $db)
  {
    $self->{'db_class'} = $db->class;
    $self->{'db_dsn'}   = undef;
  }

  return $self->{'db'} = $db;
}

sub db_dsn
{
  my($self) = shift;

  return $self->{'db_dsn'}  unless(@_);

  my $db_dsn = shift;

  if(my $db = $self->db)
  {
    $db->db_dsn($db_dsn);
  }

  return $self->{'db_dsn'} = $db_dsn;
}

sub dsn     { shift->db_dsn(@_) }
sub dbi_dsn { shift->db_dsn(@_) }

sub db_class
{
  my($self) = shift;

  return $self->{'db_class'}  unless(@_);

  my $db_class = shift;

  unless($db_class =~ /^(?:\w+::)*\w+$/)
  {
    croak "Illegal class name: $db_class";
  }

  unless(UNIVERSAL::isa($db_class, 'Rose::DB'))
  {
    my $error;

    TRY:
    {
      local $@;
      eval "require $db_class";
      $error = $@;
    }

    no strict 'refs';
    if(!$error && @{"${db_class}::ISA"} && !UNIVERSAL::isa($db_class, 'Rose::DB'))
    {
      croak "Not a Rose::DB-derived class: $db_class";
    }
  }

  if(my $db = $self->db)
  {
    $self->db(undef)  unless($db->class eq $db_class);
  }

  return $self->{'db_class'} = $db_class;
}

sub make_modules
{
  my($self, %args) = @_;

  my $module_dir = exists $args{'module_dir'} ? 
    delete $args{'module_dir'} : $self->module_dir;

  $module_dir = cwd()  unless(defined $module_dir);

  unless(-d $module_dir)
  {
    croak "Module directory '$module_dir' does not exist";
  }

  my(@extra_classes, %extra_info);

  $args{'extra_classes'} = \@extra_classes;
  $args{'extra_info'}    = \%extra_info;

  my @classes = $self->make_classes(%args);

  foreach my $class (@classes, @extra_classes)
  {
    my @path = split('::', $class);
    $path[-1] .= '.pm';
    unshift(@path, $module_dir);

    my $dir = File::Spec->catfile(@path[0 .. ($#path - 1)]);

    mkpath($dir)  unless(-e $dir);

    unless(-d $dir)
    {
      if(-f $dir)
      {
        croak "Could not create module directory '$module_dir' - a file ",
              "with the same name already exists";
      }
      croak "Could not create module directory '$module_dir' - $!";
    }

    my $file = File::Spec->catfile(@path);

    open(my $pm, '>', $file) or croak "Could not create $file - $!";

    my $preamble = exists $args{'module_preamble'} ? 
      $args{'module_preamble'} : $self->module_preamble;

    my $postamble = exists $args{'module_postamble'} ? 
      $args{'module_postamble'} : $self->module_postamble;

    if($class->isa('Rose::DB::Object'))
    {
      if($preamble)
      {
        my $this_preamble = ref $preamble eq 'CODE' ? 
          $preamble->($class->meta) : $preamble;

        print {$pm} $this_preamble;
      }

      if($extra_info{'base_classes'}{$class})
      {
        print {$pm} _perl_base_class($class, \%extra_info, \%args);
      }
      else
      {
        print {$pm} _perl_class($class, \%extra_info, \%args);
      }

      if($postamble)
      {
        my $this_postamble = ref $postamble eq 'CODE' ? 
          $postamble->($class->meta) : $postamble;

        print {$pm} $this_postamble;
      }
    }
    elsif($class->isa('Rose::DB::Object::Manager'))
    {
      if($preamble)
      {
        my $this_preamble = ref $preamble eq 'CODE' ? 
          $preamble->($class->object_class->meta, $class) : $preamble;

        print {$pm} $this_preamble;
      }

      print {$pm} $class->perl_class_definition(%args), "\n";

      if($postamble)
      {
        my $this_postamble = ref $postamble eq 'CODE' ? 
          $postamble->($class->object_class->meta, $class) : $postamble;

        print {$pm} $this_postamble;
      }
    }
    elsif($class->isa('Rose::DB'))
    {
      print {$pm} _perl_db_class($class, \%extra_info, \%args);
    }
    else { croak "Unknown class: $class" }

    close($pm) or croak "Could not write $file - $!";
  }

  return wantarray ? @classes : \@classes;
}

sub _perl_class
{
  my($class, $info, $args) = @_;

  my $auto_load = $args->{'auto_load_related_classes'};
  my $old_auto_load = $class->meta->auto_load_related_classes;

  if(defined $auto_load)
  {
    $class->meta->auto_load_related_classes($auto_load);
  }

  my $code = $class->meta->perl_class_definition(%$args);

  if(defined $auto_load)
  {
    $class->meta->auto_load_related_classes($old_auto_load);
  }

  if(!$info->{'init_db_in_base_class'} && $info->{'perl_init_db'})
  {
    my $init_db = $info->{'perl_init_db'};

    $code =~ s/1;/$init_db\n\n1;/;
  }

  return $code . "\n";
}

sub _perl_base_class
{
  my($class, $info, $args) = @_;

  my $init_db = '';

  if($info->{'init_db_in_base_class'} && $info->{'perl_init_db'})
  {
    $init_db = "\n" . $info->{'perl_init_db'} . "\n";
  }

  return<<"EOF";
package $class;

use base 'Rose::DB::Object';
$init_db
1;
EOF
}

sub _perl_db_class
{
  my($class, $info, $args) = @_;

  my $max = 0;

  foreach my $key (keys %{$info->{'db_entry'}})
  {
    $max = length($key)  if(length($key) > $max);
  }

  my $hash = perl_hashref(hash        => $info->{'db_entry'}, 
                          inline      => 0, 
                          no_curlies  => 1,
                          key_padding => $max,
                          indent      => $args->{'indent'} || 2);

  return<<"EOF";
package $class;

use strict;

use base 'Rose::DB';

__PACKAGE__->use_private_registry;

__PACKAGE__->register_db
(
$hash
);

1;
EOF
}

sub default_pre_init_hook  { }
sub default_post_init_hook { }

sub make_classes
{
  my($self, %args) = @_;

  my $extra_classes = delete $args{'extra_classes'};
  my $extra_info    = delete $args{'extra_info'};

  my $db = delete $args{'db'};

  $args{'stay_connected'} = 1;
  $args{'passive'} = 1  unless(exists $args{'passive'});

  my $require_primary_key = exists $args{'require_primary_key'} ? 
    delete $args{'require_primary_key'} : $self->require_primary_key;

  # Check for parameter alias conflicts
  if(exists $args{'warn_on_missing_pk'})
  {
    if(exists $args{'warn_on_missing_primary_key'} &&
       (($args{'warn_on_missing_pk'} ? 1 : 0) != ($args{'warn_on_missing_primary_key'} ? 1 : 0)))
    {
      croak "The warn_on_missing_primary_key and warn_on_missing_pk parameters ",
            "were both passed, and they conflict.  Since these two parameters are ",
            "aliases for each other, try passing just one.";
    }

    $args{'warn_on_missing_primary_key'} = delete $args{'warn_on_missing_pk'}; 
  }

  my $warn_on_missing_primary_key;

  # If not requiring PKs and no explicit decision, either in args or 
  # in the object, has been made about whether to warn on missing PKs,
  # then don't warn (because not requiring PKs is a strong indication
  # that their absence is not worth a warning)
  if(!$require_primary_key &&
     ((!exists $args{'warn_on_missing_primary_key'} && !defined $self->warn_on_missing_primary_key) ||
      exists $args{'warn_on_missing_primary_key'} && !defined $args{'warn_on_missing_primary_key'}))
  {
    $warn_on_missing_primary_key = 0;
  }
  else
  {
    $warn_on_missing_primary_key = exists $args{'warn_on_missing_primary_key'} ? 
      delete $args{'warn_on_missing_primary_key'} : $self->warn_on_missing_primary_key;
  }

  my $include_views = exists $args{'include_views'} ? 
    delete $args{'include_views'} : $self->include_views;

  my $with_managers = exists $args{'with_managers'} ? 
    delete $args{'with_managers'} : $self->with_managers;

  $args{'with_relationships'} = $self->with_relationships
    unless(exists $args{'with_relationships'});

  $args{'with_foreign_keys'} = $self->with_foreign_keys
    unless(exists $args{'with_foreign_keys'});

  $args{'with_unique_keys'} = $self->with_unique_keys
    unless(exists $args{'with_unique_keys'});

  my $no_auto_sequences = exists $args{'no_auto_sequences'} ? 
    delete $args{'no_auto_sequences'} : $self->no_auto_sequences;

  my $pre_init_hook = exists $args{'pre_init_hook'} ? 
    delete $args{'pre_init_hook'} : $self->pre_init_hook;

  my $post_init_hook = exists $args{'post_init_hook'} ? 
    delete $args{'post_init_hook'} : $self->post_init_hook;

  my $include = exists $args{'include_tables'} ? 
    delete $args{'include_tables'} : $self->include_tables;

  my $exclude = exists $args{'exclude_tables'} ? 
    delete $args{'exclude_tables'} : $self->exclude_tables;

  my $filter = exists $args{'filter_tables'} ? delete $args{'filter_tables'} : 
    (!defined $include && !defined $exclude) ? $self->filter_tables : undef;

  if($include || $exclude)
  {
    if($filter)
    {
      croak "The filter_tables parameter and/or object attribute cannot ",
            "be used with the include_tables or exclude_tables parameters ",
            "or object attributes";
    }

    if(defined $include)
    {
      if(ref $include eq 'ARRAY')
      {
        $include = '(?i)\A(?:' . join('|', map { quotemeta } @$include) . ')\z'
      }

      $include = qr((?i)$include);
    }

    if(defined $exclude)
    {
      if(ref $exclude eq 'ARRAY')
      {
        $exclude = '(?i)\A(?:' . join('|', map { quotemeta } @$exclude) . ')\z'
      }

      $exclude = qr((?i)$exclude);
    }

    $filter = sub 
    {
      no warnings 'uninitialized';
      return 0  if((defined $include && !/$include/) ||
                   (defined $exclude && /$exclude/));
      return 1;
    };
  }

  my $class_prefix =  exists $args{'class_prefix'} ? 
    delete $args{'class_prefix'} : $self->class_prefix || '';

  if(length $class_prefix)
  {
    unless($class_prefix =~ /^(?:\w+::)*\w+(?:::)?$/)
    {
      croak "Illegal class prefix: $class_prefix";
    }

    $class_prefix .= '::'  unless($class_prefix =~ /::$/);
  }

  # Evil masking of object attribute
  local $self->{'class_prefix'} = $class_prefix; 

  # When setting explicit values for attributes that cascade to
  # affect other attributes, save off the old values are restore
  # them at the end.
  my %save;

  if(exists $args{'db_class'})
  {
    my $db_class = delete $args{'db_class'};

    if($db && $db_class && $db_class ne $db->class)
    {
      Carp::croak "The db and db_class parameters conflict: ", $db->class,
                  " vs. $db_class";
    }

    if(defined(my $db_class = $self->db_class))
    {
      $save{'db_class'} = $db_class;
    }

    if(defined(my $db = $self->db))
    {
      $save{'db'} = $db;
    }

    $self->db_class($db_class);
  }    

  #
  # Get or create the db object
  #

  $db ||= $self->db;

  my $db_class = $db ? $db->class : undef;

  my $made_new_db_class = 0;

  unless($db)
  {
    $db_class = $self->db_class;

    if($db_class)
    {
      unless(UNIVERSAL::isa($db_class, 'Rose::DB'))
      {
        my $error;

        TRY:
        {
          local $@;
          eval "require $db_class";
          $error = $@;
        }

        if($error)
        {
          # Failed to load existing module
          unless($error =~ /^Can't locate $db_class\.pm/)
          {
            croak "Could not load db class '$db_class' - $error";
          }

          # Make the class
          no strict 'refs';
          @{"${db_class}::ISA"} = qw(Rose::DB);
          $db_class->registry(clone(Rose::DB->registry));
        }
      }
    }
    else
    {
      $db_class = $self->generate_db_base_class_name;

      # Make a class
      no strict 'refs';
      @{"${db_class}::ISA"} = qw(Rose::DB);
      $db_class->registry(clone(Rose::DB->registry));

      push(@$extra_classes, $db_class)  if($extra_classes);
      $made_new_db_class = 1;
    }
  }

  # Create the init_db subroutine that will be used with the objects
  my %db_args;

  if($db)
  {
    %db_args =
    (
      type   => $db->type,
      domain => $db->domain,
    );

    delete $db_args{'type'}    if($db_args{'type'} eq $db->default_type);
    delete $db_args{'domain'}  if($db_args{'domain'} eq $db->default_domain);
  }

  foreach my $attr (qw(db_dsn db_catalog db_schema db_username db_password db_database))
  {
    (my $db_attr = $attr) =~ s/^db_//;
    no strict 'refs';
    $db_args{$db_attr} = $self->$attr()  if(defined $self->$attr());
  }

  $db_args{'connect_options'} = $self->db_options  if(defined $self->db_options);

  # Set up the object base class
  my @base_classes = $self->base_classes;

  foreach my $class (@base_classes)
  {
    no strict 'refs';
    unless(UNIVERSAL::isa($class, 'Rose::DB::Object') || @{"${class}::ISA"})
    {
      my $error;

      TRY:
      {
        local $@;
        eval "require $class";
        $error = $@;
      }

      croak $error  if($error);
    }
  }

  my ($init_db,  $need_new_init_db);

  # Check if the base class already has its own init_db
  my $can_rdbo = Rose::DB::Object->can('init_db');
  my $can_base = $base_classes[0]->can('init_db');

  unless($can_rdbo && $can_base && $can_rdbo ne $can_base)
  {
    $need_new_init_db = 1;
  }

  if($made_new_db_class)
  {
    if($db_args{'dsn'} && !$db_args{'driver'})
    {
      if(DBI->can('parse_dsn'))
      {
        $db_args{'driver'} = lc((DBI->parse_dsn($db_args{'dsn'}))[1]);
      }

      unless($db_args{'driver'})
      {
        $db_args{'dsn'} =~ /^dbi:(\w+)/i or 
          Carp::croak "Could not extract driver name from DSN: $db_args{'dsn'}";

        $db_args{'driver'} = lc $1;
      }
    }

    $db_class->register_db(domain => $db_class->default_domain,
                           type   => $db_class->default_type,
                           %db_args);

    my $entry = 
      $db_class->registry->entry(domain => $db_class->default_domain,
                                 type   => $db_class->default_type);

    $extra_info->{'db_entry'} = { %db_args };

    unless($entry->database)
    {
      # Need appropriate db just for parsing
      my $tmp_db = $db_class->new;

      my $database = $tmp_db->database_from_dsn($entry->dsn) or
        Carp::croak "Could not extract database name from DSN: ", $entry->dsn;

      $entry->database($database);

      $extra_info->{'database'} = $database;
    }

    $init_db = sub { $db_class->new };

    $extra_info->{'perl_init_db'} =
      "use $db_class;\n\n" .
      "sub init_db { $db_class->new }";
  }
  else
  {
    $init_db = $need_new_init_db ? sub { $db_class->new(%db_args) } : $can_base;

    my $hash = perl_hashref(hash       => \%db_args,
                            inline     => 1,
                            no_curlies => 1,
                            indent     => 0);

    if($need_new_init_db)
    {
      $extra_info->{'perl_init_db'} = 
        "use $db_class;\n\n" .
        "sub init_db { $db_class->new($hash) }";
    }
  }

  # Refresh the db
  $db = $init_db->();

  $extra_info->{'init_db_in_base_class'} = 0;

  # Install the init_db routine in the base class, but only if 
  # using the default base class.
  if($self->using_default_base_class)
  {
    no strict 'refs';
    *{"$base_classes[0]::init_db"} = $init_db;
    $extra_info->{'init_db_in_base_class'} = 1;
    $extra_info->{'base_classes'}{$base_classes[0]}++;
    push(@$extra_classes, $base_classes[0]);
  }
  else
  {
    if($made_new_db_class || $db_class ne 'Rose::DB')
    {
      if($need_new_init_db)
      {
        no strict 'refs';
        no warnings;
        *{"$base_classes[0]::init_db"} = $init_db;
      }
      
      $extra_info->{'init_db_in_base_class'} = 1;
      $extra_info->{'base_classes'}{$base_classes[0]}++;
    }
    else
    {
      foreach my $base_class (@base_classes)
      {
        if($base_class->can('init_db'))
        {
          $extra_info->{'init_db_in_base_class'} = 1;
          last;
        }
      }
    }
  }

  my $force_lowercase;

  if(exists $args{'force_lowercase'})
  {
    $force_lowercase = delete $args{'force_lowercase'};
  }
  else
  {
    unless(defined($force_lowercase = $self->force_lowercase))
    {
      $force_lowercase = $db->driver eq 'oracle' ? 1 : 0;
    }
  }

  my $cm;

  # XXX: Lame way to check if the convention_manager attribute has
  # XXX: been set or fetched.
  if($self->{'convention_manager'})
  {
    $cm = $self->convention_manager;
  }
  else
  {
    $cm = $base_classes[0]->meta->convention_manager;
    $self->convention_manager($cm);
  }

  die "Missing convention manager"  unless($cm);

  # Propagate CM-relevant attributes
  $cm->force_lowercase($force_lowercase);
  $cm->no_auto_sequences($no_auto_sequences);

  $self->convention_manager($cm);

  my @classes;

  my %list_args;
  $list_args{'include_views'} = 1  if($include_views);

  # XXX: Horrible hack.  Replce eventually...
  local $Rose::DB::Object::Metadata::Auto::Missing_PK_OK = 
    $require_primary_key ? 0 : 1;

  my %created;

  # Iterate over tables, creating RDBO classes for each
  foreach my $table ($db->list_tables(%list_args))
  {
    local $_ = $table;
    next  unless(!$filter || $filter->($table));

    unless($db->has_primary_key($table))
    {
      if($warn_on_missing_primary_key)
      {
        # Warn about tables with no primary keys
        warn "Warning: table '$table' has no primary key defined.", 
              ($require_primary_key ? "  Skipping.\n" : "\n");
      }

      # Skip table if primary keys are required
      next  if($require_primary_key);
    }

    my $obj_class = $class_prefix . $cm->table_to_class($table);

    $Debug && warn "Loader loading table: $table - $obj_class\n";

    no strict 'refs';
    # Skip classes that have already been created
    #if($obj_class->isa('Rose::DB::Object') && $obj_class->meta->is_initialized)
    if($created{$obj_class})
    {
      $Debug && warn "Skipping: $obj_class already initialized\n";
      next;
    }

    # Set up the class

    @{"${obj_class}::ISA"} = @base_classes;

    unless($extra_info->{'init_db_in_base_class'})
    {
      *{"${obj_class}::init_db"} = $init_db;
    }

    my $meta = $obj_class->meta;

    $meta->db($db);

    if($pre_init_hook)
    {
      if(ref $pre_init_hook eq 'CODE')
      {
        $pre_init_hook = [ $pre_init_hook ];
      }
      elsif(ref $pre_init_hook ne 'ARRAY')
      {
        Carp::croak "Invalid pre_init_hook: $pre_init_hook";
      }
    }

    unshift(@$pre_init_hook, sub { $self->default_pre_init_hook(@_) });

    $meta->pre_init_hook($pre_init_hook);

    if($post_init_hook)
    {
      if(ref $post_init_hook eq 'CODE')
      {
        $post_init_hook = [ $post_init_hook ];
      }
      elsif(ref $post_init_hook ne 'ARRAY')
      {
        Carp::croak "Invalid post_init_hook: $post_init_hook";
      }
    }

    unshift(@$post_init_hook, sub { $self->default_post_init_hook(@_) });

    $meta->post_init_hook($post_init_hook);

    $meta->table($table);
    $meta->convention_manager($cm->clone);
    $meta->db($db);

    my $include_predicated_unique_indexes = 
      exists $args{'include_predicated_unique_indexes'} 
        ? delete $args{'include_predicated_unique_indexes'} 
        : $self->include_predicated_unique_indexes;

    $meta->include_predicated_unique_indexes($include_predicated_unique_indexes);

    $meta->auto_initialize(%args);

    push(@classes, $obj_class);

    $created{$obj_class}++;

    # Make the manager class
    if($with_managers)
    {
      my $mgr_class = $self->generate_manager_class_name($obj_class, $cm);

      $meta->make_manager_class(
        class     => $mgr_class,
        base_name => $cm->auto_manager_base_name($table, $obj_class),
        isa       => scalar $self->manager_base_classes);

      push(@classes, $mgr_class);
    }
  }

  if(@classes)
  {
    my $meta = $classes[0]->meta;

    # Retry deferred stuff: two passes
    for(1 .. 2)
    {
      $meta->retry_deferred_tasks;
      $meta->retry_deferred_foreign_keys;
      $meta->retry_deferred_relationships;
    }

    $classes[0]->meta_class->clear_all_dbs;
  }

  if(%save)
  {
    while(my($method, $value) = each(%save))
    {
      $self->$method($value);
    }
  }

  return wantarray ? @classes : \@classes;
}

1;

__END__

=head1 NAME

Rose::DB::Object::Loader - Automatically create Rose::DB::Object subclasses based on database table definitions.

=head1 SYNOPSIS

Sample database schema:

  CREATE TABLE vendors
  (
    id    SERIAL NOT NULL PRIMARY KEY,
    name  VARCHAR(255) NOT NULL,

    UNIQUE(name)
  );

  CREATE TABLE products
  (
    id      SERIAL NOT NULL PRIMARY KEY,
    name    VARCHAR(255) NOT NULL,
    price   DECIMAL(10,2) NOT NULL DEFAULT 0.00,

    vendor_id  INT REFERENCES vendors (id),

    status  VARCHAR(128) NOT NULL DEFAULT 'inactive' 
              CHECK(status IN ('inactive', 'active', 'defunct')),

    date_created  TIMESTAMP NOT NULL DEFAULT NOW(),
    release_date  TIMESTAMP,

    UNIQUE(name)
  );

  CREATE TABLE prices
  (
    id          SERIAL NOT NULL PRIMARY KEY,
    product_id  INT NOT NULL REFERENCES products (id),
    region      CHAR(2) NOT NULL DEFAULT 'US',
    price       DECIMAL(10,2) NOT NULL DEFAULT 0.00,

    UNIQUE(product_id, region)
  );

  CREATE TABLE colors
  (
    id    SERIAL NOT NULL PRIMARY KEY,
    name  VARCHAR(255) NOT NULL,

    UNIQUE(name)
  );

  CREATE TABLE product_color_map
  (
    product_id  INT NOT NULL REFERENCES products (id),
    color_id    INT NOT NULL REFERENCES colors (id),

    PRIMARY KEY(product_id, color_id)
  );

To start, make a L<Rose::DB::Object::Loader> object, specifying the database connection information and an optional class name prefix.

  $loader = 
    Rose::DB::Object::Loader->new(
      db_dsn       => 'dbi:Pg:dbname=mydb;host=localhost',
      db_username  => 'someuser',
      db_password  => 'mysecret',
      db_options   => { AutoCommit => 1, ChopBlanks => 1 },
      class_prefix => 'My::Corp');

It's even easier to specify the database information if you've set up L<Rose::DB> (say, by following the instructions in L<Rose::DB::Tutorial>).  Just pass a L<Rose::DB>-derived object pointing to the database you're interested in.

  $loader = 
    Rose::DB::Object::Loader->new(
      db           => My::Corp::DB->new('main'),
      class_prefix => 'My::Corp');

Finally, automatically create L<Rose::DB::Object> subclasses for all the tables in the database.  All it takes is one method call.

  $loader->make_classes;

Here's what you get for your effort.

  $p = My::Corp::Product->new(name => 'Sled');

  $p->vendor(name => 'Acme');

  $p->prices({ price => 1.23, region => 'US' },
             { price => 4.56, region => 'UK' });

  $p->colors({ name => 'red'   }, 
             { name => 'green' });

  $p->save;

  $products = 
    My::Corp::Product::Manager->get_products_iterator(
      query           => [ name => { like => '%le%' } ],
      with_objects    => [ 'prices' ],
      require_objects => [ 'vendor' ],
      sort_by         => 'vendor.name');

  $p = $products->next;

  print $p->vendor->name; # Acme

  # US: 1.23, UK: 4.56
  print join(', ', map { $_->region . ': ' . $_->price } $p->prices);

See the L<Rose::DB::Object> and L<Rose::DB::Object::Manager> documentation for learn more about the features these classes provide.

The contents of the database now look like this.

  mydb=# select * from products;
   id |  name  | price | vendor_id |  status  |       date_created
  ----+--------+-------+-----------+----------+-------------------------
    1 | Sled 3 |  0.00 |         1 | inactive | 2005-11-19 22:09:20.7988 


  mydb=# select * from vendors;
   id |  name  
  ----+--------
    1 | Acme 3


  mydb=# select * from prices;
   id | product_id | region | price 
  ----+------------+--------+-------
    1 |          1 | US     |  1.23
    2 |          1 | UK     |  4.56


  mydb=# select * from colors;
   id | name  
  ----+-------
    1 | red
    2 | green


  mydb=# select * from product_color_map;
   product_id | color_id 
  ------------+----------
            1 |        1
            1 |        2


=head1 DESCRIPTION

L<Rose::DB::Object::Loader> will automatically create L<Rose::DB::Object> subclasses for all the tables in a database.  It will configure column data types, default values, primary keys, unique keys, and foreign keys.  It can also discover and set up inter-table L<relationships|Rose::DB::Object::Metadata/relationship_type_classes>.  It uses L<Rose::DB::Object>'s L<auto-initialization|Rose::DB::Object::Metadata/"AUTO-INITIALIZATION"> capabilities to do all of this.

To do its work, the loader needs to know how to connect to the database.  This information can be provided in several ways.  The recommended practice is to set up L<Rose::DB> according to the instructions in the L<Rose::DB::Tutorial>, and then pass a L<Rose::DB>-derived object or class name to the loader.  The loader will also accept traditional L<DBI>-style connection information: DSN, username, password, etc.

Once the loader object is configured, the L<make_classes|/make_classes> method does all the work.  It takes a few options specifying which tables to make classes for, whether or not to make L<manager|Rose::DB::Object::Manager> classes for each table, and a few other L<options|/make_classes>.  The L<convention manager|/convention_manager> is used to convert table names to class names, generate foreign key and relationship method names, and so on.  The result of this process is a suite of L<Rose::DB::Object> (and L<Rose::DB::Object::Manager>) subclasses ready for use.

L<Rose::DB::Object::Loader> inherits from, and follows the conventions of, L<Rose::Object>.  See the L<Rose::Object> documentation for more information.

=head1 GOTCHAS

Database schema information is extracted using L<DBI>'s schema interrogation methods, which dutifully report exactly how the database describes itself.  In some cases, what the database reports about a particular table may not exactly match what you specified in your table definition.

The most egregious offender is (surprise!) MySQL, which, to give just one example, tends to offer up empty string default values for non-null character columns.  That is, if you write a table definition like this:

    CREATE TABLE widgets
    (
      id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(64) NOT NULL
    );

and then interrogate it using L<DBI>, you will find that the "name" column has a default value (as reflected in the C<COLUMN_DEF> column returned by L<DBI>'s L<column_info()|DBI/column_info> method) of '' (i.e., an empty string).  In other words, it's as if your table definition was this instead:

    CREATE TABLE widgets
    (
      id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(64) NOT NULL DEFAULT ''
    );

MySQL is full of such surprises, and it's not the only database to do such things.  Consult the documentation for your database (or do a Google search for "E<lt>mydbnameE<gt> gotchas") for the gory details.

To work around these kinds of problems, try the L<pre_init_hook|/pre_init_hook> feature.  For example, in your  L<pre_init_hook|/pre_init_hook> subroutine you could walk over the list of L<columns|Rose::DB::Object::Metadata/columns> for each class, eliminating all the empty string default values (i.e., changing them to undef instead).


=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Returns a new L<Rose::DB::Object::Loader> constructed according to PARAMS, where PARAMS are name/value pairs.  Any object method is a valid parameter name.

=back

=head1 OBJECT METHODS

=over 4

=item B<base_class CLASS>

This is an alias for the L<base_classes|/base_classes> method.

=item B<base_classes [ CLASS | ARRAYREF ]>

Get or set the list of base classes to use for the L<Rose::DB::Object> subclasses created by the L<make_classes|/make_classes> method.  The argument may be a class name or a reference to an array of class names.  At least one of the classes should inherit from L<Rose::DB::Object>.

Returns a list (in list context) or reference to an array (in scalar context) of base class names.  Defaults to a dynamically-generated L<Rose::DB::Object> subclass name.

=item B<class_prefix [PREFIX]>

Get or set the prefix affixed to all class names created by the L<make_classes|/make_classes> method.  If PREFIX doesn't end in "::", it will be added automatically.

=item B<convention_manager [ CLASS | MANAGER ]>

Get or set the L<Rose::DB::Object::ConventionManager>-derived class name or object to be used during the L<auto-initialization|Rose::DB::Object::Metadata/"AUTO-INITIALIZATION"> process for each class created by the L<make_classes|/make_classes> method.  Returns a L<Rose::DB::Object::ConventionManager>-derived object, which defaults to a new L<Rose::DB::Object::ConventionManager> object.

Unless this attribute is explicitly set or fetched before the call to the L<make_classes|/make_classes> method, the convention manager object used by L<make_classes|/make_classes> will be produced by calling the L<convention_manager|Rose::DB::Object::Metadata/convention_manager> method of the metadata object of the first (left-most) L<base class|/base_classes>.

=item B<db [DB]>

Get or set the L<Rose::DB>-derived object used to connect to the database.  This object will be used by the L<make_classes|/make_classes> method when extracting information from the database.  It will also be used as the prototype for the L<db|Rose::DB::Object/db> object used by each L<Rose::DB::Object> subclass to connect to the database.

Setting this attribute also sets the L<db_class|/db_class> attributes, overwriting any previously existing value, and sets the  L<db_dsn|/db_dsn> value to undef.

=item B<db_catalog [CATALOG]>

Get or set the L<catalog|Rose::DB/catalog> for the database connection.

=item B<db_class [CLASS]>

Get or set the name of the L<Rose::DB>-derived class used by the L<make_classes|/make_classes> method to construct a L<db|/db> object if one has not been set via the method of the same name.

Setting this attribute sets the L<db|/db> attribute to undef unless its class is the same as CLASS.

=item B<db_dsn [DSN]>

Get or set the L<DBI>-style Data Source Name (DSN) used to connect to the database.  This will be used by the L<make_classes|/make_classes> method when extracting information from the database.  The L<Rose::DB>-derived objects used by each L<Rose::DB::Object> subclass to connect to the database will be initialized with this DSN.

Setting this attribute immediately sets the L<dsn|Rose::DB/dsn> of the L<db|/db> attribute, if it is defined.

=item B<db_options [HASHREF]>

Get or set the L<options|Rose::DB/connect_options> used to connect to the database.

=item B<db_password [PASSWORD]>

Get or set the L<password|Rose::DB/password> used to connect to the database.

=item B<db_schema [SCHEMA]>

Get or set the L<schema|Rose::DB/schema> for the database connection.

=item B<db_username [USERNAME]>

Get or set the L<username|Rose::DB/username> used to connect to the database.

=item B<exclude_tables [ REGEX | ARRAYREF ]>

Get or set a regular expression or reference to an array of table names to exclude.  Table names that match REGEX or are contained in ARRAYREF will be skipped by default during calls to the L<make_classes|/make_classes> method.  Tables without primary keys are automatically (and always) skipped.

Table names are compared to REGEX and the names in ARRAYREF in a case-insensitive manner.  To override this in the case of the REGEX, add C<(?-i)> to the front of the REGEX.  Otherwise, use the L<filter_tables|/filter_tables> method instead.

=item B<filter_tables CODEREF>

Get or set a reference to a subroutine that takes a single table name argument and returns true if the table should be processed by default during calls to the L<make_classes|/make_classes> method, false if the table should be skipped.  The C<$_> variable will also be set to the table name before the call to CODEREF.  

This attribute should not be combined with the L<exclude_tables|/exclude_tables> or L<include_tables|/include_tables> attributes.

=item B<force_lowercase [BOOL]>

Get or set a boolean value that indicates whether or not L<metadata|Rose::DB::Object::Metadata> entity names should be forced to lowercase even when the related entity (e.g., table or column name) is uppercase or mixed case.  ("Metadata entities" are thing like L<columns|Rose::DB::Object::Metadata/columns>, L<relationships|Rose::DB::Object::Metadata/relationships>, and L<foreign keys|Rose::DB::Object::Metadata/foreign_keys>.)  The default value undef.

=item B<generate_manager_class_name CLASS [, CM]>

Given the name of a L<Rose::DB::Object>-derived class, returns a class name for a L<Rose::DB::Object::Manager>-derived class to manage such objects.  The default implementation calls the L<auto_manager_class_name|Rose::DB::Object::ConventionManager/auto_manager_class_name> method on the convention manager object passed as the optional CM argument, or returned from the L<convention_manager|/convention_manager> method if a CM argument is not passed. 

=item B<include_tables [ REGEX | ARRAYREF ]>

Get or set a regular expression or reference to an array of table names to include.  Table names that do not match REGEX or are not contained in ARRAYREF will be skipped by default during calls to the L<make_classes|/make_classes> method.  Tables without primary keys are automatically (and always) skipped.  

Table names are compared to REGEX and the names in ARRAYREF in a case-insensitive manner.  To override this in the case of the REGEX, add C<(?-i)> to the front of the REGEX.  Otherwise, use the L<filter_tables|/filter_tables> method instead.

=item B<include_predicated_unique_indexes BOOL>

Get or set a boolean value that will be assigned to the L<include_predicated_unique_indexes|Rose::DB::Object::Metadata/include_predicated_unique_indexes> attribute of the L<Rose::DB::Object::Metadata> object for each class created by the L<make_classes|/make_classes> method.  The default value is false.

=item B<include_views BOOL>

If true, database views will also be processed by default during calls to the L<make_classes|/make_classes> method.  Defaults to false.

=item B<make_classes [PARAMS]>

Automatically create L<Rose::DB::Object> and (optionally) L<Rose::DB::Object::Manager> subclasses for some or all of the tables in a database.  The class creation process is controlled by the loader object's attributes.  Optional name/value pairs passed to this method may override some of those values.  Valid PARAMS are:

=over 4

=item B<db [DB]>

The L<Rose::DB>-derived object used to connect to the database.  This object will also be used as the prototype for the L<db|Rose::DB::Object/db> object used by each L<Rose::DB::Object> subclass created by this call to L<make_classes|/make_classes>.  Defaults to the value of the loader object's L<db|/db> attribute.

=item B<db_class [CLASS]>

The name of the L<Rose::DB>-derived class used to construct a L<db|/db> object if one has not been set via the parameter or object attribute of the same name.  Defaults to the value of the loader object's L<db_class|/db_class> attribute.

=item B<include_tables [ REGEX | ARRAYREF ]>

Table names that do not match REGEX or are not contained in ARRAYREF will be skipped.  Defaults to the value of the loader object's L<include_tables|/include_tables> attribute.  Tables without primary keys are automatically (and always) skipped.

Table names are compared to REGEX and the names in ARRAYREF in a case-insensitive manner.  To override this in the case of the REGEX, add C<(?-i)> to the front of the REGEX.  Otherwise, use the C<filter_tables> parameter instead.

=item B<exclude_tables [ REGEX | ARRAYREF ]>

Table names that match REGEX or are contained in ARRAYREF will be skipped.  Defaults to the value of the loader object's L<exclude_tables|/exclude_tables> attribute.  Tables without primary keys are automatically (and always) skipped.

Table names are compared to REGEX and the names in ARRAYREF in a case-insensitive manner.  To override this in the case of the REGEX, add C<(?-i)> to the front of the REGEX.  Otherwise, use the C<filter_tables> parameter instead.

=item B<filter_tables CODEREF>

A reference to a subroutine that takes a single table name argument and returns true if the table should be processed, false if it should be skipped.  The C<$_> variable will also be set to the table name before the call.  This parameter cannot be combined with the C<exclude_tables> or C<include_tables> options.

Defaults to the value of the loader object's L<filter_tables|/filter_tables> attribute, provided that both the C<exclude_tables> and C<include_tables> values are undefined.  Tables without primary keys are automatically skipped.

=item B<force_lowercase BOOL>

A boolean value that indicates whether or not L<metadata|Rose::DB::Object::Metadata> entity names should be forced to lowercase even when the related entity is uppercase or mixed case.  ("Metadata entities" are thing like L<columns|Rose::DB::Object::Metadata/columns>, L<relationships|Rose::DB::Object::Metadata/relationships>, and L<foreign keys|Rose::DB::Object::Metadata/foreign_keys>.)

If this parameter is omitted and if the loader object's L<force_lowercase|/force_lowercase> attribute is not defined, then the value is chosen based on the database currently being examined.  If the database is Oracle, then it defaults to true.  Otherwise, it defaults to false.

The final value is propagated to the L<convention manager|/convention_manager> L<attribute of the same name|Rose::DB::Object::ConventionManager/force_lowercase>.

=item B<include_predicated_unique_indexes BOOL>

This value will be assigned to the L<include_predicated_unique_indexes|Rose::DB::Object::Metadata/include_predicated_unique_indexes> attribute of the L<Rose::DB::Object::Metadata> object for each class created by this method.  Defaults to the value of the loader object's L<include_predicated_unique_indexes|/include_predicated_unique_indexes> attribute.

=item B<include_views BOOL>

If true, database views will also be processed.  Defaults to the value of the loader object's L<include_views|/include_views> attribute.

=item B<post_init_hook [ CODEREF | ARRAYREF ]>

A reference to a subroutine or a reference to an array of code references that will be called just after each L<Rose::DB::Object>-derived class is L<initialize|Rose::DB::Object::Metadata/initialize>d.  Each referenced subroutine will be passed the class's L<metadata|Rose::DB::Object::Metadata> object plus any arguments to the L<initialize|Rose::DB::Object::Metadata/initialize> method.  Defaults to the value of the loader object's L<post_init_hook|/post_init_hook> attribute.

=item B<pre_init_hook [ CODEREF | ARRAYREF ]>

A reference to a subroutine or a reference to an array of code references that will be called just before each L<Rose::DB::Object>-derived class is L<initialize|Rose::DB::Object::Metadata/initialize>d.  Each referenced subroutine will be passed the class's L<metadata|Rose::DB::Object::Metadata> object plus any arguments to the L<initialize|Rose::DB::Object::Metadata/initialize> method.  Defaults to the value of the loader object's L<pre_init_hook|/pre_init_hook> attribute.

=item B<require_primary_key BOOL>

If true, then any table that does not have a primary key will be skipped.  Defaults to the value of the loader object's L<require_primary_key|/require_primary_key> attribute.  Note that a L<Rose::DB::Object>-derived class based on a table with no primary key will not function correctly in all circumstances.  Use this feature at your own risk.

=item B<warn_on_missing_pk BOOL>

This is an alias for the C<warn_on_missing_primary_key> parameter.

=item B<warn_on_missing_primary_key BOOL>

If true, then any table that does not have a primary key will trigger a warning.

If C<require_primary_key> is false and the loader object's L<warn_on_missing_primary_key|/warn_on_missing_primary_key> attribute is undefined, or if the C<warn_on_missing_primary_key> parameter is set to an undefined value or is not passed to the L<make_classes|/make_classes> call at all, then C<warn_on_missing_primary_key> is set to false.  Otherwise, it defaults to the value of the loader object's L<warn_on_missing_primary_key|/warn_on_missing_primary_key> attribute.  Note that a L<Rose::DB::Object>-derived class based on a table with no primary key will not function correctly in all circumstances.

These complicated defaults are intended to honor the intentions of the C<require_primary_key> attribute/parameter.  If not requiring primary keys and no explicit decision has been made about whether to warn about missing primary keys, either in the parameters to the  L<make_classes|/make_classes> call or in the loader object itself, then we don't warn about missing primary keys.  The idea is that not requiring primary keys is a strong indication that their absence is not worth a warning.

=item B<with_foreign_keys BOOL>

If true, set up foreign key metadata for each L<Rose::DB::Object>-derived.  Defaults to the value of the loader object's L<with_foreign_keys|/with_foreign_keys> attribute.

=item B<with_managers BOOL>

If true, create L<Rose::DB::Object::Manager|Rose::DB::Object::Manager>-derived manager classes for each L<Rose::DB::Object> subclass.  Defaults to the value of the loader object's L<with_managers|/with_managers> attribute.

The manager class name is determined by passing the L<Rose::DB::Object>-derived class name to the L<generate_manager_class_name|/generate_manager_class_name> method.

The L<Rose::DB::Object> subclass's L<metadata object|Rose::DB::Object::Metadata>'s L<make_manager_class|Rose::DB::Object::Metadata/make_manager_class> method will be used to create the manager class.  It will be passed the return value of the convention manager's L<auto_manager_base_name|Rose::DB::Object::ConventionManager/auto_manager_base_name> method as an argument.

=item B<with_relationships [ BOOL | ARRAYREF ]>

A boolean value or a reference to an array of relationship L<type|Rose::DB::Object::Metadata::Relationship/type> names.  If set to a simple boolean value, then all types of relationships will be considered when making classes.  If set to a list of relationship type names, then only relationships of those types will be considered.  Defaults to the value of the loader object's L<with_relationships|/with_relationships> attribute.

=item B<with_unique_keys BOOL>

If true, set up unique key metadata for each L<Rose::DB::Object>-derived.  Defaults to the value of the loader object's L<with_unique_keys|/with_unique_keys> attribute.

=back

Any remaining name/value parameters will be passed on to the call to L<auto_initialize|Rose::DB::Object::Metadata/auto_initialize> used to set up each class.  For example, to ask the loader not to create any L<relationships|Rose::DB::Object::Metadata/relationships>, pass the C<with_relationships> parameter with a false value.

    $loader->make_classes(with_relationships => 0);

This parameter will be passed on to the L<auto_initialize|Rose::DB::Object::Metadata/auto_initialize> method, which, in turn, will pass the parameter on to its own call to the L<auto_init_relationships|Rose::DB::Object::Metadata/auto_init_relationships> method.  See the L<Rose::DB::Object::Metadata> documentation for more information on these methods.

Each L<Rose::DB::Object> subclass will be created according to the "best practices" described in the L<Rose::DB::Object::Tutorial>.  If a L<base class|/base_classes> is not provided, one (with a dynamically generated name) will be created automatically.  The same goes for the L<db|/db> object.  If one is not set, then a new (again, dynamically named) subclass of L<Rose::DB>, with its own L<private data source registry|Rose::DB/use_private_registry>, will be created automatically.

This method returns a list (in list context) or a reference to an array (in scalar context) of the names of all the classes that were created.  (This list will include L<manager|Rose::DB::Object::Manager> class names as well, if any were created.)

=item B<make_modules [PARAMS]>

Automatically create L<Rose::DB::Object> and (optionally) L<Rose::DB::Object::Manager> subclasses for some or all of the tables in a database, then create Perl module (*.pm) files for each class.

This method calls L<make_classes|/make_classes> to make the actual classes.

B<Note:> If you are trying to regenerate a set of module files that already exist in the target C<module_dir>, please make sure that this C<module_dir> is I<not> in your C<@INC> path.  (That is, make sure it is not in the set of paths that perl will search when looking for module files in response to a C<use> or C<require> statement.)  More generally, you must make sure that existing versions of the modules you are attempting to generate are not in your C<@INC> path.

(If you do not do this, when L<make_classes|/make_classes> makes a class and looks for a related class, it will find and load the previously generated C<.pm> file, which will then cause L<make_classes|/make_classes> to skip that class later when it sees that it already exists in memory.  And if L<make_classes|/make_classes> skips it, L<make_modules|/make_modules> will never see it and therefore will never regenerate the C<.pm> file.)

This method takes all of the same parameters as L<make_classes|/make_classes>, with several additions:

=over 4

=item B<module_dir DIR>

The path to the directory where the Perl module files will be created.  For example, given a DIR of "/home/john/lib", the Perl module file for the class C<My::DB::Object> would be located at "/home/john/lib/My/DB/Object.pm".  

Defaults to the value of the loader object's L<module_dir|/module_dir> attribute.  If the L<module_dir|/module_dir> attribute is also undefined, then the current working directory (as determined by a call to L<cwd()|Cwd/cwd>) is used instead.

=item B<module_preamble [ SCALAR | CODE ]>

If defined as a scalar, inserts the contents of the variable into the auto-generated file before any of the auto-generated class information.  If provided as a code ref, calls the indicated function, passing the L<metadata object|Rose::DB::Object::Metadata> as a parameter.  (The metadata object that belongs to the C<object_class> and the L<Rose::DB::Object::Manager>-derived class name are passed if the module is a L<Rose::DB::Object::Manager>-derived class.)  The returned value of the function is inserted as the preamble text.

Defaults to the value of the loader object's L<module_preamble|/module_preamble> attribute.

=item B<module_postamble [ SCALAR | CODE ]>

If defined as a scalar, inserts the contents of the variable into the auto-generated file after any of the auto-generated class information.  If provided as a code ref, calls the indicated function, passing the L<metadata object|Rose::DB::Object::Metadata> as a parameter.  (The metadata object that belongs to the C<object_class> and the L<Rose::DB::Object::Manager>-derived class name are passed if the module is a L<Rose::DB::Object::Manager>-derived class.)  The returned value of the function is inserted as the postamble text.

Defaults to the value of the loader object's L<module_postamble|/module_postamble> attribute.

=back

=item B<module_dir [DIR]>

Get or set the path to the directory where L<make_modules|/make_modules> will create its Perl modules files.  For example, given a DIR of "/home/john/lib", L<make_modules|/make_modules> would create the file  "/home/john/lib/My/DB/Object.pm" for the class C<My::DB::Object>.

=item B<module_preamble [ SCALAR | CODE ]>

If defined as a scalar, inserts the contents of the variable into the auto-generated file before any of the auto-generated class information.  If provided as a code ref, calls the indicated function, passing the L<metadata object|Rose::DB::Object::Metadata> as a parameter.  (The metadata object that belongs to the C<object_class> and the L<Rose::DB::Object::Manager>-derived class name are passed if the module is a L<Rose::DB::Object::Manager>-derived class.)  The returned value of the function is inserted as the preamble text.

=item B<module_postamble [ SCALAR | CODE ]>

If defined as a scalar, inserts the contents of the variable into the auto-generated file after any of the auto-generated class information.  If provided as a code ref, calls the indicated function, passing the L<metadata object|Rose::DB::Object::Metadata> as a parameter.  (The metadata object that belongs to the C<object_class> and the L<Rose::DB::Object::Manager>-derived class name are passed if the module is a L<Rose::DB::Object::Manager>-derived class.)  The returned value of the function is inserted as the postamble text.

=item B<pre_init_hook [CODE]>

Get or set a reference to a subroutine to be called just before each L<Rose::DB::Object>-derived class is L<initialize|Rose::DB::Object::Metadata/initialize>ed within the L<make_classes|/make_classes> method.  The subroutine will be passed the class's L<metdata|Rose::DB::Object::Metadata> object as an argument.

=item B<require_primary_key BOOL>

Get or set a boolean value that determines whether or not the L<make_classes|/make_classes> method will skip any table that does not have a primary key will be skipped.  Defaults to true.

Note that a L<Rose::DB::Object>-derived class based on a table with no primary key will not function correctly in all circumstances.  Use this feature at your own risk.

=item B<warn_on_missing_pk BOOL>

This is an alias for the L<warn_on_missing_primary_key|/warn_on_missing_primary_key> method.

=item B<warn_on_missing_primary_key BOOL>

Get or set a boolean value that determines whether or not the L<make_classes|/make_classes> method will emit a warning when it encounters a table that does not have a primary key.  Defaults to undefined.

=item B<with_foreign_keys BOOL>

If true, the L<make_classes|/make_classes> method will set up foreign key metadata for each L<Rose::DB::Object>-derived class it creates.  Defaults to true.

=item B<with_managers [BOOL]>

If true, the L<make_classes|/make_classes> method will create L<Rose::DB::Object::Manager|Rose::DB::Object::Manager>-derived manager classes for each L<Rose::DB::Object> subclass by default.  Defaults to true.

The manager class name is determined by passing the L<Rose::DB::Object>-derived class name to the L<generate_manager_class_name|/generate_manager_class_name> method.

The L<Rose::DB::Object> subclass's L<metadata object|Rose::DB::Object::Metadata>'s L<make_manager_class|Rose::DB::Object::Metadata/make_manager_class> method will be used to create the manager class.  It will be passed the return value of the convention manager's L<auto_manager_base_name|Rose::DB::Object::ConventionManager/auto_manager_base_name> method as an argument.

=item B<with_relationships [ BOOL | ARRAYREF ]>

A boolean value or a reference to an array of relationship L<type|Rose::DB::Object::Metadata::Relationship/type> names.  If set to a simple boolean value, then the L<make_classes|/make_classes> method will consider all types of relationships when making classes.  If set to a list of relationship type names, then only relationships of those types will be considered by  L<make_classes|/make_classes>.  Defaults to true.

=item B<with_unique_keys BOOL>

If true, the L<make_classes|/make_classes> method will set up unique key metadata for each L<Rose::DB::Object>-derived class it creates.  Defaults to true.

=item B<manager_base_class CLASS>

This is an alias for the L<manager_base_classes|/manager_base_classes> method.

=item B<manager_base_classes [ CLASS | ARRAYREF ]>

Get or set the list of base classes to use for the L<Rose::DB::Object::Manager> subclasses created by the L<make_classes|/make_classes> method.  The argument may be a class name or a reference to an array of class names.  At least one of the classes should inherit from L<Rose::DB::Object::Manager>.

Returns a list (in list context) or reference to an array (in scalar context) of base class names.  Defaults to L<Rose::DB::Object::Manager>.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
