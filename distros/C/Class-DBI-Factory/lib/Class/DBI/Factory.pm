package Class::DBI::Factory;
use strict;

use Class::DBI::Factory::Exception qw(:try);
use Data::Dumper;

# to connect to the database in the proper manner, we must
use Ima::DBI;

# and to make sure that the unique-object cache is disabled:
use Class::DBI;
$Class::DBI::Weaken_Is_Available = 0;

use vars qw( $VERSION $AUTOLOAD $_factories $class_debug_level $factory_id_from $ghost_class $list_class $iterator_class $mailer_class $db_rootclass);

$VERSION = '0.994';
$_factories = {};
$class_debug_level = 0;
$factory_id_from = '_SITE_TITLE';

=head1 NAME

Class::DBI::Factory - factory interface to a set of Class::DBI classes, with optional mod_perl application skeleton

=head1 SYNOPSIS

  # in a simple script:
  
  my $factory = Class::DBI::Factory->new;
  $factory->set_db({ 
    db_type => 'mysql',
    db_name => 'items',
    db_username => 'me',
    db_password => 'password',
  });
  
  $factory->use_classes(qw(My::Item));
  
  my @columns = $factory->columns('item');
  my $item = $factory->retrieve('item', 1);
  my $iterator = $factory->search('item', year => 1980);

    
  # in an apache host configuration:
  
  PerlSetEnv _CDF_SITE_CONFIG '/home/my_site/conf/cdf.conf'
  <Location "/directory">
    SetHandler perl-script
    PerlHandler Class::DBI::Factory::Handler
  </Location>
  
  # and on a template somewhere:
  
  <p>
  [% FOREACH album IN factory.search('album', 
    'year', input.year,
    'artist', artist,
  ) %][% album.title %]<br>[% END %]
  </p>

=head1 INTRODUCTION

If you use Class::DBI::Factory by itself, it's a quick, clean way to work with a set of Class::DBI data classes, providing a simple way to access their data and class methods and removing some of cdbi's limitations: with the factory it's very easy to use the same data classes for different databases at the same time.

If you use Class::DBI::Factory with the set of helper classes that come with it, it's a full framework for MVC-friendly mod_perl-based web applications. The supplied Handler base class makes the factory's simple, consistent interface available on TT2 (or other) templates and hides all the complexity of working under mod_perl. In this context the database-abstraction that the factory offers allows you to use the same application on several sites on the same server, which is where all this began many years ago.

CDF is a simple alternative to application frameworks like Maypole and Catalyst. It doesn't automate the creation of CDBI classes - I prefer to write them - but it handles pretty much everything else and is very easy to extend and override.

=head1 EXAMPLES

A minimal script for getting at your data with no config files or other clutter:

  use Class::DBI::Factory;
  my $factory = Class::DBI::Factory->new;
  $factory->set_db({ 
    db_type => 'mysql',
    db_name => 'qanda',
    db_username => 'me',
    db_password => 'password',
  });
  
  $factory->use_classes(qw(My::Answer My::Question));
  my $question = $factory->retrieve('question', 1);

The same thing but with a configuration file:

  # in limited-access config file './answers.conf'
  
  db_type = 'mysql',
  db_name = 'qanda',
  db_username = 'me',
  db_password = 'password',
  class = My::Answer
  class = My::Question
  
  # in your script

  use Class::DBI::Factory;
  my $factory = Class::DBI::Factory->new('./items.conf');
  my $question = $factory->retrieve('question', 1);

A very simple mod_perl application:

  # in your virtualhost configuration

  PerlSetEnv _CDF_CONFIG '/home/conf/cdf.conf'
  PerlSetEnv _CDF_SITE_CONFIG '/home/answers/conf/site.conf'
  
  <Location "/answers">
    SetHandler perl-script
    PerlHandler Class::DBI::Factory::Handler
  </Location>

  # in /home/answers/conf/cdf.conf

  db_type = 'mysql',
  db_name = 'qanda',
  db_username = 'me',
  db_password = 'password',
  class = My::Question
  class = My::Answer
  master_template = 'master.tt2'
  template_path = '/home/answers/templates'
  default_view = 'welcome'
  
  # in /home/answers/templates/master.tt2

  [% PROCESS "views/${view}.tt2" %]

  # in /home/answers/templates/views/welcome.tt2

  [% IF input.question %]
    [% answers = factory.search('answer', 'question', question ) %]
    ...
  [% ELSE %]
    [% questions = factory.search('answer', 'question', question ) %]
    [% FOREACH q IN questions %]
      ...
    [% END %]
  [% END %]

It does get a little more complicated, but CDF comes with a set of five helpers that should make the rest of your job easier too:

=over

=item L<Class::DBI::Factory::Config>

Wraps around Andy Wardley's AppConfig to provide a simple, friendly configuration mechanism for CDF and the rest of your application. This is very likely to be loaded during even the simplest use of CDF, but you can supply your own configuration mechanism instead.
  
=item L<Class::DBI::Factory::Handler>

A fairly comprehensive base class for mod_perl handlers, providing standard ways of retrieving and displaying one or many cdbi objects. It's biased towards the Template Toolkit but you can easily replace that with your preferred templating system. See the L<Class::DBI::Factory::Handler> docs for much much more. 

There is also a rather experimental Class::DBI::Factory::Handler2 that should provide mod_perl 2 compatibility with little or no rewriting. It's in a fragile state at the moment because of fluctuations in the mod_perl and libapreq2 APIs, but later this year it should allow seamless migration from mod_perl 1 to 2 behind the Factory::Handler interface.

=item L<Class::DBI::Factory::Exception>

Pervasive but fairly simple exception-handling routines for CDF-based applications based on Apache return codes. CDF::Handler uses try/catch for everything, and most of the other classes here will throw a CDF::Exception on error. See C<fail()>, below.
  
=item L<Class::DBI::Factory::List>

A fairly comprehensive builder and paginater of lists. It's iterator-based, so should be able to paginate most normal CDBI query results. You can also supply search criteria during list construction. See C<list()> and C<list_from()>, below.
  
=item L<Class::DBI::Factory::Ghost>

'Ghost' objects are cdbi prototypes: each one is associated with a data class but doesn't belong to it. The ghost object will act like the cdbi object in most simple ways: column values can be set and relationships created, but without any effect on the database. I find this useful before the creation of an object (when populating forms) and after its deletion (for displaying confirmation page and deciding what next), but some people frown on such laziness. See C<ghost_object> and C<ghost_from>, below.

=item L<Class::DBI::Factory::Mailer>

This is a simple interface to Email::Send: it can send messages raw or use the factory's Template object to format them, and it will use the factory's configuration settings to decide how email should be sent. See C<email_message> below.

=back

None of these modules is loaded unless you make a call that requires it, and all of them are easily replaced with your own subclass or alternative module. They all have the same sort of endless POD as this one :)

=head2 PERSISTENCE AND CONCURRENCY

The factory object by itself is a fairly lean and simple thing. Once it has loaded your data classes it should add very little overhead. It is designed to load its helpers only when you do something that requires them, and until you do it should be only a little bit slower or bulkier than working with Class::DBI directly.

Constructing a factory object can take a little while, though: it has to load all your data classes, establish database connections, and if you're using TT it has to create its Template object. It's possible to do all that in the course of a CGI request, but really not advisable. That's why the factory comes with all its associated mod_perl machinery. The factory object is designed to stay in memory, holding its database connection, template object and data stores in readiness for the next request.

CDF::Handler objects are lightweight and short-lived: a new one is constructed to deal with every incoming request. They can be be quick and simple because it's the factory that does all the work. The normal sequence goes like this:

=over

=item 1. Apache directs an incoming request to mod_perl

=item 2. mod_perl causese the creation of a new Handler object to deal with the request.

=item 3. Handler object uses an existing Factory object for session-management, database access, configuration, template-processing machinery and the other resources needed to deal with the request.

=item 4. Handler object returns output to Apache and is destroyed.

=item 5. Factory waits in memory for next request.

=back

This is all made more useful by the fact that each factory is stored with a distinct id. You can keep several factories active in memory at once, each with a different configuration object and therefore its own cache of database handles, connection parameters, template paths and so on. 

Because the data classes' normal database-access methods have been replaced with factory calls, this means that you can use the same set of data classes in as many sites as you like. Each time they ask for database access, the factory object will give them the right database for the current site.

The factories don't really 'sleep', of course. They're held in a class-data hash in Class::DBI::Factory. When a handler (or data class, or other script) calls CDF->instance to get its factory object, the instance method will consult its input and environment, work out a factory id and return the factory it's holding against that hash key. If no such factory exists, it will be created, and then left available for future requests.

In most cases, the 'id' associated with the factory will be the name of a website. If you want, you can specify an $ENV{_SITE_TITLE} in Apache's virtualhost definition:

    PerlSetEnv _SITE_TITLE = 'mysite.com'
    
But CDF will fall back on the $ENV{SITE_NAME} that Apache defines for each virtualhost and which will contain the name given to its ServerName directive.

The same mechanism can be adapted any other situation where you want to keep one or more factory objects handy without having to pass them round all the time. The factory id can be specified directly:

  my $factory = Class::DBI::Factory->instance('cd_collection');

or based on any environment variable you specify, such as:

  $Class::DBI::Factory::factory_id_from = 'USER';

which will keep one factory per user. Note that changing $factory_id_from has universal effect within the current namespace.

If no id can be retrieved from anywhere to single out a particular factory, then CDF will return the same singleton factory object on every call to instance(). This is often a useful shortcut, but if you don't like it you can always call C<instance(blah)> and get an entirely new factory object instead.
  
=head2 MANAGED CLASSES

Each factory gathers up a set of what I've been calling 'data classes': that's your standard Class::DBI sub(sub)class with columns and relationships and whatnot. The set of classes is defined either by including a number of 'class' parameters in the configuration file(s) for each site, or by calling 

  $factory->use_classes( list of names );

directly. Or both. The factory will ask each class for its moniker, along with a few other bits of optional but useful information, then it will drop in two methods that force the class to use the factory for database access. The result is as if you had added this in your base data class:

  sub _factory { Class::DBI::Factory->instance; }
  sub db_Main { shift->_factory->dbh; }

and that should be all that's required to get your application hooked up to the factory. For convenience, I usually add these methods too:

  sub config { shift->_factory->config; }
  sub debug { shift->_factory->debug(@_); }
  sub send_message { shift->_factory->send_message(@_); }

...but I don't want to trample on anyone's columns more than I already have, so I'll leave that up to you.

Note that Class::DBI will follow relationships in the usual way, require()ing the foreign class and hooking it up. You still have to declare all those classes in the factory configuration if you want the factory to provide access to them, or them to have access to it. 

WARNING: If you miss out a class in the configuration but mention it in a has_many relationship, then that class will not be using the factory for its data access. This won't work, of course, and may mean that the barriers between your sites break down and cause bad strangeness.

=head1 FACTORY INTERFACE

Having bundled up a set of classes, the main purpose of the factory is to pass information between you and them. This is handled in a fairly intuitive and simple way: any mormal cdbi command of the form

  My::Class->foo(bar);

can be written

  $factory->foo($moniker, bar);
  
Provided that

  My::Class->moniker == $moniker;

and foo() is in the permitted set of methods, it should just work. If $moniker doesn't give us a valid class, we fail silently with only a debugging message. If foo() isn't allowed, we fail noisily. 
  
=head2 CONFIGURATION

CDF is commonly used with at least two configuration files: a global server config and a local site config, but you can supply any number of configuration files to be read at construction time:

  my $factory = Class::DBI::Factory->new(
  	'/global/config.file',
  	'/local/config.file',
    ...
  );
  
You can also make the factory read one or two configuration files by filling these two environment variables:
  
  $ENV{_CDF_CONFIG} = '/global/config.file';
  $ENV{_CDF_SITE_CONFIG} = '/local/config.file';
  my $factory = Class::DBI::Factory->new;

This can also be done with PerlSetEnv, of course. There is no functional difference between configuration files, except in that they are read in a certain order and later declarations may supercede earlier.

The work here is actually done by L<Class::DBI::Factory::Config>. Here's an example of a more practical configuration than the minimal ones above:

  db_type = 'SQLite'
  db_name = '/home/cdfdemo/data/cdfdemo.db'

  site_url = 'www.myrecords.com'
  site_title = 'My Record Collection'
  template_dir = '/home/myrecords/templates'
  template_suffix = 'html'

  class = 'My::Album'
  class = 'My::Artist'	
  class = 'My::Track'	
  class = 'My::Genre'	

  debug_level = 4
  mailer = 'Qmail'
  master_template = 'holder.html'
  default_view = 'front'

The config object is available to templates and data classes too, so there is no limit to the sort of information you might want to include there:

  form_box_width = '360px'
  html_email_allowed = 0
  show_document_count = 1
  ...

There's a sample application included with this distribution, using a configuration much like this one. It isn't big or clever, but it shows the basic principles at work and you might even be able to use it as a starting point. It uses SQLite and TT2, and should be very easy to set up provided you have a mod_perl-enabled Apache around. It's in C<./cdfdemo> and comes with a dim but enthusiastic installer and some B<very> basic documentation.

=head1 CONSTRUCTION METHODS

In which a factory is built according to the instructions in the one or more configuration files described above.

=head2 new( @config_files )

This is now just a synonym for instance(). To maintain the old interface, it doesn't expect a factory id and relies on instance() to detect one. Unless you take  steps to make sure that a site id can be discovered, this will mean that new() is a singleton constructor.

WARNING: If you want to use two factories with distinct configurations in the same script, you will need to construct them by calling C<instance(foo, ...)> and C<instance(bar, ...)>. Calling new() twice with different config files won't work because the second factory will overwrite the first in the internal store.

=cut

sub new {
	return shift->instance(undef, @_);
}

=head2 instance( $tag, @config_files )

Returns the factory corresponding to the supplied or discovered site id. If no such factory exists, it is created and stored.

If no id is supplied then C<site_id> is called, which by default will look for C<$ENV{_SITE_TITLE}>. If that doesn't work, we will attempt to use Apache's C<$ENV{SITE_NAME}>. If no site id is available from any source then a singleton factory object will be returned to all requests.

If you supply a list of configuration files to instance(), they will be used when a factory object is constructed. They will have no effect on an existing factory object.

  my $factory = Class::DBI::Factory->new(); 
  my $factory = Class::DBI::Factory->instance(); 
  # will use environment variables for site id and configuration file
    
  my $factory = Class::DBI::Factory->instance( $site_id );

  my $factory = Class::DBI::Factory->instance(
    $site_id,
    $global_config_file, 
    $per_site_package_file,
    $per_site_config_file,
    $per_user_config_file,
    $per_day_config_file...
  );

=cut

sub instance {
    my $class = shift;
	my $tag = shift || $class->site_id || $ENV{SITE_NAME} || '__singleton';
	return $_factories->{$tag} if $_factories->{$tag};
	
	$class->debug(1, "Creating new CDF instance for '$tag'", 'factory');
	my $self = bless {
		_timestamp => scalar time,
		_log => [],
		_packages => [],
		_classes => [],
		_sorted_classes => [],
		_title => {},
		_plural => {},
		_description => {},
	}, $class;
	$self->{_config_files} = \@_ if @_;
    $self->{_site} = $tag;
    $_factories->{$tag} = $self;
    return $self;
}

=head2 factory_id_from()

A handy mutator that gets or sets the name of the environment variable that we will use as the key when storing and retrieving a factory object. It defaults to the arbitrary _SITE_ID, as explained above. 

Note that this has global effect. If you want to do odd things with a particular factory's id, you have to supply it directly to the construction and retrieval methods. The easiest way to do that is call to instance( $site_id ) for the initial construction step.

=cut

sub factory_id_from {
    my $class = shift;
    return $factory_id_from = $_[0] if @_;
    return $factory_id_from;
}

sub site_id {$ENV{ shift->factory_id_from }}

=head2 config_class()

Should return the Full::Class::Name that will be used to handle factory configuration. Defaults to L<Class::DBI::Factory::Config>. 

=head2 config()

Returns the configuration object which the factory is using, with which any settings can be retrieved or set.

If you're using L<Class::DBI::Factory::Config>, then the config object is just a thinly-wrapped L<AppConfig> object.

Note that no configuration is read or built until you call config(). The first call to this method will cause the factory to load Class::DBI::Factory::Config and thus AppConfig and read whatever configuration files have been specified.

=cut

sub config_class { "Class::DBI::Factory::Config" }

sub config {
	my ($self, $parameter) = @_;
	unless ($self->{_config}) {
        $self->_require_class( $self->config_class );
        my @cf = $self->{_config_files} ? @{ $self->{_config_files} } : ($ENV{_CDF_CONFIG}, $ENV{_CDF_SITE_CONFIG});
    	$self->{_config} = $self->config_class->new(@cf);
	}
	return $self->{_config} unless $parameter;
	return $self->{_config}->get($parameter);
}

sub config_files {

}

=head2 id()

Returns the site tag by which this factory would be retrieved. This ought to be the same as C<site_id>, which looks in the host configuration, unless something has gone horribly wrong.

=cut

sub id { shift->{_site} }

=head2 use_classes()

For quick and dirty work you can skip any or all of these configuration mechanisms and just pass in a list of Full::Class::Names. You can also set configuration parameters, so this will work:

  my $factory = Class::DBI::Factory->new;
  $factory->use_classes( qw(My::Movie My::Actor My::Role) );
  $factory->config->set( worst_effects_ever => 'All out monsters attack!' );
  
This has to be done first, before any factory method is called that depends on the data classes being loaded, which is nearly all of them.

=cut

sub use_classes {
    my ($self, @classes) = @_;
    $self->fail(-text => "Can't call use_classes() after classes already loaded") if $self->{_loaded};
    $self->config->set(class => $_) for @classes;
}

=head2 init()

Initialises the factory: loads data classes, reads configuration files, and so on. When constructed the factory is vacant: this method populates it with classes. init() is called for you before any factory operation that needs it, so you very rarely need to invoke it directly. There are a few situations, though: if you want to access a data class directly before you have done anything else with the factory, for example. This is rare outside a test script.

init() just calls _load_classes(), but this may change in future. Use init().

=head2 _load_classes()

Each class that has been specified in the configuration (the list is retrieved by calling C<_class_names>, if you felt like changing it in devious ways) is C<require>d here, in the usual eval-and-check way, and its moniker stored as a retrieval key. 

Normally this is done only once, and before anything else happens, but if you call C<_load_classes(1)> (or with any other true value), you force it to require everything again. This doesn't unload the already required classes, so you can't, currently, use this to change the list of managed classes.

This is mostly accomplished by calls to the following methods:

=head2 pre_require()

This method is called once before the loading of classes begins (unlike post_require, which is called for each class). It can act on the configuration data to affect the list of classes called, or make whatever other preparations you require. The default does nothing. 

=head2 load_class()

This method handles the details of incorporating each individual class into the application. It requires the module, checks that the require has worked, and among other things makes calls to C<assimilate_class> and then C<post_require> for each class:

=head2 assimilate_class()

This method is called to store information about the class in the factory object. The default version here hopes that each class will have at least some of the following methods:

=over

=item moniker: a tag by which to refer to the class, eg 'cd'

=item class_title: a proper name by which the class can be described, eg 'CD'

=item class_plural: plural form of the title

=item class_description: a blurb about the class

=back

Only the moniker is actually required and the standard cdbi moniker mechanism will normally provide that, so you can safely ignore all this unless it seems useful.

=head2 post_require

This is called for each class after it has been loaded and assimilated, and is supplied with the moniker and full class name. 

Here it is used to place C<factory()> and C<db_Main()> methods in each data class. That work is actually done by:

=head2 create_factory_accessor

Which you can override or ignore. If your cdbi subclass already has a db_Main method that you want to keep, just override post_require().
	
=cut

sub init {
	return shift->_load_classes(@_);
}

sub _load_classes {
	my ($self, $reload) = @_;
	return if $self->{_loaded} && ! $reload;
	$self->debug(3, "loading data classes", 'factory');
	$self->pre_require();
	$self->load_class($_) for @{ $self->_class_names };
	$self->{_loaded} = 1;
	return $self;
}

sub load_class {
	my ($self, $class) = @_;
	return unless $class;
	return $self->fail({ -text => "load_class: bad class name: '$class'" }) unless $class !~ /[^\w:]/;
	$self->debug(5, "loading class '$class'", 'factory');
	$self->_require_class($class);
	$self->assimilate_class($class);
	$self->post_require($class);
}

sub _require_class {
	my ($self, $class) = @_;
	return if (eval "defined %${class}::");
	eval "require $class";
	return $self->fail({ -text => "failed to load class '$class': $@" }) if $@;
}

sub assimilate_class {
	my ($self, $class) = @_;
	return unless $class;
	my $moniker = $class->moniker;
	push @{ $self->{_classes} }, $moniker;
	$self->{_class_name}->{$moniker} = $class;
	$self->{_title}->{$moniker} = $class->class_title;
	$self->{_plural}->{$moniker} = $class->class_plural;
	$self->{_description}->{$moniker} = $class->class_description;
}

sub pre_require { return }

sub post_require { 
    my ($self, $class) = @_;
	$self->create_factory_accessor($class);
}

sub create_factory_accessor {
    my ($self, $class) = @_;
    my $factory_class = ref $self;
    no strict ('refs');
	*{"$class\::_factory"} = sub { 
		return $factory_class->instance;
	};
    *{"$class\::db_Main"} = sub { 
        return shift->_factory->dbh;
    };
}

sub AUTOLOAD {
	my $self = shift;
	my $moniker = shift;
	$self->init;
	my $method_name = $AUTOLOAD;
	$method_name =~ s/.*://;
	my ($package, $filename, $line) = caller;
    $self->debug(4, "CDF->$method_name called at $package line $line", 'factory');
    return if $method_name eq 'DESTROY';

	my $class = $self->class_name($moniker);
	$self->debug(1, "bad AUTOLOAD call: no class from moniker '$moniker'", 'factory') unless $class;
  	return unless $class;
	
	my $method = $self->permitted_methods($method_name);
	return $self->fail({
	   -text => "Class::DBI::Factory::AUTOLOAD is trying to call a '$method_name' method that is not recognised",
	}) unless $method;
	
	$self->debug(3, "AUTOLOAD: $class->$method(" . join(', ', @_) . ");", 'factory');
	return wantarray ? $class->$method(@_) : scalar( $class->$method(@_) );
}

=head2 permitted_methods()

This method defines a core set of method calls that the factory will accept and pass on to data classes: it's the Class::DBI interface, basically, along with the extensions provided by Class::DBI::mysql and a few synonyms to cover old changes (has_column == find_column, for example) or simplify template code. 

It does this by returning a hash of 

  factory_method_name => cdbi_object_method_name,

which is used as a dispatch table by AUTOLOAD. Subclass this method to replace the standard factory interface with a reduced or different set of allowed methods.

=cut

sub permitted_methods {
	my ($self, $call) = @_;
	return unless $call;
	my $extras = $self->extra_methods();
	return $extras->{$call} if $extras->{$call};
	
	my $standard_ops = {
		create => 'create',
		retrieve => 'retrieve',
		find_or_create => 'find_or_create',
		foc => 'find_or_create',
		all => 'retrieve_all',
		retrieve_all => 'retrieve_all',
		search => 'search',
		search_like => 'search_like',
		like => 'search_like',
		where => 'search',
		retrieve_where => 'search',
		count_all => 'count_all',
		count => 'count_all',
		max => 'maximum_value_of',
		min => 'minimum_value_of',
		has_column => 'find_column',
		find_column => 'find_column',
		columns => 'columns',
		table => 'table',
		primary => 'primary',
		create_table => 'create_table',
		set_up_table => 'set_up_table',
		retrieve_random => 'retrieve_random',
		random => 'retrieve_random',
		column_type => 'column_type',
		enum_vals => 'enum_vals',
		meta_info => 'meta_info',
	};
	return $standard_ops->{$call};
}

=head2 extra_methods()

This is a hook to allow subclasses to extend (or selectively override) the set of permitted method calls with a minimum of bother. It returns a reference to a hash that is appended to the hash returned by C<permitted_methods>, with the same factory method => cdbi method structure.

It's common for a local subclass of Class::DBI to add custom operations to the normal cdbi set: a C<retrieve_latest> here, a C<delete_older_than> there. To access these methods through the factory, you need to add a local factory subclass next to the cdbi subclass, containing at least an C<extra_methods> method.

  package My::Factory;
  use base qw( Class::DBI::Factory );

  sub extra_methods {
    return {
      latest => retrieve_latest,
      purge => delete_older_than,
      by_title => retrieve_by_title,
    }
  }

The default extra_methods method doesn't do anything, so it can be overridden freely.

=cut

sub extra_methods { return {} }

=head2 classes()

returns an array reference containing the list of monikers. This is populated by the C<_load_classes> method and includes only those classes which were successfully loaded.

=head2 _class_names()

returns an array reference containing the list of full class names.

=head2 class_name()

Returns the full class name for a given moniker.

=head2 has_class()

Returns true if the supplied value is a valid moniker.

=cut

sub classes {
	my $self = shift;
	$self->init;
	return $self->{_classes};
}

sub _class_names {
	return shift->config->classes;
}

sub class_name {
	my ($self, $moniker) = @_;
	$self->init;
	return $self->{_class_name}->{$moniker};
}

sub has_class {
	my ($self, $moniker) = @_;
	$self->init;
	return exists $self->{_class_name}->{$moniker};
}

=head2 relationships( $moniker, $type )

A handy gadget that looks into Class::DBI's meta_info to find the relationships entered into by the monikered class. 
The relationship type defaults to 'has_a', and we return a hash of method names => foreign class monikers.

  $factory->relationships( 'album' );

in the supplied demo application would return ('genre', 'artist').

=head2 relationship_exists( $moniker, $relationship )

Returns true if the class designated by $moniker has a has_many relationship of the supplied name. 

=cut

sub relationships {
    my ($self, $moniker, $reltype) = @_;
    return unless $moniker;
    $reltype = 'has_a' unless $reltype eq 'has_many' || $reltype eq 'might_have';
    my $meta_info = $self->meta_info($moniker, $reltype);
    return unless $meta_info && %$meta_info;
    my %relations = map { $_ => $self->moniker_from_class( $meta_info->{$_}->foreign_class ) } keys %$meta_info;
    return \%relations;
}

sub relationship_exists {
    my ($self, $moniker, $relationship) = @_;
    return unless $moniker && $relationship;
    return unless $self->meta_info($moniker, 'has_many', $relationship);
    return 1;
}

=head2 moniker_from_class()

Given a full class name, returns the moniker. This is rarely used directly, since you would normally just call $class->moniker, but it is wrapped in an eval and therefore safe in the case of an uncertain value for $class.

=cut

sub moniker_from_class {
	my ($self, $class) = @_;
	return unless $class;
	my $moniker;
	eval {
	   $moniker = $class->moniker;
    };
    $self->debug(3, "bad moniker_from_class call: '$class' gives error $@", 'factory') if $@;
    return $moniker;
}

=head2 moniker_from_relationship()

Given a moniker and a has_many relationship name, returns the moniker of the foreign class. This is useful if, say, you want to count the number of related objects in SQL rather than perl: You can turn the relationship name into a class name here and call count_where on that.

=cut

sub moniker_from_relationship {
	my ($self, $moniker, $relationship) = @_;
	return unless $moniker && $relationship;
    my $meta_info = $self->meta_info($moniker, 'has_many', $relationship);
    $self->debug(3, "moniker_from_relationship: $moniker->$relationship gives: " . Dumper($meta_info), 'factory');
    return $self->moniker_from_class($meta_info->{foreign_class});
}

=head2 inflate_if_possible()

Accepts a column name => value pair and inflates the value, if possible, into a member of the class monikered by the column name.

=cut

sub inflate_if_possible {
	my $self = shift;
	my ($column, $content, $calling_moniker) = @_;
	return $content unless $column;
	return $content if ref $content;
	my $moniker = $self->translate_to_moniker($column, $calling_moniker) || $column;
	return $content unless $self->has_class( $moniker );
	return $self->retrieve( $moniker, $content ) || $content;
}

=head2 translate_to_moniker( column name, moniker of calling class )

Some column names don't match the moniker of the objects they contain: perhaps because there is more than one column containing that type, or perhaps just for readability. get_moniker maps the column name onto the moniker. 

The method defined here (which expects to be overridden), strips _id off the end of a column name, and maps 'parent' onto the moniker of the present class.

=cut

sub translate_to_moniker {
	my ($self, $tag, $parent_moniker) = @_;
	my $aliases = $self->moniker_aliases || {};
    return $parent_moniker if $tag eq 'parent';
    return $aliases->{$tag} if $aliases->{$tag};
    $tag =~ s/_id$//;
    return $tag;
}

=head2 moniker_aliases( )

Returns a hashref of column_name => moniker that is used by translate_to_moniker to turn column names into monikers for inflation. This is only of relevance to $factory->inflate_if_possible, which is called from a few places (like Handler->param) but doesn't have any effect on the normal cdbi inflation mechanism.

The hashref is empty by default: this method expects to be subclassed.

=cut

sub moniker_aliases {{}}

=head2 ghost_class()

Sets and/or returns the Full::Class::Name that will be used to handle paginated lists. Checks the value of $Class::DBI::Factory::list_class then defaults to L<Class::DBI::Factory::List>.

There are several methods here of this form, used to determine the class that should be used to perform some function or other. They include list_class, mailer_class, iterator_class and ghost_class. The logic is the same in each case;

=over
=item the value supplied
=item the value previously supplied or discovered
=item the class-wide default, if set
=item the hard default
=back

In the case of ghost_class, the class-wide default is held in $Class::DBI::Factory::ghost_class and can be set at any time. The hard default if no other value is discovered is 'Class::DBI::Factory::Ghost', which is the standard helper that comes with CDF. The other methods work in the same way but with predictably different variable names.

=cut

sub ghost_class { 
	my $self = shift;
	return $self->{_ghost_class} = $_[0] if @_;
	return $self->{_ghost_class} if $self->{_ghost_class};
	return $self->{_ghost_class} = $ghost_class || 'Class::DBI::Factory::Ghost';
}

=head2 ghost_object( moniker, columns_hashref )

Creates and returns an object of the ghost class, which is just a data-holder able to mimic a cdbi object well enough to populate a template, but no more. A hashref of column=>value should be supplied and will be used to construct the ghost.

=cut

sub ghost_object {
    my ($self, $moniker, $columns) = @_;
    my ($package, $filename, $line) = caller;
    $self->debug(4, 'ghost_object(' . join(',',@_) . ") called at $package line $line", 'factory');
    $self->_require_class( $self->ghost_class );
    $columns ||= {};
    $columns->{moniker} = $moniker;
    $columns->{date} = $self->now;
    return $self->ghost_class->new($columns);
}

=head2 ghost_from( data_object )

Returns a ghost object based on the class and properties of the supplied real object. This is useful to keep a record of an object about to be deleted, for example. 

(In which case the deleted object can be reconsituted with a call to C<$ghost-\>make>. You will lose anything that was removed in a cascading delete, though. This is not nearly good enough to serve as an undo mechanism unless you extend the ghost to ghost all its relatives too).

=cut

sub ghost_from {
    my ($self, $thing) = @_;
    $self->_require_class( $self->ghost_class );
    return $self->ghost_class->from($thing);
}

=head2 title() plural() description()

each return the corresponding value defined in the data class, as in:

  Which of these [% factory.plural('track') %] 
  has not been covered by a boy band?
  
We only have these values if you add the corresponding class_title, class_plural and class_description methods to your data classes. I normally do this:

  package My::Album
  sub moniker { 'album' }
  sub class_title { 'Album' }
  sub class_plural { 'Albums' }
  sub class_description { 'An album (from Latin albus "white", "blank", relating to a blank book in which something can be inserted) is a packaged collection of related things.' }

=cut

sub title {
	my ($self, $moniker) = @_;
	return $self->{_title}->{$moniker} if $moniker;
	return $self->{_title};
}

sub plural {
	my ($self, $moniker) = @_;
	return $self->{_plural}->{$moniker} if $moniker;
	return $self->{_plural};
}

sub description {
	my ($self, $moniker) = @_;
	return $self->{_description}->{$moniker} if $moniker;
	return $self->{_description};
}

=head1 USEFUL SERVICES

The rest of the factory's functions are designed to provide support to L<Class::DBI> applications. The factory is an efficient place to store widely used components like database handles and template engines, pagers, searches and lists, and to keep useful tools like C<escape> and C<unescape>, so that's what we do:

=head2 dsn()

Returns the $data_string that CDF is using to create handles for this factory. Some modules - like L<Class::DBI::Loader> - want to be given a dsn rather than a database handle: sending them $factory->dsn should just work.

If a db_dsn parameter is supplied, it is accepted intact. Otherwise we will look for db_type, db_name, db_host, db_server and db_port parameters to try and build a suitable data source string. You will probably also want to db_username and db_password settings unless you're using SQLite.

=head2 dbh()

Returns the database handle which is used by this factory. 

Each factory normally has one handle, created according to its configuration instructions and then made available to all its data classes. The main point of this is to get around the one class -> one table assumptions of Class::DBI: each factory can provide a different database connection to the data using different data.

For this to be useful you must also override db_Main in your Class::DBI subclass, eg:

  sub db_Main { return shift->factory->dbh(@_); }

Should do it, except that you will probably have subclassed CDF, and should use the name of your subclass instead.

You can safely ignore all this unless your data clases need access to configuration information, template handler, unrelated other data classes or some other factory mechanism.

=head2 set_db()

Can be used to set database connection values if for some reason you don't want them in a config file. Expects to receive a hashref of parameters. The tests for CDF use this approach, if you want a look.

  $factory->set_db({
    db_type => '...',         # defaults to 'SQLite'
    db_host => '...',         # in which case no other parameters
    db_port => '...',         # are needed except a path/to/file
    db_name => '...',         # in db_name
    db_username => '...',
    db_password => '...',
  });
 
Defaults can be supplied by C<Class::DBI::Config::default_values>, which is called early in the configuration process.

=cut

sub dsn {
	my $self = shift;
	my $dsn = $self->config->get('db_dsn');
	unless ($dsn) {
	    $dsn = "dbi:" . $self->config->get('db_type') . ":";
	    $dsn .= "dbname=" . $self->config->get('db_name') if $self->config->get('db_name') && $self->config->get('db_name') ne '<undef>';
    	$dsn .= ";server=" . $self->config->get('db_servername') if $self->config->get('db_servername') && $self->config->get('db_servername') ne '<undef>';
    	$dsn .= ";host=" . $self->config->get('db_host') if $self->config->get('db_host') && $self->config->get('db_host') ne '<undef>';
    	$dsn .= ";port=" . $self->config->get('db_port') if $self->config->get('db_port') && $self->config->get('db_port') ne '<undef>';
    }
    return $dsn;
}

sub dbh {
    my $self = shift;
    my $dbh = &{ $self->_dbc() };
    $self->debug(0, 'No database handle returned. Please check database account.', 'factory') unless $dbh;
    if ($self->config->get('dbi_trace')) {
        $dbh->trace( $self->config->get('dbi_trace'), $self->config->get('dbi_trace_file') || undef );
    }
    return $dbh;
}

sub set_db {
	my ($self, $parameters) = @_;
	$self->config->set($_, $parameters->{$_}) for grep { exists $parameters->{$_} } qw(db_type db_name db_username db_password db_port db_host db_dsn);
}

=head2 _dbc()

Taps into the terrible innards of Ima::DBI to retrieve a closure that returns a database handle of the right kind for use here, but instead of being incorprated as a method, the closure is stored in the factory object's hashref.

(All C<dbh> really does is to execute the closure held in $self->{_dbc}.)

This depends on close tracking of internal features of Ima::DBI and Class::DBI, since there is no easy way to make use of the handle-creation defaults from the outside. It will no doubt have to change with each update to cdbi.

=cut 

sub _dbc {
	my $self = shift;
	return $self->{_dbc} if $self->{_dbc};
	my $dsn = $self->dsn;
	my $attributes = $self->db_options;
	my @config = (
		$dsn,
		$self->config->get('db_username'), 
		$self->config->get('db_password'), 
		$attributes,
	);
	return $self->{_dbc} = Ima::DBI->_mk_db_closure(@config);	
}

=head2 db_options()

Returns the hash of attributes that will be used to create database connections. Separated out here for subclassing. This too will change abruptly when new versions of CDBI come out.

=cut 

sub db_options {
    my $self = shift;
    return {
        AutoCommit => $self->config->get('db_autocommit') || '',
        RaiseError => $self->config->get('db_raiseerror') || '',
        ShowErrorStatement => $self->config->get('db_showerrorstatement') || '',
        FetchHashKeyName => 'NAME_lc',
        ChopBlanks => 1,
        PrintError => 0,
        Taint => $self->config->get('db_taint') || '',
        RootClass => $self->db_rootclass,
    }
}

=head2 db_rootclass()

Returns the full name of the root class for $dbh. It is very unlikely that this will not be DBIx::ContextualFetch, but I suppose you might have subclassed that.

I doubt very much that any good will come of changing this unless you do it immediately upon construction of the factory and before any database has been accessed access.

=cut 

sub db_rootclass { 
	my $self = shift;
	return $self->{_db_rootclass} = $_[0] if @_;
	return $self->{_db_rootclass} if $self->{_db_rootclass};
	return $self->{_db_rootclass} = $db_rootclass || 'DBIx::ContextualFetch';
}

=head2 tt()

Like the database handle, each factory object can hold and make available a single Template object. This is almost always called by handlers during the return of a page, but you sometimes find that the data classes themselves need to make use of a template, eg. to publish a page or send an email. If you don't intend to use the Template Toolkit, you can override C<process> or just ignore all this: the Toolkit is not loaded until C<tt> is called.

Template paths can be supplied in two ways: as simple template_dir parameters, or by supplying a single template_root and several template_subdir parameters. The two can be combined: See L<Class::DBI::Factory::Config> for details.

=cut

sub tt {
	my $self = shift;
	return $self->{_tt} if $self->{_tt};

	$self->debug(3, 'loading Template Toolkit', 'factory');
    $self->_require_class( 'Template' );

	my $recursion = $self->config->get('allow_template_recursion') || '0';
    my $path = $self->config->template_path || [];
	$self->debug(3, "recursion is '$recursion'\ntemplate path is '" . join(', ', @$path) . "'", 'factory');

	my $tt = Template->new({ 
		INCLUDE_PATH => $path, 
		RECURSION => $recursion,
	});
	
	return $self->fail({
	   -text => "Template initialisation error: $Template::Error",
	}) unless $tt;

	return $self->{_tt} = $tt;
}

=head2 process()

  $self->process( $template_path, $output_hashref, $outcome_scalar_ref );

Uses the local Template object to display the output data you provide in the template you specify and store the resulting text in the scalar (or request object) you supply (or to STDOUT if you don't). If you're using a templating system other than TT, this should be the only method you need to override.

Note that C<process> returns Apache's OK on success and SERVER_ERROR on failure, and OK is zero. It means you can close a method handler with C<return $self->process(...)> but can't say C<$self-<gt>process(...) or ... >

This is separated out here so that all data classes and handlers can use the same method for template-parsing. It should be easy to replace it with some other templating system, or amend it with whatever strange template hacks you like to apply before returning pages.

=cut

sub process {
	my ($self, $template, $data, $outcome) = @_;
	$self->debug(3, "CDF: processing template '$template'.", 'factory');
	return 0 if $self->tt->process($template, $data, $outcome);
	return $self->fail({
	   -text => $self->tt->error,
	});
}

=head2 list()

returns a list object with the parameters you specify. These can include column values as well as display parameters:

  my $list = $factory->list('cd',
    year => 1969,
    artist => $artist_object,
    sort_by => 'title',
    sort_order => 'asc',
    step => 20,
  );

The default list module (L<Class::DBI::Factory::List>) will build a query from the criteria you specify, turn it into an iterator and provide hooks that make it easy to display and paginate lists.

=head2 list_from()

For situations where the C<list> method doesn't quite provide the right access, you can also create a list object from any iterator by calling:

  my $list = $factory->list_from($iterator);

Which will provide display and pagination support without requiring you to jump through so many hoops.

=head2 list_class()

Sets and/or returns the Full::Class::Name that will be used to handle paginated lists. Checks the value of $Class::DBI::Factory::list_class then defaults to L<Class::DBI::Factory::List>.

=cut

sub list {
	my ($self, $moniker, %criteria) = @_;
    $self->_require_class( $self->list_class );
 	$criteria{moniker} ||= $moniker;
	return $self->list_class->new(\%criteria);
}

sub list_from {
	my ($self, $iterator, $source, $param) = @_;
	return unless $iterator;
    $self->_require_class( $self->list_class );
	return $self->list_class->from( $iterator, $source, $param );
}

sub list_class { 
	my $self = shift;
	return $self->{_list_class} = $_[0] if @_;
	return $self->{_list_class} if $self->{_list_class};
	return $self->{_list_class} = $list_class || 'Class::DBI::Factory::List';
}

=head2 iterator_from( class, listref )

Returns an iterator built around the list of supplied ids. A list of objects can also be used instead: it's not very efficient, but sometimes it's necessary.

=head2 iterator_class()

Sets and/or returns the Full::Class::Name that will be used to build iterators. Checks the value of $Class::DBI::Factory::iterator_class then defaults to L<Class::DBI::Factory::List>.

=cut

sub iterator_class { 
	my $self = shift;
	return $self->{_iterator_class} = $_[0] if @_;
	return $self->{_iterator_class} if $self->{_iterator_class};
	return $self->{_iterator_class} = $iterator_class || 'Class::DBI::Iterator';
}

sub iterator_from {
    my ($self, $class, $list) = @_;
    return unless $class && $list;
	$class->debug(3, "building iterator from list of " . scalar(@$list) . " items of class $class", 'factory');
    return $self->iterator_class->new($class, $list);
}

=head2 fail( $parameters )

A general-purpose failure-handler. Throws a SERVER_ERROR exception with the supplied -text parameter. Parameters are passed on to the exception handler. If you don't like CDF::Exception, overriding this method will almost make it go away.

=cut

sub fail {
    my ($self, $failure) = @_;
    my $text = $failure->{-text} || "An unspecified error has occurred!";
    die $text if delete $failure->{-fatal};
    throw Exception::SERVER_ERROR( %$failure );
}

=head1 EMAIL

This is a bit tangential, but for web applications the factory is the obvious place to handle email-sending: like the template and database connections, we hold an email channel open and wait for instructions.

=head2 mailer_class()

Sets and/or returns the Full::Class::Name that will be used to handle email. Checks the value of $Class::DBI::Factory::mailer_class then defaults to L<Class::DBI::Factory::Mailer>.

=head2 mailer()

Returns an object of the mailer class. These are usual very dumb creatures with only a send_message method and a few bits and pieces. We'll hang on to it and it should be used for all subsequent emailing duties.

=cut

sub mailer_class { 
	my $self = shift;
	return $self->{_mailer_class} = $_[0] if @_;
	return $self->{_mailer_class} if $self->{_mailer_class};
	return $self->{_mailer_class} = $mailer_class || 'Class::DBI::Factory::Mailer';
}

sub mailer {
	my $self = shift;
	return $self->{_mailer} = $_[0] if $_[0];
	return $self->{_mailer} if $self->{_mailer};
    $self->_require_class( $self->mailer_class );
    return $self->{_mailer} = $self->mailer_class->new;
}

=head2 send_message()

Sends an email message. See L<Class::DBI::Factory::Mailer> for more about the required and possible parameters, but to begin with:

  $factory->send_message({
    to => 'someone@there',
    from => 'someone@here',
    subject => 'down with this kind of thing',
    message => 'Careful now',
  });

Instead of the C<message> parameter, you can pass through a template path as C<template>. The usual templating mechanism will be used to generate the message using the other values you have supplied will be passed to the template. Otherwise, the mailer will look for a message parameter and treat that as finished message text.

=head2 email_admin()

Sends a message to the standard admin address associated with this factory configuration. Otherwise exactly the same as send_message.

=cut

sub send_message {
    shift->mailer->send_message(@_);
}

sub email_admin {
    shift->mailer->email_admin(@_);
}

=head1 DEBUGGING

The factory provides a general-purpose logger that prints to STDERR. Each debugging message has an importance value and optionally a set of subject tags. The configuration of each factory defines a threshold, and a set of debugging topics that we're interested in. If the message importance is less than the threshold, and there is an overlap between the debugging topics and the message tags, the message will be printed.

If there are no debugging topics in the configuration, that part of the filter is omitted and all sufficiently urgent messages appear.

Note that including debugging lines always incurs some small cost, since this method is called and the threshold comparison performed each time, even if the message isn't printed. For more expensive debugging operations you might want to test the value of $factory->debug_level before doing the work.

  $self->factory->debug_level(1);
  $self->factory->debug(2, 
    "session id is $s", 
    "session key is $k",
    "these messages will not be logged",
  );
  $self->factory->debug(0, "but this will appear in the log");

=head2 debug( $importance, @messages )

Checks the threshold and prints the messages. Each message has prepended a [site_id] marker, but even so nothing will make much sense if requests overlap. For debugging processes you probably want to run apache in single-process mode.

=cut

sub debug {
    my ($self, $level, $message, @topics) = @_;
    return unless $message;
    my $threshold = $self->debug_level || 0;
    return if $level > $threshold;
    
    my $debug_topics = $self->debug_topics;
    my @relevant_topics;
   	return unless ! $debug_topics or ! @$debug_topics or @relevant_topics = _list_overlap($debug_topics, \@topics);

    my $id = (ref $self) ? $self->id : '*';
    $id .= ": " . join(', ', @relevant_topics) if @relevant_topics;
    warn "[$id] $message\n";
    return;
}

sub _check_debug_topics {
    my ($self, @messagetopics) = @_;
    my $debugtopics = $self->debug_topics;
    return @messagetopics unless $debugtopics;
    my %sitetopics = map { $_=> 1 } @$debugtopics;
    return grep { $sitetopics{$_} } @messagetopics;
}

=head2 debug_level()

Sets and gets the threshold for display of debugging messages. Defaults to the config file value (set by the debug_level parameter). Roughly:

=over

=item B<debug_level = 1>

prints a few important messages: usually ways in which this request or operation differs from the normal run of events
  
=item B<debug_level = 2>

prints markers as well, to record the stages of a request or operation as it is handled. This can be a useful trace when trying to locate a failure.
  
=item B<debug_level = 3>

adds more detail, including AUTOLOAD calls and other bulky but useful notes.
  
=item B<debug_level = 4>

prints pretty much everything as it happens.

=item B<debug_level = 5>

won't shut up.

=back

If C<debug()> is called as a class method, configuration information will not be available. In that case the global value

  $Class::DBI::Factory::class_debug_threshold

will be used. It defaults to zero. Changing it will have global effect within the current namespace (eg all factories within a given apache process).

=head2 debug_topic {

Debug messages optionally come with additional parameters that associate them with one or more topics. If you supply one or more debug_topic parameters either by passing them to this method or by including one or more debug_topic parameters in the site configuration, then only messages associated with those topics will be printed.

Useful possibilities include 'handler', 'input', 'templates', 'storage', 'factory', 'list', 'ghost' and 'session'.

If no topic is defined then all messages of sufficent importance are printed.

=cut

sub debug_level {
    my $self = shift;
    return $class_debug_level unless ref $self;
    return $self->{_debug_level} = $_[0] if @_;
    return $self->{_debug_level} if $self->{_debug_level};
    return $self->{_debug_level} = $self->config->get('debug_level') || $class_debug_level;
}

sub debug_topics {
    my $self = shift;
    return unless ref $self;
    return $self->{_debug_topics} = [@_] if @_;
    $self->{_debug_topics} ||= $self->config->get('debug_topic'); # listref
    return $self->{_debug_topics} || [];
}

=head2 version()

Returns the global C<$Class::DBI::Factory::VERSION>, so your subclass will probably want its own version method.

=cut

sub version {
	return $VERSION;
}

=head2 timestamp()

Returns the timestamp (ie creation time in epoch seconds) of this factory object. Sometimes useful for debugging, especially if you're using GTopLimit or some such killer-off.

The config object associated with the factory normally has its own timestamp: unlike this one, it is updated when the configuration is refreshed. Comparing them can be useful.

=cut

sub timestamp {
	my $self = shift;
	return $self->{_timestamp} if ref $self;
}

=head2 add_status_menu()

If CDF is loaded under mod_perl and Apache::Status is in your mod_perl configuration, then calling C<CDF->add_status_menu> will add a menu item to the main page. The obvious place to call it from is startup.pl.

The report it produces is useful in debugging multiple-site configurations, solving namespace clashes and tracing startup problems, none of which should happen if the module is working properly, but you know.

Remember that the server must be started in single-process mode for the reports to be of much use, and that factories are not created until they're needed (eg. on the first request, not on server startup), so you need to blip each site before you can see its factory in the report.

=cut

sub add_status_menu {
	Apache::Status->menu_item(
		'factories' => "Class::DBI::Factory factories",
		\&status_menu
	);
}

sub status_menu {
	my ($r,$q) = @_;
	my @strings = (qq|<h1>CDF factories</h1><p>This is the list of factory-instances currently in memory. The factory is not created until a request requires it, so you need to blip each site before you see the factories here, and that the same goes for each apache child process. This (and other Apache::Session reports) will work best in single-process mode.</p>|);

	for (sort keys %$_factories) {
		my $string = "<h3>site id: $_</h3>";
		my $factory = __PACKAGE__->instance($_);

		$string .= "<b>in memory:</b> " . $factory . "<br>";

		$string .= "<b>configuration files:</b> " . join(', ', $factory->config->files) . "<br>";
		$string .= "<b>database name:</b> " . $factory->config->db_name . "<br>";
		$string .= "<b>database handle:</b> " . $factory->dbh . "<br>";
		$string .= "<b>template object:</b> " . $factory->tt . "<br>";

		$string .= "<b>managed classes:</b> ";
		$string .= join(', ', map { qq|<a href="?$_">$_</a>| } @{ $factory->_class_names });
		$string .= "<br>";

		push @strings, $string;
	}
	return \@strings;
}

=head1 SUBCLASSING

In serious use, Class::DBI::Factory and all its helper modules expect to be subclassed and extended. The methods you will want to look at first are probably:

  CDF::Handler::build_page()
  CDF::Handler::factory_class()
  
  CDF::pre_require()
  CDF::post_require()
  CDF::extra_methods()
  CDF::list_class()
  CDF::mailer_class()
  CDF::iterator_class()
  
  CDF::Config::skeleton()
  CDF::Config::list_parameters()
  CDF::Config::hash_parameters()
  CDF::Config::default_values()

All of which have been separated out and surrounded with ancillary methods in order to facilitate selective replacement. See the method descriptions above, and in the helper modules, which will go on about all this in exhausting detail.

I'm trying to keep CDF minimal and to the point, with variable success. It's always tempting to implement something at this level, so that it's universally available, so the development cycle has mostly consisted of throwing stuff in and then pruning carefully. This version (0.9) is mostly the result of pruning, so you can imagine how bushy some of the others have been :)

For an example of how much can be done on this platform, have a look at www.spanner.org/delivery/

=head1 KNOWN ISSUES

=over

=item This version of CDF is unlikely to work with any combination other than Class::DBI 0.96 and Ima::DBI 0.33.

=item CDF under mod_perl is not compatible with the unique-object cache introduced in Class::DBI v0.96, and cannot be made so since the cache is held as class data and assumes that an object of a class with a certain id is always the same object. The next version of CDBI will probably give me a way to work with this: there are plans to introduce a more structured object cache, and/or to make it possible to subclass some of its storage and retrieval mechanisms. Until then, the factory disables the cache immediately upon loading.

=item Class::DBI and Apache::DBI are not entirely compatible. This is because Ima::DBI has its own caching mechanism for database handles. It's not a serious problem unless you're using database transactions, in which case some necessary cleaning up doesn't happen, but it's easily avoided just by omitting Apache::DBI from your setup.

=item I haven't tried using CDF with the various setup_table methods provided by cdbi subclasses like Class::DBI::mysql. There's no reason why they shouldn't work, but no reason why they should, either.

=back

=head1 BUGS

Are likely. Please use http://rt.cpan.org/ to report them, or write to wross@cpan.org to suggest more sweeping changes and new features. I use this all the time and am likely to respond quickly.

=head1 TODO

=over

=item *
Ensure cross-database compatibility (I've only used this with mysql and sqlite). This is especially problematic for CDF::List, probably.

=item *
Improve Apache::Status reports, eg with optional logs and error reports.

=item *
Wiki and mailing list. you know you know.

=back

=head1 REQUIRES

=over

=item L<Class::DBI>

=item L<AppConfig> (unless you replace the configuration mechanism)

=item L<Apache::Request> (if you use CDF::Handler)

=item L<Apache::Cookie> (if you use CDF::Handler);

=item L<DBD::SQLite2> (but only for tests and demo)

=back

=head1 SEE ALSO

L<Class::DBI> L<Class::DBI::Factory::List> L<Class::DBI::Factory::Config> L<Class::DBI::Factory::Handler> L<Class::DBI::Factory::Exception>  L<Class::DBI::Factory::Ghost>

=head1 AUTHOR

William Ross, wross@cpan.org

=head1 COPYRIGHT

Copyright 2001-4 William Ross, spanner ltd.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
