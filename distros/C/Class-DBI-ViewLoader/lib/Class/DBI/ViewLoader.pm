package Class::DBI::ViewLoader;

use strict;
use warnings;

our $VERSION = '0.06';

=head1 NAME

Class::DBI::ViewLoader - Load views from existing databases as Class::DBI
classes

=head1 SYNOPSIS

    use Class::DBI::ViewLoader;

    # set up loader object
    $loader = new Class::DBI::ViewLoader (
	    dsn => 'dbi:Pg:dbname=mydb',
	    username => 'me',
	    password => 'mypasswd',
	    options => {
		RaiseError => 1,
		AutoCommit => 1
	    },
	    namespace => 'MyClass::View',
	    exclude => qr(^te(?:st|mp)_)i,
	    include => qr(_foo$),
	    import_classes => [qw(
		Class::DBI::Plugin::RetrieveAll
		Class::DBI::AbstractSearch
	    )];
	    base_classes => [qw(
		MyBase
	    )],
	    accessor_prefix => 'get_',
	    mutator_prefix => 'set_',
	);

    # create classes
    @classes = $loader->load_views;

    # retrieve all rows from view live_foo
    MyClass::View::LiveFoo->retrieve_all()

    # Get the class name from the view name
    $class = $loader->view_to_class('live_foo');

    # Works for views that weren't loaded too
    $unloaded_class = $loader->view_to_class('test_foo');

=head1 DESCRIPTION

This class loads views from databases as L<Class::DBI> classes. It follows
roughly the same interface employed by L<Class::DBI::Loader>.

This class behaves as a base class for the database-dependent driver classes,
which are loaded by L<Module::Pluggable>. Objects are reblessed into the
relevant subclass as soon as the driver is discovered, see set_dsn(). Driver
classes should always be named Class::DBI::ViewLoader::E<lt>driver_nameE<gt>.

=cut

use Module::Pluggable (
	search_path => __PACKAGE__,
	require => 1,
	inner => 0
    );

use Class::DBI;
use DBI 1.43;

use Carp qw( carp croak confess );

our %handlers = reverse map { /(.*::(.*))/ } __PACKAGE__->plugins();

# Keep a record of all the classes we've created so we can avoid creating the
# same one twice
our %class_cache;

=head1 CONSTRUCTOR

=head2 new

    $obj = $class->new(%args)

Instantiates a new object. The values of %args are passed to the relevant set_*
accessors, detailed below. The following 2 statements should be equivalent:

    new Class::DBI::ViewLoader ( dsn => $dsn, username => $user );

    new Class::DBI::ViewLoader->set_dsn($dsn)->set_username($user);

For compatibilty with L<Class::DBI::Loader>, the following aliases are provided
for use in the arguments to new() only.

=over 4

=item * user -> username

=item * additional_classes -> import_classes

=item * additional_base_classes -> base_classes

=item * constraint -> include

=back

the debug and relationships options are not supported but are silently ignored.

So

    new Class::DBI::ViewLoader user => 'me', constraint => '^foo', debug => 1;

Is equivalent to:

    new Class::DBI::ViewLoader username => 'me', include => '^foo';


Unrecognised options will cause a fatal error to be raised, see DIAGNOSTICS.

=cut

# Class::DBI::Loader compatibility
my %compat = (
	user => 'username',
	additional_classes => 'import_classes',
	additional_base_classes => 'base_classes',
	constraint => 'include',

	# False values to cause silent skipping
	debug => '',
	relationships => '',
    );

sub new {
    my($class, %args) = @_;

    my $self = bless {}, $class;

    # Do dsn first, as we may be reblessed
    if ($args{'dsn'}) {
	$self->set_dsn(delete $args{'dsn'});
    }

    $self->_compat(\%args);

    for my $arg (keys %args) {
	if (my $setter = $self->can("set_$arg")) {
	    &$setter($self, delete $args{$arg});
	}
    }

    if (%args) {
	# All supported arguments should have been deleted
	my $extra = join(', ', map {"'$_'"} sort keys %args);
	croak "Unrecognised arguments in new: $extra";
    }

    return $self;
}

sub _compat {
    my ($self, $args) = @_;

    for my $arg (keys %$args) {
	if (defined $compat{$arg}) {
	    my $value = delete $args->{$arg};

	    # silently skip unsupported Class::DBI::Loader args
	    $arg = $compat{$arg} or next;
	    $args->{$arg} = $value;
	}
    }

    return $self;
}

=head1 ACCESSORS

=head2 set_dsn

    $obj = $obj->set_dsn($dsn_string)

Sets the datasource for the object. This should be in the form understood by
L<DBI> e.g. "dbi:Pg:dbname=mydb"

Calling this method will rebless the object into a handler class for the given
driver. If no such handler is installed, "No handler for driver" will be raised
via croak(). See DIAGNOSTICS for other fatal errors raised by this method.

=cut

sub set_dsn {
    my($self, $dsn) = @_;

    croak "No dsn" unless $dsn;

    my $driver = (DBI->parse_dsn($dsn))[1]
	or croak "Invalid dsn '$dsn'";

    $self->_load_driver($driver)->{_dsn} = $dsn;

    return $self;
}

# rebless into driver class
sub _load_driver {
    my ($self, $driver) = @_;

    my $handler = $handlers{$driver};

    if ($handler) {
	if ($handler->isa(__PACKAGE__)) {
	    # rebless into handler class
	    bless $self, $handler;
	}
	else {
	    confess "$handler is not a ".__PACKAGE__." subclass";
	}
    }
    else {
	croak "No handler for driver '$driver'";
    }

    return $self;
}

=head2 get_dsn

    $dsn = $obj->get_dsn

Returns the dsn string, as passed in by set_dsn.

=cut

sub get_dsn { $_[0]->{_dsn} }

=head2 set_username

    $obj = $obj->set_username($username)

Sets the username to use when connecting to the database.

=cut

sub set_username {
    my($self, $user) = @_;

    # force stringification
    $user = "$user" if defined $user;

    $self->{_username} = $user;

    return $self;
}

=head2 get_username

    $username = $obj->get_username

Returns the username.

=cut

sub get_username { $_[0]->{_username} }

=head2 set_password

    $obj = $obj->set_password

Sets the password to use when connecting to the database.

=cut

sub set_password {
    my($self, $pass) = @_;

    # force stringification
    $pass = "$pass" if defined $pass;

    $self->{_password} = $pass;

    return $self;
}

=head2 get_password

    $password = $obj->get_password

Returns the password

=cut

sub get_password { $_[0]->{_password} }

=head2 set_options

    $obj = $obj->set_dbi_options(%opts)

Accepts a hash or a hash reference.

Sets the additional configuration options to pass to L<DBI>.

The hash will be copied internally, to guard against any accidental
modification after assignment.

Options specified affect how the database that is used by the loader is built.
This is not always the same handle that is used by generated classes.

=cut

sub set_options {
    my $self = shift;
    my $opts = { ref $_[0] ? %{ $_[0] } : @_ };

    $self->{_dbi_options} = $opts;

    return $self;
}

=head2 get_options

    \%opts = $obj->get_dbi_options

Returns the DBI options hash. The return value should always be a hash
reference, even if there are no dbi options set.

The reference returned by this function is live, so modification of it directly
affects the object.

=cut

sub get_options {
    my $self = shift;

    # set up an empty options hash if there is none available.
    $self->set_options unless $self->{_dbi_options};

    return $self->{_dbi_options};
}

# Return this object's complete arguments to send to DBI.
sub _get_dbi_args {
    my $self = shift;

    # breaking encapsulation to use hashslice:
    return @$self{qw( _dsn _username _password _dbi_options )};
}

# Return a new or existing DBI handle
# Drivers should use this method to access the database
sub _get_dbi_handle {
    my $self = shift;

    return $self->{_dbh} if $self->{_dbh};

    my $dbh = DBI->connect( $self->_get_dbi_args )
	or croak "Couldn't connect to database, $DBI::errstr";

    $self->_set_dbi_handle($dbh);

    return $dbh;
}

# set the DBI handle. Might one day be called directly..
sub _set_dbi_handle {
    my $self = shift;
    my $dbh = shift;

    $self->_clear_dbi_handle;
    $self->{_dbh} = $dbh;

    return $self;
}

# disconnect current DBI handle, if any
sub _clear_dbi_handle {
    my $self = shift;

    return $self if $self->_keepalive;

    if (defined $self->{_dbh}) {
	delete($self->{_dbh})->disconnect;
    }

    return $self;
}

sub DESTROY {
    my $self = shift;

    $self->_clear_dbi_handle;
}

# switch to disable _clear_dbi_handle
sub _set_keepalive {
    my $self = shift;
    $self->{__keepalive} = shift;
    return $self;
}

# check status of switch
sub _keepalive {
    my $self = shift;
    return $self->{__keepalive};
}

=head2 set_namespace

    $obj = $obj->set_namespace($namespace)

Sets the namespace to load views into. This should be a valid perl package name,
with or without a trailing '::'.

=cut

sub set_namespace {
    my($self, $namespace) = @_;

    $namespace =~ s/::$//;

    $self->{_namespace} = $namespace;

    return $self;
}

=head2 get_namespace

    $namespace = $obj->get_namespace

Returns the target namespace. If not set, returns an empty list.

=cut

sub get_namespace {
    my $self = shift;
    my $out = $self->{_namespace};

    if (defined $out and length $out) {
	return $out;
    }
    else {
	return;
    }
}

=head2 set_include

    $obj = $obj->set_include($regexp)

Sets a regexp that matches the views to load. Only views that match this expression will be loaded, unless they also match the exclude expression.

Accepts strings or Regexps, croaks if any other reference is passed.

The value is stored as a Regexp, even if a string was passed in.

=cut

sub set_include {
    my($self, $include) = @_;

    $self->{_include} = $self->_compile_regex($include);

    return $self;
}

=head2 get_include

    $regexp = $obj->get_include

Returns the include regular expression.

Note that this may not be identical to what was passed in.

=cut

sub get_include { $_[0]->{_include} }

=head2 set_exclude

    $obj = $obj->set_exclude($regexp)

Sets a regexp to use to rule out views. Any view that matches this regex will
not be loaded by load_views(), even if it is explicitly included by the include
rule.

Accepts strings or Regexps, croaks if any other reference is passed.

The value is stored as a Regexp, even if a string was passed in.

=cut

sub set_exclude {
    my($self, $exclude) = @_;

    $self->{_exclude} = $self->_compile_regex($exclude);

    return $self;
}

=head2 get_exclude

    $regexp = $obj->get_exclude

Returns the exclude regular expression.

Note that this may not be identical to what was passed in.

=cut

sub get_exclude { $_[0]->{_exclude} }

# Return a compiled regex from a string or regex
sub _compile_regex {
    my($self, $regex) = @_;

    if (defined $regex) {
	if (ref $regex) {
	    croak "Regexp or string required"
		if ref $regex ne 'Regexp';
	}
	else {
	    $regex = qr($regex);
	}
    }

    return $regex;
}

# Apply include and exclude rules to a list of view names
sub _filter_views {
    my($self, @views) = @_;

    my $include = $self->get_include;
    my $exclude = $self->get_exclude;

    @views = grep { $_ =~ $include } @views if $include;
    @views = grep { $_ !~ $exclude } @views if $exclude;

    return @views;
}

=head2 set_base_classes

    $obj = $obj->set_base_classes(@classes)

Sets classes for all generated classes to inherit from.

This is in addition to the class specified by the driver's base_class method,
which will always be the first item in the generated @ISA. 

Note that these classes are not loaded for you, be sure to C<use> or C<require>
them yourself.

=cut

sub set_base_classes {
    my $self = shift;

    # We might get a ref from new()
    my @classes = ref $_[0] ? @{$_[0]} : @_;

    $self->{_base_classes} = \@classes;

    return $self;
}

=head2 add_base_classes

    $obj = $obj->add_base_classes(@classes)

Appends to the list of base classes.

=cut

sub add_base_classes {
    my($self, @new) = @_;

    return $self->set_base_classes($self->get_base_classes, @new);
}

=head2 get_base_classes

    @classes = $obj->get_base_classes

Returns the list of base classes, as supplied by set_base_classes.

=cut

sub get_base_classes {
    return @{$_[0]->{_base_classes} || []}
}

=head2 set_left_base_classes

Sets base classes like set_base_classes, except that the added classes will go
before the driver's base_class.

=cut

sub set_left_base_classes {
    my $self = shift;

    # We might get a ref from new()
    my @classes = ref $_[0] ? @{$_[0]} : @_;

    $self->{_left_base_classes} = \@classes;

    return $self;
}

=head2 get_left_base_classes

    @classes = $obj->get_left_base_classes

Returns the list of left base classes, as supplied by set_base_classes.

=cut

sub get_left_base_classes {
    my $self = shift;

    return @{ $self->{_left_base_classes} || [] }
}

=head2 add_left_base_classes

    $obj = $obj->add_base_classes(@classes)

Appends to the list of left base classes.

=cut

sub add_left_base_classes {
    my ($self, @new) = @_;

    return $self->set_left_base_classes($self->get_left_base_classes, @new);
}

sub _get_all_base_classes {
    my $self = shift;

    return reverse($self->get_left_base_classes),
	   $self->base_class,
	   $self->get_base_classes,
}

=head2 set_import_classes

    $obj = $obj->set_import_classes(@classes)

Sets a list of classes to import from. Note that these classes are not loaded by
the generated class itself.

    # Load the module first
    require Class::DBI::Plugin::RetrieveAll;
    
    # Make generated classes import symbols
    $loader->set_import_classes(qw(Class::DBI::Plugin::RetrieveAll));

Any classes that inherit from Exporter will be loaded via Exporter's C<export>
function. Any other classes are loaded by a C<use> call in a string eval.

=cut

sub set_import_classes {
    my $self = shift;

    # We might get a ref from new()
    my @classes = ref $_[0] ? @{$_[0]} : @_;

    $self->{_import_classes} = \@classes;

    return $self;
}

=head2 add_import_classes

    $obj = $obj->add_import_classes(@classes)

Appends to the list of import classes.

=cut

sub add_import_classes {
    my($self, @new) = @_;

    return $self->set_import_classes($self->get_import_classes, @new);
}

=head2 get_import_classes

    @classes = $obj->get_import_classes

Returns the list of classes that will be imported into you generated classes.

=cut

sub get_import_classes { @{$_[0]->{_import_classes} || []} }

=head2 set_accessor_prefix

    $obj = $obj->set_accessor_prefix

Sets the accessor prefix for generated classes. See L<Class::DBI> for details of
how this works.

=cut

sub set_accessor_prefix {
    my($self, $prefix) = @_;

    $self->{_accessor} = "$prefix";

    return $self;
}

=head2 get_accessor_prefix

    $prefix = $obj->get_accessor_prefix

Returns the object's accessor prefix.

=cut

sub get_accessor_prefix { $_[0]->{_accessor} }

=head2 set_mutator_prefix

    $obj = $obj->set_mutator_prefix

Sets the mutator prefix for generated classes. See L<Class::DBI> for details of
how this works.

=cut

sub set_mutator_prefix {
    my($self, $prefix) = @_;

    $self->{_mutator} = "$prefix";

    return $self;
}

=head2 get_mutator_prefix

    $prefix = $obj->get_mutator_prefix

Returns the object's mutator prefix.

=cut

sub get_mutator_prefix { $_[0]->{_mutator} }

=head1 METHODS

=head2 load_views

    @classes = $obj->load_views

The main method for the class, loads all relevant views from the database and
generates classes for those views.

The generated classes will be read-only and have a multi-column primary key
containing every column. This is because it is not guaranteed that the view will
have a real primary key and Class::DBI insists that there should be a unique
identifier for every row.

If the newly generated class inherits a "Main" Class::DBI handle (via
C<connection> or C<set_db> calls in base classes) that handle will be used by
the class. Otherwise, a new connection is set up for the classes based on the
loader's connection.

Usually, any row containing an undef (NULL) primary key column is considered
false in boolean context, in this particular case however that doesn't make much
sense. So only all-null rows are considered false in classes generated by this
class.

Each class is only ever generated once, no matter how many times load_views() is
called. If you want to load the same view twice for some reason, you can achieve
this by changing the namespace.

Returns class names for all created classes.

=cut

sub load_views {
    my $self = shift;

    my @views = $self->get_views;

    my @classes;

    for my $view ($self->_filter_views(@views)) {
	my @cols = $self->get_view_cols($view);

	if (@cols) {
	    push @classes, $self->_create_class($view, @cols);
	}
	else {
	    carp "No columns found in $view, skipping\n";
	}
    }

    # load all symbols into all classes in a single call.
    $self->_do_eval;

    return @classes;
}

# Set up the view class.
sub _create_class {
    my($self, $view, @columns) = @_;

    my $class = $self->view_to_class($view);

    # Don't load the same class twice
    return if $class_cache{$class}++;

    {
	no strict 'refs';

	@{$class.'::ISA'} = $self->_get_all_base_classes;

	# We only want all-null primary keys to be considered false.
	# (This method is used by the bool overloader)
	*{$class.'::_undefined_primary'} = sub {
	    my $self = shift;
	    my @cols = $self->_attrs($self->primary_columns);
	    my @undef = grep { not defined } @cols;

	    return @undef == @cols ? 1 : 0;
	};
    }

    $self->_setup_accessors($class);

    # Only set up the connection explicitly if needed.
    unless ($class->can('db_Main')) {
	$class->connection($self->_get_dbi_args);
    }

    # Prevent attempts to write to views
    $class->make_read_only;

    $class->table($view);

    # We probably won't have a primary key,
    # use a multi-column primary key containing all rows
    $class->columns(Primary => @columns);

    $self->_do_imports($class);

    return $class;
}

# Handle different Class::DBI accessor / mutator name interfaces

our ($_accessor_method, $_mutator_method);
sub __detect_version {
    my $v = $Class::DBI::VERSION;

    $_accessor_method = 'accessor_name';
    $_mutator_method = 'mutator_name';

    if (ref $v eq 'version') {
	if ($v >= version->new(3.0.7)) {
	    $_accessor_method = 'accessor_name_for';
	    $_mutator_method = 'mutator_name_for';
	}
    }
}
BEGIN { __detect_version() }

sub _setup_accessors {
    my ($self, $class) = @_;

    no strict 'refs';

    if (defined(my $accessor = $self->get_accessor_prefix)) {
	my $method = "$class\::$_accessor_method";

	*$method = sub {
	    my ($self, $col) = @_;
	    return $accessor . $col;
	};
    }

    if (defined(my $mutator = $self->get_mutator_prefix)) {
	my $method = "$class\::$_mutator_method";

	*$method = sub {
	    my ($self, $col) = @_;
	    return $mutator . $col;
	};
    }

    return $self;
}

# import symbols into the target namespace. Try to avoid string eval when
# possible. This eval code is cached by _set_eval and can be executed with
# _do_eval
sub _do_imports {
    my($self, $class) = @_;

    my @imports = $self->get_import_classes or return $self;

    my @manual;
    for my $module (@imports) {
	# Any non-ref scalar should be a valid class name
	# We're not interested in other valid invocants
	next if ref $module;

	if ($module->isa('Exporter')) {
	    # use Exporter's export method, avoid string eval
	    $module->export($class);
	}
	elsif ($module->can('import')) {
	    push @manual, $module;
	}
	else {
	    carp "$module has no import function";
	}
    }

    if (@manual) {
	# load classes via string eval (yuk!)
	$self->_set_eval($class, @manual);
    }

    return $self;
}

# cache code to eval to minimise string eval calls
sub _set_eval {
    my ($self, $class, @manual) = @_;

    my $code = join("\n",
        "package $class;",
        map {"use $_;"} @manual
    );

    push @{$self->{__eval_cache}}, $code;
}

# process pending eval code and reset
sub _do_eval {
    my $self = shift;

    my $cache = delete $self->{__eval_cache};

    if (defined $cache) {
	my $code = join("\n\n", @$cache);

	eval $code;

	croak "Eval error!\nCode:\n$code\n\nMessage: $@" if $@;
    }

    return $self;
}

=head2 view_to_class

    $class = $obj->view_to_class($view)

Returns the class for the given view name. This depends on the object's current
namespace, see set_namespace(). It doesn't matter if the class has been loaded,
or if the view exists in the database.

If this method is called without arguments, or with an empty string, it returns
an empty string.

=cut

sub view_to_class {
    my($self, $view) = @_;

    if (defined $view and length $view) {
	# cribbed from Class::DBI::Loader
	$view = join('', map { ucfirst } split(/[\W_]+/, $view));

	return join('::', $self->get_namespace, $view);
    }
    else {
	return '';
    }
}

=head2 _get_dbi_handle

    $dbh = $obj->_get_dbi_handle

Returns a DBI handle based on the object's dsn, username and password. This
generally shouldn't be called externally (hence the leading underscore).

Making multiple calls to this method won't cause multiple connections to be
made. A single handle is cached by the object from the first call to
_get_dbi_handle until such time as the object goes out of scope or set_dsn is
called again, at which time the handle is disconnected and the cache is cleared.

If the connection fails, a fatal error is raised.

=head2 _clear_dbi_handle

    $obj->_clear_dbi_handle

This is the cleanup method for the object's DBI handle. It is called whenever
the DBI handle needs to be closed down. i.e. when a new handle is used or the
object goes out of scope. Subclasses should override this method if they need to
clean up any state data that relies on the current database connection, like
statement handles for example. If you don't want the handle that the object is
using to be disconnected, use the _set_keepalive method.

    sub _clear_dbi_handle {
	my $self = shift;

	delete $self->{statement_handle};

	$self->SUPER::_clear_dbi_handle(@_);
    }

=head2 _set_dbi_handle

    $obj = $obj->_set_dbi_handle($dbh)

This method is used to attach a DBI handle to the object. It might prove useful
to use this method in order to use an existing database connection in the loader
object. Note that unlike set_dsn, calling this method directly will not cause an
appropriate driver to be loaded. See _load_driver for that.

=head2 _set_keepalive

    $obj = $obj->_set_keepalive($bool)

When set to true, the database handle used by the object won't be disconnected automatically.

=head2 _load_driver

    $obj = $obj->_load_driver($driver_name)

This method is used internally by set_dsn to load a driver to handle
database-specific functionality. It can be called directly in conjunction with
_set_dbi_handle to load views from an existing database connection.

=head1 DRIVER METHODS

The following methods are provided by the relevant driver classes. If they are
called on a native Class::DBI::ViewLoader object (one without a dsn set), they
will cause fatal errors. They are documented here for the benefit of driver
writers but they may prove useful for users also.

=over 4

=item * base_class

    $class = $driver->base_class

Should return the name of the base class to be used by generated classes. This
will generally be a Class::DBI driver class.

    package Class::DBI::ViewLoader::Pg;

    # Generate postgres classes
    sub base_class { "Class::DBI::Pg" }

=item * get_views

    @views = $driver->get_views;

Should return the names of all the views in the current database.

=item * get_view_cols

    @columns = $driver->get_view_cols($view);

Should return the names of all the columns in the given view.

=back

A list of these methods is provided by this class, in
@Class::DBI::ViewLoader::driver_methods, so that each driver can be sure that it
is implementing all required methods. The provided t/04..plugin.t is a
self-contained test script that checks a driver for compatibility with the
current version of Class::DBI::ViewLoader, driver writers should be able to copy
the test into their distribution and edit the driver name to provide basic
compliance tests.

=cut

our @driver_methods = qw(
	base_class
	get_views
	get_view_cols
    );

for my $method (@driver_methods) {
    no strict 'refs';
    *$method = sub { $_[0]->_refer_to_handler($method) };
}

sub _refer_to_handler {
    my($self, $sub) = @_;
    my $handler = ref $self;

    if ($handler eq __PACKAGE__) {
	# We haven't reblessed into a subclass
	confess "No handler loaded, try calling set_dsn() first";
    }
    else {
	confess "$sub not overridden by $handler";
    }
}

1;

__END__

=head1 DIAGNOSTICS

The following fatal errors are raised by this class:

=over 4

=item * No dsn

set_dsn was called without an argument

=item * Invalid dsn %s

the dsn passed to set_dsn couldn't be parsed by DBI->parse_dsn

=item * No handler for driver %s, from dsn %s

set_dsn couldn't find a driver handler for the given dsn. You may need to
install a plugin to handle your database.

=item * No handler loaded

load_views() or some other driver-dependent method was called on an object which
hadn't loaded a driver.

=item * %s not overridden

A driver did not override the given method. You may need to upgrade the driver
class.

=item * Couldn't connect to database

Self-explanatory. The DBI error string is appended to the error message.

=item * Regexp or string required

set_include or set_exclude called with a ref other than 'Regexp'.

=item * Unrecognised arguments in new

new() encountered unsupported arguments. The offending arguments are listed
after the error message.

=back

The following warnings are generated:

=over 4

=item * No columns found in %s, skipping

The given view didn't seem to have any columns, it won't be loaded.

=item * %s has no import function

The given module from the object's import_classes list couldn't be imported
because it had no import() function.

=back

=head1 BUGS

With later versions of Class::DBI, columns names that clash with methods (such
as 'id') can cause exceptions. Using accessor_prefix and mutator_prefix can help
avoid this problem.

=head1 SEE ALSO

L<DBI>, L<Class::DBI>, L<Class::DBI::Loader>

=head1 AUTHOR

Matt Lawrence E<lt>mattlaw@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2005 Matt Lawrence, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

vim: ts=8 sts=4 sw=4 noet sr
