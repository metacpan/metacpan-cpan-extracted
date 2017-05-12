package Class::Cache;
use strict;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    ($VERSION)   = ('$Revision: 1.12 $' =~ m/([\.\d]+)/) ;
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

use Class::Prototyped;
use Data::Dumper;

use Params::Validate qw(:all);
use Carp qw(carp croak cluck confess);


=head1 NAME

Class::Cache - object factory with revivifying cache

=head1 SYNOPSIS

 use Class::Cache;

 my $class_cache = Class::Cache->new(
   # expire cache items when retrieved (on_get). The other option is
   # to never expire them, by setting this key's value to 0. Timed
   # expiry is not implemented or entirely expected in the application
   # domain of this module.
   expires   => 'on_get',

   # default constructor is new for items constructed by simple_* call
   new       => 'new',

   # call the constructor eagerly?
   lazy      => 0,

   # constructor takes no args by default
   args      => [],

   # IMPORTANT:
   # There is *_NO_* default package for object construction. If the
   # key C<pkg> does not exist in the configuration hash for a cache
   # item, then it is assumed that the cache item key is the package
   # name 

 );

 # All ofthe above constructor parms are the defaults, so the same
 # Class::Cache could have been created via Class::Cache->new();


 # Key and package are assumed to have the same name if "pkg" is not
 # part of the configuration hashref. Therefore, in this case
 # constructor name is "build". Do not expire this cache entry.
 $class_cache->set(
    'html::footer' => { new  => 'build', expires => 0 },
  );

 # Here, key and package have the same name. Constructor is new and we
 # supply args for it:
 $class_cache->set(
   'Class::Cache::Adder' => { args => [1,2,3] },
 )

 # key and package same name, constructor is new, takes no args	
 $class_cache->set(
    'Super::SimpleClass'   => 1,
 );

 $class_cache->set(
    # key is lazy_adder, lazily call as Lazy->Adder->new(1,2,3);
    lazy_adder => { lazy => 1, pkg => 'Lazy::Adder', args => [1,2,3] }
  );

 # Write a constructor as opposed to having this module build it.
 # Do not forget to use or require the module you need for your
 # custom factory to work!
 $class_cache->set(
   compo => { lazy => 1, new => sub { 
     my $pkg = 'Uber::Super::Cali::Fragi::Listic::Complex::Package';
     my $x = $pkg->this; $pkg->that; $pkg->give_object;
     }
   }

  );



=head1 DESCRIPTION

In mod_perl, one wants to pre-load as many things as
possible. However, the objects created from the classes that I was
loading can only be used once, after which they have to be
recreated. So, to save oneself the trouble of keeping track of which
class instances have been used and then writing code to re-vivify
them, this module handles that.


=head1 METHODS

=head2 new

 Usage     : ->new(%factory_config)
 Purpose   : creates a new class cache. All object instances will be
             created per %default_factory_config, unless overridden in
             the call to set(). The possible configuration options
             were documented in the SYNOPSIS. The values given to
             these options are the default values.
 Returns   : returns a Class::Cache object
 Argument  : %factory_config
 Throws    : Exceptions and other anomolies: none

=cut


sub new {
  my $class = shift;

  my %default_factory_config = (
    expires => { default => 'on_get' },
    new     => { default => 'new'    },
    lazy    => { default => 0    },
    args    => { default => []   },
   );

  my %self;

  my %factory_config = validate (@_, \%default_factory_config);

  # the cache of manufactured objects
  $self{C} = Class::Prototyped->new;

  # the attributes for the manufactured objects - Class::Prototyped does
  # not have general support for this. The attributes are hardcoded, so
  # I have to keep track of the attributes for the things in the cache
  # in another data structure.
  $self{A} = Class::Prototyped->new;

  # we store the key of expired cache items so that we can reconstruct
  # them later
  $self{E} = [];

  $self{factory_config} = \%factory_config;

  bless \%self, $class;
}


=head2 set

 Usage     : ->set($key => $factory_config)
 Purpose   : Creates a FactoryCache item accessible by $key whose value will
             be the object created in fashion specified by $factory_config.
             $factory_config can be either a hashref or a scalar. 
             If it is a scalar, then it uses the defaults for object
             creation
	     If it is a hashref, then each of the given parameters in
	     this hashref overwrite the default ones. Of particular
	     important is the new parameter. If this is a scalar, then
	     it is taken as the name of the constructor. If it is a
	     coderef, then the only other factory_config parameter
	     that matters is lazy. If lazy is set, then the
	     constructor execution is delayed until the cache item is
	     requested. Otherwise, the constructor runs immediately.
 Returns   : nothing
 Throws    : Exception if class cannot be created

=cut

# _merge():
# internal routine supporting ->set()
sub _merge {
  my ($current_config, $default_config) = @_;

  my %p = %{$default_config};

  $p{$_} = $current_config->{$_} for (keys %{$current_config}) ;

  \%p;
}

sub set {
  my $self = shift;
  my $key  = shift;
  my $input_config = shift;


  my $parms = do {
    if (ref $input_config eq 'HASH') {
      _merge $input_config, $self->{factory_config};
    } else {
      $self->{factory_config}
    }
  };

  $self->add_cache_item($key,$parms);

}

sub is_lazy {
  my ($self, $current_config) = @_;

  $current_config->{lazy} || $self->{factory_config}->{lazy};
}

# internal routine which makes it easy to declare a 
# field as create-on-demand using Class::Prototyped conventions
sub _autoload_field { [ $_[0], 'FIELD', 'autoload' ] }

# internal routine:
# all the logic associated with adding a cache item executes here
sub add_cache_item {
  my $self = shift;
  my $key  = shift;
  my $current_config = shift;
  my $default_parms  = $self->{factory_config};

  my ($object, $K, $V);

  # When something is about to be added to the cache by a custom
  # coderef, then it only matters whether the object is created now or
  # on-demand: all other factory configuration parms are ignored.
  if (ref $current_config->{new} eq 'CODE') {
    if ($self->is_lazy($current_config)) {
      $K = _autoload_field $key;
      $V = $current_config->{new};
    } else {
      $K = $key;
      $V = $current_config->{new}->();
    }
  # Same logic, but this time, the factory configuration at
  # Class::Cache instance time requires us to run the same logic. This
  # happens when a class instance is added to the cache and no "new"
  # parameter was supplied
  } elsif (ref $default_parms->{new} eq 'CODE') {
    if ($self->is_lazy($current_config)) {
      $K = _autoload_field $key;
      $V = $default_parms->{new};
    } else {
      $K = $key;
      $V = $default_parms->{new}->();
    }
  # Otherwise build a constructor based on the 
  } else {

    my $pkg = do {
      if    (exists $current_config->{pkg}) { $current_config->{pkg} }
      elsif (exists $default_parms->{pkg})  { $default_parms->{pkg} } 
      else                                  { $key }
    };					  
    my $new = do {
      if    (exists $current_config->{new}) { $current_config->{new} }
      elsif (exists $default_parms->{new})  { $default_parms->{new} } 
      else                                  { $key }
    };					  

    my @arg = exists $current_config->{args} 
        ? @{$current_config->{args}}
        : @{$default_parms->{args}};

    my $constructor = sub { 
      eval "require $pkg"; 
      confess $@ if $@;
      $pkg->$new(@arg) 
    } ;

    if ($self->is_lazy($current_config)) {
      $K = [$key, 'FIELD', 'autoload'];
      $V = $constructor;
    } else {
      $K = $key;
      $V = $constructor->();
    }

  }

  # put the key-value pair in the Class::Cache cache
  $self->{C}->reflect->addSlot($K => $V);

  # we keep the config parameters around for the manufactured object so that
  # we can check them later. Specifically, when a user requests an object
  # from the cache, we check that items's attributes to see if this object
  # expires on_get, if so, we expire it.
  $self->{A}->reflect->addSlot($key => $current_config);
}



=head2 get

 Usage     : ->get($cache_item_key)
 Purpose   : returns the cache item with name $cache_item_key. If the
	     cache item was stored with the "lazy" parameter, then
	     the cache item value is constructed now. If the cache
	     item was stored with the "expires" parameter set to
	     "on_get" then we expire this item.
 Returns   : the cache item value or undef

=cut


sub get {

  my $self = shift;

  validate_pos(@_, 1);

  my $key = shift;

  my $retval = $self->{C}->reflect->getSlot($key);

  # get the user-supplied attributes for this cache item
  my $a = $self->{A}->reflect->getSlot($key);

  if ($a->{expires} eq 'on_get') {
    # add $key to list of expired keys so it can be re-vivified later
    push @{$self->{E}}, $key;

    # remove $key from the object cache
    $self->{C}->reflect->deleteSlot($key);
  }

  # interestingly, calling getSlot on a Class::Prototyped object does
  # not eval the coderef in the value slot. If you get the slot by
  # calling the key as a method, then it does. So, I have to eval the
  # coderef in the slot myself.
  if ($self->is_lazy($a)) {
    if (ref $retval eq 'CODE') {
      $retval = $retval->() ;
    }
  }
  $retval;

}


=head2 refill

 Usage     : ->refill
 Purpose   : recreates the objects which were expired from cache
 Returns   : nothing
 Argument  : none
 Throws    : nothing

=cut


sub refill {

  my $self = shift;

  do {
    my $factory_config = $self->{A}->reflect->getSlot($_);
    $self->add_cache_item($_ => $factory_config);
  } for @{$self->{E}} ;

  $self->{E} = [];

}


=head2 classes

 Usage     : ->classes
 Purpose   : returns a list of the classes in the cache available for 
             retrieval
 Returns   : a list
 Argument  : none
 Throws    : nothing

=cut

sub classes {
  my $self = shift;

  $self->{C}->reflect->slotNames;
}

=head2 expired

 Usage     : ->expired
 Purpose   : returns a list of the expired classes in the cache
 Returns   : a list
 Argument  : none
 Throws    : nothing

=cut

sub expired {
  my $self = shift;

  @{$self->{E}};
}

=head1 BUGS

None known.



=head1 SUPPORT

Email the author.

=head1 CVS SOURCES

 cvs -d:pserver:anonymous@cvs.sourceforge.net:/cvsroot/seamstress login
 cvs -d:pserver:anonymous@cvs.sourceforge.net:/cvsroot/seamstress co -P classcache

Or browse the repository here:
L<http://cvs.sourceforge.net/viewcvs.py/seamstress>

=head1 AUTHOR

	Terrence Brannon
	CPAN ID: TBONE
	metaperl.com
	metaperl@gmail.com
	http://www.metaperl.com

Original implementation had substantial help from mauke on

        irc://irc.efnet.org

Current version is completely new. I am indebted to Randal Schwartz
for generating my interest in Class::Prototyped.

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

