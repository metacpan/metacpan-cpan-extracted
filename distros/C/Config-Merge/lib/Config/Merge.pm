package Config::Merge;

use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

use File::Spec();
use File::Glob 'bsd_glob';

use Storable();
use overload (
    '&{}' => sub {
        my $self = shift;
        return sub { $self->C(@_) }
    },
    'fallback' => 1
);

use vars qw($VERSION);
$VERSION = '1.04';

=head1 NAME

Config::Merge - load a configuration directory tree containing
YAML, JSON, XML, Perl, INI or Config::General files

=head1 SYNOPSIS

   OO style
   -------------------------------------------------------
   use Config::Merge();

   my $config    = Config::Merge->new('/path/to/config');

   @hosts        = $config->('db.hosts.session');
   $hosts_ref    = $config->('db.hosts.session');
   @cloned_hosts = $config->clone('db.hosts.session');
   -------------------------------------------------------

OR

   Functional style
   -------------------------------------------------------
   # On startup
   use Config::Merge('My::Config' => '/path/to/config');


   # Then, in any module where you want to use the config
   package My::Module;
   use My::Config;

   @hosts        = C('db.hosts.sesssion');
   $hosts_ref    = C('db.hosts.sesssion');
   @cloned_hosts = My::Config::clone('db.hosts.session');
   $config       = My::Config::object;
   -------------------------------------------------------

ADVANCED USAGE

   OO style
   -------------------------------------------------------
   my $config    = Config::Merge->new(
       path      => '/path/to/config',
       skip      => sub {} | regex | {} ,
       is_local  => sub {} | regex | {} ,
       load_as   => sub {} | regex ,
       sort      => sub {} ,
       debug     => 1 | 0
   );
   -------------------------------------------------------

   Functional style
   -------------------------------------------------------
   use Config::Merge(
       'My::Config' => '/path/to/config',
       {
           skip      => sub {} | regex | {} ,
           is_local  => sub {} | regex | {} ,
           load_as   => sub {} | regex ,
           sort      => sub {} ,
           debug     => 1 | 0
       }
   );

   # Also, you can subclass these:

     package My::Config;
     sub skip {
         ...
     }

   -------------------------------------------------------

=head1 DESCRIPTION

Config::Merge is a configuration module which has six goals:

=over

=item * Flexible storage

Store all configuration in your format(s) of choice (YAML, JSON, INI, XML, Perl,
Config::General / Apache-style config) broken down into individual files in
a configuration directory tree, for easy maintenance.
 See L</"CONFIG TREE LAYOUT">

=item * Flexible access

Provide a simple, easy to read, concise way of accessing the configuration
values (similar to L<Template>). See L</"ACCESSING CONFIG DATA">

=item * Minimal maintenance

Specify the location of the configuration files only once per
application, so that it requires minimal effort to relocate.
See L</"USING Config::Merge">

=item * Easy to alter development environment

Provide a way for overriding configuration values on a development
machine, so that differences between the dev environment and
the live environment do not get copied over accidentally.
See L</"OVERRIDING CONFIG LOCALLY">

=item * Minimise memory use

Load all config at startup so that (eg in the mod_perl environment) the
data is shared between all child processes. See L</"MINIMISING MEMORY USE">

=item * Flexible implementation

You may want to use a different schema for your configuration files,
so you can pass in (or subclass) methods for determining how your
files are merged.  See L</"ADVANCED USAGE">.

=back

=head1 USING C<Config::Merge>

There are two ways to use C<Config::Merge>:

=over

=item OO STYLE

   use Config::Merge();
   my $config    = Config::Merge->new('/path/to/config');

   @hosts        = $config->('db.hosts.session');
   $hosts_ref    = $config->('db.hosts.session');
   @cloned_hosts = $config->clone('db.hosts.session');

Also, see L</"ADVANCED USAGE">.

=item YOUR OWN CONFIG CLASS (functional style)

The following code:

   # On startup
   use Config::Merge('My::Config' => '/path/to/config');

=over

=item *

auto-generates the class C<My::Config>

=item *

loads the configuration data in C<'/path/to/config'>

=item *

creates the subs C<My::Config::C>, C<My::Config::clone>
and C<My::Config::object>.

=back

Then when you want your application to have access to your configuration data,
you add this (eg in your class C<My::Module>):

   package My::Module;
   use My::Config;       # Note, no ()

This exports the sub C<C> into your current package, which allows you to
access your configuation data as follows:

   @hosts        = C('db.hosts.sesssion');
   $hosts_ref    = C('db.hosts.sesssion');
   @cloned_hosts = My::Config::clone('db.hosts.session');
   $config       = My::Config::object;

=back

=head1 CONFIG TREE LAYOUT

Config::Merge reads the data from any number (and type) of config files
stored in a directory tree. File names and directory names are used as keys in
the configuration hash.

It uses file extensions to decide what type of data the file contains, so:

    YAML            : .yaml .yml
    JSON            : .json .jsn
    XML             : .xml
    INI             : .ini
    Perl            : .perl .pl
    Config::General : .conf .cnf

When loading your config data, Config::Merge starts at the directory
specified at startup (see L</"USING Config::Merge">) and looks
through all the sub-directories for files ending in one of the above
extensions.

The name of the file or subdirectory is used as the first key.  So:

    global/
        db.yaml:
            username : admin
            hosts:
                     - host1
                     - host2
            password:
              host1:   password1
              host2:   password2

would be loaded as :

    $Config = {
       global => {
           db => {
               username => 'admin',
               password => { host1 => 'password1', host2 => 'password2'},
               hosts    => ['host1','host2'],
           }
       }
    }

Subdirectories are processed before the current directory, so
you can have a directory and a config file with the same name,
and the values will be merged into a single hash, so for
instance, you can have:

    confdir:
       syndication/
       --data_types/
         --traffic.yaml
         --headlines.yaml
       --data_types.ini
       syndication.conf

The config items in syndication.conf will be added to (or overwrite)
the items loaded into the syndication namespace via the subdirectory
called syndication.

=head1 OVERRIDING CONFIG LOCALLY

The situation often arises where it is necessary to specify
different config values on different machines. For instance,
the database host on a dev machine may be different from the host
on the live application. Also, see L</"ADVANCED USAGE"> which
provides you with other means to merge local data.

Instead of changing this data during dev and then having to remember
to change it back before putting the new code live, we have a mechanism
for overriding config locally in a C<local.*> file and then, as long as
that file never gets uploaded to live, you are protected.

You can put a file called C<local.*> (where * is any of the recognised
extensions) in any sub-directory, and
the data in this file will be merged with the existing data.

Just make sure that the C<local.*> files are never checked into your live
code.

For instance, if we have:

    confdir:
        db.yaml
        local.yaml

and db.yaml has :

    connections:
        default_settings:
            host:       localhost
            table:      abc
            password:   123

And in local.yaml:

    db:
        connections:
            default_settings:
                password:   456

the resulting configuration will look like this:

    db:
        connections:
            default_settings:
                host:       localhost
                table:      abc
                password:   456

=head1 ACCESSING CONFIG DATA

All configuration data is loaded into a single hash, eg:

    $config = {
        db    => {
            hosts  => {
                session  => ['host1','host2','host3'],
                images   => ['host1','host2','host3'],
                etc...
            }
        }
    }


If you want to access it via standard Perl dereferences, you can just ask
for the hash:

    OO:
       $data_ref  = $config->();
       $hosts_ref = $data_ref->{db}{hosts}{session};
       $host_1    = $data_ref->{db}{hosts}{session}[0];

    Functional:
       $data_ref  = C();
       $hosts_ref = $data_ref->{db}{hosts}{session};
       $host_1    = $data_ref->{db}{hosts}{session}[0];

However, C<Config::Merge> also provides an easy to read dot-notation in the
style of Template Toolkit: C<('key1.key2.keyn')>.

A key can be the key of a hash or the index of an array. The return value is
context sensitive, so if called in list context, a hash ref or array ref will
be dereferenced.

    OO:
       @hosts     = $config->('db.hosts.session');
       $hosts_ref = $config->('db.hosts.session');
       $host_1    = $config->('db.hosts.session.0');

    Functional:
       @hosts     = C('db.hosts.session');
       $hosts_ref = C('db.hosts.session');
       $host_1    = C('db.hosts.session.0');

These lookups are memo'ised, so lookups are fast.

If the specified key is not found, then an error is thrown.

=head1 MINIMISING MEMORY USE

The more configuration data you load, the more memory you use. In order to
keep the memory use as low as possible for mod_perl (or other forking
applications), the configuration data should be loaded at startup in the
parent process.

As long as the data is never changed by the children, the configuration hash
will be stored in shared memory, rather than there being a separate copy in each
child process.

(See L<http://search.cpan.org/~pgollucci/mod_perl-2.0.3/docs/user/performance/mpm.pod>)

=head1 METHODS

=over

=item C<new()>

    $conf = Config::Merge->new($config_dir);

new() instantiates a config object, loads the config from
the directory specified, and returns the object.

=cut

#===================================
sub new {
#===================================
    my $proto = shift;
    my $class = ref $proto || $proto;

    my $self = {};
    bless( $self, $class );

    my $params
        = @_ > 1              ? {@_}
        : ref $_[0] eq 'HASH' ? shift()
        :                       { path => shift() };

    # Emit debug messages
    $self->{debug} = $params->{debug} ? 1 : 0;

    die "Parameter 'sort' must be a coderef"
        if exists $params->{sort} && ref $params->{sort} ne 'CODE';

    # Setup callbacks
    $self->_init_callback( $_, $params->{$_} )
        foreach qw(skip is_local load_as sort);

    my $path = $params->{path}
        or die( "Configuration directory not specified when creating a new "
            . "'$class' object" );

    if ( $path && -d $path && -r _ ) {

        $path =~ s|/?$|/|;
        $self->{config_dir} = $path;
        $self->load_config();

        return $self;
    }
    else {
        die( "Configuration directory '$path' not readable when creating a new "
                . "'$class' object" );
    }
    return $self;
}

=item C<C()>

  $val = $config->C('key1.key2.keyn');
  $val = $config->C('key1.key2.keyn',$hash_ref);

C<Config::Merge> objects are overloaded so that this also works:

  $val = $config->('key1.key2.keyn');
  $val = $config->('key1.key2.keyn',$hash_ref);

Or, if used in the functional style (see L</"USING Config::Merge">):

  $val = C('key1.key2.keyn');
  $val = C('key1.key2.keyn',$hash_ref);

C<key1> etc can be keys in a hash, or indexes of an array.

C<C('key1.key2.keyn')> returns everything from C<keyn> down,
so you can use the return value just as you would any normal Perl variable.

The return values are context-sensitive, so if called
in list context, an array ref or hash ref will be returned as lists.
Scalar values, code refs, regexes and blessed objects will always be returned
as themselves.

So for example:

  $password = C('database.main.password');
  $regex    = C('database.main.password_regex');

  @countries = C('lists.countries');
  $countries_array_ref = C('lists.countries');

  etc

If called with a hash ref as the second parameter, then that hash ref will be
examined, rather than the C<$config> data.

=cut

#===================================
sub C {
#===================================
    my $self = shift;
    my $path = shift;
    $path = '' unless defined $path;

    my ( $config, @keys );

    # If a private hash is passed in use that
    if (@_) {
        $config = $_[0];
        @keys   = split( /\./, $path );
        $config = $self->_walk_path( $config, 'PRIVATE', \@keys );
    }

    # Otherwise use the stored config data
    else {

        # Have we previously memoised this?
        if ( exists $self->{_memo}->{$path} ) {
            $config = ${ $self->{_memo}->{$path} };
        }

        # Not memoised, so get it manually
        else {
            $config = $self->{config};
            (@keys) = split( /\./, $path );
            $config = $self->_walk_path( $config, '', \@keys );
            $self->{_memo}->{$path} = \$config;
        }
    }

    return
          wantarray && ref($config) eq 'HASH'  ? %{$config}
        : wantarray && ref($config) eq 'ARRAY' ? @{$config}
        :                                        $config;
}

#===================================
sub _walk_path {
#===================================
    my $self = shift;
    my ( $config, $key_path, $keys ) = @_;

    foreach my $key (@$keys) {
        next unless defined $key && length($key);
        if (   ref $config eq 'ARRAY'
            && $key =~ /^[0-9]+/
            && exists $config->[$key] )
        {
            $config = $config->[$key];
            $key_path .= '.' . $key;
            next;
        }
        elsif ( ref $config eq 'HASH' && exists $config->{$key} ) {
            $config = $config->{$key};
            $key_path = $self->_join_key_path( $key_path, $key );
            next;
        }
        die("Invalid key '$key' specified for '$key_path'\n");
    }
    return $config;
}

=item C<clone()>

This works exactly the same way as L</"C()"> but it performs a
deep clone of the data before returning it.

This means that the returned data can be changed without
affecting the data stored in the $conf object;

The data is deep cloned, using Storable, so the bigger the data, the more
performance hit.  That said, Storable's dclone is very fast.

=cut

#===================================
sub clone {
#===================================
    my $self = shift;
    my $data = $self->Config::Merge::C(@_);
    return Storable::dclone($data);
}

my @Builtin_Merges = qw(
    Config::Any::YAML
    Config::Any::General
    Config::Any::XML
    Config::Any::INI
    Config::Any::JSON
    Config::Merge::Perl
);

my %Module_For_Ext = ();
__PACKAGE__->register_loader($_) foreach @Builtin_Merges;

=item C<register_loader()>

    Config::Merge->register_loader( 'Config::Merge::XYZ');

    Config::Merge->register_loader( 'Config::Merge::XYZ' => 'xyz','xxx');

By default, C<Config::Merge> uses the C<Config::Any>
plugins to support YAML, JSON, INI, XML, Perl and Config::General configuration
files, using the standard file extensions to recognise the file type. (See
L</"CONFIG TREE LAYOUT">).

If you would like to change the handler for an extension (eg, you want C<.conf>
and C<.cnf> files to be treated as YAML), do the following:

    Config::Merge->register_loader ('Config::Any::YAML' => 'conf', 'cnf');

If you would like to add a new config style, then your module should have two
methods: C<extensions()> (which returns a list of the extensions it handles),
and C<load()> which accepts the name of the file to load, and returns
a hash ref containing the data in the file. See L<Config::Any> for details.

Alternatively, you can specify the extensions when you load it:

    Config::Merge->register_loader ('My::Merge' => 'conf', 'cnf');

=cut

#===================================
sub register_loader {
#===================================
    my $class  = shift;
    my $loader = shift
        or die "No loader class passed to register_loader()";
    eval "require $loader"
        or die $@;
    my @extensions = @_ ? @_ : $loader->extensions;
    foreach my $ext (@extensions) {
        $Module_For_Ext{ lc($ext) } = $loader;
    }
    return;
}

=item C<load_config()>

    $config->load_config();

Will reload the config files located in the directory specified at object
creation (see L</"new()">).

BEWARE : If you are using this in a mod_perl environment, you will lose the
benefit of shared memory by calling this in a child process
 - each child will have its own copy of the data.
See L<MINIMISING MEMORY USE>.

Returns the config hash ref.

=cut

#===================================
sub load_config {
#===================================
    my $self = shift;
    $self->{_memo} = {};
    $self->debug("Loading config data");
    return $self->{config} = $self->_load_config() || {};
}

#===================================
sub _load_config {
#===================================
    my $self          = shift;
    my $dir           = shift || $self->{config_dir};
    my $key_path      = shift || '';
    my $loading_local = shift;

    my $config = {};

    my @local;

    my $config_files = $self->{sort}
        ->( $self, [ bsd_glob( File::Spec->catfile( $dir, '*' ) ) ] );

    my $is_local = $self->{is_local};
    $self->debug( '', "Entering dir: $dir", '-' x ( length($dir) + 14 ) );

CONFIG_FILE:
    foreach my $config_file (@$config_files) {
        my ( $data, $name, $curr_key_path, $loader );

        my $filename = ( File::Spec->splitpath($config_file) )[2];

        # If it is a file
        if ( -f $config_file ) {
            $self->debug("  Found file : $config_file");

            # Must have an extension
            ( $name, my $ext ) = ( $filename =~ /(.+)[.]([^.]+)/ )
                or $self->debug("  ... No extension") && next CONFIG_FILE;

            # Must have an associated module
            $loader = $Module_For_Ext{ lc $ext }
                or $self->debug("  ... No loader") && next CONFIG_FILE;
        }
        elsif ( -d $config_file ) {
            $self->debug("  Found dir : $config_file");
            $name = $filename;
            undef $loader;
        }

        # Anything else (eg symlink), skip
        else {
            next;
        }

        # If it is a local file/dir, process last
        if ( !$loading_local && $is_local->( $self, $name ) ) {
            $self->debug("  ... will merge later");
            push @local, [ $loader, $config_file, $filename ];
            next CONFIG_FILE;
        }

        # Find the key name from the filename
        $name = $self->_load_as( $key_path, $name, $loading_local );
        next CONFIG_FILE if not defined $name;

        # loader = module name to load file, or undef for directory
        $data
            = $loader
            ? $self->_load_config_file( $loader, $config_file )
            : $self->_load_config( $config_file,
            $self->_join_key_path( $key_path, $name ),
            $loading_local );

        next CONFIG_FILE unless defined $data;

        # Merge keys if already exists
        if (   exists $config->{$name}
            && ref $config->{$name} eq 'HASH'
            && ref $data eq 'HASH' )
        {
            $config->{$name}->{$_} = $data->{$_} foreach keys %$data;
        }
        else {
            $config->{$name} = $data;
        }
    }

    # Merge local config into main config
LOCAL_FILE:
    foreach my $local_file (@local) {
        my ( $loader, $config_file, $name ) = @$local_file;
        $self->debug("  Merging file $config_file");
        $name = $self->_load_as( $key_path, $name, 1 );
        next LOCAL_FILE
            unless defined $name;

        my $data
            = $loader
            ? $self->_load_config_file( $loader, $config_file )
            : $self->_load_config( $config_file, $key_path, 1 );

        next LOCAL_FILE unless defined $data;

        $config = $self->_merge_hash(
            $config, $name
            ? { $name => $data }
            : $data
        );
    }

    return keys %$config ? $config : undef;
}

#===================================
sub _load_as {
#===================================
    my ( $self, $key_path, $name, $loading_local ) = @_;

    # Find the key name from the filename
    $name = $self->{load_as}->( $self, $name, $loading_local );
    unless ( defined $name ) {
        $self->debug("  ... Skipped by load_as()");
        return;
    }

    die "load_as() cannot return '' when loading main config"
        if !$loading_local && $name eq '';

    my $curr_key_path = $self->_join_key_path( $key_path, $name );
    $self->debug( "  ... loading at : "
            . ( length($curr_key_path) ? $curr_key_path : '.' ) );

    if ( $self->{skip}->( $self, $curr_key_path ) ) {
        $self->debug("  ... skipped by skip()");
        return;
    }
    return $name;
}

#===================================
sub _join_key_path {
#===================================
    my ( $self, $key_path, $name ) = @_;
    return $key_path . '.' . $name if length($key_path);
    return $name;
}

#===================================
sub _load_config_file {
#===================================
    my $self = shift;
    my ( $loader, $config_file ) = @_;
    $self->debug("  ... with : $loader");
    my $data;
    eval {
        my @data = $loader->load($config_file);
        $data
            = @data > 1
            ? \@data
            : $data[0];
    };
    if ($@) {
        die( "Error loading config file $config_file:\n\n" . $@ );
    }

    return $data;
}

=item C<clear_cache()>

    $config->clear_cache();

Config data is generally not supposed to be changed at runtime. However, if
you do make changes, you may get inconsistent results, because lookups are
cached.

For instance:

    print $config->C('db.hosts.session');  # Caches this lookup
    > "host1 host2 host3"

    $data = $config->C('db.hosts');
    $data->{session} = 123;

    print $config->C('db.hosts.session'); # uses cached value
    > "host1 host2 host3"

    $config->clear_cache();
    print $config->C('db.hosts.session'); # uses actual value
    > "123"

=cut

#===================================
sub clear_cache {
#===================================
    my $self = shift;
    $self->{_memo} = {};
    return;
}

=item C<import()>

C<import()> will normally be called automatically when you
C<use Config::Merge>. However, you may want to do this:

    use Config::Merge();
    Config::Merge->register_loader('My::Plugin' => 'ext');
    Config::Merge->import('My::Config' => '/path/to/config/dir');

If called with two params: C<$config_class> and C<$config_dir>, it
generates the new class (which inherits from Config::Merge)
specified in C<$config_class>, creates a new
object of that class and creates 4 subs:

=over

=item C<C()>

    As a function:
        C('keys...')

    is the equivalent of:
        $config->C('keys...');

=item C<clone()>

    As a function:
        clone('keys...')

    is the equivalent of:
        $config->clone('keys...');

=item C<object()>

    $config = My::Config->object();

Returns the C<$config> object,

=item C<import()>

When you use your generated config class, it exports the C<C()> sub into your
package:

    use My::Config;
    $hosts = C('db.hosts.session');

=back

=back

=cut

#===================================
sub import {
#===================================
    my $caller_class = shift;
    my ( $class, $dir ) = @_;
    return
        unless defined $class;

    unless ( defined $dir ) {
        $dir   = $class;
        $class = $caller_class;
    }
    if ( $class eq __PACKAGE__ ) {
        die <<USAGE;

USAGE : use $class ('Your::Config' => '/path/to/config/dir' );

USAGE

    }

    my $inc_path = $class;
    $inc_path =~ s{::}{/}g;
    $inc_path .= '.pm';

    no strict 'refs';
    unless ( exists $INC{$inc_path} ) {
        @{ $class . '::ISA' } = ($caller_class);
        $INC{$inc_path} = 'Auto-inflated by ' . $caller_class;
    }

    my $params = @_ % 2 ? shift() : {@_};
    $params->{path} = $dir;
    my $config = $class->new(%$params);

    # Export C, clone to the subclass
    *{ $class . "::C" }
        = sub { my $c = ref $_[0] ? shift : $config; return C( $c, @_ ) };
    *{ $class . "::clone" } = sub {
        my $c = ref $_[0] ? shift : $config;
        return clone( $c, @_ );
    };
    *{ $class . "::object" } = sub { return $config };

    # Create a new import sub in the subclass
    *{ $class . "::import" } = eval '
        sub {
            my $callpkg = caller(0);
            no strict \'refs\';
            *{$callpkg."::C"} = \&' . $class . '::C;
        }';

    return;
}

#===================================
sub _merge_hash {
#===================================
    my $self   = shift;
    my $config = shift;
    my $local  = shift;
KEY:
    foreach my $key ( keys %$local ) {
        if ( ref $local->{$key} eq 'HASH'
            && exists $config->{$key} )
        {
            if ( ref $config->{$key} eq 'HASH' ) {
                $self->debug("  ... entering hash : $key");
                $config->{$key}
                    = $self->_merge_hash( $config->{$key}, $local->{$key} );
                next KEY;
            }
            if (   ref $config->{$key} eq 'ARRAY'
                && exists $local->{$key}{'!'}
                && ref $local->{$key}{'!'} eq 'HASH' )
            {
                $self->_merge_array( $key, $config, $local );
                next KEY;
            }
        }
        $self->debug("  ... setting key : $key");
        $config->{$key} = $local->{$key};
    }
    $self->debug("  ... leaving hash");
    return $config;
}

=head1 ADVANCED USAGE

The items in the section allow you to customise how Config::Merge
loads your data.  You may never need them.

You can:

=over

=item *

Override array values

=item *

Skip the loading of parts of your config tree

=item *

Specify which files / dirs are local

=item *

Specify how to translate a file / dir name into a key

=item *

Change order in which files are loaded

=item *

See debug output

=back

=over

=item Overriding array values

Overriding hash values is easy, however arrays are more complex.
it may be simpler to copy and paste and edit the array you want to
change locally.

However, if your array is too long, and you want to make small changes,
then you can use the following:

In the main config:

    {
      cron => [qw( job1 job2 job3 job4)]
    }

In the local file

    {
      cron => {
        '3'  => 'newjob4',      # changes 'job4' -> 'newjob4'

        '!'  => {               # signals an array override

             '-' => [1],        # deletes 'job2'

             '+' => ['job5'],   # appends 'job5'

          OR '+' => {           # inserts 'job3a' after 'job3'
                 2 => 'job3a'
             }
        }
    }

=over

=item *

The override has to be a hash, with at least this structure
 C<< { '!' => {} } >> to signal an array override

=item *

Any other keys with integers are treated as indexes and
are used to change the value at that index in the original array

=item *

The C<'-'> key should contain an array ref, with the indexes of the
elements to remove from the array.

=item *

If the C<'+'> key contains an array ref, then its contents are appended
to the original array.

=item *

If the C<'+'> key contains a hash ref, then each value is inserted
into the original array at the index given in the key

=item *

Indexes are zero based, just as in Perl.

=back

=cut

#===================================
sub _merge_array {
#===================================
    my ( $self, $key, $config, $local ) = @_;
    $self->debug("  ... merging array : $key");
    my $dest    = $config->{$key};
    my $merge   = $local->{$key};
    my $changes = delete $merge->{'!'};

    # Changed elements
    foreach my $index ( keys %$merge ) {
        $index = '' if !defined $index;
        die "Array override for key '$key' : '$index' is not an integer"
            unless $index =~ /^\d+$/;
        $dest->[$index] = $merge->{$index};
        $self->debug("      ... changing index  : $index");
    }

    my %actions;

    # Deleted elements
    my $remove = $changes->{'-'} || [];
    die "Index delete for key '$key' : '-' is not an array ref"
        unless ref $remove eq 'ARRAY';

    foreach my $delete_index (@$remove) {
        next unless $delete_index =~ /^\d+/;
        $actions{$delete_index} = ['-']
            if $delete_index < @$dest;
    }

    # Added elements
    my $add = $changes->{'+'} || [];

    # Append
    if ( ref $add eq 'ARRAY' ) {
        if (@$add) {
            push @$dest, @$add;
            $self->debug(
                '      ... appending ' . ( scalar @$add ) . ' element(s)' );
        }
    }

    # Insert
    elsif ( ref $add eq 'HASH' ) {
        foreach my $add_index ( keys %$add ) {
            next unless $add_index =~ /^\d+/;
            $actions{$add_index} = [
                ( exists $actions{$add_index} || $add_index >= @$dest )
                ? '~'
                : '+',
                $add->{$add_index}
            ];
        }

    }
    else {
        die "Array add for key '$key' : '+' is not an array or hash ref";
    }

    foreach my $index ( sort { $b <=> $a } keys %actions ) {
        my ( $action, $value ) = @{ $actions{$index} };
        if ( $action eq '-' ) {
            splice( @$dest, $index, 1 );
            $self->debug("      ... deleting index  : $index");
            next;
        }
        if ( $action eq '~' ) {
            $dest->[$index] = $value;
            $self->debug("      ... changing index  : $index");
            next;
        }
        splice( @$dest, $index, 0, $value );
        $self->debug("      ... inserting index : $index");
    }
    return;
}

=item C<skip()>

    $c = Config::Merge->new(
            path  => '/path/to/config',
            skip  => qr/regex/,
                     | [ qr/regex1/, qr/regex2/...]
                     | {  name1 => 1, name2 => 2}
                     | sub {}
    );

C<skip()> allows you to skip the loading of parts of your config
tree.  For instance, if you don't need a list of cron jobs when running
your web server, you can skip it.

The decision is made based on the path to that value, eg 'app.db.hosts'
rather than on filenames. Also, the check is only performed for each
new directory or filename - it doesn't check the data within each file.

To use C<skip()>, you can either subclass it, or pass in a parameter
to new:

=over

=item C<qr/regex/> or C<[qr/regex1/, qr/regex2]>

Each regex will be checked against the key path, and if it matches
then the loading of that tree will be skipped

=item C<< {key_path => 1} >>

If the key path exists in the hash, then loading will be skipped

=item C<sub {}> or subclassed C<skip>

   sub {
       my ($self,$key_path) = @_;
       ...make decision...
       return 1 | 0;
   }

=back

=cut

#===================================
sub skip {
#===================================
    return;
}

=item C<is_local()>

    $c = Config::Merge->new(
            path     => '/path/to/config',
            is_local => qr/regex/,
                        | [ qr/regex1/, qr/regex2/...]
                        | {  name1 => 1, name2 => 2}
                        | sub {}
    );

C<is_local()> indicates whether a file or dir should be considered
part of the main config (and thus loaded normally) or part of the
local config (and thus merged into the main config).

The decision is made based on the name of the file / dir, without
any extension.

To use C<is_local()>, you can either subclass it, or pass in a parameter
to new:

=over

=item C<qr/regex/> or C<[qr/regex1/, qr/regex2]>

Each regex will be checked against the file/dir name, and if it matches
then that tree will be merged

=item C<< {filename => 1, dirname => 1} >>

If the file/dir name exists in the hash, then that tree will be merged

=item C<sub {}> or subclassed C<is_local>

   sub {
       my ($self,$name) = @_;
       ...make decision...
       return 1 | 0;
   }

=back

See L</"EXAMPLE USING is_local() AND load_as()">.

=cut

#===================================
sub is_local {
#===================================
    my ( $self, $filename ) = @_;
    return $filename =~ /^local\b/;
}

=item C<load_as()>

    $c = Config::Merge->new(
            path     => '/path/to/config',
            load_as  => qr/(regex)/,
                        | sub {}
    );

C<load_as()> returns the name of the key to use when loading
the file / dir. By default, it returns the C<$name> for main
config files, or C<''> for local files.

The decision is made based on the name of the file / dir, without
any extension.

If C<load_as()> returns an empty string, then each key in the file/tree
is merged separately. This is how the C<local.*> files work by default.
See L</"OVERRIDING CONFIG LOCALLY">.

For instance:

   main.yaml:
     key1:  value
     key2:  value

   db.yaml:
     key3:  value
     key4:  value

   local.yaml:
     main:
        key1: new_value
     db:
        key4: new_value

To use C<load_as()>, you can either subclass it, or pass in a parameter
to new:

=over

=item C<qr/(regex)/>

The regex will be checked against the file/dir name, and if it matches
then it returns the string captured in the regex, otherwise it returns
the original name.

=item C<sub {}> or subclassed C<is_local>

   sub {
       my ($self,$name,$is_local) = @_;
       ...make decision...
       return 'string';   # string is used as the keyname
       return '';         # acts like local.* (see above)
       return undef;      # don't load this file/dir
   }

=back

Also, see L</"EXAMPLE USING is_local() AND load_as()">.

=cut

#===================================
sub load_as {
#===================================
    my ( $self, $filename, $local ) = @_;
    return $local ? '' : $filename;
}

my %callbacks = (
    CODE  => \&_init_code_callback,
    HASH  => \&_init_hash_callback,
    ARRAY => \&_init_array_callback,
);

=item EXAMPLE USING C<is_local()> AND C<load_as()>

For instance, instead of using C<local.*> files, you may want to
keep versioned copies of local configs for different machines, and so use:

   app.yaml
   app-(dev1.domain.com).yaml
   app-(dev2.domain.com).yaml

You would implement this as follows:

    my $config = Config::Merge->new(
        path        => '/path/to/config',

        # If matches 'xxx-(yyy)'
        is_local    => sub {
            my ( $self, $name ) = @_;
            return $name=~/- [(] .+ [)]/x ? 1 : 0;
        },

        # If local and matches 'xxx-(hostname)', return xxx
        load_as => sub {
            my ( $self, $name, $is_local ) = @_;
            if ($is_local) {
                if ( $name=~/(.*) - [(] ($hostname) [)] /x ) {
                    return  $1;
                }
                return undef;
            }
            return $name;
        }
    );

See C<examples/advanced.pl> for a working illustration.

=item C<sort()>

    $c = Config::Merge->new(
            path   => '/path/to/config',
            sort   => sub {}
    );

By default, directory entries are sorted alphabetically, with
directories before filenames.

This would be the order for these directory entries:

  api/
  api-(dev1)/
  api.yaml
  api-(dev1).yaml

To override this, you can subclass C<sort()> or pass it in as a
parameter to new:

   sub {
       my ($self,$names_array_ref) = @_
       ...sort...
       return $names_array_ref;
   }

=cut

#===================================
sub sort {
#===================================
    my ( $self, $names ) = @_;
    s/[.]([^.]+$)/ .$1/ foreach @$names;
    $names = [ sort { $a cmp $b } @$names ];
    s/ [.]([^.]+$)/.$1/ foreach @$names;
    return $names;
}

=item C<debug()>

    my $config = Config::Merge->new(
        path        => '/path/to/config',
        debug       => 1 | 0
    );

If C<debug> is true, then Config::Merge prints out an explanation
of what it is doing on STDERR.

=back

=cut

#===================================
sub debug {
#===================================
    my $self = shift;
    print STDERR ( join( "\n", @_, '' ) )
        if $self->{debug};
    return 1;
}

#===================================
sub _init_callback {
#===================================
    my ( $self, $callback, $check ) = @_;

    # If nothing set, use default or subclassed version
    unless ($check) {
        $self->{$callback} = $self->can($callback);
        $self->debug("Using default or subclassed $callback()");
        return;
    }

    $check = [$check]
        unless exists $callbacks{ ref $check };

    $self->debug( 'Using ' . ( ref $check ) . " handler for $callback()" );

    $self->{$callback} = $callbacks{ ref $check }->( $check, $callback );
    return;
}

#===================================
sub _init_code_callback {
#===================================
    return $_[0];
}

#===================================
sub _init_hash_callback {
#===================================
    my ( $check, $callback ) = @_;
    die "load_as() cannot be a hashref"
        if $callback eq 'load_as';
    return sub {
        my $self  = shift;
        my $param = shift;
        return exists $check->{$param};
    };
}

#===================================
sub _init_array_callback {
#===================================
    my ( $check, $callback ) = @_;
    if ( $callback eq 'load_as' ) {
        die "load_as() must contain a single regex"
            unless @$check == 1;
        my $regex = $check->[0];
        return sub {
            my $self     = shift;
            my $filename = shift;
            return $filename =~ m/$regex/
                ? $1
                : $filename;
        };
    }

    foreach my $value (@$check) {
        $value ||= '';
        die "'$value' is not a regular expression"
            unless ref $value eq 'Regexp';
    }
    return sub {
        my $self  = shift;
        my $value = shift;
        foreach my $regex (@$check) {
            return 1 if $value =~ m/$regex/;
        }
        return 0;
    };
}

=head1 SEE ALSO

L<Storable>, L<Config::Any>, L<Config::Any::YAML>,
L<Config::Any::JSON>, L<Config::Any::INI>, L<Config::Any::XML>,
L<Config::Any::General>

=head1 THANKS

Thanks to Hasanuddin Tamir [HASANT] for vacating the Config::Merge namespace,
which allowed me to rename Config::Loader to the more meaningful Config::Merge.

His version of Config::Merge can be found in
L<http://backpan.cpan.org/modules/by-authors/id/H/HA/HASANT/>.

Thanks to Joel Bernstein and Brian Cassidy for the interface to the various
configuration modules. Also to Ewan Edwards for his suggestions about how
to make Config::Merge more flexible.

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to
L<http://github.com/clintongormley/ConfigMerge/issues>.

=head1 AUTHOR

Clinton Gormley, E<lt>clinton@traveljury.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2007-2010 by Clinton Gormley

=cut

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut

1

